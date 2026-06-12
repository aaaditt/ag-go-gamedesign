--!strict
-- M4: in-race mode mechanics that need the local kart — fruit smashing
-- (proximity → server validates) and slalom gate judging (pass/miss).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fruitSmashRemote = remotes:WaitForChild("FruitSmash") :: RemoteEvent

local mode: string? = nil
local racing = false
local judgedGates: { [number]: boolean } = {}

Bus.on("challenge", function(def)
	mode = def.mode
end)
Bus.on("launch", function()
	racing = true
	table.clear(judgedGates)
end)
Bus.on("reset", function()
	racing = false
	table.clear(judgedGates)
end)

RunService.Heartbeat:Connect(function()
	if not racing then
		return
	end
	local kart = workspace:FindFirstChild(player.Name .. "_Kart")
	local chassis = kart and kart:FindFirstChild("Chassis")
	if not (chassis and chassis:IsA("BasePart")) then
		return
	end
	local props = workspace:FindFirstChild("ModeProps")
	if not props then
		return
	end

	if mode == "FruitSplat" then
		for _, fruit in props:GetChildren() do
			if fruit:IsA("BasePart") and fruit.Name:sub(1, 6) == "Fruit_" then
				if (chassis.Position - fruit.Position).Magnitude < 8 then
					fruit.Transparency = 0.8 -- instant local feedback; server confirms
					fruitSmashRemote:FireServer(fruit.Name)
				end
			end
		end
	elseif mode == "Slalom" then
		local kartVel = chassis.AssemblyLinearVelocity
		for _, marker in props:GetChildren() do
			if marker.Name:sub(1, 5) == "Gate_" and marker:IsA("BasePart") then
				local idx = marker:GetAttribute("GateIndex") :: number?
				if not idx or judgedGates[idx] then
					continue
				end
				local toGate = marker.Position - chassis.Position
				local halfWidth = (marker:GetAttribute("HalfWidth") :: number?) or 7
				-- judge when the kart is passing the gate's plane (close in Z-along-velocity)
				local along = kartVel.Magnitude > 1 and toGate:Dot(kartVel.Unit) or toGate.Magnitude
				if along < 0 and toGate.Magnitude < 60 then
					-- gate is now behind us: pass if we went through the opening
					local lateralDist = (Vector3.new(toGate.X, 0, toGate.Z)
						- (kartVel.Magnitude > 1 and kartVel.Unit * toGate:Dot(kartVel.Unit) or Vector3.zero)).Magnitude
					judgedGates[idx] = true
					if toGate.Magnitude < halfWidth + 4 or lateralDist <= halfWidth then
						Bus.fire("gatePassed", idx)
					else
						Bus.fire("gateMissed", idx)
					end
				end
			end
		end
	end
end)
