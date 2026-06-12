--!strict
-- M4 server side: challenge selection, mode props (fruit, slalom gates),
-- bot configuration per mode, fruit smash validation, boss power vs player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Challenges = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Challenges"))
local SplineUtil = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SplineUtil"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local launchRemote = remotes:WaitForChild("RequestLaunch") :: RemoteEvent
local powerFxRemote = remotes:WaitForChild("PowerFx", 30) :: RemoteEvent

local setChallengeRemote = Instance.new("RemoteEvent")
setChallengeRemote.Name = "SetChallenge"
setChallengeRemote.Parent = remotes

local fruitSmashRemote = Instance.new("RemoteEvent")
fruitSmashRemote.Name = "FruitSmash"
fruitSmashRemote.Parent = remotes

-- AIService consumes this to (re)configure the bot grid per challenge
local botConfigBus = Instance.new("BindableEvent")
botConfigBus.Name = "BotConfigBus"
botConfigBus.Parent = ServerStorage

-- ============ racing line (for prop placement) ============
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
	local nodes = {}
	for _, child in anchor:GetChildren() do
		if child:IsA("Attachment") then
			table.insert(nodes, child)
		end
	end
	table.sort(nodes, function(a, b)
		return a.Name < b.Name
	end)
	local points = {}
	for _, n in nodes do
		table.insert(points, n.WorldPosition)
	end
	return #points >= 2 and SplineUtil.new(points, 8) or nil
end

local spline = buildSpline()

-- ============ mode props ============
local propsFolder = Instance.new("Folder")
propsFolder.Name = "ModeProps"
propsFolder.Parent = workspace

local fruitAlive: { [string]: BasePart } = {}

local function clearProps()
	propsFolder:ClearAllChildren()
	table.clear(fruitAlive)
end

-- track swaps rebuild the placement spline and clear stale props
task.spawn(function()
	local bus = ServerStorage:WaitForChild("TrackChangedBus", 60) :: BindableEvent?
	if bus then
		bus.Event:Connect(function()
			spline = buildSpline()
			clearProps()
		end)
	end
end)

local FRUIT_COLORS = { Color3.fromRGB(230, 60, 60), Color3.fromRGB(255, 170, 40), Color3.fromRGB(170, 80, 220) }

local function spawnFruit(count: number)
	if not spline then
		return
	end
	local line = spline :: SplineUtil.Spline
	local from = 80
	local span = line.total - 160
	for i = 1, count do
		local d = from + span * (i - 1) / math.max(count - 1, 1)
		local tangent = line:TangentAt(d)
		local right = tangent:Cross(Vector3.yAxis).Unit
		local lateral = math.random(-14, 14)
		local fruit = Instance.new("Part")
		fruit.Shape = Enum.PartType.Ball
		fruit.Size = Vector3.new(4, 4, 4)
		fruit.Color = FRUIT_COLORS[(i % #FRUIT_COLORS) + 1]
		fruit.Material = Enum.Material.Neon
		fruit.Anchored = true
		fruit.CanCollide = false
		fruit.Name = "Fruit_" .. i
		fruit.Position = line:PosAt(d) + right * lateral + Vector3.new(0, 2, 0)
		fruit.Parent = propsFolder
		fruitAlive[fruit.Name] = fruit
	end
end

local function spawnGates(count: number)
	if not spline then
		return
	end
	local line = spline :: SplineUtil.Spline
	local from = 100
	local span = line.total - 220
	for i = 1, count do
		local d = from + span * (i - 1) / math.max(count - 1, 1)
		local pos = line:PosAt(d)
		local tangent = line:TangentAt(d)
		local right = tangent:Cross(Vector3.yAxis).Unit
		local lateral = (i % 2 == 0) and 9 or -9 -- alternate sides
		local gateCenter = pos + right * lateral + Vector3.new(0, 1, 0)
		for _, side in { -1, 1 } do
			local post = Instance.new("Part")
			post.Size = Vector3.new(1.5, 9, 1.5)
			post.Color = Color3.fromRGB(90, 200, 255)
			post.Material = Enum.Material.Neon
			post.Anchored = true
			post.CanCollide = false
			post.Name = ("GatePost_%d_%s"):format(i, side == -1 and "L" or "R")
			post.Position = gateCenter + right * (side * 7) + Vector3.new(0, 3.5, 0)
			post.Parent = propsFolder
		end
		-- gate metadata for the client judge
		local marker = Instance.new("Part")
		marker.Size = Vector3.one
		marker.Transparency = 1
		marker.Anchored = true
		marker.CanCollide = false
		marker.Name = "Gate_" .. i
		marker.Position = gateCenter
		marker:SetAttribute("GateIndex", i)
		marker:SetAttribute("HalfWidth", 7)
		marker.Parent = propsFolder
	end
end

-- ============ challenge selection ============
local activeChallenge: { [Player]: string } = {}

setChallengeRemote.OnServerEvent:Connect(function(player, challengeId)
	local def = Challenges.byId[challengeId]
	if not def then
		return
	end
	-- CC gate (docs/06): kart must be powerful enough
	local cc = (player:GetAttribute("CC") :: number?) or 0
	if cc < def.ccRequired then
		return
	end
	-- challenge must belong to the loaded track
	if (workspace:GetAttribute("ActiveTrackId") :: string?) ~= def.trackId then
		return
	end
	activeChallenge[player] = def.id
	player:SetAttribute("ChallengeId", def.id)
	player:SetAttribute("FruitCount", 0)

	clearProps()
	if def.mode == "FruitSplat" then
		spawnFruit(def.fruitCount or 25)
	elseif def.mode == "Slalom" then
		spawnGates(def.gates or 10)
	end

	botConfigBus:Fire({
		count = def.bots,
		cruiseOverride = def.rivalCruise,
	})
end)

Players.PlayerRemoving:Connect(function(p)
	activeChallenge[p] = nil
end)

-- ============ fruit smashing (client reports, server validates) ============
fruitSmashRemote.OnServerEvent:Connect(function(player, fruitName)
	local fruit = typeof(fruitName) == "string" and fruitAlive[fruitName]
	if not fruit then
		return
	end
	local kart = workspace:FindFirstChild(player.Name .. "_Kart")
	local chassis = kart and kart:FindFirstChild("Chassis")
	if not (chassis and chassis:IsA("BasePart")) then
		return
	end
	if (chassis.Position - fruit.Position).Magnitude > 18 then
		return -- too far: reject
	end
	fruitAlive[fruitName] = nil
	fruit:Destroy()
	player:SetAttribute("FruitCount", ((player:GetAttribute("FruitCount") :: number?) or 0) + 1)
end)

-- ============ Champion Chase: boss strikes back (W3.5) ============
launchRemote.OnServerEvent:Connect(function(player)
	local def = Challenges.byId[activeChallenge[player] or ""]
	if not def or def.mode ~= "ChampionChase" then
		return
	end
	-- boss fires an enhanced power once, at a dramatic mid-race moment
	task.delay(math.random(8, 16), function()
		if player.Parent == nil then
			return
		end
		if (player:GetAttribute("ChallengeId") :: string?) ~= def.id then
			return
		end
		local shieldUntil = (player:GetAttribute("ShieldUntil") :: number?) or 0
		if os.clock() < shieldUntil then
			powerFxRemote:FireClient(player, { action = "shieldBlocked" })
		else
			powerFxRemote:FireClient(player, { action = "bossFreeze", duration = 1.6 })
		end
	end)
end)
