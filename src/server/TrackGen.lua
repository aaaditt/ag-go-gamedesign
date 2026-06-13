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
-- docs/15 P4: start high enough that even the long new tracks (which descend
-- 500–800 studs) stay above Tuning.FallY (-120) for the whole lap.
local START_CF = CFrame.new(0, 1100, 0)
local PROP_EVERY = 34 -- studs between roadside prop clusters

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

	-- ============ procedural roadside props (docs/15 P4) ============
	-- Blocks + balls only (no Cylinder parts — their length-along-X axis is a
	-- common "tree lying on its side" trap). Props are planted in WORLD up and
	-- only beside right-side-up road, so loops/walls never get furniture.
	local function ball(diam: number, pos: Vector3, color: Color3, material: Enum.Material): Part
		local p = makePart(Vector3.new(diam, diam, diam), CFrame.new(pos), color, "Prop")
		p.Shape = Enum.PartType.Ball
		p.Material = material
		p.CanCollide = false
		return p
	end
	local function block(size: Vector3, cf: CFrame, color: Color3, material: Enum.Material): Part
		local p = makePart(size, cf, color, "Prop")
		p.Material = material
		p.CanCollide = false
		return p
	end

	local function buildProp(style: string, basePos: Vector3)
		if style == "grass" then
			if math.random() < 0.7 then -- round tree
				local h = math.random(14, 26)
				block(Vector3.new(2.6, h, 2.6), CFrame.new(basePos + Vector3.new(0, h / 2, 0)), Color3.fromRGB(96, 64, 38), Enum.Material.Wood)
				ball(h * 0.95, basePos + Vector3.new(0, h + 1, 0), Color3.fromRGB(72, 138, 64), Enum.Material.Grass)
			else -- bush
				local s = math.random(6, 11)
				ball(s, basePos + Vector3.new(0, s * 0.45, 0), Color3.fromRGB(86, 150, 72), Enum.Material.Grass)
			end
		elseif style == "canyon" then
			if math.random() < 0.55 then -- rock spire
				local h, w = math.random(16, 42), math.random(8, 16)
				block(
					Vector3.new(w, h, w * 0.9),
					CFrame.new(basePos + Vector3.new(0, h / 2, 0))
						* CFrame.Angles(math.rad(math.random(-5, 5)), math.rad(math.random(0, 180)), math.rad(math.random(-5, 5))),
					Color3.fromRGB(170, 116, 74),
					Enum.Material.Slate
				)
			else -- cactus (column + one arm)
				local h = math.random(12, 20)
				block(Vector3.new(3.4, h, 3.4), CFrame.new(basePos + Vector3.new(0, h / 2, 0)), Color3.fromRGB(72, 120, 70), Enum.Material.Grass)
				block(Vector3.new(2.6, h * 0.4, 2.6), CFrame.new(basePos + Vector3.new(3, h * 0.55, 0)), Color3.fromRGB(72, 120, 70), Enum.Material.Grass)
			end
		else -- ice
			if math.random() < 0.6 then -- snow pine (trunk + stacked tiers)
				local h = math.random(16, 28)
				block(Vector3.new(2.2, h * 0.45, 2.2), CFrame.new(basePos + Vector3.new(0, h * 0.22, 0)), Color3.fromRGB(96, 64, 38), Enum.Material.Wood)
				for i = 0, 2 do
					local sz = h * (0.72 - i * 0.18)
					ball(sz, basePos + Vector3.new(0, h * 0.42 + i * h * 0.2, 0), Color3.fromRGB(78, 128, 98), Enum.Material.Snow)
				end
			else -- ice spike
				local h = math.random(14, 30)
				local sp = block(
					Vector3.new(4, h, 4),
					CFrame.new(basePos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(math.rad(math.random(-4, 4)), 0, math.rad(math.random(-4, 4))),
					Color3.fromRGB(150, 205, 240),
					Enum.Material.Ice
				)
				sp.Transparency = 0.25
			end
		end
	end

	local function placeProps(mid: CFrame, style: string)
		if mid.UpVector.Y < 0.6 then -- skip loops / walls / inverted road
			return
		end
		local right = Vector3.new(mid.RightVector.X, 0, mid.RightVector.Z)
		local fwd = Vector3.new(mid.LookVector.X, 0, mid.LookVector.Z)
		if right.Magnitude < 0.05 or fwd.Magnitude < 0.05 then
			return
		end
		right, fwd = right.Unit, fwd.Unit
		for _, side in { -1, 1 } do
			if math.random() < 0.85 then
				local dist = ROAD_WIDTH / 2 + 12 + math.random(0, 16)
				local jitter = (math.random() - 0.5) * 18
				buildProp(style, mid.Position + right * (side * dist) + fwd * jitter)
			end
		end
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

	-- distant themed valley floor (cosmetic backdrop; CanCollide off so a real
	-- fall still drops through to Tuning.FallY and respawns rather than landing)
	local groundMat = theme.propStyle == "ice" and Enum.Material.Snow
		or (theme.propStyle == "canyon" and Enum.Material.Sand or Enum.Material.Grass)
	local ground = makePart(
		Vector3.new(7000, 8, 7000),
		CFrame.new(START_CF.X, START_CF.Y - 900, START_CF.Z - 1600),
		theme.groundColor,
		"ValleyFloor"
	)
	ground.Material = groundMat
	ground.CanCollide = false

	-- ribbon walk
	local cursor = START_CF * CFrame.new(0, 0, -20)
	local currentPitch = 0
	local sinceNode = 0
	local sinceProp = 0
	local dashToggle = false

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
		-- dashed centre line (cosmetic): every other step, sits on the road surface
		dashToggle = not dashToggle
		if dashToggle then
			makePart(
				Vector3.new(2.6, 0.25, (STEP + STEP_OVERLAP) * 0.55),
				mid * CFrame.new(0, ROAD_THICKNESS / 2 + 0.15, 0),
				Color3.fromRGB(245, 240, 220),
				"Dash"
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
				sinceProp += stepLen
				if sinceProp >= PROP_EVERY then
					placeProps(mid, theme.propStyle)
					sinceProp = 0
				end
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
