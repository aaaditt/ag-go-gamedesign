--!strict
-- docs/15 P8: first-time user experience. A coached overlay that runs once (until
-- the persisted tutorialDone flag is set), advancing off real ClientBus events
-- with timed fallbacks so it never gets stuck. Replayable from Settings (which
-- flips tutorialDone back to false). Pure overlay — never blocks input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local saveRemote = remotes:WaitForChild("SaveSettings") :: RemoteEvent

-- ============ state from settings ============
local done = false
local function pullDone()
	local json = player:GetAttribute("SettingsJson") :: string?
	if json then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, json)
		if ok and type(t) == "table" and type(t.tutorialDone) == "boolean" then
			done = t.tutorialDone
		end
	end
end
pullDone()

-- ============ overlay ============
local gui = Instance.new("ScreenGui")
gui.Name = "FTUEGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local banner = Instance.new("TextLabel")
banner.Size = UDim2.new(0.6, 0, 0, 60)
banner.Position = UDim2.new(0.2, 0, 0.08, 0)
banner.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
banner.BackgroundTransparency = 0.15
banner.TextColor3 = Color3.new(1, 1, 1)
banner.Font = Enum.Font.GothamMedium
banner.TextSize = 18
banner.TextWrapped = true
banner.Visible = false
banner.Parent = gui
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = banner

local skip = Instance.new("TextButton")
skip.Size = UDim2.new(0, 90, 0, 26)
skip.Position = UDim2.new(0.8, -94, 0.08, 2)
skip.BackgroundColor3 = Color3.fromRGB(70, 70, 84)
skip.TextColor3 = Color3.new(1, 1, 1)
skip.Font = Enum.Font.Gotham
skip.TextSize = 13
skip.Text = "Skip ▶"
skip.Visible = false
skip.Parent = gui
local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 6)
skipCorner.Parent = skip

-- ============ step machine ============
local steps = {
	{ text = "Welcome to Downhill Flock Racers! HOLD SPACE to charge the slingshot — release in the GREEN to launch.", event = "launch", timeout = 14 },
	{ text = "Steer with A / D (or the on-screen stick). It's a casual cruise — no need to floor it.", timeout = 5 },
	{ text = "Hold SHIFT while turning, then release for a SKID BOOST. Hold longer for a bigger one!", event = "skidBoost", timeout = 8 },
	{ text = "When you fly off a ramp, HOLD SPACE to GLIDE across the gap.", timeout = 6 },
	{ text = "Press Q to fire your character's special POWER. Now go win the race!", timeout = 6 },
}

local active = false
local idx = 0
local advance: () -> ()

local function finish()
	if not active then
		return
	end
	active = false
	done = true
	banner.Text = "Tutorial complete — have fun! (Replay it anytime from ⚙ Settings.)"
	banner.Visible = true
	skip.Visible = false
	saveRemote:FireServer(HttpService:JSONEncode({ tutorialDone = true }))
	task.delay(4, function()
		if not active then
			banner.Visible = false
		end
	end)
end

local function showStep()
	local s = steps[idx]
	if not s then
		finish()
		return
	end
	banner.Text = s.text
	banner.Visible = true
	skip.Visible = true
	local myIdx = idx
	if s.timeout then
		task.delay(s.timeout, function()
			if active and idx == myIdx then
				advance()
			end
		end)
	end
end

advance = function()
	if not active then
		return
	end
	idx += 1
	if idx > #steps then
		finish()
	else
		showStep()
	end
end

local function start()
	if active or done then
		return
	end
	active = true
	idx = 1
	showStep()
end

-- advance on the matching gameplay event for the current step
local function eventAdvance(name: string)
	if active and steps[idx] and steps[idx].event == name then
		advance()
	end
end
Bus.on("launch", function()
	eventAdvance("launch")
end)
Bus.on("skidBoost", function()
	eventAdvance("skidBoost")
end)
Bus.on("finished", function()
	if active then
		finish()
	end
end)

skip.Activated:Connect(finish)

-- start when entering play mode for the first time; restart if Settings replays it
Bus.on("playMode", function(on: boolean)
	if on then
		start()
	elseif active then
		-- left play mode mid-tutorial: hide but don't mark done (resumes next play)
		active = false
		banner.Visible = false
		skip.Visible = false
	end
end)

player:GetAttributeChangedSignal("SettingsJson"):Connect(function()
	local was = done
	pullDone()
	-- "Replay tutorial" sets tutorialDone=false → allow it to run again
	if was and not done then
		start()
	end
end)
