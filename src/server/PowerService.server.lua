--!strict
-- M3 (docs/13 W3.1–W3.4): character selection + power charges + execution.
-- Self powers bounce back to the owning client (it owns kart physics);
-- bot powers are forwarded to AIService over the BotEffect bindable.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Characters = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Characters"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local launchRemote = remotes:WaitForChild("RequestLaunch") :: RemoteEvent

local selectRemote = Instance.new("RemoteEvent")
selectRemote.Name = "SelectCharacter"
selectRemote.Parent = remotes

local usePowerRemote = Instance.new("RemoteEvent")
usePowerRemote.Name = "UsePower"
usePowerRemote.Parent = remotes

local powerFxRemote = Instance.new("RemoteEvent")
powerFxRemote.Name = "PowerFx"
powerFxRemote.Parent = remotes

local botEffectBus = Instance.new("BindableEvent")
botEffectBus.Name = "BotEffectBus"
botEffectBus.Parent = ServerStorage

local chargesLeft: { [Player]: number } = {}

local function characterOf(player: Player)
	local id = player:GetAttribute("CharacterId")
	return Characters.byId[id] or Characters.byId[Characters.DEFAULT]
end

local function recolorKart(player: Player)
	local kart = workspace:FindFirstChild(player.Name .. "_Kart")
	local chassis = kart and kart:FindFirstChild("Chassis")
	if chassis and chassis:IsA("BasePart") then
		chassis.Color = characterOf(player).color
	end
end

Players.PlayerAdded:Connect(function(player)
	player:SetAttribute("CharacterId", Characters.DEFAULT)
	chargesLeft[player] = 0
end)
for _, p in Players:GetPlayers() do
	p:SetAttribute("CharacterId", p:GetAttribute("CharacterId") or Characters.DEFAULT)
	chargesLeft[p] = chargesLeft[p] or 0
end
Players.PlayerRemoving:Connect(function(p)
	chargesLeft[p] = nil
end)

selectRemote.OnServerEvent:Connect(function(player, id)
	if typeof(id) ~= "string" or not Characters.byId[id] then
		return
	end
	-- recruitment gating: starter is always allowed; others must be recruited
	if id ~= Characters.DEFAULT then
		local unlocked = (player:GetAttribute("UnlockedChars") :: string?) or ""
		if not string.find("," .. unlocked .. ",", "," .. id .. ",", 1, true) then
			return
		end
	end
	player:SetAttribute("CharacterId", id)
	recolorKart(player)
end)

launchRemote.OnServerEvent:Connect(function(player)
	local def = characterOf(player)
	chargesLeft[player] = def.power.charges
	player:SetAttribute("PowerCharges", def.power.charges)
	recolorKart(player)
end)

usePowerRemote.OnServerEvent:Connect(function(player)
	local left = chargesLeft[player] or 0
	if left <= 0 then
		return
	end
	chargesLeft[player] = left - 1
	player:SetAttribute("PowerCharges", left - 1)

	local def = characterOf(player)
	local p = def.power
	if p.kind == "self" then
		if p.id == "shield" then
			player:SetAttribute("ShieldUntil", os.clock() + (p.shieldDuration or 3))
			powerFxRemote:FireClient(player, { action = "shield", duration = p.shieldDuration })
		else
			powerFxRemote:FireClient(player, { action = "selfBoost", cap = p.boostCap, duration = p.boostDuration })
		end
	else
		botEffectBus:Fire(player, {
			range = p.range,
			targets = p.targets,
			aheadOnly = p.aheadOnly,
			freezeTime = p.freezeTime,
			knockback = p.knockback,
		})
		powerFxRemote:FireClient(player, { action = "botHit", power = p.id })
	end
end)
