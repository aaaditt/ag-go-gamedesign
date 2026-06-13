--!strict
-- M6: manages which track is loaded. Preserves an editor-authored Track
-- (saved in the place) as the custom version of its TrackId; all other
-- tracks generate from presets. Fires TrackChangedBus so splines rebuild.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Lighting = game:GetService("Lighting")

local Tracks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tracks"))
local TrackGen = require(script.Parent:WaitForChild("TrackGen"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local selectTrackRemote = Instance.new("RemoteEvent")
selectTrackRemote.Name = "SelectTrack"
selectTrackRemote.Parent = remotes

local trackChangedBus = Instance.new("BindableEvent")
trackChangedBus.Name = "TrackChangedBus"
trackChangedBus.Parent = ServerStorage

local rebuildKartBus = ServerStorage:WaitForChild("RebuildKartBus", 30) :: BindableEvent?

local customTracks = Instance.new("Folder")
customTracks.Name = "CustomTracks"
customTracks.Parent = ServerStorage

-- permanent ocean safety floor (independent of track swaps)
local ocean = Instance.new("Part")
ocean.Name = "Ocean"
ocean.Anchored = true
ocean.Size = Vector3.new(4096, 4, 4096)
ocean.CFrame = CFrame.new(0, -200, 0)
ocean.Color = Color3.fromRGB(80, 140, 200)
ocean.Parent = workspace

-- docs/15 P4: per-episode atmosphere. Lighting is global and replicates to all
-- clients, so set it once when a track becomes active. (No other script writes
-- Lighting, so there's nothing to fight.)
local function applyAtmosphere(def: Tracks.TrackDef)
	local atmo = def.theme.atmosphere
	Lighting.ClockTime = atmo.clockTime
	Lighting.Ambient = atmo.ambient
	Lighting.OutdoorAmbient = atmo.outdoorAmbient
	Lighting.FogColor = atmo.fogColor
	Lighting.FogStart = atmo.fogStart
	Lighting.FogEnd = atmo.fogEnd
	Lighting.Brightness = atmo.brightness
	local a = Lighting:FindFirstChildOfClass("Atmosphere")
	if not a then
		a = Instance.new("Atmosphere")
		a.Parent = Lighting
	end
	a.Density = 0.32
	a.Haze = atmo.haze
	a.Color = atmo.atmoColor
	ocean.Color = def.theme.groundColor
end

local activeId: string? = nil

-- preserve a hand-edited track saved in the place as the custom e1t1 (or its tagged id)
local existing = workspace:FindFirstChild("Track")
if existing then
	local id = (existing:GetAttribute("TrackId") :: string?) or Tracks.DEFAULT
	existing:SetAttribute("TrackId", id)
	local keep = existing:Clone()
	keep.Name = "Custom_" .. id
	keep.Parent = customTracks
	activeId = id
	print(("[TrackService] Preserved editor-authored track as custom %s"):format(id))
end

local function loadTrack(id: string)
	if activeId == id and workspace:FindFirstChild("Track") then
		return
	end
	local def = Tracks.byId[id]
	if not def then
		return
	end

	local old = workspace:FindFirstChild("Track")
	if old then
		old:Destroy()
	end

	local custom = customTracks:FindFirstChild("Custom_" .. id)
	local track: Instance
	if custom then
		track = custom:Clone()
		track.Name = "Track"
	else
		track = TrackGen.Build(def)
	end
	track:SetAttribute("TrackId", id)
	track.Parent = workspace

	activeId = id
	workspace:SetAttribute("ActiveTrackId", id)
	applyAtmosphere(def)
	trackChangedBus:Fire(id)

	-- respawn every player's kart at the new start pad
	if rebuildKartBus then
		for _, player in Players:GetPlayers() do
			if player.Character then
				rebuildKartBus:Fire(player)
			end
		end
	end
end

-- episode gating (server-side mirror of the UI rule)
local function episodeUnlockedFor(player: Player, episode: number): boolean
	if episode <= 1 then
		return true
	end
	local unlocked = "," .. (((player:GetAttribute("UnlockedChars") :: string?) or "")) .. ","
	for _, bossId in Tracks.bossesOfEpisode(episode - 1) do
		if not string.find(unlocked, "," .. bossId .. ",", 1, true) then
			return false
		end
	end
	return true
end

selectTrackRemote.OnServerEvent:Connect(function(player, trackId)
	local def = typeof(trackId) == "string" and Tracks.byId[trackId]
	if not def then
		return
	end
	if not episodeUnlockedFor(player, def.episode) then
		return
	end
	loadTrack(def.id)
end)

-- initial track
if not workspace:FindFirstChild("Track") then
	loadTrack(Tracks.DEFAULT)
else
	workspace:SetAttribute("ActiveTrackId", activeId)
	local def = activeId and Tracks.byId[activeId]
	if def then
		applyAtmosphere(def)
	end
	trackChangedBus:Fire(activeId)
end
