--!strict
-- M5 (docs/13 W5.3/W5.7 + W4.7): player profiles (DataStore), coins, parts,
-- loadout/stats publishing, finish validation → stars/coins/recruits.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local KartParts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KartParts"))
local Challenges = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Challenges"))
local Characters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Characters"))
local Tracks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tracks"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

-- every boss id (for the "recruited them all" milestone)
local allBosses: { [string]: boolean } = {}
for _, t in Tracks.list do
	allBosses[t.bossId] = true
end

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local buyPartRemote = Instance.new("RemoteEvent")
buyPartRemote.Name = "BuyPart"
buyPartRemote.Parent = remotes
local equipPartRemote = Instance.new("RemoteEvent")
equipPartRemote.Name = "EquipPart"
equipPartRemote.Parent = remotes
local upgradePartRemote = Instance.new("RemoteEvent")
upgradePartRemote.Name = "UpgradePart"
upgradePartRemote.Parent = remotes
local reportFinishRemote = Instance.new("RemoteEvent")
reportFinishRemote.Name = "ReportFinish"
reportFinishRemote.Parent = remotes
local rewardFxRemote = Instance.new("RemoteEvent")
rewardFxRemote.Name = "RewardFx"
rewardFxRemote.Parent = remotes

local saveSettingsRemote = Instance.new("RemoteEvent")
saveSettingsRemote.Name = "SaveSettings"
saveSettingsRemote.Parent = remotes

local leaderboardFn = Instance.new("RemoteFunction")
leaderboardFn.Name = "GetLeaderboard"
leaderboardFn.Parent = remotes

local rebuildKartBus = Instance.new("BindableEvent")
rebuildKartBus.Name = "RebuildKartBus"
rebuildKartBus.Parent = ServerStorage

-- docs/15 P9: milestone signals (BadgeService + AnalyticsService listen) and a
-- coin-grant inlet (MonetizationService fires it after a validated purchase).
local milestoneBus = Instance.new("BindableEvent")
milestoneBus.Name = "MilestoneBus"
milestoneBus.Parent = ServerStorage

local grantCoinsBus = Instance.new("BindableEvent")
grantCoinsBus.Name = "GrantCoinsBus"
grantCoinsBus.Parent = ServerStorage

local store = nil
pcall(function()
	store = DataStoreService:GetDataStore("PlayerProfiles_v1")
end)

type Profile = {
	coins: number,
	ownedParts: { [string]: boolean },
	partLevels: { [string]: number },
	loadout: { [string]: string },
	characterId: string,
	chaseWins: { [string]: number },
	recruited: { [string]: boolean },
	stars: { [string]: number },
	bestTimes: { [string]: number },
	settings: { [string]: any },
}

local function defaultProfile(): Profile
	local owned = {}
	for _, id in KartParts.DEFAULT_LOADOUT do
		owned[id] = true
	end
	return {
		coins = 300,
		ownedParts = owned,
		partLevels = {},
		loadout = table.clone(KartParts.DEFAULT_LOADOUT),
		characterId = Characters.DEFAULT,
		chaseWins = {},
		recruited = {},
		stars = {},
		bestTimes = {},
		settings = { music = 0.6, sfx = 0.8, shake = true, tutorialDone = false },
	}
end

local profiles: { [Player]: Profile } = {}
local launchTimes: { [Player]: number } = {}

-- ============ attribute publishing ============
local function publish(player: Player)
	local p = profiles[player]
	if not p then
		return
	end
	local stats = KartParts.computeStats(p.loadout, p.partLevels)
	player:SetAttribute("Coins", p.coins)
	player:SetAttribute("CC", stats.cc)
	player:SetAttribute("StatTopSpeed", stats.topSpeed)
	player:SetAttribute("StatAccel", stats.accel)
	player:SetAttribute("StatHandling", stats.handling)
	player:SetAttribute("StatStrength", stats.strength)
	player:SetAttribute("LoadoutJson", HttpService:JSONEncode(p.loadout))
	local unlocked = { Characters.DEFAULT }
	for id in p.recruited do
		table.insert(unlocked, id)
	end
	player:SetAttribute("UnlockedChars", table.concat(unlocked, ","))
	player:SetAttribute("StarsJson", HttpService:JSONEncode(p.stars))
	player:SetAttribute("SettingsJson", HttpService:JSONEncode(p.settings))
end

-- ============ load/save ============
local function load(player: Player)
	local profile = defaultProfile()
	if store then
		pcall(function()
			local saved = (store :: any):GetAsync("p_" .. player.UserId)
			if saved then
				for k, v in saved do
					(profile :: any)[k] = v
				end
			end
		end)
	end
	profiles[player] = profile
	publish(player)

	-- daily login streak (docs/13 W5.8 lean): new UTC day = streak + coins
	local today = math.floor(os.time() / 86400)
	local last = (profile :: any).lastDailyDay or 0
	if today > last then
		local streak = ((profile :: any).dailyStreak or 0)
		streak = (today - last == 1) and streak + 1 or 1
		;(profile :: any).dailyStreak = streak
		;(profile :: any).lastDailyDay = today
		local bonus = 100 + 25 * math.min(streak, 7)
		profile.coins += bonus
		publish(player)
		task.delay(6, function()
			if player.Parent then
				rewardFxRemote:FireClient(player, { coins = bonus, stars = 0, daily = streak })
			end
		end)
	end
end

local function save(player: Player)
	local p = profiles[player]
	if not (p and store) then
		return
	end
	pcall(function()
		(store :: any):SetAsync("p_" .. player.UserId, p)
	end)
end

Players.PlayerAdded:Connect(load)
for _, pl in Players:GetPlayers() do
	if not profiles[pl] then
		load(pl)
	end
end
Players.PlayerRemoving:Connect(function(pl)
	save(pl)
	profiles[pl] = nil
	launchTimes[pl] = nil
end)
game:BindToClose(function()
	for pl in profiles do
		save(pl)
	end
end)

-- ============ garage ops ============
buyPartRemote.OnServerEvent:Connect(function(player, partId)
	local p = profiles[player]
	local part = typeof(partId) == "string" and KartParts.byId[partId]
	if not (p and part) or p.ownedParts[part.id] then
		return
	end
	if p.coins < part.cost then
		return
	end
	p.coins -= part.cost
	p.ownedParts[part.id] = true
	publish(player)
end)

equipPartRemote.OnServerEvent:Connect(function(player, slot, partId)
	local p = profiles[player]
	local part = typeof(partId) == "string" and KartParts.byId[partId]
	if not (p and part) or part.slot ~= slot or not p.ownedParts[part.id] then
		return
	end
	p.loadout[slot] = part.id
	publish(player)
	rebuildKartBus:Fire(player)
end)

upgradePartRemote.OnServerEvent:Connect(function(player, partId)
	local p = profiles[player]
	local part = typeof(partId) == "string" and KartParts.byId[partId]
	if not (p and part) or not p.ownedParts[part.id] then
		return
	end
	local level = p.partLevels[part.id] or 1
	if level >= KartParts.MAX_LEVEL then
		return
	end
	local cost = KartParts.upgradeCost(part, level)
	if p.coins < cost then
		return
	end
	p.coins -= cost
	p.partLevels[part.id] = level + 1
	publish(player)
end)

-- ============ settings persistence (docs/15 P7) ============
local ALLOWED_SETTINGS = { music = "number", sfx = "number", shake = "boolean", tutorialDone = "boolean" }
saveSettingsRemote.OnServerEvent:Connect(function(player, json)
	local p = profiles[player]
	if not p or typeof(json) ~= "string" or #json > 500 then
		return
	end
	local ok, t = pcall(function()
		return HttpService:JSONDecode(json)
	end)
	if not ok or type(t) ~= "table" then
		return
	end
	for k, expected in ALLOWED_SETTINGS do
		local v = t[k]
		if typeof(v) == expected then
			if expected == "number" then
				v = math.clamp(v, 0, 1)
			end
			p.settings[k] = v
		end
	end
	publish(player)
end)

-- ============ coin grants from MonetizationService (docs/15 P9) ============
grantCoinsBus.Event:Connect(function(player: Player, coins: number)
	local p = profiles[player]
	if not p or typeof(coins) ~= "number" or coins <= 0 then
		return
	end
	p.coins += math.floor(coins)
	publish(player)
	save(player) -- purchases persist immediately
	if player.Parent then
		rewardFxRemote:FireClient(player, { coins = math.floor(coins), stars = 0 })
	end
end)

-- ============ finish validation → rewards (docs/06 lean) ============
local remotesLaunch = remotes:WaitForChild("RequestLaunch") :: RemoteEvent
remotesLaunch.OnServerEvent:Connect(function(player)
	launchTimes[player] = os.clock()
end)

local function starsFor(def, success: boolean, t: number, place: number?): number
	if not success then
		return 0
	end
	local mode = def.mode
	if mode == "Race" or mode == "Versus" then
		if place == 1 then
			return 3
		elseif place == 2 then
			return 2
		end
		return place == 3 and 1 or 0
	elseif mode == "TimeBoom" or mode == "Slalom" then
		local limit = def.timeLimit or 60
		local margin = (limit - t) / limit
		return margin >= 0.3 and 3 or margin >= 0.15 and 2 or 1
	elseif mode == "FruitSplat" then
		return 3 -- gauge cleared; finer criteria when episodes land (M6)
	elseif mode == "ChampionChase" then
		return 1 -- one star per win; accumulates to 3 via wins
	end
	return 1
end

reportFinishRemote.OnServerEvent:Connect(function(player, success, timeTaken)
	local p = profiles[player]
	local def = Challenges.byId[(player:GetAttribute("ChallengeId") :: string?) or ""]
	if not (p and def) or typeof(success) ~= "boolean" or typeof(timeTaken) ~= "number" then
		return
	end
	-- sanity: a real run takes time, and must follow an actual launch
	local launched = launchTimes[player]
	if not launched or timeTaken < 15 or math.abs((os.clock() - launched) - timeTaken) > 8 then
		return
	end
	launchTimes[player] = nil

	if def.mode == "Race" then
		milestoneBus:Fire(player, "race")
	end

	local place = player:GetAttribute("RacePosition") :: number?
	local coins = 0
	local stars = 0

	if success then
		coins = 100
		if def.mode == "Race" or def.mode == "Versus" or def.mode == "ChampionChase" then
			coins += place == 1 and 200 or place == 2 and 120 or place == 3 and 60 or 0
		end
		stars = starsFor(def, success, timeTaken, place)
		coins += stars * 50
		if (p.stars[def.id] or 0) == 0 then
			coins += 300 -- first clear
			milestoneBus:Fire(player, "clear")
		end

		-- Champion Chase recruitment (server-authoritative)
		if def.mode == "ChampionChase" and place == 1 and def.bossId then
			p.chaseWins[def.bossId] = (p.chaseWins[def.bossId] or 0) + 1
			coins += 150 + p.chaseWins[def.bossId] * 100
			if p.chaseWins[def.bossId] >= (def.winsNeeded or 3) and not p.recruited[def.bossId] then
				p.recruited[def.bossId] = true
				milestoneBus:Fire(player, "recruit", def.bossId)
				local all = true
				for boss in allBosses do
					if not p.recruited[boss] then
						all = false
						break
					end
				end
				if all then
					milestoneBus:Fire(player, "allRecruited")
				end
			end
			stars = math.min(p.chaseWins[def.bossId], 3)
		end

		p.stars[def.id] = math.max(p.stars[def.id] or 0, stars)
		local best = p.bestTimes[def.id]
		if not best or timeTaken < best then
			p.bestTimes[def.id] = timeTaken
		end
	else
		coins = 25 -- consolation
	end

	if player:GetAttribute("VIPDoubleCoins") then
		coins = math.floor(coins * Config.vipCoinMultiplier)
	end
	p.coins += coins
	publish(player)
	rewardFxRemote:FireClient(player, { coins = coins, stars = stars })

	-- per-challenge best-time leaderboard (validated runs only, docs/13 W7.4)
	if success then
		task.spawn(function()
			pcall(function()
				local board = DataStoreService:GetOrderedDataStore("TT1_" .. def.id)
				local ms = math.floor(timeTaken * 1000)
				local existing = board:GetAsync(tostring(player.UserId))
				if not existing or ms < existing then
					board:SetAsync(tostring(player.UserId), ms)
				end
			end)
		end)
	end
end)

-- top-10 query for the results screen
leaderboardFn.OnServerInvoke = function(_, challengeId)
	if typeof(challengeId) ~= "string" or not Challenges.byId[challengeId] then
		return {}
	end
	local out = {}
	pcall(function()
		local board = DataStoreService:GetOrderedDataStore("TT1_" .. challengeId)
		local page = board:GetSortedAsync(true, 10):GetCurrentPage()
		for rank, entry in page do
			local name = "???"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(tonumber(entry.key) :: number)
			end)
			table.insert(out, { rank = rank, name = name, ms = entry.value })
		end
	end)
	return out
end
