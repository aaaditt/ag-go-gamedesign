--!strict
-- Driving-feel tuning sheet v3 (docs/12-driving-mechanics-spec.md)
-- EVERY number a feel-tester might want to change lives here.

return {
	-- Speed model (docs/12): engine + slope + caps
	EngineTopSpeed = 90, -- studs/s, what W alone can reach
	EngineAccel = 35, -- studs/s^2 while holding W
	CoastDecel = 7, -- studs/s^2 bleed when not holding W on flat/uphill
	BrakeDecel = 60, -- studs/s^2 while holding S
	DownhillMaxSpeed = 140, -- absolute ceiling from gravity alone
	ExcessDecay = 8, -- studs/s^2 bleed when above your current cap (kept momentum)
	SlopeAccelFactor = 1.7, -- multiplier on g·sin(slope): steeper = faster gain
	UphillDecelFactor = 0.8, -- climbing genuinely costs speed

	-- Slingshot launch
	LaunchChargeTime = 1.5,
	LaunchMaxSpeed = 135,
	LaunchSweetZone = { 0.85, 1.0 },
	LaunchPerfectBonus = 1.1,

	-- Steering
	SteerRateDeg = 95, -- deg/s baseline
	SteerHighSpeedPenalty = 0.35, -- fraction lost at high speed
	Grip = 9, -- /s, velocity direction chases heading

	-- Skid/drift (Mario-Kart mini-turbo, 3 stages)
	DriftSteerMult = 1.6,
	DriftGrip = 3.2,
	DriftStageTimes = { 1.0, 2.2, 3.5 }, -- s held to reach stage 1/2/3
	DriftBoostSpeeds = { 115, 125, 135 }, -- cap during release boost per stage
	DriftBoostDurations = { 1.0, 1.5, 2.2 }, -- s of boost per stage
	DriftChargeSteerBonus = 1.6, -- charge rate multiplier at full steering input

	-- Boost pads
	BoostPadSpeed = 150,
	BoostPadDuration = 1.5,

	-- Glide (airborne, hold Space)
	GlideFallSpeed = 22, -- max fall rate while gliding (studs/s)
	GlideAirSteerMult = 2.0,

	-- Airborne (not gliding)
	AirControlDeg = 25,
	LevelOutRate = 2.5,

	-- Hover suspension (docs/11; surface-relative since the Wild Geometry update)
	RideHeight = 2.5,
	HoverGain = 10,
	HoverMaxVel = 60,
	GroundRayMargin = 4,
	InvertMinSpeed = 32, -- slower than this on walls/ceiling (normal.Y < 0.15) = you fall off

	-- Body & camera
	KartSize = Vector3.new(6, 2, 9),
	CameraDistance = 26,
	CameraHeight = 9,
	CameraFOVBase = 70,
	CameraFOVMax = 96, -- at DownhillMaxSpeed+

	-- Respawn
	FallY = -120,
	RespawnSpeedFraction = 0.5,
}
