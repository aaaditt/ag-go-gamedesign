--!strict
-- docs/14 client side: routes lobby portal actions to the right UI,
-- shows the BACK TO LOBBY button in play mode, toasts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local lobbyUiRemote = remotes:WaitForChild("LobbyUi") :: RemoteEvent
local exitToLobbyRemote = remotes:WaitForChild("ExitToLobby") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local backBtn = Instance.new("TextButton")
backBtn.Size = UDim2.new(0.11, 0, 0.055, 0)
backBtn.Position = UDim2.new(0.87, 0, 0.01, 0)
backBtn.BackgroundColor3 = Color3.fromRGB(160, 70, 70)
backBtn.TextScaled = true
backBtn.Font = Enum.Font.GothamBold
backBtn.TextColor3 = Color3.new(1, 1, 1)
backBtn.Text = "⌂ LOBBY"
backBtn.Visible = false
backBtn.Parent = gui
local corner = Instance.new("UICorner")
corner.Parent = backBtn

local toast = Instance.new("TextLabel")
toast.Size = UDim2.new(0.4, 0, 0.05, 0)
toast.Position = UDim2.new(0.3, 0, 0.12, 0)
toast.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
toast.BackgroundTransparency = 0.25
toast.TextScaled = true
toast.Font = Enum.Font.Gotham
toast.TextColor3 = Color3.new(1, 1, 1)
toast.Visible = false
toast.Parent = gui
local tCorner = Instance.new("UICorner")
tCorner.Parent = toast

local function showToast(text: string)
	toast.Text = text
	toast.Visible = true
	task.delay(2.5, function()
		if toast.Text == text then
			toast.Visible = false
		end
	end)
end

backBtn.Activated:Connect(function()
	exitToLobbyRemote:FireServer()
end)

-- multiplayer queue + synchronized countdown
local countdownLabel = Instance.new("TextLabel")
countdownLabel.Size = UDim2.new(0.2, 0, 0.18, 0)
countdownLabel.Position = UDim2.new(0.4, 0, 0.3, 0)
countdownLabel.BackgroundTransparency = 1
countdownLabel.TextScaled = true
countdownLabel.Font = Enum.Font.GothamBold
countdownLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
countdownLabel.TextStrokeTransparency = 0.3
countdownLabel.Visible = false
countdownLabel.Parent = gui

task.spawn(function()
	local groupRace = remotes:WaitForChild("GroupRace", 60) :: RemoteEvent?
	if not groupRace then
		return
	end
	groupRace.OnClientEvent:Connect(function(data)
		if data.action ~= "countdown" then
			return
		end
		Bus.fire("launchLock", true)
		countdownLabel.Visible = true
		for i = data.seconds or 3, 1, -1 do
			countdownLabel.Text = tostring(i)
			task.wait(1)
		end
		countdownLabel.Text = "GO!"
		Bus.fire("launchLock", false)
		task.delay(1, function()
			countdownLabel.Visible = false
		end)
	end)
end)

lobbyUiRemote.OnClientEvent:Connect(function(data: { action: string, text: string? })
	if data.action == "joinMpQueue" then
		local joinQueue = remotes:FindFirstChild("JoinMpQueue")
		if joinQueue and joinQueue:IsA("RemoteEvent") then
			joinQueue:FireServer()
		end
		return
	end
	if data.action == "enteredPlay" then
		backBtn.Visible = true
		Bus.fire("playMode", true)
		Bus.fire("reset")
	elseif data.action == "enteredLobby" then
		backBtn.Visible = false
		Bus.fire("playMode", false)
		Bus.fire("reset")
	elseif data.action == "openGarage" then
		Bus.fire("openGarage")
	elseif data.action == "openMap" then
		Bus.fire("openMap")
	elseif data.action == "toast" then
		showToast(data.text or "")
	end
end)
