--!strict
-- Track generator v2 (docs/12 geometry standard): builds the greybox hill as a
-- SMOOTH ribbon — 6-stud steps, ≤4° turn and ≤1.5° pitch change per step, with
-- overlap, so curves have no outer-edge holes and slope changes have no creases.
-- Skips itself if a Track already exists (editor-authored track wins).
-- Regenerate: delete workspace.Track, then run this from the command bar:
--   loadstring(game.ServerScriptService.Server.TrackBuilder.Source)()

if workspace:FindFirstChild("Track") then
	print("[TrackBuilder] Track already present in workspace — skipping procedural build")
	return
end

local ROAD_WIDTH = 42
local ROAD_THICKNESS = 3
local RAIL_HEIGHT = 4
local STEP = 6 -- studs per ribbon step
local STEP_OVERLAP = 2.5
local MAX_YAW_PER_STEP = 4 -- degrees (keeps outer-curve gaps < overlap)
local MAX_PITCH_DELTA_PER_STEP = 1.5 -- degrees (eases slope transitions)
local NODE_EVERY = 50 -- studs of ribbon per respawn node

local trackFolder = Instance.new("Folder")
trackFolder.Name = "Track"

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

-- ============ authored segment list ============
-- pitchDeg: negative = downhill (target pitch; transitions are eased)
-- yawDeg: total turn across the segment   gap: no road (a jump)
-- boostPad: orange pad at segment start
type Segment = {
	length: number,
	pitchDeg: number,
	yawDeg: number,
	gap: boolean?,
	boostPad: boolean?,
	label: string?,
}

local SEGMENTS: { Segment } = {
	{ length = 50, pitchDeg = -5, yawDeg = 0, label = "start chute" },
	{ length = 80, pitchDeg = -13, yawDeg = 0, label = "first dive" },
	{ length = 70, pitchDeg = -8, yawDeg = -50, label = "left sweeper" },
	{ length = 50, pitchDeg = -16, yawDeg = 0, boostPad = true, label = "steep dive" },
	{ length = 80, pitchDeg = -10, yawDeg = 55, label = "right horseshoe" },
	{ length = 50, pitchDeg = -4, yawDeg = 0, label = "breather flat-ish" },
	{ length = 40, pitchDeg = -12, yawDeg = -25, label = "kink left" },
	{ length = 45, pitchDeg = -3, yawDeg = 0, boostPad = true, label = "boost runway" },
	{ length = 30, pitchDeg = 14, yawDeg = 0, label = "JUMP ramp" },
	{ length = 38, pitchDeg = 0, yawDeg = 0, gap = true, label = "THE GAP (38)" },
	{ length = 70, pitchDeg = -14, yawDeg = 0, label = "landing slope" },
	{ length = 80, pitchDeg = -8, yawDeg = -35, label = "final sweeper" },
	{ length = 90, pitchDeg = -4, yawDeg = 0, label = "run-out" },
	{ length = 50, pitchDeg = -1, yawDeg = 0, label = "finish flat" },
}

-- ============ start pad + slingshot ============
local START_CF = CFrame.new(0, 400, 0)
local pad = makePart(Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, 40), START_CF, Color3.fromRGB(120, 200, 120), "StartPad")

local forkCF = START_CF * CFrame.new(0, 0, -8)
makePart(Vector3.new(2, 14, 2), forkCF * CFrame.new(-8, 8, 0), Color3.fromRGB(110, 70, 40), "SlingPostL")
makePart(Vector3.new(2, 14, 2), forkCF * CFrame.new(8, 8, 0), Color3.fromRGB(110, 70, 40), "SlingPostR")

local kartSpawn = Instance.new("Attachment")
kartSpawn.Name = "KartSpawn"
kartSpawn.Parent = pad
kartSpawn.WorldCFrame = START_CF * CFrame.new(0, 4, -5)
dropNode(START_CF * CFrame.new(0, 0, -5))

local spawnLoc = Instance.new("SpawnLocation")
spawnLoc.Size = Vector3.new(8, 1, 8)
spawnLoc.CFrame = START_CF * CFrame.new(0, 2, 12)
spawnLoc.Anchored = true
spawnLoc.Neutral = true
spawnLoc.Transparency = 1
spawnLoc.Duration = 0
spawnLoc.Parent = trackFolder

-- ============ ribbon walk ============
-- cursor: road grows along -Z. Pitch is eased toward each segment's target.
local cursor = START_CF * CFrame.new(0, 0, -20)
local currentPitch = 0 -- degrees
local sinceNode = 0
local stepCount = 0

local function placeStep(mid: CFrame, segIdx: number)
	local road = makePart(
		Vector3.new(ROAD_WIDTH, ROAD_THICKNESS, STEP + STEP_OVERLAP),
		mid,
		Color3.fromRGB(160, 160, 165),
		"Road_" .. segIdx
	)
	road.Material = Enum.Material.Concrete
	for _, side in { -1, 1 } do
		makePart(
			Vector3.new(1.5, RAIL_HEIGHT, STEP + 3),
			mid * CFrame.new(side * (ROAD_WIDTH / 2 + 0.75), RAIL_HEIGHT / 2 + ROAD_THICKNESS / 2, 0),
			Color3.fromRGB(220, 90, 60),
			"Rail"
		)
	end
end

local function placeBoostPad(cf: CFrame)
	local padPart = makePart(
		Vector3.new(ROAD_WIDTH * 0.6, 0.4, 14),
		cf * CFrame.new(0, ROAD_THICKNESS / 2 + 0.2, 0),
		Color3.fromRGB(255, 150, 30),
		"BoostPad"
	)
	padPart.Material = Enum.Material.Neon
end

for segIdx, seg in SEGMENTS do
	local steps = math.max(1, math.ceil(seg.length / STEP))
	-- respect the max-yaw-per-step rule (more steps on tight turns)
	if math.abs(seg.yawDeg) / steps > MAX_YAW_PER_STEP then
		steps = math.ceil(math.abs(seg.yawDeg) / MAX_YAW_PER_STEP)
	end
	local stepLen = seg.length / steps
	local yawPerStep = seg.yawDeg / steps

	if seg.boostPad and not seg.gap then
		placeBoostPad(cursor * CFrame.new(0, 0, -10))
	end

	for _ = 1, steps do
		-- ease pitch toward this segment's target
		local delta = math.clamp(seg.pitchDeg - currentPitch, -MAX_PITCH_DELTA_PER_STEP, MAX_PITCH_DELTA_PER_STEP)
		currentPitch += delta

		-- split the step's yaw half before / half after (smooth chord)
		cursor = cursor * CFrame.Angles(0, math.rad(yawPerStep / 2), 0)
		local stepped = cursor * CFrame.Angles(math.rad(currentPitch), 0, 0)
		local mid = stepped * CFrame.new(0, 0, -stepLen / 2)
		if not seg.gap then
			stepCount += 1
			placeStep(mid, segIdx)
		end
		cursor = stepped * CFrame.new(0, 0, -stepLen) * CFrame.Angles(math.rad(-currentPitch), 0, 0)
			* CFrame.Angles(0, math.rad(yawPerStep / 2), 0)

		sinceNode += stepLen
		if sinceNode >= NODE_EVERY and not seg.gap then
			dropNode(cursor)
			sinceNode = 0
		end
	end
end

-- ============ finish ============
local finish = makePart(
	Vector3.new(ROAD_WIDTH + 20, ROAD_THICKNESS, 50),
	cursor * CFrame.new(0, 0, -25),
	Color3.fromRGB(240, 220, 100),
	"FinishPad"
)
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
dropNode(cursor * CFrame.new(0, 0, -25))

makePart(Vector3.new(4096, 4, 4096), CFrame.new(0, -200, 0), Color3.fromRGB(80, 140, 200), "Ocean")

trackFolder.Parent = workspace
print(("[TrackBuilder v2] Smooth ribbon built: %d segments, %d road steps, %d respawn nodes"):format(#SEGMENTS, stepCount, nodeIndex))
