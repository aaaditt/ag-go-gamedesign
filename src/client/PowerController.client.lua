--!strict
-- M3 client side: character picker (pre-launch) + power button (in race).
-- Self powers execute locally over the ClientBus; bot powers are server-side.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Characters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Characters"))
local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local selectRemote = remotes:WaitForChild("SelectCharacter") :: RemoteEvent
local usePowerRemote = remotes:WaitForChild("UsePower") :: RemoteEvent
local powerFxRemote = remotes:WaitForChild("PowerFx") :: RemoteEvent

local racing = false
local selectedIndex = 1

-- ============ UI ============
local gui = Instance.new("ScreenGui")
gui.Name = "PowerHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- character picker (visible pre-launch)
local picker = Instance.new("Frame")
picker.Size = UDim2.new(0.26, 0, 0.07, 0)
picker.Position = UDim2.new(0.37, 0, 0.7, 0)
picker.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
picker.BackgroundTransparency = 0.2
picker.Parent = gui
local pickerCorner = Instance.new("UICorner")
pickerCorner.CornerRadius = UDim.new(0, 10)
pickerCorner.Parent = picker

local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(0.6, 0, 1, 0)
nameLabel.Position = UDim2.new(0.2, 0, 0, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.TextScaled = true
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextColor3 = Color3.new(1, 1, 1)
nameLabel.Parent = picker

local function pickerArrow(text: string, x: number, dir: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.18, 0, 1, 0)
	b.Position = UDim2.new(x, 0, 0, 0)
	b.BackgroundTransparency = 1
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.fromRGB(255, 220, 90)
	b.Text = text
	b.Parent = picker
	b.Activated:Connect(function()
		selectedIndex = ((selectedIndex - 1 + dir) % #Characters.list) + 1
		local def = Characters.list[selectedIndex]
		selectRemote:FireServer(def.id)
		nameLabel.Text = ("%s — %s"):format(def.name, def.powerName)
		nameLabel.TextColor3 = def.color:Lerp(Color3.new(1, 1, 1), 0.5)
	end)
	return b
end
pickerArrow("<", 0, -1)
pickerArrow(">", 0.82, 1)
nameLabel.Text = ("%s — %s"):format(Characters.list[1].name, Characters.list[1].powerName)

-- power button (visible in race)
local powerBtn = Instance.new("TextButton")
powerBtn.Size = UDim2.new(0.11, 0, 0.16, 0)
powerBtn.Position = UDim2.new(0.86, 0, 0.7, 0)
powerBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 40)
powerBtn.TextScaled = true
powerBtn.Font = Enum.Font.GothamBold
powerBtn.TextColor3 = Color3.new(1, 1, 1)
powerBtn.Text = "POWER\n(Q)"
powerBtn.Visible = false
powerBtn.Parent = gui
local powerCorner = Instance.new("UICorner")
powerCorner.CornerRadius = UDim.new(1, 0)
powerCorner.Parent = powerBtn

local function refreshPowerButton()
	local charges = (player:GetAttribute("PowerCharges") :: number?) or 0
	powerBtn.Visible = racing and charges > 0
	if charges > 1 then
		powerBtn.Text = ("POWER x%d\n(Q)"):format(charges)
	else
		powerBtn.Text = "POWER\n(Q)"
	end
end
player:GetAttributeChangedSignal("PowerCharges"):Connect(refreshPowerButton)

local function usePower()
	if not racing then
		return
	end
	usePowerRemote:FireServer()
end
powerBtn.Activated:Connect(usePower)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Q then
		usePower()
	end
end)

-- ============ state ============
Bus.on("launch", function()
	racing = true
	picker.Visible = false
	task.wait(0.1)
	refreshPowerButton()
end)

Bus.on("reset", function()
	racing = false
	picker.Visible = true
	powerBtn.Visible = false
end)

-- ============ server-approved effects ============
powerFxRemote.OnClientEvent:Connect(function(fx: { [string]: any })
	if fx.action == "selfBoost" then
		Bus.fire("powerBoost", fx.cap, fx.duration)
	elseif fx.action == "shield" then
		Bus.fire("shield", fx.duration)
		-- simple shield visual
		local kart = workspace:FindFirstChild(player.Name .. "_Kart")
		local chassis = kart and kart:FindFirstChild("Chassis")
		if chassis and chassis:IsA("BasePart") then
			local bubble = Instance.new("Part")
			bubble.Shape = Enum.PartType.Ball
			bubble.Size = Vector3.new(14, 14, 14)
			bubble.Transparency = 0.7
			bubble.Color = Color3.fromRGB(250, 130, 190)
			bubble.Material = Enum.Material.ForceField
			bubble.CanCollide = false
			bubble.Massless = true
			bubble.CFrame = chassis.CFrame
			bubble.Parent = kart
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = chassis
			weld.Part1 = bubble
			weld.Parent = bubble
			task.delay(fx.duration or 3, function()
				bubble:Destroy()
			end)
		end
	end
	if fx.action == "bossFreeze" then
		Bus.fire("playerFrozen", fx.duration or 1.5)
		-- ice flash on the kart
		local kart = workspace:FindFirstChild(player.Name .. "_Kart")
		local chassis = kart and kart:FindFirstChild("Chassis")
		if chassis and chassis:IsA("BasePart") then
			local original = chassis.Color
			chassis.Color = Color3.fromRGB(150, 220, 255)
			task.delay(fx.duration or 1.5, function()
				chassis.Color = original
			end)
		end
	elseif fx.action == "shieldBlocked" then
		Bus.fire("shieldBlocked")
	end
	-- "botHit" needs no client action (server already applied it); VFX in M8
end)
