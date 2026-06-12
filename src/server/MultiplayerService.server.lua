--!strict
-- M7 W7.2 (lean v1): group races through the Multiplayer portal.
-- Players queue at the portal; after a short window everyone queued is
-- dropped onto the loaded track together with a synchronized countdown.
-- Bots fill the rest of the grid. Positions count players AND bots.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local lobbyUiRemote = remotes:WaitForChild("LobbyUi") :: RemoteEvent
local setChallengeRemote = remotes:WaitForChild("SetChallenge") :: RemoteEvent

local groupRaceRemote = Instance.new("RemoteEvent")
groupRaceRemote.Name = "GroupRace"
groupRaceRemote.Parent = remotes

local joinQueueRemote = Instance.new("RemoteEvent")
joinQueueRemote.Name = "JoinMpQueue"
joinQueueRemote.Parent = remotes

local spawnKartBus = ServerStorage:WaitForChild("SpawnKartBus", 60) :: BindableEvent
local botConfigBus = ServerStorage:WaitForChild("BotConfigBus", 60) :: BindableEvent

local QUEUE_WINDOW = 12 -- seconds after first joiner before the race starts
local queue: { Player } = {}
local queueTimer: thread? = nil

local function startGroupRace()
	local racers = {}
	for _, p in queue do
		if p.Parent then
			table.insert(racers, p)
		end
	end
	table.clear(queue)
	queueTimer = nil
	if #racers == 0 then
		return
	end

	-- everyone races the loaded track's Race challenge; bots fill to 8
	local trackId = (workspace:GetAttribute("ActiveTrackId") :: string?) or "e1t1"
	botConfigBus:Fire({ count = math.max(0, 8 - #racers) })
	for _, p in racers do
		p:SetAttribute("ChallengeId", trackId .. "_race")
		spawnKartBus:Fire(p)
		lobbyUiRemote:FireClient(p, { action = "enteredPlay" })
	end
	-- synchronized countdown: clients lock the sling until GO
	task.wait(0.5)
	for _, p in racers do
		groupRaceRemote:FireClient(p, { action = "countdown", seconds = 3 })
	end
end

joinQueueRemote.OnServerEvent:Connect(function(player)
	if table.find(queue, player) then
		return
	end
	table.insert(queue, player)
	for _, p in queue do
		lobbyUiRemote:FireClient(p, {
			action = "toast",
			text = ("Race starting soon — %d racer(s) queued…"):format(#queue),
		})
	end
	if #queue >= 8 then
		if queueTimer then
			task.cancel(queueTimer)
		end
		startGroupRace()
	elseif not queueTimer then
		queueTimer = task.delay(QUEUE_WINDOW, startGroupRace)
	end
end)

Players.PlayerRemoving:Connect(function(p)
	local i = table.find(queue, p)
	if i then
		table.remove(queue, i)
	end
end)
