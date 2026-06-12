--!strict
-- M4: pre-launch challenge picker. Selecting a challenge configures the
-- server (props, bots) and tells local systems the active mode over the bus.

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
panel.Size = UDim2.new(0.16, 0, 0.5, 0)
panel.Position = UDim2.new(0.02, 0, 0.2, 0)
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

local buttons: { [string]: TextButton } = {}
local activeId = Challenges.DEFAULT

local function refresh()
	for id, b in buttons do
		b.BackgroundColor3 = (id == activeId) and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(50, 50, 62)
	end
end

for i, def in Challenges.list do
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.9, 0, 0.115, 0)
	b.TextScaled = true
	b.Font = Enum.Font.Gotham
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = def.name
	b.LayoutOrder = i
	b.Parent = panel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 8)
	c.Parent = b
	buttons[def.id] = b
	b.Activated:Connect(function()
		activeId = def.id
		setChallengeRemote:FireServer(def.id)
		Bus.fire("challenge", def)
		refresh()
	end)
end
refresh()

-- default challenge on join
task.delay(1, function()
	setChallengeRemote:FireServer(activeId)
	Bus.fire("challenge", Challenges.byId[activeId])
end)

Bus.on("launch", function()
	panel.Visible = false
end)
Bus.on("reset", function()
	panel.Visible = true
end)
