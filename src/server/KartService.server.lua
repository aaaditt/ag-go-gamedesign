--!strict
-- Phase 1: spawns one kart per player, seats them, hands physics ownership
-- to their client, and handles respawn requests.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Tuning = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tuning"))
local KartParts = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("KartParts"))

local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local respawnRemote = Instance.new("RemoteEvent")
respawnRemote.Name = "RequestRespawn"
respawnRemote.Parent = remotes

local launchRemote = Instance.new("RemoteEvent")
launchRemote.Name = "RequestLaunch"
launchRemote.Parent = remotes

local function getSpawnCFrame(): CFrame
	local track = workspace:WaitForChild("Track")
	local pad = track:WaitForChild("StartPad")
	local att = pad:WaitForChild("KartSpawn") :: Attachment
	return att.WorldCFrame
end

local function getNodes(): { Attachment }
	local anchor = workspace:WaitForChild("Track"):WaitForChild("RespawnNodes"):WaitForChild("NodeAnchor")
	local nodes = {}
	for _, child in anchor:GetChildren() do
		if child:IsA("Attachment") then
			table.insert(nodes, child)
		end
	end
	table.sort(nodes, function(a, b)
		return a.Name < b.Name
	end)
	return nodes
end

local kartsByPlayer: { [Player]: Model } = {}

local function buildKart(player: Player): Model
	local kart = Instance.new("Model")
	kart.Name = player.Name .. "_Kart"

	local chassis = Instance.new("Part")
	chassis.Name = "Chassis"
	chassis.Size = Tuning.KartSize
	chassis.Color = Color3.fromRGB(200, 60, 50)
	chassis.Material = Enum.Material.SmoothPlastic
	chassis.CustomPhysicalProperties = PhysicalProperties.new(2, 0.4, 0.2, 1, 1)
	chassis.Parent = kart
	kart.PrimaryPart = chassis

	-- visual assembly from the player's loadout (docs/13 W5.5)
	local loadout = table.clone(KartParts.DEFAULT_LOADOUT)
	pcall(function()
		local json = player:GetAttribute("LoadoutJson") :: string?
		if json then
			for slot, id in HttpService:JSONDecode(json) do
				loadout[slot] = id
			end
		end
	end)
	local function weldTo(part: BasePart)
		part.CanCollide = false
		part.Massless = true
		part.Parent = kart
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = chassis
		weld.Part1 = part
		weld.Parent = chassis
	end

	local chassisPart = KartParts.byId[loadout.chassis]
	if chassisPart then
		chassis.Color = chassisPart.color
	end

	local wheelDef = KartParts.byId[loadout.wheels]
	for _, off in { Vector3.new(-3.4, -0.6, -3), Vector3.new(3.4, -0.6, -3), Vector3.new(-3.4, -0.6, 3), Vector3.new(3.4, -0.6, 3) } do
		local wheel = Instance.new("Part")
		wheel.Shape = Enum.PartType.Cylinder
		wheel.Size = Vector3.new(1.2, 3, 3)
		wheel.Color = wheelDef and wheelDef.color or Color3.fromRGB(60, 60, 60)
		wheel.Material = Enum.Material.SmoothPlastic
		wheel.CFrame = chassis.CFrame * CFrame.new(off)
		weldTo(wheel)
	end

	local nose = Instance.new("WedgePart")
	nose.Size = Vector3.new(4, 2, 3)
	local frontDef = KartParts.byId[loadout.front]
	nose.Color = frontDef and loadout.front ~= "none_f" and frontDef.color or Color3.fromRGB(255, 200, 60)
	nose.CFrame = chassis.CFrame * CFrame.new(0, 0, -Tuning.KartSize.Z / 2 - 1.5)
	weldTo(nose)

	if loadout.rear ~= "none_r" then
		local rearDef = KartParts.byId[loadout.rear]
		local fin = Instance.new("Part")
		fin.Size = Vector3.new(5, 1, 1.5)
		fin.Color = rearDef and rearDef.color or Color3.fromRGB(90, 90, 100)
		fin.CFrame = chassis.CFrame * CFrame.new(0, 2.2, Tuning.KartSize.Z / 2 - 0.5)
		weldTo(fin)
	end

	local seat = Instance.new("Seat")
	seat.Size = Vector3.new(3, 1, 3)
	seat.Color = Color3.fromRGB(50, 50, 50)
	seat.CFrame = chassis.CFrame * CFrame.new(0, 1.5, 1)
	seat.Parent = kart
	local seatWeld = Instance.new("WeldConstraint")
	seatWeld.Part0 = chassis
	seatWeld.Part1 = seat
	seatWeld.Parent = chassis

	-- Lock the rider in: Space is the slingshot key, NOT "jump out of the kart"
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occupant = seat.Occupant
		if occupant then
			occupant.JumpPower = 0
			occupant.UseJumpPower = true
			occupant:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		end
	end)

	-- movers the client drives (forces start zeroed)
	local att = Instance.new("Attachment")
	att.Name = "RootAttachment"
	att.Parent = chassis

	local lv = Instance.new("LinearVelocity")
	lv.Name = "Mover"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.MaxForce = 0 -- client enables on launch
	lv.VectorVelocity = Vector3.zero
	lv.Parent = chassis

	local ao = Instance.new("AlignOrientation")
	ao.Name = "Aligner"
	ao.Attachment0 = att
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Responsiveness = 60
	ao.MaxTorque = 0 -- client enables on launch
	ao.Parent = chassis

	return kart
end

local function placeKart(player: Player, cf: CFrame, anchored: boolean)
	local kart = kartsByPlayer[player]
	if not kart or not kart.PrimaryPart then
		return
	end
	local chassis = kart.PrimaryPart :: Part
	chassis.AssemblyLinearVelocity = Vector3.zero
	chassis.AssemblyAngularVelocity = Vector3.zero
	kart:PivotTo(cf * CFrame.new(0, 3, 0))
	chassis.Anchored = anchored
end

local function spawnKartFor(player: Player, character: Model)
	local old = kartsByPlayer[player]
	if old then
		old:Destroy()
	end

	local kart = buildKart(player)
	kartsByPlayer[player] = kart
	kart.Parent = workspace
	placeKart(player, getSpawnCFrame(), true) -- anchored until slingshot launch

	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local seat = kart:FindFirstChildOfClass("Seat") :: Seat
	task.wait(0.2) -- let physics settle before seating
	seat:Sit(humanoid)
	-- NOTE: network ownership is granted at launch — SetNetworkOwner errors on anchored parts
end

local function hookPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		spawnKartFor(player, character)
	end)
	-- Play Solo race condition: the character often exists before this script runs
	if player.Character then
		task.spawn(spawnKartFor, player, player.Character)
	end
end

Players.PlayerAdded:Connect(hookPlayer)
for _, player in Players:GetPlayers() do
	hookPlayer(player)
end

Players.PlayerRemoving:Connect(function(player)
	local kart = kartsByPlayer[player]
	if kart then
		kart:Destroy()
		kartsByPlayer[player] = nil
	end
end)

-- Garage equips rebuild the kart (DataService fires after loadout changes)
task.spawn(function()
	local bus = ServerStorage:WaitForChild("RebuildKartBus", 30) :: BindableEvent?
	if not bus then
		return
	end
	bus.Event:Connect(function(player: Player)
		local character = player.Character
		if character then
			spawnKartFor(player, character)
		end
	end)
end)

-- Launch: only the server may unanchor; then physics ownership goes to the rider.
launchRemote.OnServerEvent:Connect(function(player)
	local kart = kartsByPlayer[player]
	local chassis = kart and kart.PrimaryPart
	if not chassis then
		return
	end
	chassis.Anchored = false
	for _, part in (kart :: Model):GetDescendants() do
		if part:IsA("BasePart") and not part.Anchored then
			part:SetNetworkOwner(player)
		end
	end
end)

-- Respawn: client asks with the node index it last passed; server validates range.
respawnRemote.OnServerEvent:Connect(function(player, nodeIdx)
	local nodes = getNodes()
	local idx = math.clamp(tonumber(nodeIdx) or 1, 1, #nodes)
	placeKart(player, nodes[idx].WorldCFrame, idx == 1) -- node 1 = start pad, re-anchor for sling
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local kart = kartsByPlayer[player]
	local seat = kart and kart:FindFirstChildOfClass("Seat")
	if humanoid and seat and humanoid.SeatPart ~= seat then
		task.wait(0.1)
		seat:Sit(humanoid)
	end
end)
