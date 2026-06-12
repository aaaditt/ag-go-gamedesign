--!strict
-- M5 garage panel: equip/buy/upgrade parts per slot, live stats + CC.
-- Greybox UI; visual polish lands in M8.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KartParts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KartParts"))
local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local buyRemote = remotes:WaitForChild("BuyPart") :: RemoteEvent
local equipRemote = remotes:WaitForChild("EquipPart") :: RemoteEvent
local upgradeRemote = remotes:WaitForChild("UpgradePart") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "GarageHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- toggle button
local toggle = Instance.new("TextButton")
toggle.Size = UDim2.new(0.1, 0, 0.06, 0)
toggle.Position = UDim2.new(0.02, 0, 0.08, 0)
toggle.BackgroundColor3 = Color3.fromRGB(200, 140, 40)
toggle.TextScaled = true
toggle.Font = Enum.Font.GothamBold
toggle.TextColor3 = Color3.new(1, 1, 1)
toggle.Text = "GARAGE"
toggle.Parent = gui
local tCorner = Instance.new("UICorner")
tCorner.Parent = toggle

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0.34, 0, 0.62, 0)
panel.Position = UDim2.new(0.33, 0, 0.16, 0)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui
local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 12)
pCorner.Parent = panel

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Size = UDim2.new(0.45, 0, 0.08, 0)
coinsLabel.Position = UDim2.new(0.03, 0, 0.02, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
coinsLabel.TextXAlignment = Enum.TextXAlignment.Left
coinsLabel.Parent = panel

local ccLabel = Instance.new("TextLabel")
ccLabel.Size = UDim2.new(0.45, 0, 0.08, 0)
ccLabel.Position = UDim2.new(0.52, 0, 0.02, 0)
ccLabel.BackgroundTransparency = 1
ccLabel.TextScaled = true
ccLabel.Font = Enum.Font.GothamBold
ccLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
ccLabel.TextXAlignment = Enum.TextXAlignment.Right
ccLabel.Parent = panel

-- per-slot rows
local slotIndex: { [string]: number } = {}
local rows: { [string]: { label: TextLabel, action: TextButton, upgrade: TextButton } } = {}

local function partsForSlot(slot: string): { KartParts.Part }
	local out = {}
	for _, part in KartParts.list do
		if part.slot == slot then
			table.insert(out, part)
		end
	end
	return out
end

local function ownedSet(): { [string]: boolean }
	-- owned parts inferred: server rejects invalid ops; we track optimistic UI from attributes
	-- (lean v1: rely on Coins/CC refresh after each op)
	return {}
end

local function currentLoadout(): { [string]: string }
	local out = table.clone(KartParts.DEFAULT_LOADOUT)
	pcall(function()
		local json = player:GetAttribute("LoadoutJson") :: string?
		if json then
			for slot, id in game:GetService("HttpService"):JSONDecode(json) do
				out[slot] = id
			end
		end
	end)
	return out
end

local function refresh()
	coinsLabel.Text = ("🪙 %d"):format((player:GetAttribute("Coins") :: number?) or 0)
	ccLabel.Text = ("%d CC"):format((player:GetAttribute("CC") :: number?) or 0)
	local loadout = currentLoadout()
	for slot, row in rows do
		local parts = partsForSlot(slot)
		local idx = slotIndex[slot] or 1
		local part = parts[((idx - 1) % #parts) + 1]
		local equipped = loadout[slot] == part.id
		row.label.Text = ("%s: %s"):format(slot:upper(), part.name)
		if equipped then
			row.action.Text = "EQUIPPED"
			row.action.BackgroundColor3 = Color3.fromRGB(60, 110, 60)
		else
			row.action.Text = part.cost > 0 and ("EQUIP / BUY %d"):format(part.cost) or "EQUIP"
			row.action.BackgroundColor3 = Color3.fromRGB(70, 120, 180)
		end
		row.upgrade.Text = ("UPGRADE (%d)"):format(KartParts.upgradeCost(part, 1))
	end
end

local yPos = 0.13
for _, slot in KartParts.SLOTS do
	slotIndex[slot] = 1
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0.5, 0, 0.07, 0)
	label.Position = UDim2.new(0.03, 0, yPos, 0)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel

	local prev = Instance.new("TextButton")
	prev.Size = UDim2.new(0.05, 0, 0.07, 0)
	prev.Position = UDim2.new(0.54, 0, yPos, 0)
	prev.Text = "<"
	prev.TextScaled = true
	prev.Parent = panel
	local nxt = Instance.new("TextButton")
	nxt.Size = UDim2.new(0.05, 0, 0.07, 0)
	nxt.Position = UDim2.new(0.6, 0, yPos, 0)
	nxt.Text = ">"
	nxt.TextScaled = true
	nxt.Parent = panel

	local action = Instance.new("TextButton")
	action.Size = UDim2.new(0.32, 0, 0.07, 0)
	action.Position = UDim2.new(0.66, 0, yPos, 0)
	action.TextScaled = true
	action.Font = Enum.Font.GothamBold
	action.TextColor3 = Color3.new(1, 1, 1)
	action.Parent = panel
	local aCorner = Instance.new("UICorner")
	aCorner.Parent = action

	local upgrade = Instance.new("TextButton")
	upgrade.Size = UDim2.new(0.32, 0, 0.05, 0)
	upgrade.Position = UDim2.new(0.66, 0, yPos + 0.075, 0)
	upgrade.TextScaled = true
	upgrade.Font = Enum.Font.Gotham
	upgrade.BackgroundColor3 = Color3.fromRGB(120, 90, 160)
	upgrade.TextColor3 = Color3.new(1, 1, 1)
	upgrade.Parent = panel
	local uCorner = Instance.new("UICorner")
	uCorner.Parent = upgrade

	rows[slot] = { label = label, action = action, upgrade = upgrade }

	local function shift(dir: number)
		local parts = partsForSlot(slot)
		slotIndex[slot] = ((slotIndex[slot] - 1 + dir) % #parts) + 1
		refresh()
	end
	prev.Activated:Connect(function()
		shift(-1)
	end)
	nxt.Activated:Connect(function()
		shift(1)
	end)
	action.Activated:Connect(function()
		local parts = partsForSlot(slot)
		local part = parts[slotIndex[slot]]
		buyRemote:FireServer(part.id) -- server ignores if owned
		equipRemote:FireServer(slot, part.id)
		task.delay(0.3, refresh)
	end)
	upgrade.Activated:Connect(function()
		local parts = partsForSlot(slot)
		upgradeRemote:FireServer(parts[slotIndex[slot]].id)
		task.delay(0.3, refresh)
	end)

	yPos += 0.16
end

toggle.Activated:Connect(function()
	panel.Visible = not panel.Visible
	refresh()
end)
player:GetAttributeChangedSignal("Coins"):Connect(refresh)
player:GetAttributeChangedSignal("CC"):Connect(refresh)
player:GetAttributeChangedSignal("LoadoutJson"):Connect(refresh)

Bus.on("launch", function()
	panel.Visible = false
	toggle.Visible = false
end)
Bus.on("reset", function()
	toggle.Visible = true
end)
