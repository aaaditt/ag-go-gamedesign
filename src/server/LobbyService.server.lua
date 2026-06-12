--!strict
-- docs/14: lobby-first flow. Players spawn on foot in the Lobby; portals
-- enter play mode (kart at track), open garage/map, or tease multiplayer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local LobbyGen = require(script.Parent:WaitForChild("LobbyGen"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")

local enterPlayRemote = Instance.new("RemoteEvent")
enterPlayRemote.Name = "EnterPlay"
enterPlayRemote.Parent = remotes
local exitToLobbyRemote = Instance.new("RemoteEvent")
exitToLobbyRemote.Name = "ExitToLobby"
exitToLobbyRemote.Parent = remotes
local lobbyUiRemote = Instance.new("RemoteEvent")
lobbyUiRemote.Name = "LobbyUi"
lobbyUiRemote.Parent = remotes

-- kart spawning is owned by KartService; we drive it over a bindable
local spawnKartBus = Instance.new("BindableEvent")
spawnKartBus.Name = "SpawnKartBus"
spawnKartBus.Parent = ServerStorage
local despawnKartBus = Instance.new("BindableEvent")
despawnKartBus.Name = "DespawnKartBus"
despawnKartBus.Parent = ServerStorage

-- build greybox lobby only if the place doesn't carry a hand-designed one
local lobby = workspace:FindFirstChild("Lobby") :: Folder?
if not lobby then
	lobby = LobbyGen.Build()
	;(lobby :: Folder).Parent = workspace
	print("[LobbyService] Greybox lobby built — redesign it freely in Studio (keep anchor names)")
end
local lobbyFolder = lobby :: Folder

local inPlayMode: { [Player]: boolean } = {}

local function teleportToLobby(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local spawnPlatform = lobbyFolder:FindFirstChild("SpawnPlatform") :: BasePart?
	if root and root:IsA("BasePart") and spawnPlatform then
		root.CFrame = spawnPlatform.CFrame * CFrame.new(0, 4, 0)
	end
end

local function enterPlay(player: Player)
	if inPlayMode[player] then
		return
	end
	inPlayMode[player] = true
	spawnKartBus:Fire(player)
	lobbyUiRemote:FireClient(player, { action = "enteredPlay" })
end

local function exitToLobby(player: Player)
	inPlayMode[player] = nil
	despawnKartBus:Fire(player)
	teleportToLobby(player)
	lobbyUiRemote:FireClient(player, { action = "enteredLobby" })
end

-- portal touch wiring (by anchor name; survives full lobby redesigns)
local debounce: { [Player]: number } = {}
local function onPortalTouch(portalName: string, hit: BasePart)
	local character = hit.Parent
	local player = character and Players:GetPlayerFromCharacter(character :: Model)
	if not player then
		return
	end
	local now = os.clock()
	if (debounce[player] or 0) > now then
		return
	end
	debounce[player] = now + 1.5

	if portalName == "PlayPortal" then
		enterPlay(player)
	elseif portalName == "GaragePortal" then
		lobbyUiRemote:FireClient(player, { action = "openGarage" })
	elseif portalName == "MapBoard" then
		lobbyUiRemote:FireClient(player, { action = "openMap" })
	elseif portalName == "MultiplayerPortal" then
		lobbyUiRemote:FireClient(player, { action = "toast", text = "Multiplayer races are coming soon! (M7)" })
	end
end

for _, name in { "PlayPortal", "GaragePortal", "MapBoard", "MultiplayerPortal" } do
	task.spawn(function()
		local anchor = lobbyFolder:WaitForChild(name, 30)
		if anchor and anchor:IsA("BasePart") then
			anchor.Touched:Connect(function(hit)
				onPortalTouch(name, hit)
			end)
		else
			warn(("[LobbyService] Lobby anchor '%s' missing — that portal is dead until restored"):format(name))
		end
	end)
end

enterPlayRemote.OnServerEvent:Connect(enterPlay)
exitToLobbyRemote.OnServerEvent:Connect(exitToLobby)

Players.PlayerRemoving:Connect(function(p)
	inPlayMode[p] = nil
	debounce[p] = nil
end)
