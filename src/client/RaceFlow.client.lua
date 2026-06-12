--!strict
-- M1 race loop (docs/13 W1.2–W1.5): timer from launch, finish detection
-- derived from the FinishPad at runtime, results overlay with retry.
-- State machine: PreLaunch → Racing → Finished (signalled over ClientBus).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer

-- ============ state ============
type RaceState = "PreLaunch" | "Racing" | "Finished"
local state: RaceState = "PreLaunch"
local raceStart = 0
local bestTime: number? = nil

-- ============ UI ============
local gui = Instance.new("ScreenGui")
gui.Name = "RaceHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0.14, 0, 0.06, 0)
timerLabel.Position = UDim2.new(0.43, 0, 0.03, 0)
timerLabel.BackgroundTransparency = 0.4
timerLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
timerLabel.TextScaled = true
timerLabel.TextColor3 = Color3.new(1, 1, 1)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = ""
timerLabel.Visible = false
timerLabel.Parent = gui
local timerCorner = Instance.new("UICorner")
timerCorner.Parent = timerLabel

local results = Instance.new("Frame")
results.Size = UDim2.new(0.4, 0, 0.34, 0)
results.Position = UDim2.new(0.3, 0, 0.28, 0)
results.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
results.BackgroundTransparency = 0.06
results.Visible = false
results.Parent = gui
local resultsCorner = Instance.new("UICorner")
resultsCorner.CornerRadius = UDim.new(0, 14)
resultsCorner.Parent = results

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0.28, 0)
title.BackgroundTransparency = 1
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 220, 90)
title.Text = "FINISH!"
title.Parent = results

local timeLabel = Instance.new("TextLabel")
timeLabel.Size = UDim2.new(1, 0, 0.2, 0)
timeLabel.Position = UDim2.new(0, 0, 0.3, 0)
timeLabel.BackgroundTransparency = 1
timeLabel.TextScaled = true
timeLabel.Font = Enum.Font.Gotham
timeLabel.TextColor3 = Color3.new(1, 1, 1)
timeLabel.Parent = results

local bestLabel = Instance.new("TextLabel")
bestLabel.Size = UDim2.new(1, 0, 0.14, 0)
bestLabel.Position = UDim2.new(0, 0, 0.52, 0)
bestLabel.BackgroundTransparency = 1
bestLabel.TextScaled = true
bestLabel.Font = Enum.Font.Gotham
bestLabel.TextColor3 = Color3.fromRGB(170, 220, 170)
bestLabel.Parent = results

local function makeButton(text: string, x: number): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0.4, 0, 0.18, 0)
	b.Position = UDim2.new(x, 0, 0.74, 0)
	b.BackgroundColor3 = Color3.fromRGB(70, 140, 70)
	b.TextScaled = true
	b.Font = Enum.Font.GothamBold
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.Parent = results
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = b
	return b
end

local retryBtn = makeButton("RETRY", 0.07)
local continueBtn = makeButton("KEEP DRIVING", 0.53)
continueBtn.BackgroundColor3 = Color3.fromRGB(70, 100, 150)

retryBtn.Activated:Connect(function()
	results.Visible = false
	Bus.fire("forceReset")
end)
continueBtn.Activated:Connect(function()
	results.Visible = false
end)

-- ============ finish volume (derived from FinishPad at runtime) ============
local finishCFrame: CFrame? = nil
local finishHalfSize: Vector3? = nil

task.spawn(function()
	local track = workspace:WaitForChild("Track", 60)
	if not track then
		return
	end
	local pad = track:WaitForChild("FinishPad", 60) :: BasePart?
	if not pad then
		warn("[RaceFlow] No FinishPad found — finish detection disabled")
		return
	end
	-- detection box: pad footprint, raised to catch airborne crossings
	finishCFrame = pad.CFrame * CFrame.new(0, 12, 0)
	finishHalfSize = Vector3.new(pad.Size.X / 2, 14, pad.Size.Z / 2)
end)

local function inFinishVolume(pos: Vector3): boolean
	if not finishCFrame or not finishHalfSize then
		return false
	end
	local localPos = finishCFrame:PointToObjectSpace(pos)
	local h = finishHalfSize :: Vector3
	return math.abs(localPos.X) <= h.X and math.abs(localPos.Y) <= h.Y and math.abs(localPos.Z) <= h.Z
end

-- ============ state transitions ============
Bus.on("launch", function()
	state = "Racing"
	raceStart = os.clock()
	timerLabel.Visible = true
	results.Visible = false
end)

Bus.on("reset", function()
	state = "PreLaunch"
	timerLabel.Visible = false
	results.Visible = false
end)

local function finishRace()
	state = "Finished"
	local t = os.clock() - raceStart
	local isRecord = bestTime == nil or t < bestTime :: number
	if isRecord then
		bestTime = t
	end
	timeLabel.Text = ("Time: %.2fs"):format(t)
	bestLabel.Text = isRecord and "NEW SESSION BEST!" or ("Session best: %.2fs"):format(bestTime :: number)
	title.Text = "FINISH!"
	results.Visible = true
	timerLabel.Visible = false
	Bus.fire("finished", t)
end

-- ============ loop ============
RunService.Heartbeat:Connect(function()
	if state ~= "Racing" then
		return
	end
	timerLabel.Text = ("%.1f"):format(os.clock() - raceStart)

	local kart = workspace:FindFirstChild(player.Name .. "_Kart")
	local chassis = kart and kart:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") and inFinishVolume(chassis.Position) then
		finishRace()
	end
end)
