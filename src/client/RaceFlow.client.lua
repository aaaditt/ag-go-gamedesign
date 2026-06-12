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

-- mode context (M4)
local challenge: { [string]: any }? = nil
local slalomPenalty = 0
local chaseWins: { [string]: number } = {} -- bossId → session wins

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

local posLabel = Instance.new("TextLabel")
posLabel.Size = UDim2.new(0.12, 0, 0.08, 0)
posLabel.Position = UDim2.new(0.03, 0, 0.03, 0)
posLabel.BackgroundTransparency = 0.4
posLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
posLabel.TextScaled = true
posLabel.TextColor3 = Color3.fromRGB(255, 220, 90)
posLabel.Font = Enum.Font.GothamBold
posLabel.Text = ""
posLabel.Visible = false
posLabel.Parent = gui
local posCorner = Instance.new("UICorner")
posCorner.Parent = posLabel

local PLACE_NAMES = { "1st", "2nd", "3rd", "4th", "5th", "6th", "7th", "8th" }

-- fruit gauge (FruitSplat)
local gaugeBack = Instance.new("Frame")
gaugeBack.Size = UDim2.new(0.3, 0, 0.025, 0)
gaugeBack.Position = UDim2.new(0.35, 0, 0.11, 0)
gaugeBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
gaugeBack.Visible = false
gaugeBack.Parent = gui
local gaugeFill = Instance.new("Frame")
gaugeFill.Size = UDim2.new(0, 0, 1, 0)
gaugeFill.BackgroundColor3 = Color3.fromRGB(230, 90, 200)
gaugeFill.Parent = gaugeBack
local gaugeText = Instance.new("TextLabel")
gaugeText.Size = UDim2.new(1, 0, 1.6, 0)
gaugeText.Position = UDim2.new(0, 0, -1.7, 0)
gaugeText.BackgroundTransparency = 1
gaugeText.TextScaled = true
gaugeText.Font = Enum.Font.GothamBold
gaugeText.TextColor3 = Color3.fromRGB(255, 180, 240)
gaugeText.TextStrokeTransparency = 0.5
gaugeText.Parent = gaugeBack

local flashLabel = Instance.new("TextLabel")
flashLabel.Size = UDim2.new(0.3, 0, 0.05, 0)
flashLabel.Position = UDim2.new(0.35, 0, 0.16, 0)
flashLabel.BackgroundTransparency = 1
flashLabel.TextScaled = true
flashLabel.Font = Enum.Font.GothamBold
flashLabel.TextStrokeTransparency = 0.4
flashLabel.Text = ""
flashLabel.Parent = gui

local function flash(text: string, color: Color3)
	flashLabel.Text = text
	flashLabel.TextColor3 = color
	task.delay(1.2, function()
		if flashLabel.Text == text then
			flashLabel.Text = ""
		end
	end)
end

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
Bus.on("challenge", function(def)
	challenge = def
end)

Bus.on("gateMissed", function()
	local penalty = challenge and challenge.gatePenalty or 4
	slalomPenalty += penalty
	flash(("MISSED GATE  −%ds!"):format(penalty), Color3.fromRGB(255, 90, 90))
end)

Bus.on("gatePassed", function()
	flash("GATE ✓", Color3.fromRGB(120, 230, 130))
end)

Bus.on("launch", function()
	state = "Racing"
	raceStart = os.clock()
	slalomPenalty = 0
	timerLabel.Visible = true
	results.Visible = false
	local mode = challenge and challenge.mode or "Race"
	posLabel.Visible = (mode == "Race" or mode == "Versus" or mode == "ChampionChase")
	gaugeBack.Visible = (mode == "FruitSplat")
end)

Bus.on("reset", function()
	state = "PreLaunch"
	timerLabel.Visible = false
	posLabel.Visible = false
	results.Visible = false
	gaugeBack.Visible = false
	slalomPenalty = 0
end)

local function finishRace(success: boolean, failReason: string?)
	state = "Finished"
	local t = os.clock() - raceStart
	local mode = challenge and challenge.mode or "Race"
	local place = player:GetAttribute("RacePosition") :: number?
	local total = player:GetAttribute("RacersTotal") :: number?

	if not success then
		title.Text = failReason or "FAILED!"
		title.TextColor3 = Color3.fromRGB(255, 100, 90)
		bestLabel.Text = "Try again!"
	elseif mode == "ChampionChase" then
		local bossId = challenge and challenge.bossId or "?"
		if place == 1 then
			chaseWins[bossId] = (chaseWins[bossId] or 0) + 1
			local wins = chaseWins[bossId]
			local needed = challenge and challenge.winsNeeded or 3
			if wins >= needed then
				title.Text = "CHAMPION RECRUITED! ★"
				title.TextColor3 = Color3.fromRGB(120, 255, 140)
				bestLabel.Text = "They've joined your flock!"
			else
				title.Text = ("CHASE WIN %d/%d!"):format(wins, needed)
				title.TextColor3 = Color3.fromRGB(255, 220, 90)
				bestLabel.Text = "Beat them again!"
			end
		else
			title.Text = "THE CHAMPION ESCAPED!"
			title.TextColor3 = Color3.fromRGB(255, 100, 90)
			bestLabel.Text = ("Wins so far: %d/%d"):format(chaseWins[bossId] or 0, challenge and challenge.winsNeeded or 3)
		end
	elseif (mode == "Race" or mode == "Versus") and place and total then
		title.Text = ("%s / %d!"):format(PLACE_NAMES[place] or tostring(place), total)
		title.TextColor3 = place == 1 and Color3.fromRGB(255, 220, 90) or Color3.fromRGB(220, 220, 230)
		local isRecord = bestTime == nil or t < bestTime :: number
		if isRecord then
			bestTime = t
		end
		bestLabel.Text = isRecord and "NEW SESSION BEST!" or ("Session best: %.2fs"):format(bestTime :: number)
	else
		title.Text = mode == "FruitSplat" and "GAUGE CLEARED!" or "FINISH!"
		title.TextColor3 = Color3.fromRGB(255, 220, 90)
		local isRecord = bestTime == nil or t < bestTime :: number
		if isRecord then
			bestTime = t
		end
		bestLabel.Text = isRecord and "NEW SESSION BEST!" or ("Session best: %.2fs"):format(bestTime :: number)
	end

	timeLabel.Text = ("Time: %.2fs"):format(t)
	results.Visible = true
	timerLabel.Visible = false
	posLabel.Visible = false
	gaugeBack.Visible = false
	Bus.fire("finished", t, place, success)
end

-- ============ loop ============
RunService.Heartbeat:Connect(function()
	if state ~= "Racing" then
		return
	end
	local elapsed = os.clock() - raceStart
	local mode = challenge and challenge.mode or "Race"

	-- timer: count down in timed modes, up otherwise
	if mode == "TimeBoom" or mode == "Slalom" then
		local remaining = (challenge and challenge.timeLimit or 60) - elapsed - slalomPenalty
		timerLabel.Text = ("%.1f"):format(math.max(remaining, 0))
		timerLabel.TextColor3 = remaining < 5 and Color3.fromRGB(255, 80, 80) or Color3.new(1, 1, 1)
		if remaining <= 0 then
			finishRace(false, "BOOM! 💥 OUT OF TIME")
			return
		end
	else
		timerLabel.Text = ("%.1f"):format(elapsed)
	end

	if mode == "FruitSplat" then
		local count = (player:GetAttribute("FruitCount") :: number?) or 0
		local target = challenge and challenge.fruitTarget or 20
		gaugeFill.Size = UDim2.new(math.clamp(count / target, 0, 1), 0, 1, 0)
		gaugeText.Text = ("FRUIT %d / %d"):format(count, target)
	end

	local place = player:GetAttribute("RacePosition") :: number?
	local total = player:GetAttribute("RacersTotal") :: number?
	if place and total and posLabel.Visible then
		posLabel.Text = ("%s/%d"):format(PLACE_NAMES[place] or tostring(place), total)
	end

	local kart = workspace:FindFirstChild(player.Name .. "_Kart")
	local chassis = kart and kart:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") and inFinishVolume(chassis.Position) then
		if mode == "FruitSplat" then
			local count = (player:GetAttribute("FruitCount") :: number?) or 0
			local target = challenge and challenge.fruitTarget or 20
			finishRace(count >= target, count < target and "NOT ENOUGH FRUIT!" or nil)
		else
			finishRace(true)
		end
	end
end)
