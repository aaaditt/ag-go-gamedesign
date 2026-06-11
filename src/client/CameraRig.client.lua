--!strict
-- Phase 1 chase camera: sits behind/above the kart, leads into speed,
-- FOV widens with velocity (docs/05 §6, docs/08 camera notes).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Tuning = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Tuning"))

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local smoothedPos: Vector3? = nil

RunService.RenderStepped:Connect(function(dt)
	local kart = workspace:FindFirstChild(player.Name .. "_Kart")
	local chassis = kart and kart:FindFirstChild("Chassis")
	if not chassis or not chassis:IsA("BasePart") then
		camera.CameraType = Enum.CameraType.Custom
		return
	end

	camera.CameraType = Enum.CameraType.Scriptable

	local vel = chassis.AssemblyLinearVelocity
	local speedFrac = math.clamp(vel.Magnitude / Tuning.BaseTopSpeed, 0, 1.3)

	-- follow point: behind the kart's facing, pulled back a touch more at speed
	local look = chassis.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	flatLook = flatLook.Magnitude > 0.01 and flatLook.Unit or Vector3.zAxis
	local dist = Tuning.CameraDistance * (1 + 0.15 * speedFrac)
	local targetPos = chassis.Position - flatLook * dist + Vector3.new(0, Tuning.CameraHeight, 0)

	smoothedPos = smoothedPos and smoothedPos:Lerp(targetPos, math.clamp(8 * dt, 0, 1)) or targetPos
	camera.CFrame = CFrame.lookAt(smoothedPos :: Vector3, chassis.Position + flatLook * 8 + Vector3.new(0, 2, 0))
	camera.FieldOfView = Tuning.CameraFOVBase + (Tuning.CameraFOVMax - Tuning.CameraFOVBase) * speedFrac
end)
