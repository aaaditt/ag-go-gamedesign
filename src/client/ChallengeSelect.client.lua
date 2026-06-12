--!strict
-- M6: pre-launch challenge picker for the LOADED track. Rebuilds when the
-- track changes; locks rungs whose CC requirement exceeds the kart's CC.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Challenges = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Challenges"))
local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local setChallengeRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("SetChallenge") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "ChallengeHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.16, 0, 0.56, 0)
panel.Position = UDim2.new(0.02, 0, 0.18, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
panel.BackgroundTransparency = 0.2
panel.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = panel

local header = Instance.new("TextLabel")
header.Size = UDim2.new(0.9, 0, 0.08, 0)
header.BackgroundTransparency = 1
header.TextScaled = true
header.Font = Enum.Font.GothamBold
header.TextColor3 = Color3.fromRGB(255, 220, 90)
header.Text = "CHALLENGES"
header.LayoutOrder = 0
header.Parent = panel

local activeId: string? = nil
local buttons: { TextButton } = {}

local function starsFor(challengeId: string): number
	local ok, stars = pcall(function()
		local json = player:GetAttribute("StarsJson") :: string?
		return json and game:GetService("HttpService"):JSONDecode(json)[challengeId] or 0
	end)
	return ok and stars or 0
end

local function rebuild()
	for _, b in buttons do
		b:Destroy()
	end
	table.clear(buttons)

	local trackId = (workspace:GetAttribute("ActiveTrackId") :: string?) or "e1t1"
	local cc = (player:GetAttribute("CC") :: number?) or 0
	local ladder = Challenges.ladderFor(trackId)
	activeId = nil

	for i, def in ladder do
		local locked = cc < def.ccRequired
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.9, 0, 0.115, 0)
		b.TextScaled = true
		b.Font = Enum.Font.Gotham
		b.TextColor3 = locked and Color3.fromRGB(150, 150, 160) or Color3.new(1, 1, 1)
		local stars = starsFor(def.id)
		b.Text = locked and ("🔒 %s (%d CC)"):format(def.name, def.ccRequired)
			or ("%s %s"):format(def.name, string.rep("★", stars))
		b.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
		b.LayoutOrder = i
		b.Parent = panel
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 8)
		c.Parent = b
		table.insert(buttons, b)

		if not locked then
			b.Activated:Connect(function()
				activeId = def.id
				setChallengeRemote:FireServer(def.id)
				Bus.fire("challenge", def)
				for _, other in buttons do
					other.BackgroundColor3 = Color3.fromRGB(50, 50, 62)
				end
				b.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
			end)
			-- auto-select the first unlocked rung
			if not activeId then
				activeId = def.id
				setChallengeRemote:FireServer(def.id)
				Bus.fire("challenge", def)
				b.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
			end
		end
	end
end

task.delay(1.5, rebuild)
workspace:GetAttributeChangedSignal("ActiveTrackId"):Connect(function()
	task.delay(0.3, rebuild)
end)
player:GetAttributeChangedSignal("CC"):Connect(function()
	if panel.Visible then
		rebuild()
	end
end)

Bus.on("launch", function()
	panel.Visible = false
end)
Bus.on("reset", function()
	panel.Visible = true
end)
