--!strict
-- Driving model v3 (docs/12): throttle, momentum slope rules, 3-stage skid
-- boosts, glide, boost pads — on hover suspension (docs/11). Owning client.
--
-- Controls: W/S throttle/brake · A/D steer · Shift hold = skid (release = boost)
--           Space = slingshot charge at start, GLIDE while airborne · R = reset

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Tuning = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tuning"))
local Bus = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ClientBus"))
local InputState = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InputState"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local respawnRemote = remotes:WaitForChild("RequestRespawn") :: RemoteEvent
local launchRemote = remotes:WaitForChild("RequestLaunch") :: RemoteEvent

-- ============ state ============
local chassis: Part? = nil
local mover: LinearVelocity? = nil
local aligner: AlignOrientation? = nil

local launched = false
local charging = false
local charge = 0
local speed = 0
local heading = 0
local velDir: Vector3 = -Vector3.zAxis
local surfFwd: Vector3 = -Vector3.zAxis -- persistent steered forward ON the surface
local steerInput = 0

local drifting = false
local driftTime = 0
local driftStage = 0

local boostTimer = 0 -- time left at raised cap
local boostCap = 0 -- cap while boosting (pad or drift release)
local frozenUntil = 0 -- boss freeze (Champion Chase)

local lastNodeIdx = 1

-- ============ find my kart ============
local function syncHeadingFromChassis()
	if not chassis then
		return
	end
	local look = chassis.CFrame.LookVector
	heading = math.atan2(-look.X, -look.Z)
	local flat = Vector3.new(look.X, 0, look.Z)
	velDir = flat.Magnitude > 0.01 and flat.Unit or -Vector3.zAxis
	surfFwd = velDir
end

local function findKart()
	local kart = workspace:WaitForChild(player.Name .. "_Kart", 30)
	if not kart then
		return
	end
	chassis = kart:WaitForChild("Chassis") :: Part
	mover = chassis:WaitForChild("Mover") :: LinearVelocity
	aligner = chassis:WaitForChild("Aligner") :: AlignOrientation
	launched, charging, charge, speed = false, false, 0, 0
	boostTimer, driftTime, driftStage, lastNodeIdx = 0, 0, 0, 1
	syncHeadingFromChassis()

	-- juice: skid sparks + boost trail emitters (W8.2 lean)
	local att = (chassis :: Part):FindFirstChild("RootAttachment")
	if att and att:IsA("Attachment") and not att:FindFirstChild("DriftSparks") then
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "DriftSparks"
		sparks.Enabled = false
		sparks.Rate = 60
		sparks.Lifetime = NumberRange.new(0.2, 0.45)
		sparks.Speed = NumberRange.new(8, 16)
		sparks.SpreadAngle = Vector2.new(35, 35)
		sparks.Size = NumberSequence.new(0.35)
		sparks.Parent = att
		local trail = Instance.new("ParticleEmitter")
		trail.Name = "BoostTrail"
		trail.Enabled = false
		trail.Rate = 90
		trail.Lifetime = NumberRange.new(0.3, 0.6)
		trail.Speed = NumberRange.new(2, 5)
		trail.Size = NumberSequence.new(0.8)
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 170, 50))
		trail.Parent = att
	end

	chargeBack.Visible = true
	chargeFill.Size = UDim2.new(0, 0, 1, 0)
	hint.Text = "HOLD SPACE to charge the sling — release in the GREEN"
	hint.Visible = true
end
task.spawn(findKart)
workspace.ChildAdded:Connect(function(child)
	if child.Name == player.Name .. "_Kart" then
		task.wait(0.1)
		findKart()
	end
end)
workspace.ChildRemoved:Connect(function(child)
	if child.Name == player.Name .. "_Kart" then
		chassis, mover, aligner = nil, nil, nil
		launched, charging = false, false
	end
end)


-- ============ HUD (greybox) ============
local gui = Instance.new("ScreenGui")
gui.Name = "DriveHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local chargeBack = Instance.new("Frame")
chargeBack.Size = UDim2.new(0.3, 0, 0.03, 0)
chargeBack.Position = UDim2.new(0.35, 0, 0.85, 0)
chargeBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
chargeBack.Visible = false -- shown when a kart spawns (play mode)
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

local driftLabel = Instance.new("TextLabel")
driftLabel.Size = UDim2.new(0.2, 0, 0.045, 0)
driftLabel.Position = UDim2.new(0.4, 0, 0.9, 0)
driftLabel.BackgroundTransparency = 1
driftLabel.TextScaled = true
driftLabel.TextStrokeTransparency = 0.3
driftLabel.Text = ""
driftLabel.Parent = gui

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(0.6, 0, 0.04, 0)
hint.Position = UDim2.new(0.2, 0, 0.79, 0)
hint.BackgroundTransparency = 1
hint.TextScaled = true
hint.TextColor3 = Color3.new(1, 1, 1)
hint.TextStrokeTransparency = 0.4
hint.Text = "HOLD SPACE to charge the sling — release in the GREEN"
hint.Visible = false
hint.Parent = gui

local DRIFT_COLORS = {
	Color3.fromRGB(90, 170, 255), -- stage 1: blue
	Color3.fromRGB(255, 160, 60), -- stage 2: orange
	Color3.fromRGB(220, 100, 255), -- stage 3: purple
}

-- ============ respawn/reset ============
local respawning = false

local function resetToStart()
	respawnRemote:FireServer(1)
	launched, charging, charge, speed = false, false, 0, 0
	drifting, driftTime, driftStage = false, 0, 0
	boostTimer, boostCap = 0, 0
	lastNodeIdx = 1
	chargeFill.Size = UDim2.new(0, 0, 1, 0)
	chargeBack.Visible = true
	driftLabel.Text = ""
	hint.Text = "HOLD SPACE to charge the sling — release in the GREEN"
	hint.Visible = true
	if mover then
		mover.MaxForce = 0
		mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		mover.VectorVelocity = Vector3.zero
	end
	if aligner then
		aligner.MaxTorque = 0
	end
	task.delay(0.2, syncHeadingFromChassis)
	Bus.fire("reset")
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

Bus.on("forceReset", resetToStart)

-- self powers (boosts) arrive from PowerController via the bus
Bus.on("powerBoost", function(cap: number, duration: number)
	boostCap = cap
	boostTimer = duration
	speed = math.max(speed, cap * 0.92)
end)

-- boss powers against us (Champion Chase)
Bus.on("playerFrozen", function(duration: number)
	frozenUntil = os.clock() + duration
	boostTimer = 0
	boostCap = 0
end)

-- ============ drift helpers ============
local function currentDriftStage(): number
	local stage = 0
	for i, t in Tuning.DriftStageTimes do
		if driftTime >= t then
			stage = i
		end
	end
	return stage
end

local function releaseDrift()
	if driftStage > 0 then
		boostCap = Tuning.DriftBoostSpeeds[driftStage]
		boostTimer = Tuning.DriftBoostDurations[driftStage]
		speed = math.max(speed, boostCap * 0.92) -- surge
		hint.Text = ("SKID BOOST x%d!"):format(driftStage)
		hint.Visible = true
		task.delay(1, function()
			if not charging then
				hint.Visible = false
			end
		end)
	end
	drifting, driftTime, driftStage = false, 0, 0
	driftLabel.Text = ""
end

-- ============ input (keyboard + touch merged; edge-detected per frame) ============
local prevLaunchHeld = false
local prevDriftHeld = false
local launchLocked = false
Bus.on("launchLock", function(locked: boolean)
	launchLocked = locked
end)

local function doLaunch()
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
	launchRemote:FireServer()
	if mover then
		mover.MaxForce = math.huge
	end
	if aligner then
		aligner.MaxTorque = math.huge
	end
	Bus.fire("launch")
end

-- merges keyboard + touch each frame; returns held states
local function readInputs(): (boolean, boolean, boolean, boolean)
	local kbSteer = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		kbSteer -= 1
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		kbSteer += 1
	end
	steerInput = math.clamp(kbSteer + InputState.steer, -1, 1)
	local throttle = UserInputService:IsKeyDown(Enum.KeyCode.W)
		or UserInputService:IsKeyDown(Enum.KeyCode.Up)
		or InputState.throttle
	local braking = UserInputService:IsKeyDown(Enum.KeyCode.S)
		or UserInputService:IsKeyDown(Enum.KeyCode.Down)
		or InputState.brake
	local spaceDown = UserInputService:IsKeyDown(Enum.KeyCode.Space)
	local launchHeld = spaceDown or InputState.launchHeld
	local glideHeld = spaceDown or InputState.glideHeld
	local driftHeld = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or InputState.drift
	-- drift edges
	if driftHeld and not prevDriftHeld and launched then
		drifting = true
		driftTime = 0
	elseif prevDriftHeld and not driftHeld and drifting then
		releaseDrift()
	end
	prevDriftHeld = driftHeld
	-- launch charge edges (locked during multiplayer countdowns)
	if not launched and not launchLocked then
		if launchHeld and not prevLaunchHeld then
			charging = true
			charge = 0
		elseif prevLaunchHeld and not launchHeld and charging then
			doLaunch()
		end
	end
	prevLaunchHeld = launchHeld
	return throttle, braking, glideHeld, driftHeld
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		resetToStart()
	end
end)

-- ============ ground sampling (hover, docs/11) ============
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local CORNER_OFFSETS = {
	Vector3.new(0.8, 0, 0.8),
	Vector3.new(-0.8, 0, 0.8),
	Vector3.new(0.8, 0, -0.8),
	Vector3.new(-0.8, 0, -0.8),
}

-- Surface-relative sampling (Wild Geometry update): rays follow the KART'S
-- down, not world down — so loops, walls, and inverted road all register.
-- Returns grounded, average hit DISTANCE along the ray, normal, pad, ice.
local function groundSample(): (boolean, number, Vector3, boolean, boolean)
	if not chassis then
		return false, 0, Vector3.yAxis, false, false
	end
	rayParams.FilterDescendantsInstances = { chassis.Parent :: Instance, player.Character :: Instance? }
	local halfY = Tuning.KartSize.Y / 2
	local rayLen = halfY + Tuning.RideHeight + Tuning.GroundRayMargin
	local down = -chassis.CFrame.UpVector
	local hits, sumDist, sumNormal = 0, 0, Vector3.zero
	local onBoostPad = false
	local onIce = false
	for _, off in CORNER_OFFSETS do
		local origin = (chassis.CFrame * CFrame.new(off.X * Tuning.KartSize.X / 2, 0, off.Z * Tuning.KartSize.Z / 2)).Position
		local result = workspace:Raycast(origin, down * rayLen, rayParams)
		if result then
			hits += 1
			sumDist += (result.Position - origin).Magnitude
			sumNormal += result.Normal
			if result.Instance.Name == "BoostPad" then
				onBoostPad = true
			end
			if result.Instance:GetAttribute("Ice") then
				onIce = true
			end
		end
	end
	if hits < 2 then
		return false, 0, Vector3.yAxis, false, false
	end
	return true, sumDist / hits, sumNormal.Unit, onBoostPad, onIce
end

local function updateLastNode()
	local track = workspace:FindFirstChild("Track")
	local anchor = track and track:FindFirstChild("RespawnNodes")
	anchor = anchor and anchor:FindFirstChild("NodeAnchor")
	if not anchor or not chassis then
		return
	end
	local bestDist, bestIdx = math.huge, lastNodeIdx
	for _, node in anchor:GetChildren() do
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

	local throttle, braking, glideHeld = readInputs()

	if charging then
		charge = math.min(1, charge + dt / Tuning.LaunchChargeTime)
		chargeFill.Size = UDim2.new(charge, 0, 1, 0)
		return
	end
	if not launched then
		return
	end

	local grounded, groundDist, groundNormal, onBoostPad, onIce = groundSample()

	-- inverted-stick rule: too slow on a wall/ceiling = peel off and fall
	if grounded and groundNormal.Y < 0.15 and speed < Tuning.InvertMinSpeed then
		grounded = false
	end

	-- boost pad pickup
	if onBoostPad then
		boostCap = Tuning.BoostPadSpeed
		boostTimer = math.max(boostTimer, Tuning.BoostPadDuration)
		speed = math.max(speed, Tuning.BoostPadSpeed)
	end
	if boostTimer > 0 then
		boostTimer -= dt
		if boostTimer <= 0 then
			boostCap = 0
		end
	end

	-- steering
	local statHandlingPre = (player:GetAttribute("StatHandling") :: number?) or 1
	local speedFrac = math.clamp(speed / Tuning.DownhillMaxSpeed, 0, 1)
	local steerRate = math.rad(Tuning.SteerRateDeg) * statHandlingPre * (1 - Tuning.SteerHighSpeedPenalty * speedFrac)
	if grounded and drifting then
		steerRate *= Tuning.DriftSteerMult
		-- charge faster when steering harder (MK rule)
		local chargeRate = 1 + (Tuning.DriftChargeSteerBonus - 1) * math.abs(steerInput)
		driftTime += dt * chargeRate
		local stage = currentDriftStage()
		if stage ~= driftStage then
			driftStage = stage
		end
		if driftStage > 0 then
			driftLabel.Text = ("SKID %d"):format(driftStage)
			driftLabel.TextColor3 = DRIFT_COLORS[driftStage]
		end
	elseif not grounded then
		steerRate = math.rad(Tuning.AirControlDeg)
		if glideHeld then
			steerRate *= Tuning.GlideAirSteerMult
		end
	end
	if not grounded then
		heading -= steerInput * steerRate * dt
	end
	local headingDir = Vector3.new(-math.sin(heading), 0, -math.cos(heading))

	-- kart stats from the equipped loadout (server-published attributes)
	local statTop = (player:GetAttribute("StatTopSpeed") :: number?) or 1
	local statAccel = (player:GetAttribute("StatAccel") :: number?) or 1
	local statHandling = (player:GetAttribute("StatHandling") :: number?) or 1

	if grounded then
		local normal = groundNormal
		-- Wild Geometry: the PERSISTENT steered forward (surfFwd) lives on the
		-- surface. Project it onto the current plane (continuity across slope
		-- changes), rotate it around the surface NORMAL by the steering input
		-- at full authority — velDir then chases it through grip. This is the
		-- steering-vs-grip separation the original heading model had.
		local fwdOnSlope = surfFwd - normal * surfFwd:Dot(normal)
		if fwdOnSlope.Magnitude < 0.05 then
			local look = chassis.CFrame.LookVector
			fwdOnSlope = look - normal * look:Dot(normal)
		end
		fwdOnSlope = fwdOnSlope.Unit
		if steerInput ~= 0 then
			fwdOnSlope = CFrame.fromAxisAngle(normal, -steerInput * steerRate * dt):VectorToWorldSpace(fwdOnSlope)
		end
		surfFwd = fwdOnSlope
		-- keep world heading synced so leaving the ground feels continuous
		local flatFwd = Vector3.new(fwdOnSlope.X, 0, fwdOnSlope.Z)
		if flatFwd.Magnitude > 0.05 then
			heading = math.atan2(-flatFwd.X, -flatFwd.Z)
		end

		-- slope force: steeper = stronger (∝ sin); uphill costs at UphillDecelFactor
		local slopeAccel = -fwdOnSlope.Y * workspace.Gravity * Tuning.SlopeAccelFactor / 9.81
		if slopeAccel < 0 then
			slopeAccel *= Tuning.UphillDecelFactor
		end

		-- engine/coast/brake (docs/12 speed model)
		local engineTop = Tuning.EngineTopSpeed * statTop
		local accel = slopeAccel
		if braking then
			accel -= Tuning.BrakeDecel
		elseif throttle then
			if speed < engineTop then
				accel += Tuning.EngineAccel * statAccel
			end
		else
			if slopeAccel <= 0.5 then -- flat or uphill: coast bleed
				accel -= Tuning.CoastDecel
			end
		end
		speed += accel * dt

		-- boss freeze: speed crushed while frozen
		if os.clock() < frozenUntil then
			speed = math.min(speed, 12)
		end

		-- caps: engine 90 / downhill 140 / boost overrides; above cap = gentle bleed
		local cap = math.max(boostTimer > 0 and boostCap or 0, Tuning.DownhillMaxSpeed)
		if speed > cap then
			speed = cap
		end
		local softCap = boostTimer > 0 and boostCap
			or (slopeAccel > 0.5 and Tuning.DownhillMaxSpeed or engineTop)
		if speed > softCap then
			speed = math.max(softCap, speed - Tuning.ExcessDecay * dt)
		end
		speed = math.max(speed, 0)

		-- grip: velocity chases heading (loose in a skid; looser still on ice)
		local grip = drifting and Tuning.DriftGrip or Tuning.Grip
		if onIce then
			grip *= 0.5
		end
		velDir = velDir:Lerp(fwdOnSlope, math.clamp(grip * dt, 0, 1))
		if velDir.Magnitude > 0.001 then
			velDir = velDir.Unit
		end

		-- hover servo along the SURFACE NORMAL (works upside down): hold the
		-- ride distance measured along the kart's own down-ray
		local targetDist = Tuning.RideHeight + Tuning.KartSize.Y / 2
		local hoverVel =
			math.clamp((targetDist - groundDist) * Tuning.HoverGain, -Tuning.HoverMaxVel, Tuning.HoverMaxVel)

		mover.MaxForce = math.huge
		mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		mover.VectorVelocity = velDir * speed + normal * hoverVel

		aligner.CFrame = CFrame.lookAt(Vector3.zero, fwdOnSlope, normal)
	else
		-- airborne
		if drifting then
			releaseDrift() -- can't skid in the air; bank whatever you charged
		end
		local gliding = glideHeld
		local flat = Vector3.new(headingDir.X, 0, headingDir.Z).Unit * speed
		velDir = Vector3.new(headingDir.X, 0, headingDir.Z).Unit -- landings re-project from this
		surfFwd = velDir
		mover.MaxForce = math.huge
		if gliding then
			-- glide: integrate gravity manually, but never fall faster than glide speed
			local vy = math.max(chassis.AssemblyLinearVelocity.Y - workspace.Gravity * dt, -Tuning.GlideFallSpeed)
			mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			mover.VectorVelocity = Vector3.new(flat.X, vy, flat.Z)
		else
			-- free fall: gravity owns Y
			mover.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
			mover.PrimaryTangentAxis = Vector3.xAxis
			mover.SecondaryTangentAxis = Vector3.zAxis
			mover.PlaneVelocity = Vector2.new(flat.X, flat.Z)
		end
		local levelCF = CFrame.fromOrientation(0, heading, 0)
		aligner.CFrame = aligner.CFrame:Lerp(levelCF, math.clamp(Tuning.LevelOutRate * dt, 0, 1))
	end

	updateLastNode()
	speedLabel.Text = ("%d"):format(speed)
	speedLabel.TextColor3 = boostTimer > 0 and Color3.fromRGB(255, 170, 50) or Color3.new(1, 1, 1)

	-- juice emitters track state
	local att = chassis:FindFirstChild("RootAttachment")
	if att then
		local sparks = att:FindFirstChild("DriftSparks") :: ParticleEmitter?
		if sparks then
			sparks.Enabled = grounded and drifting
			if driftStage > 0 then
				sparks.Color = ColorSequence.new(DRIFT_COLORS[driftStage])
			end
		end
		local trail = att:FindFirstChild("BoostTrail") :: ParticleEmitter?
		if trail then
			trail.Enabled = boostTimer > 0
		end
	end

	if chassis.Position.Y < Tuning.FallY then
		fallRespawn()
	end
end)
