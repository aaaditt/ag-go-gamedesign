--!strict
-- Greybox lobby generator (docs/14). Runs ONCE — if a Lobby exists in the
-- saved place (hand-designed), it is never touched. Scripts only need the
-- named anchor parts: SpawnPlatform, PlayPortal, GaragePortal,
-- MultiplayerPortal, MapBoard.

local LOBBY_CF = CFrame.new(600, 402, 600)

local LobbyGen = {}

local function part(props: { [string]: any }, parent: Instance): Part
	local p = Instance.new("Part")
	p.Anchored = true
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

local function label(target: Part, text: string, color: Color3)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.TextScaled = true
		t.Font = Enum.Font.GothamBold
		t.Text = text
		t.TextColor3 = color
		t.Parent = gui
		gui.Parent = target
	end
end

local function portalArch(parent: Folder, cf: CFrame, name: string, text: string, color: Color3): Part
	part({ Name = name .. "_PostL", Size = Vector3.new(2, 12, 2), CFrame = cf * CFrame.new(-6, 6, 0), Color = color }, parent)
	part({ Name = name .. "_PostR", Size = Vector3.new(2, 12, 2), CFrame = cf * CFrame.new(6, 6, 0), Color = color }, parent)
	local banner = part({
		Name = name .. "_Banner",
		Size = Vector3.new(14, 3, 1),
		CFrame = cf * CFrame.new(0, 13.5, 0),
		Color = color,
	}, parent)
	label(banner, text, Color3.new(1, 1, 1))
	-- the functional touch volume (THE named anchor)
	local trigger = part({
		Name = name,
		Size = Vector3.new(12, 12, 4),
		CFrame = cf * CFrame.new(0, 6, 0),
		Transparency = 0.85,
		Color = color,
		CanCollide = false,
		Material = Enum.Material.ForceField,
	}, parent)
	return trigger
end

function LobbyGen.Build(): Folder
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"

	-- plaza floor
	part({
		Name = "PlazaFloor",
		Size = Vector3.new(100, 4, 100),
		CFrame = LOBBY_CF * CFrame.new(0, -2, 0),
		Color = Color3.fromRGB(140, 170, 140),
		Material = Enum.Material.Grass,
	}, lobby)
	-- low walls so nobody strolls off the edge
	for _, side in { CFrame.new(0, 2, -51), CFrame.new(0, 2, 51) } do
		part({ Name = "Wall", Size = Vector3.new(102, 6, 2), CFrame = LOBBY_CF * side, Color = Color3.fromRGB(110, 130, 110) }, lobby)
	end
	for _, side in { CFrame.new(-51, 2, 0), CFrame.new(51, 2, 0) } do
		part({ Name = "Wall", Size = Vector3.new(2, 6, 102), CFrame = LOBBY_CF * side, Color = Color3.fromRGB(110, 130, 110) }, lobby)
	end

	-- spawn
	local spawnLoc = Instance.new("SpawnLocation")
	spawnLoc.Name = "SpawnPlatform"
	spawnLoc.Size = Vector3.new(10, 1, 10)
	spawnLoc.CFrame = LOBBY_CF * CFrame.new(0, 0.5, 20)
	spawnLoc.Anchored = true
	spawnLoc.Neutral = true
	spawnLoc.Duration = 0
	spawnLoc.Color = Color3.fromRGB(200, 200, 210)
	spawnLoc.Parent = lobby

	-- portals: PLAY on the left, GARAGE on the right, MULTIPLAYER ahead
	portalArch(lobby, LOBBY_CF * CFrame.new(-40, 0, 0) * CFrame.Angles(0, math.rad(90), 0), "PlayPortal", "▶ SOLO PLAY", Color3.fromRGB(80, 180, 80))
	portalArch(lobby, LOBBY_CF * CFrame.new(40, 0, 0) * CFrame.Angles(0, math.rad(-90), 0), "GaragePortal", "🔧 GARAGE", Color3.fromRGB(230, 150, 50))
	portalArch(lobby, LOBBY_CF * CFrame.new(0, 0, -40), "MultiplayerPortal", "👥 MULTIPLAYER (SOON)", Color3.fromRGB(90, 130, 220))

	-- map board
	local board = part({
		Name = "MapBoard",
		Size = Vector3.new(16, 9, 1),
		CFrame = LOBBY_CF * CFrame.new(20, 5.5, -25) * CFrame.Angles(0, math.rad(20), 0),
		Color = Color3.fromRGB(60, 90, 140),
	}, lobby)
	label(board, "🗺 EPISODE MAP\n(touch to open)", Color3.fromRGB(255, 230, 140))

	return lobby
end

LobbyGen.LOBBY_CF = LOBBY_CF

return LobbyGen
