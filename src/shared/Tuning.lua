--!strict
-- Phase 1 driving-feel tuning sheet (see docs/05-physics-and-driving.md §7)
-- EVERY number a feel-tester might want to change lives here.

return {
	-- Speed model
	BaseTopSpeed = 90, -- studs/s, stock kart cap
	SlopeAccelFactor = 1.6, -- multiplier on gravity-along-forward when descending
	FlowAssist = 8, -- studs/s^2 constant downhill-direction assist so flats never stall
	Drag = 0.35, -- /s, produces terminal velocity feel
	OffTrackDragMult = 3.0, -- extra drag off the road surface

	-- Slingshot launch
	LaunchChargeTime = 1.5, -- seconds of hold to reach full power
	LaunchMaxSpeed = 135, -- studs/s at full charge
	LaunchSweetZone = { 0.85, 1.0 }, -- charge fraction window for "PERFECT!" bonus
	LaunchPerfectBonus = 1.1, -- speed multiplier on sweet-zone release

	-- Steering
	SteerRateDeg = 95, -- deg/s at standstill-ish speeds
	SteerHighSpeedPenalty = 0.35, -- fraction of steer rate lost at top speed
	Grip = 9, -- /s, how fast velocity direction chases heading (higher = grippier)

	-- Drift
	DriftSteerMult = 1.6,
	DriftGrip = 3.2, -- loose grip while drifting
	DriftMinTime = 0.8, -- s held before release grants boost
	DriftBoostMult = 1.15,
	DriftBoostDuration = 1.2,

	-- Airborne
	AirControlDeg = 25, -- deg/s yaw authority in the air
	LevelOutRate = 2.5, -- /s, how fast kart levels mid-air

	-- Body & camera
	KartSize = Vector3.new(6, 2, 9),
	GroundRayLength = 5,
	StickForce = 14, -- studs/s pushed into the slope while grounded
	CameraDistance = 26,
	CameraHeight = 9,
	CameraFOVBase = 70,
	CameraFOVMax = 92, -- at top speed

	-- Respawn
	FallY = -120, -- below this Y = respawn
	RespawnSpeedFraction = 0.5,
}
