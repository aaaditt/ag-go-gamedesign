--!strict
-- docs/15 P7: audio layer. Pure ClientBus listener — plays one-shot SFX on
-- gameplay events + an optional speed-pitched engine loop + music. Reads every
-- asset id from GameConfig (0 = silent no-op), and volumes from the persisted
-- SettingsJson attribute. Touches nothing in the gameplay code.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local player = Players.LocalPlayer
local SFX = Config.sounds

-- ============ volume settings ============
local musicVol, sfxVol = 0.6, 0.8
local function refreshVolumes()
	local json = player:GetAttribute("SettingsJson") :: string?
	if json then
		local ok, t = pcall(HttpService.JSONDecode, HttpService, json)
		if ok and type(t) == "table" then
			musicVol = type(t.music) == "number" and t.music or musicVol
			sfxVol = type(t.sfx) == "number" and t.sfx or sfxVol
		end
	end
end
refreshVolumes()
player:GetAttributeChangedSignal("SettingsJson"):Connect(refreshVolumes)

-- ============ one-shot SFX ============
local function playOne(key: string, scale: number?)
	local id = SFX[key]
	if not id or id == 0 then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. tostring(id)
	s.Volume = sfxVol * (scale or 1)
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(10, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

Bus.on("launch", function()
	playOne("launch")
end)
Bus.on("skidBoost", function()
	playOne("skidBoost")
end)
Bus.on("boostPad", function()
	playOne("boostPad")
end)
Bus.on("shield", function()
	playOne("shield")
end)
Bus.on("shieldBlocked", function()
	playOne("shieldBlocked")
end)
Bus.on("playerFrozen", function()
	playOne("frozen")
end)
Bus.on("gatePassed", function()
	playOne("gatePassed", 0.7)
end)
Bus.on("gateMissed", function()
	playOne("gateMissed")
end)
Bus.on("finished", function(_t: number, _place: number, success: boolean)
	playOne(success and "finishWin" or "finishLose")
end)
for _, e in { "openGarage", "openMap", "challenge" } do
	Bus.on(e, function()
		playOne("uiOpen", 0.6)
	end)
end

-- ============ background music ============
if SFX.music and SFX.music ~= 0 then
	local music = Instance.new("Sound")
	music.SoundId = "rbxassetid://" .. tostring(SFX.music)
	music.Looped = true
	music.Volume = musicVol
	music.Parent = SoundService
	music:Play()
	player:GetAttributeChangedSignal("SettingsJson"):Connect(function()
		music.Volume = musicVol
	end)
end

-- ============ engine loop (pitch tracks speed) ============
if SFX.engineLoop and SFX.engineLoop ~= 0 then
	local engine = Instance.new("Sound")
	engine.SoundId = "rbxassetid://" .. tostring(SFX.engineLoop)
	engine.Looped = true
	engine.Volume = 0
	engine.Parent = SoundService
	engine:Play()
	RunService.Heartbeat:Connect(function()
		local kart = workspace:FindFirstChild(player.Name .. "_Kart")
		local chassis = kart and kart:FindFirstChild("Chassis")
		if chassis and chassis:IsA("BasePart") then
			local spd = chassis.AssemblyLinearVelocity.Magnitude
			engine.PlaybackSpeed = 0.65 + math.clamp(spd / 90, 0, 1.4)
			engine.Volume = sfxVol * math.clamp(spd / 60, 0.05, 0.6)
		else
			engine.Volume = 0
		end
	end)
end
