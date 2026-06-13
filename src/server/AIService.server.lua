--!strict
-- M2 (docs/13 W2.1–W2.6): bot opponents on the racing line + live positions.
-- Bots are kinematic followers of a Catmull-Rom line built from the respawn
-- nodes — smooth, cheap, deterministic. (Physical bot karts: later milestone.)
-- They wait at the start, go when the player launches, and finish places lock.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SplineUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SplineUtil"))

local BOT_COUNT = 7
local BOT_COLORS = {
	Color3.fromRGB(250, 200, 60),
	Color3.fromRGB(80, 160, 250),
	Color3.fromRGB(120, 120, 130),
	Color3.fromRGB(240, 240, 245),
	Color3.fromRGB(120, 200, 90),
	Color3.fromRGB(250, 130, 190),
	Color3.fromRGB(150, 90, 200),
}
-- target cruise speeds per bot (difficulty spread; rubber-band scales these)
-- Halved with the casual rebalance (docs/15 P1) to match the slower player kart.
local BOT_SPEEDS = { 31, 34, 37, 39, 42, 44, 47 }
local RUBBERBAND_RANGE = 700 -- studs of gap at which the full factor applies
local RUBBERBAND_MIN, RUBBERBAND_MAX = 0.85, 1.25
local SLOPE_SPEED_BONUS = 1.4 -- downhill tangent multiplier cap

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local launchRemote = remotes:WaitForChild("RequestLaunch") :: RemoteEvent
local respawnRemote = remotes:WaitForChild("RequestRespawn") :: RemoteEvent

-- ============ racing line ============
local function buildSpline(): SplineUtil.Spline?
	local track = workspace:WaitForChild("Track", 120)
	if not track then
		return nil
	end
	local anchor = track:WaitForChild("RespawnNodes", 30)
	anchor = anchor and anchor:WaitForChild("NodeAnchor", 30)
	if not anchor then
		return nil
	end
	local nodes: { Attachment } = {}
	for _, child in anchor:GetChildren() do
		if child:IsA("Attachment") then
			table.insert(nodes, child)
		end
	end
	table.sort(nodes, function(a, b)
		return a.Name < b.Name
	end)
	if #nodes < 2 then
		return nil
	end
	local points = table.create(#nodes)
	for _, node in nodes do
		table.insert(points, node.WorldPosition)
	end
	return SplineUtil.new(points, 8)
end

local line: SplineUtil.Spline? = buildSpline()

-- ============ bot karts ============
type Bot = {
	model: Model,
	chassis: Part,
	dist: number,
	lateral: number,
	cruise: number,
	finished: boolean,
	place: number?,
	frozenUntil: number,
	baseColor: Color3,
}

local botsFolder = Instance.new("Folder")
botsFolder.Name = "Bots"
botsFolder.Parent = workspace

local bots: { Bot } = {}
local raceActive = false
local finishCounter = 0
local activeBotCount = BOT_COUNT
local cruiseOverride: number? = nil

local function makeBot(i: number): Bot
	local model = Instance.new("Model")
	model.Name = "BotKart_" .. i

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Vector3.new(6, 2, 9)
	chassis.Color = BOT_COLORS[i]
	chassis.Material = Enum.Material.SmoothPlastic
	chassis.Anchored = true
	chassis.CanCollide = false -- ghosts in M2; physical bumping is a later milestone
	chassis.Parent = model
	model.PrimaryPart = chassis

	local nose = Instance.new("WedgePart")
	nose.Size = Vector3.new(4, 2, 3)
	nose.Color = Color3.fromRGB(40, 40, 45)
	nose.Anchored = true
	nose.CanCollide = false
	nose.Parent = model

	-- cosmetic parity with the player kart (docs/15 P10). Created at offsets from
	-- the origin (chassis is at origin here); model:PivotTo carries them along.
	local hood = Instance.new("Part")
	hood.Size = Vector3.new(4.8, 1.4, 4.5)
	hood.Color = BOT_COLORS[i]
	hood.Material = Enum.Material.SmoothPlastic
	hood.Anchored = true
	hood.CanCollide = false
	hood.CFrame = CFrame.new(0, 1.5, -1)
	hood.Parent = model
	for _, sx in { -1, 1 } do
		local hl = Instance.new("Part")
		hl.Shape = Enum.PartType.Ball
		hl.Size = Vector3.new(1.1, 1.1, 1.1)
		hl.Color = Color3.fromRGB(255, 245, 200)
		hl.Material = Enum.Material.Neon
		hl.Anchored = true
		hl.CanCollide = false
		hl.CFrame = CFrame.new(sx * 1.8, 0.1, -4.8)
		hl.Parent = model
		local tl = Instance.new("Part")
		tl.Size = Vector3.new(0.9, 0.7, 0.4)
		tl.Color = Color3.fromRGB(220, 40, 40)
		tl.Material = Enum.Material.Neon
		tl.Anchored = true
		tl.CanCollide = false
		tl.CFrame = CFrame.new(sx * 1.8, 0.5, 4.7)
		tl.Parent = model
	end

	model.Parent = botsFolder

	return {
		model = model,
		chassis = chassis,
		dist = -(i * 9), -- staggered grid behind the line
		lateral = (i - (BOT_COUNT + 1) / 2) * 4.5,
		cruise = BOT_SPEEDS[i],
		finished = false,
		place = nil,
		frozenUntil = 0,
		baseColor = BOT_COLORS[i],
	}
end

local function poseBot(bot: Bot)
	local l = line
	if not l then
		return
	end
	local d = math.max(bot.dist, 0)
	local pos = l:PosAt(d)
	local tangent = l:TangentAt(d)
	-- guard: tangent can go vertical inside loops/corkscrews
	local right = tangent:Cross(Vector3.yAxis)
	right = right.Magnitude > 0.05 and right.Unit or Vector3.xAxis
	local up = right:Cross(tangent)
	up = up.Magnitude > 0.05 and up.Unit or Vector3.yAxis
	local offsetPos = pos + right * bot.lateral + up
	local cf = CFrame.lookAt(offsetPos, offsetPos + tangent * 10, up)
	bot.model:PivotTo(cf)
	local nose = bot.model:FindFirstChildOfClass("WedgePart")
	if nose then
		nose.CFrame = cf * CFrame.new(0, 0, -6)
	end
end

local function resetBots()
	raceActive = false
	finishCounter = 0
	for i, bot in bots do
		bot.dist = -(i * 9)
		bot.finished = false
		bot.place = nil
		bot.frozenUntil = 0
		bot.chassis.Color = bot.baseColor
		local active = i <= activeBotCount
		bot.model.Parent = active and botsFolder or nil
		if active then
			poseBot(bot)
		end
	end
end

for i = 1, BOT_COUNT do
	local bot = makeBot(i)
	table.insert(bots, bot)
	poseBot(bot)
end

-- ============ player progress tracking ============
type Progress = { dist: number, hint: number }
local playerProgress: { [Player]: Progress } = {}

local function trackPlayer(player: Player)
	playerProgress[player] = { dist = 0, hint = 1 }
end
Players.PlayerAdded:Connect(trackPlayer)
for _, p in Players:GetPlayers() do
	trackPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	playerProgress[p] = nil
end)

-- ============ race control ============
launchRemote.OnServerEvent:Connect(function()
	if not raceActive then
		raceActive = true
	end
end)

respawnRemote.OnServerEvent:Connect(function(player, nodeIdx)
	if (tonumber(nodeIdx) or 1) <= 1 then
		resetBots()
		local prog = playerProgress[player]
		if prog then
			prog.dist = 0
			prog.hint = 1
		end
	end
end)

-- ============ per-challenge bot grid config (from ChallengeService) ============
local ServerStorage = game:GetService("ServerStorage")
task.spawn(function()
	local bus = ServerStorage:WaitForChild("BotConfigBus", 30) :: BindableEvent?
	if not bus then
		return
	end
	bus.Event:Connect(function(config: { count: number?, cruiseOverride: number? })
		activeBotCount = math.clamp(config.count or BOT_COUNT, 0, BOT_COUNT)
		cruiseOverride = config.cruiseOverride
		resetBots()
	end)
end)

-- ============ track swaps rebuild the racing line ============
task.spawn(function()
	local bus = ServerStorage:WaitForChild("TrackChangedBus", 60) :: BindableEvent?
	if not bus then
		return
	end
	bus.Event:Connect(function()
		line = buildSpline()
		for _, prog in playerProgress do
			prog.dist = 0
			prog.hint = 1
		end
		resetBots()
	end)
end)

-- ============ power effects on bots (from PowerService) ============
task.spawn(function()
	local bus = ServerStorage:WaitForChild("BotEffectBus", 30) :: BindableEvent?
	if not bus then
		return
	end
	bus.Event:Connect(function(fromPlayer: Player, effect: { [string]: any })
		local prog = playerProgress[fromPlayer]
		local playerDist = prog and prog.dist or 0

		-- collect candidates by along-track distance from the caster
		local candidates: { { bot: Bot, gap: number } } = {}
		for _, bot in bots do
			if bot.finished then
				continue
			end
			local gap = bot.dist - playerDist
			if effect.aheadOnly and gap <= 0 then
				continue
			end
			if effect.range and math.abs(gap) > effect.range then
				continue
			end
			table.insert(candidates, { bot = bot, gap = math.abs(gap) })
		end
		table.sort(candidates, function(a, b)
			return a.gap < b.gap
		end)

		local maxTargets = effect.targets or #candidates
		for i = 1, math.min(maxTargets, #candidates) do
			local bot = candidates[i].bot
			if effect.knockback then
				bot.dist = math.max(bot.dist - effect.knockback, 0)
			end
			if effect.freezeTime then
				bot.frozenUntil = os.clock() + effect.freezeTime
			end
			poseBot(bot)
		end
	end)
end)

-- ============ main loop ============
local positionTick = 0

RunService.Heartbeat:Connect(function(dt)
	if not raceActive then
		return
	end
	local l = line
	if not l then
		return
	end

	-- furthest player progress (rubber-band reference)
	local leadPlayerDist = 0
	for player, prog in playerProgress do
		local kart = workspace:FindFirstChild(player.Name .. "_Kart")
		local chassis = kart and kart:FindFirstChild("Chassis")
		if chassis and chassis:IsA("BasePart") then
			local d, hint = l:NearestDist(chassis.Position, prog.hint)
			-- only accept forward-ish movement (avoids snapping across switchbacks)
			if d > prog.dist - 80 then
				prog.dist = math.max(prog.dist, d)
				prog.hint = hint
			end
			leadPlayerDist = math.max(leadPlayerDist, prog.dist)
		end
	end

	-- advance bots
	local now = os.clock()
	for i, bot in bots do
		if bot.finished or i > activeBotCount then
			continue
		end
		if now < bot.frozenUntil then
			bot.chassis.Color = Color3.fromRGB(150, 220, 255)
			continue
		elseif bot.chassis.Color ~= bot.baseColor then
			bot.chassis.Color = bot.baseColor
		end
		local gap = leadPlayerDist - bot.dist
		local rubber = math.clamp(1 + (gap / RUBBERBAND_RANGE) * 0.35, RUBBERBAND_MIN, RUBBERBAND_MAX)
		local tangent = l:TangentAt(math.max(bot.dist, 0))
		local slope = math.clamp(1 + math.max(-tangent.Y, 0) * 1.2, 1, SLOPE_SPEED_BONUS)
		local cruise = cruiseOverride or bot.cruise
		bot.dist += cruise * rubber * slope * dt
		if bot.dist >= l.total then
			bot.finished = true
			finishCounter += 1
			bot.place = finishCounter
			bot.dist = l.total
		end
		poseBot(bot)
	end

	-- live positions for players (10x/s)
	positionTick += dt
	if positionTick >= 0.1 then
		positionTick = 0
		-- racing players (started moving) count in each other's positions
		local racingPlayers = 0
		for _, prog in playerProgress do
			if prog.dist > 5 then
				racingPlayers += 1
			end
		end
		racingPlayers = math.max(racingPlayers, 1)
		for player, prog in playerProgress do
			local ahead = 0
			for i, bot in bots do
				if i <= activeBotCount and bot.dist > prog.dist then
					ahead += 1
				end
			end
			for other, otherProg in playerProgress do
				if other ~= player and otherProg.dist > 5 and otherProg.dist > prog.dist then
					ahead += 1
				end
			end
			player:SetAttribute("RacePosition", ahead + 1)
			player:SetAttribute("RacersTotal", activeBotCount + racingPlayers)
		end
	end
end)
