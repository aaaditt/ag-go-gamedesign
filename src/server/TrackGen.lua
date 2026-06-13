--!strict
-- Ribbon track generator (docs/12 geometry standard), parametrized by
-- TrackDef (segments + theme). Returns the Track folder (unparented).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TracksConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tracks"))

local ROAD_WIDTH = 42
local ROAD_THICKNESS = 3
local RAIL_HEIGHT = 4
local STEP = 6
local STEP_OVERLAP = 2.5
local MAX_YAW_PER_STEP = 4
local MAX_PITCH_DELTA_PER_STEP = 1.5
local NODE_EVERY = 50
local START_CF = CFrame.new(0, 400, 0)

local TrackGen = {}

function TrackGen.Build(def: TracksConfig.TrackDef): Folder
	local theme = def.theme
	local trackFolder = Instance.new("Folder")
	trackFolder.Name = "Track"
	trackFolder:SetAttribute("TrackId", def.id)

	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "RespawnNodes"
	nodesFolder.Parent = trackFolder

	local nodeAnchor = Instance.new("Part")
	nodeAnchor.Name = "NodeAnchor"
	nodeAnchor.Anchored = true
	nodeAnchor.Transparency = 1
	nodeAnchor.CanCollide = false
	nodeAnchor.Size = Vector3.one
	nodeAnchor.CFrame = CFrame.new(0, -500, 0)
	nodeAnchor.Parent = nodesFolder

	local function makePart(size: Vector3, cf: CFrame, color: Color3, name: string): Part
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = Enum.Material.SmoothPlastic
		p.Name = name
		p.Parent = trackFolder
		return p
	end

	local nodeIndex = 0
	local function dropNode(cf: CFrame)
		nodeIndex += 1
		local node = Instance.new("Attachment")
		node.Name = string.format("Node%03d", nodeIndex)
		node.Parent = nodeAnchor
		node.WorldCFrame = cf * CFrame.new(0, 4, 0)
	end

	-- start pad + slingshot posts + spawns
	local pad = makePart(Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, 40), START_CF, theme.padColor, "StartPad")
	local forkCF = START_CF * CFrame.new(0, 0, -8)
	makePart(Vector3.new(2, 14, 2), forkCF * CFrame.new(-8, 8, 0), Color3.fromRGB(110, 70, 40), "SlingPostL")
	makePart(Vector3.new(2, 14, 2), forkCF * CFrame.new(8, 8, 0), Color3.fromRGB(110, 70, 40), "SlingPostR")

	local kartSpawn = Instance.new("Attachment")
	kartSpawn.Name = "KartSpawn"
	kartSpawn.Parent = pad
	kartSpawn.WorldCFrame = START_CF * CFrame.new(0, 4, -5)
	dropNode(START_CF * CFrame.new(0, 0, -5))

	-- (no SpawnLocation here — players spawn in the Lobby, docs/14)

	-- ribbon walk
	local cursor = START_CF * CFrame.new(0, 0, -20)
	local currentPitch = 0
	local sinceNode = 0

	local function placeStep(mid: CFrame, segIdx: number)
		local road = makePart(
			Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, STEP + STEP_OVERLAP),
			mid,
			theme.roadColor,
			"Road_" .. segIdx
		)
		road.Material = theme.roadMaterial
		if theme.ice then
			road:SetAttribute("Ice", true)
		end
		for _, side in { -1, 1 } do
			makePart(
				Vector3.new(1.5, RAIL_HEIGHT, STEP + 3),
				mid * CFrame.new(side * (ROAD_WIDTH / 2 + 0.75), RAIL_HEIGHT / 2 + ROAD_THICKNESS / 2, 0),
				theme.railColor,
				"Rail"
			)
		end
	end

	for segIdx, segDef in def.segments do
		-- ============ vertical LOOP segments (docs/15 P2: grand + integrated) ============
		-- A clean vertical loop: pitch a full 360° so the EXIT heading stays
		-- parallel to the entry (reads as "properly integrated", no off-axis
		-- drift). The whole loop marches sideways by a FIXED amount so the exit
		-- road clears the entry road regardless of how big the loop is. Step
		-- count scales with radius so even a 140-stud loop stays smooth.
		if segDef.loop then
			local radius = segDef.radius or 90
			local steps = math.clamp(math.round(radius * 0.7), 28, 80)
			local anglePer = 360 / steps
			local stepLen = 2 * math.pi * radius / steps
			local sidePerStep = (ROAD_WIDTH + 12) / steps -- exit clears entry, radius-independent
			local loopStart = currentPitch
			for _ = 1, steps do
				currentPitch += anglePer
				cursor = cursor * CFrame.new(sidePerStep, 0, 0) -- uniform sideways drift
				local stepped = cursor * CFrame.Angles(math.rad(currentPitch), 0, 0)
				local mid = stepped * CFrame.new(0, 0, -stepLen / 2)
				placeStep(mid, segIdx)
				cursor = stepped * CFrame.new(0, 0, -stepLen) * CFrame.Angles(math.rad(-currentPitch), 0, 0)
				sinceNode += stepLen
				-- respawn nodes only on the right-side-up (bottom) part of the loop
				local p = (currentPitch - loopStart) % 360
				if sinceNode >= NODE_EVERY and (p < 45 or p > 315) then
					dropNode(cursor)
					sinceNode = 0
				end
			end
			currentPitch -= 360 -- full circle: back to the incoming pitch
			continue
		end

		local steps = math.max(1, math.ceil(segDef.length / STEP))
		if math.abs(segDef.yawDeg) / steps > MAX_YAW_PER_STEP then
			steps = math.ceil(math.abs(segDef.yawDeg) / MAX_YAW_PER_STEP)
		end
		local stepLen = segDef.length / steps
		local yawPerStep = segDef.yawDeg / steps

		if segDef.boostPad and not segDef.gap then
			local bp = makePart(
				Vector3.new(ROAD_WIDTH * 0.6, 0.4, 14),
				cursor * CFrame.new(0, ROAD_THICKNESS / 2 + 0.2, -10),
				Color3.fromRGB(255, 150, 30),
				"BoostPad"
			)
			bp.Material = Enum.Material.Neon
		end

		for _ = 1, steps do
			local delta = math.clamp(segDef.pitchDeg - currentPitch, -MAX_PITCH_DELTA_PER_STEP, MAX_PITCH_DELTA_PER_STEP)
			currentPitch += delta
			cursor = cursor * CFrame.Angles(0, math.rad(yawPerStep / 2), 0)
			local stepped = cursor * CFrame.Angles(math.rad(currentPitch), 0, 0)
			local mid = stepped * CFrame.new(0, 0, -stepLen / 2)
			if not segDef.gap then
				placeStep(mid, segIdx)
			end
			cursor = stepped * CFrame.new(0, 0, -stepLen) * CFrame.Angles(math.rad(-currentPitch), 0, 0)
				* CFrame.Angles(0, math.rad(yawPerStep / 2), 0)
			sinceNode += stepLen
			if sinceNode >= NODE_EVERY and not segDef.gap then
				dropNode(cursor)
				sinceNode = 0
			end
		end
	end

	-- finish
	makePart(Vector3.new(ROAD_WIDTH + 20, ROAD_THICKNESS, 50), cursor * CFrame.new(0, 0, -25), Color3.fromRGB(240, 220, 100), "FinishPad")
	local banner = makePart(Vector3.new(ROAD_WIDTH, 8, 1), cursor * CFrame.new(0, 12, -25), Color3.fromRGB(60, 60, 200), "FinishBanner")
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Text = "FINISH — " .. def.name
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	gui.Parent = banner
	dropNode(cursor * CFrame.new(0, 0, -25))

	return trackFolder
end

return TrackGen
