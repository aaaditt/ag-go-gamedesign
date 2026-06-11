--!strict
-- Phase 1: procedurally builds the greybox test hill at runtime.
-- One straight chute, two curves (L/R), a ramp jump, and a finish pad.
-- Geometry-in-code means Claude can reshape the track without touching Studio.

local ServerStorage = game:GetService("ServerStorage")

local ROAD_WIDTH = 42
local ROAD_THICKNESS = 3
local RAIL_HEIGHT = 4

local trackFolder = Instance.new("Folder")
trackFolder.Name = "Track"
trackFolder.Parent = workspace

local nodesFolder = Instance.new("Folder")
nodesFolder.Name = "RespawnNodes"
nodesFolder.Parent = trackFolder

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

local nodeAnchor = Instance.new("Part")
nodeAnchor.Name = "NodeAnchor"
nodeAnchor.Anchored = true
nodeAnchor.Transparency = 1
nodeAnchor.CanCollide = false
nodeAnchor.Size = Vector3.one
nodeAnchor.CFrame = CFrame.new(0, -500, 0)
nodeAnchor.Parent = nodesFolder

local nodeIndex = 0
local function dropNode(cf: CFrame)
	nodeIndex += 1
	local node = Instance.new("Attachment")
	node.Name = string.format("Node%03d", nodeIndex)
	node.Parent = nodeAnchor -- parent FIRST: WorldCFrame needs a parent to resolve against
	node.WorldCFrame = cf * CFrame.new(0, 4, 0)
end

-- Track is authored as a segment list; cursor CFrame chains them together.
-- pitchDeg negative = downhill. yawDeg turns the road. length in studs.
type Segment = { length: number, pitchDeg: number, yawDeg: number, gap: boolean?, label: string? }

local SEGMENTS: { Segment } = {
	{ length = 50, pitchDeg = -4, yawDeg = 0, label = "start chute" },
	{ length = 70, pitchDeg = -10, yawDeg = 0 },
	{ length = 70, pitchDeg = -12, yawDeg = 0 },
	{ length = 60, pitchDeg = -8, yawDeg = -25, label = "left sweeper" },
	{ length = 60, pitchDeg = -8, yawDeg = -25 },
	{ length = 80, pitchDeg = -14, yawDeg = 0, label = "steep straight" },
	{ length = 55, pitchDeg = -6, yawDeg = 30, label = "right hairpin-ish" },
	{ length = 55, pitchDeg = -6, yawDeg = 30 },
	{ length = 60, pitchDeg = -10, yawDeg = 0 },
	{ length = 35, pitchDeg = 8, yawDeg = 0, label = "ramp up" },
	{ length = 45, pitchDeg = 0, yawDeg = 0, gap = true, label = "THE JUMP" },
	{ length = 60, pitchDeg = -12, yawDeg = 0, label = "landing slope" },
	{ length = 70, pitchDeg = -9, yawDeg = -20 },
	{ length = 80, pitchDeg = -5, yawDeg = 0, label = "run-out" },
	{ length = 60, pitchDeg = -2, yawDeg = 0, label = "finish flat" },
}

-- Start pad, high in the sky
local START_CF = CFrame.new(0, 400, 0)
local pad = makePart(Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, 40), START_CF, Color3.fromRGB(120, 200, 120), "StartPad")

-- Slingshot fork visual (two posts + crossbar)
local forkCF = START_CF * CFrame.new(0, 0, -8)
makePart(Vector3.new(2, 14, 2), forkCF * CFrame.new(-8, 8, 0), Color3.fromRGB(110, 70, 40), "SlingPostL")
makePart(Vector3.new(2, 14, 2), forkCF * CFrame.new(8, 8, 0), Color3.fromRGB(110, 70, 40), "SlingPostR")

local kartSpawn = Instance.new("Attachment")
kartSpawn.Name = "KartSpawn"
kartSpawn.Parent = pad
kartSpawn.WorldCFrame = START_CF * CFrame.new(0, 4, -5)
dropNode(START_CF * CFrame.new(0, 0, -5))

-- Avatar spawns on the pad (not at world origin) before being seated in the kart
local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Size = Vector3.new(8, 1, 8)
spawnLoc.CFrame = START_CF * CFrame.new(0, 2, 12)
spawnLoc.Anchored = true
spawnLoc.Neutral = true
spawnLoc.Transparency = 1
spawnLoc.Duration = 0
spawnLoc.Parent = trackFolder

-- Chain segments from the front edge of the pad
local cursor = START_CF * CFrame.new(0, 0, -20) -- road grows in -Z (forward)
for i, seg in SEGMENTS do
	-- negative pitch tilts the road's forward (-Z) downward: LookVector.Y = sin(pitch)
	cursor = cursor * CFrame.Angles(0, math.rad(seg.yawDeg / 2), 0) * CFrame.Angles(math.rad(seg.pitchDeg), 0, 0)
	local mid = cursor * CFrame.new(0, 0, -seg.length / 2)
	if not seg.gap then
		local road = makePart(
			Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, seg.length + 2),
			mid,
			Color3.fromRGB(160, 160, 165),
			"Road_" .. i .. (seg.label and ("_" .. seg.label) or "")
		)
		road.Material = Enum.Material.Concrete
		-- side rails
		for _, side in { -1, 1 } do
			makePart(
				Vector3.new(1.5, RAIL_HEIGHT, seg.length + 2),
				mid * CFrame.new(side * (ROAD_WIDTH / 2 + 0.75), RAIL_HEIGHT / 2, 0),
				Color3.fromRGB(220, 90, 60),
				"Rail"
			)
		end
	end
	cursor = cursor * CFrame.new(0, 0, -seg.length) * CFrame.Angles(math.rad(-seg.pitchDeg), 0, 0)
		* CFrame.Angles(0, math.rad(seg.yawDeg / 2), 0)
	dropNode(cursor)
end

-- Finish pad + banner
local finish = makePart(Vector3.new(ROAD_WIDTH + 20, ROAD_THICKNESS, 50), cursor * CFrame.new(0, 0, -25), Color3.fromRGB(240, 220, 100), "FinishPad")
local banner = makePart(Vector3.new(ROAD_WIDTH, 8, 1), cursor * CFrame.new(0, 12, -25), Color3.fromRGB(60, 60, 200), "FinishBanner")
local gui = Instance.new("SurfaceGui")
gui.Face = Enum.NormalId.Front
local label = Instance.new("TextLabel")
label.Size = UDim2.fromScale(1, 1)
label.BackgroundTransparency = 1
label.TextScaled = true
label.Text = "FINISH"
label.TextColor3 = Color3.new(1, 1, 1)
label.Parent = gui
gui.Parent = banner

-- Big safety floor far below (catches falls before FallY respawn fires visually)
makePart(Vector3.new(4096, 4, 4096), CFrame.new(0, -200, 0), Color3.fromRGB(80, 140, 200), "Ocean")

print(("[TrackBuilder] Greybox hill built: %d segments, %d respawn nodes"):format(#SEGMENTS, nodeIndex))
