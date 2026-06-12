--!strict
-- M8 W8.4: on-screen controls for touch devices. Writes to InputState;
-- KartController merges it with keyboard input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

if not UserInputService.TouchEnabled then
	return
end

local InputState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InputState"))
local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "TouchHUD"
gui.ResetOnSpawn = false
gui.Visible = false
gui.Parent = player:WaitForChild("PlayerGui")

local function holdButton(text: string, pos: UDim2, size: UDim2, color: Color3, onDown: () -> (), onUp: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Text = text
	b.Position = pos
	b.Size = size
	b.BackgroundColor3 = color
	b.BackgroundTransparency = 0.35
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.new(1, 1, 1)
	b.AutoButtonColor = true
	b.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.3, 0)
	c.Parent = b
	b.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			onDown()
		end
	end)
	b.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			onUp()
		end
	end)
	return b
end

-- steering: bottom-left pair
holdButton("◀", UDim2.new(0.03, 0, 0.74, 0), UDim2.new(0.1, 0, 0.16, 0), Color3.fromRGB(70, 90, 130), function()
	InputState.steer = -1
end, function()
	if InputState.steer < 0 then
		InputState.steer = 0
	end
end)
holdButton("▶", UDim2.new(0.15, 0, 0.74, 0), UDim2.new(0.1, 0, 0.16, 0), Color3.fromRGB(70, 90, 130), function()
	InputState.steer = 1
end, function()
	if InputState.steer > 0 then
		InputState.steer = 0
	end
end)

-- right cluster: gas / skid / sling+glide
holdButton("GAS", UDim2.new(0.86, 0, 0.55, 0), UDim2.new(0.1, 0, 0.13, 0), Color3.fromRGB(70, 140, 70), function()
	InputState.throttle = true
end, function()
	InputState.throttle = false
end)
holdButton("SKID", UDim2.new(0.74, 0, 0.74, 0), UDim2.new(0.1, 0, 0.16, 0), Color3.fromRGB(150, 110, 60), function()
	InputState.drift = true
end, function()
	InputState.drift = false
end)
holdButton("SLING /\nGLIDE", UDim2.new(0.86, 0, 0.74, 0), UDim2.new(0.1, 0, 0.16, 0), Color3.fromRGB(180, 80, 80), function()
	InputState.launchHeld = true
	InputState.glideHeld = true
end, function()
	InputState.launchHeld = false
	InputState.glideHeld = false
end)

-- visible only in play mode
Bus.on("playMode", function(active: boolean)
	gui.Visible = active
	InputState.steer = 0
	InputState.throttle = false
	InputState.drift = false
	InputState.launchHeld = false
	InputState.glideHeld = false
end)
