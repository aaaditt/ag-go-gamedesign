--!strict
-- docs/15 P7: settings panel (gear button, top-right). Music + SFX volume
-- sliders, a camera-shake toggle, and a "replay tutorial" button. Persists via
-- the SaveSettings remote; SoundController/CameraRig/FTUE read the resulting
-- SettingsJson attribute.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local saveRemote = remotes:WaitForChild("SaveSettings") :: RemoteEvent

-- ============ current settings (from the published attribute) ============
local settings = { music = 0.6, sfx = 0.8, shake = true, tutorialDone = false }
local function pull()
	local json = player:GetAttribute("SettingsJson") :: string?
	if json then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, json)
		if ok and type(t) == "table" then
			for k in settings do
				if t[k] ~= nil then
					settings[k] = t[k]
				end
			end
		end
	end
end
pull()

local function push()
	saveRemote:FireServer(HttpService:JSONEncode(settings))
end

-- ============ UI ============
local gui = Instance.new("ScreenGui")
gui.Name = "SettingsGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local gear = Instance.new("TextButton")
gear.Size = UDim2.new(0, 42, 0, 42)
gear.Position = UDim2.new(1, -52, 0, 10)
gear.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
gear.BackgroundTransparency = 0.2
gear.Text = "⚙"
gear.TextScaled = true
gear.TextColor3 = Color3.new(1, 1, 1)
gear.Parent = gui
local gearCorner = Instance.new("UICorner")
gearCorner.CornerRadius = UDim.new(0, 8)
gearCorner.Parent = gear

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 320, 0, 250)
panel.Position = UDim2.new(1, -332, 0, 60)
panel.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 10)
pCorner.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 12)
pad.PaddingLeft = UDim.new(0, 14)
pad.PaddingRight = UDim.new(0, 14)
pad.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 26)
title.BackgroundTransparency = 1
title.Text = "Settings"
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.GothamBold
title.Parent = panel

gear.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)

-- a labelled click/drag slider 0..1
local function makeSlider(name: string, key: string)
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 40)
	row.BackgroundTransparency = 1
	row.Parent = panel

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 16)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(220, 220, 230)
	label.Font = Enum.Font.Gotham
	label.TextSize = 14
	label.Parent = row

	local bar = Instance.new("TextButton")
	bar.Size = UDim2.new(1, 0, 0, 16)
	bar.Position = UDim2.new(0, 0, 0, 20)
	bar.BackgroundColor3 = Color3.fromRGB(60, 60, 72)
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Parent = row
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(1, 0)
	barCorner.Parent = bar

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = Color3.fromRGB(120, 200, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local function render()
		local v = settings[key] :: number
		fill.Size = UDim2.new(v, 0, 1, 0)
		label.Text = ("%s — %d%%"):format(name, math.round(v * 100))
	end
	render()

	local dragging = false
	local function setFromX(x: number)
		local frac = math.clamp((x - bar.AbsolutePosition.X) / math.max(bar.AbsoluteSize.X, 1), 0, 1)
		settings[key] = frac
		render()
	end
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
		end
	end)
	bar.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				push()
			end
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setFromX(input.Position.X)
		end
	end)
end

makeSlider("Music", "music")
makeSlider("Sound FX", "sfx")

local function makeButton(textFn: () -> string, onClick: () -> ()): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 32)
	b.BackgroundColor3 = Color3.fromRGB(55, 55, 68)
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.Text = textFn()
	b.Parent = panel
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 6)
	c.Parent = b
	b.Activated:Connect(function()
		onClick()
		b.Text = textFn()
	end)
	return b
end

makeButton(function()
	return "Camera shake: " .. (settings.shake and "ON" or "OFF")
end, function()
	settings.shake = not settings.shake
	push()
end)

makeButton(function()
	return "Replay tutorial"
end, function()
	settings.tutorialDone = false
	push()
end)

player:GetAttributeChangedSignal("SettingsJson"):Connect(pull)
