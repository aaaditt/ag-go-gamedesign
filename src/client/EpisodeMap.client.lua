--!strict
-- M6: episode/track navigation (docs/08 S4 lean). Three themed episodes,
-- three tracks each; episodes lock until the previous episode's bosses
-- are recruited. Selecting a track asks the server to load it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Tracks = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tracks"))
local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local selectTrackRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SelectTrack") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "MapHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0.1, 0, 0.06, 0)
toggle.Position = UDim2.new(0.02, 0, 0.01, 0)
toggle.BackgroundColor3 = Color3.fromRGB(70, 130, 200)
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Text = "🗺 MAP"
toggle.Parent = gui
local tCorner = Instance.new("UICorner")
tCorner.Parent = toggle

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.5, 0, 0.55, 0)
panel.Position = UDim2.new(0.25, 0, 0.2, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
panel.Visible = false
panel.Parent = gui
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent = panel

local EP_COLORS = { Color3.fromRGB(110, 190, 110), Color3.fromRGB(220, 170, 100), Color3.fromRGB(140, 190, 240) }

local function isEpisodeUnlocked(ep: number): boolean
	if ep <= 1 then
		return true
	end
	local unlocked = "," .. ((player:GetAttribute("UnlockedChars") :: string?) or "") .. ","
	for _, bossId in Tracks.bossesOfEpisode(ep - 1) do
		if not string.find(unlocked, "," .. bossId .. ",", 1, true) then
			return false
		end
	end
	return true
end

local function rebuild()
	for _, child in panel:GetChildren() do
		if child:IsA("TextLabel") or child:IsA("TextButton") then
			child:Destroy()
		end
	end
	local activeTrack = (workspace:GetAttribute("ActiveTrackId") :: string?) or "e1t1"

	for ep = 1, 3 do
		local unlocked = isEpisodeUnlocked(ep)
		local epLabel = Instance.new("TextLabel")
		epLabel.Size = UDim2.new(0.3, 0, 0.1, 0)
		epLabel.Position = UDim2.new(0.02 + (ep - 1) * 0.33, 0, 0.04, 0)
		epLabel.BackgroundTransparency = 1
		epLabel.TextScaled = true
		epLabel.Font = Enum.Font.GothamBold
		epLabel.TextColor3 = unlocked and EP_COLORS[ep] or Color3.fromRGB(120, 120, 130)
		epLabel.Text = (unlocked and "" or "🔒 ") .. Tracks.EPISODE_NAMES[ep]
		epLabel.Parent = panel

		for _, track in Tracks.list do
			if track.episode ~= ep then
				continue
			end
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0.3, 0, 0.16, 0)
			b.Position = UDim2.new(0.02 + (ep - 1) * 0.33, 0, 0.08 + track.order * 0.18, 0)
			b.TextScaled = true
			b.Font = Enum.Font.Gotham
			b.TextColor3 = unlocked and Color3.new(1, 1, 1) or Color3.fromRGB(140, 140, 150)
			b.BackgroundColor3 = track.id == activeTrack and Color3.fromRGB(80, 150, 80)
				or (unlocked and Color3.fromRGB(55, 55, 70) or Color3.fromRGB(40, 40, 48))
			b.Text = track.name
			b.Parent = panel
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, 8)
			c.Parent = b
			if unlocked then
				b.Activated:Connect(function()
					selectTrackRemote:FireServer(track.id)
					panel.Visible = false
				end)
			end
		end
	end
end

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	if panel.Visible then
		rebuild()
	end
end)
workspace:GetAttributeChangedSignal("ActiveTrackId"):Connect(function()
	if panel.Visible then
		rebuild()
	end
end)

Bus.on("launch", function()
	panel.Visible = false
	toggle.Visible = false
end)
Bus.on("reset", function()
	toggle.Visible = true
end)
