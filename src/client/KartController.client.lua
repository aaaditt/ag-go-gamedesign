--!strict
-- Phase 1 driving model (docs/05): slingshot launch, downhill speed,
-- steering, drift + boost, respawn. Runs on the owning client.
--
-- Controls (PC):  A/D or ←/→ steer · LeftShift hold = drift · Space hold+release = slingshot launch
--                 R = respawn to last node
-- Controls (touch): left/right screen halves steer · drift button · hold anywhere at start = launch

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Tuning = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tuning"))

local player = Players.LocalPlayer
local respawnRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestRespawn") :: RemoteEvent
local launchRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RequestLaunch") :: RemoteEvent

-- ============ state ============
local chassis: Part? = nil
local mover: LinearVelocity? = nil
local aligner: AlignOrientation? = nil

local launched = false
local charging = false
local charge = 0 -- 0..1
local speed = 0
local heading = 0 -- radians, world yaw
local velDir: Vector3 = Vector3.zAxis * -1 -- actual travel direction (lags heading while drifting)
local drifting = false
local driftTime = 0
local boostTimer = 0
local lastNodeIdx = 1
local steerInput = 0

-- ============ find my kart ============
local function findKart()
	local kart = workspace:WaitForChild(player.Name .. "_Kart", 30)
	if not kart then
		return
	end
	chassis = kart:WaitForChild("Chassis") :: Part
	mover = chassis:WaitForChild("Mover") :: LinearVelocity
	aligner = chassis:WaitForChild("Aligner") :: AlignOrientation
	-- reset state for a fresh kart
	launched, charging, charge, speed = false, false, 0, 0
	boostTimer, driftTime, lastNodeIdx = 0, 0, 1
	local look = chassis.CFrame.LookVector
	heading = math.atan2(-look.X, -look.Z)
	velDir = Vector3.new(look.X, 0, look.Z).Unit
end
task.spawn(findKart)
workspace.ChildAdded:Connect(function(child)
	if child.Name == player.Name .. "_Kart" then
		task.wait(0.1)
		findKart()
	end
end)

-- ============ HUD (minimal greybox UI) ============
local gui = Instance.new("ScreenGui")
gui.Name = "DriveHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local chargeBack = Instance.new("Frame")
chargeBack.Size = UDim2.new(0.3, 0, 0.03, 0)
chargeBack.Position = UDim2.new(0.35, 0, 0.85, 0)
chargeBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
chargeBack.Visible = true
chargeBack.Parent = gui

local sweetZone = Instance.new("Frame")
sweetZone.Size = UDim2.new(Tuning.LaunchSweetZone[2] - Tuning.LaunchSweetZone[1], 0, 1, 0)
sweetZone.Position = UDim2.new(Tuning.LaunchSweetZone[1], 0, 0, 0)
sweetZone.BackgroundColor3 = Color3.fromRGB(80, 200, 90)
sweetZone.Parent = chargeBack

local chargeFill = Instance.new("Frame")
chargeFill.Size = UDim2.new(0, 0, 1, 0)
chargeFill.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
chargeFill.BackgroundTransparency = 0.2
chargeFill.Parent = chargeBack

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.12, 0, 0.05, 0)
speedLabel.Position = UDim2.new(0.86, 0, 0.9, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.TextScaled = true
speedLabel.TextColor3 = Color3.new(1, 1, 1)
speedLabel.TextStrokeTransparency = 0.4
speedLabel.Text = ""
speedLabel.Parent = gui

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0.5, 0, 0.04, 0)
hint.Position = UDim2.new(0.25, 0, 0.79, 0)
hint.BackgroundTransparency = 1
hint.TextScaled = true
hint.TextColor3 = Color3.new(1, 1, 1)
hint.TextStrokeTransparency = 0.4
hint.Text = "HOLD SPACE to charge the sling — release in the GREEN"
hint.Parent = gui

-- ============ respawn/reset ============
local respawning = false

local function syncHeadingFromChassis()
	if not chassis then
		return
	end
	local look = chassis.CFrame.LookVector
	heading = math.atan2(-look.X, -look.Z)
	velDir = Vector3.new(look.X, 0, look.Z).Unit
end

local function resetToStart()
	respawnRemote:FireServer(1)
	launched, charging, charge, speed = false, false, 0, 0
	drifting, driftTime, boostTimer = false, 0, 0
	lastNodeIdx = 1
	chargeFill.Size = UDim2.new(0, 0, 1, 0)
	chargeBack.Visible = true
	hint.Text = "HOLD SPACE to charge the sling — release in the GREEN"
	hint.Visible = true
	if mover then
		mover.MaxForce = 0
		mover.VectorVelocity = Vector3.zero
	end
	if aligner then
		aligner.MaxTorque = 0
	end
	task.delay(0.2, syncHeadingFromChassis)
end

local function fallRespawn()
	if respawning then
		return
	end
	respawning = true
	if lastNodeIdx <= 1 then
		resetToStart()
	else
		respawnRemote:FireServer(lastNodeIdx)
		speed *= Tuning.RespawnSpeedFraction
		task.delay(0.2, syncHeadingFromChassis)
	end
	task.delay(1.5, function()
		respawning = false
	end)
end

-- ============ input ============
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space then
		if not launched then
			charging = true
			charge = 0
		end
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		drifting = true
	elseif input.KeyCode == Enum.KeyCode.R then
		resetToStart()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space and charging and not launched then
		-- LAUNCH
		charging = false
		launched = true
		local power = charge
		local mult = 1
		if power >= Tuning.LaunchSweetZone[1] and power <= Tuning.LaunchSweetZone[2] then
			mult = Tuning.LaunchPerfectBonus
			hint.Text = "PERFECT LAUNCH!"
		else
			hint.Text = ""
		end
		speed = Tuning.LaunchMaxSpeed * power * mult
		chargeBack.Visible = false
		task.delay(1.5, function()
			hint.Visible = false
		end)
		launchRemote:FireServer() -- server unanchors + grants us physics ownership
		if mover then
			mover.MaxForce = math.huge
		end
		if aligner then
			aligner.MaxTorque = math.huge
		end
	elseif input.KeyCode == Enum.KeyCode.LeftShift then
		if drifting and driftTime >= Tuning.DriftMinTime then
			boostTimer = Tuning.DriftBoostDuration
		end
		drifting = false
		driftTime = 0
	end
end)

-- ============ helpers ============
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundCast(): RaycastResult?
	if not chassis then
		return nil
	end
	rayParams.FilterDescendantsInstances = { chassis.Parent :: Instance, player.Character :: Instance? }
	return workspace:Raycast(chassis.Position, Vector3.new(0, -(Tuning.GroundRayLength + Tuning.KartSize.Y / 2), 0), rayParams)
end

local function updateLastNode()
	local anchor = workspace:FindFirstChild("Track")
		and workspace.Track:FindFirstChild("RespawnNodes")
		and workspace.Track.RespawnNodes:FindFirstChild("NodeAnchor")
	if not anchor or not chassis then
		return
	end
	local bestDist, bestIdx = math.huge, lastNodeIdx
	for i, node in anchor:GetChildren() do
		if node:IsA("Attachment") then
			local d = (node.WorldPosition - chassis.Position).Magnitude
			if d < bestDist then
				bestDist, bestIdx = d, tonumber(node.Name:match("%d+")) or 1
			end
		end
	end
	if bestDist < 60 then
		lastNodeIdx = math.max(lastNodeIdx, bestIdx)
	end
end

-- ============ main loop ============
RunService.Heartbeat:Connect(function(dt)
	if not chassis or not mover or not aligner then
		return
	end

	-- steering input (keyboard; touch handled via ContextActionService later phases)
	steerInput = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		steerInput -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		steerInput += 1
	end

	-- slingshot charge
	if charging then
		charge = math.min(1, charge + dt / Tuning.LaunchChargeTime)
		chargeFill.Size = UDim2.new(charge, 0, 1, 0)
		return
	end
	if not launched then
		return
	end

	local ground = groundCast()
	local grounded = ground ~= nil

	-- heading
	local steerRate = math.rad(Tuning.SteerRateDeg)
		* (1 - Tuning.SteerHighSpeedPenalty * math.clamp(speed / Tuning.BaseTopSpeed, 0, 1))
	if drifting and grounded then
		steerRate *= Tuning.DriftSteerMult
		driftTime += dt
	end
	if not grounded then
		steerRate = math.rad(Tuning.AirControlDeg)
	end
	heading -= steerInput * steerRate * dt

	local headingDir = Vector3.new(-math.sin(heading), 0, -math.cos(heading))

	-- speed model
	if grounded then
		local normal = ground.Normal
		-- forward projected onto the slope plane
		local fwdOnSlope = (headingDir - normal * headingDir:Dot(normal)).Unit
		local slopeAccel = -fwdOnSlope.Y * workspace.Gravity * Tuning.SlopeAccelFactor / 9.81 -- normalized feel factor
		speed += (slopeAccel + Tuning.FlowAssist) * dt
		speed -= Tuning.Drag * speed * dt

		local topSpeed = Tuning.BaseTopSpeed * (boostTimer > 0 and Tuning.DriftBoostMult or 1)
		speed = math.clamp(speed, 0, topSpeed)

		-- velocity direction chases heading (loose while drifting)
		local grip = drifting and Tuning.DriftGrip or Tuning.Grip
		velDir = velDir:Lerp(fwdOnSlope, math.clamp(grip * dt, 0, 1))
		if velDir.Magnitude > 0.001 then
			velDir = velDir.Unit
		end

		mover.MaxForce = math.huge
		mover.VectorVelocity = velDir * speed - normal * Tuning.StickForce

		-- orient to heading + slope
		local right = headingDir:Cross(Vector3.yAxis).Unit
		local upOnSlope = normal
		local fwd = fwdOnSlope
		aligner.CFrame = CFrame.fromMatrix(Vector3.zero, right, upOnSlope, -fwd)
	else
		-- airborne: keep XZ momentum; gravity owns Y (feed current Y back in each frame)
		mover.MaxForce = math.huge
		local current = chassis.AssemblyLinearVelocity
		local flat = Vector3.new(headingDir.X, 0, headingDir.Z).Unit * speed
		mover.VectorVelocity = Vector3.new(flat.X, current.Y, flat.Z)

		-- level out slowly toward heading
		local levelCF = CFrame.fromOrientation(0, heading, 0)
		aligner.CFrame = aligner.CFrame:Lerp(levelCF, math.clamp(Tuning.LevelOutRate * dt, 0, 1))
	end

	if boostTimer > 0 then
		boostTimer -= dt
	end

	-- bookkeeping
	updateLastNode()
	speedLabel.Text = ("%d"):format(speed)

	-- fall respawn
	if chassis.Position.Y < Tuning.FallY then
		fallRespawn()
	end
end)
