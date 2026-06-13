--!strict
-- Driving-feel tuning sheet v3 (docs/12-driving-mechanics-spec.md)
-- EVERY number a feel-tester might want to change lives here.

return {
	-- Speed model (docs/12): engine + slope + caps
	-- CASUAL REBALANCE (docs/15 P1): all linear speeds/accels halved vs the
	-- original twitchy tuning. Half speed ⇒ tracks last ~2× longer; the feel is
	-- preserved because caps AND accels scaled together. Angular/time rates below
	-- (steer deg/s, grip /s, drift seconds) are deliberately NOT halved.
	EngineTopSpeed = 45, -- studs/s, what W alone can reach
	EngineAccel = 18, -- studs/s^2 while holding W
	CoastDecel = 4, -- studs/s^2 bleed when not holding W on flat/uphill
	BrakeDecel = 30, -- studs/s^2 while holding S
	DownhillMaxSpeed = 72, -- absolute ceiling from gravity alone
	ExcessDecay = 5, -- studs/s^2 bleed when above your current cap (kept momentum)
	SlopeAccelFactor = 1.3, -- multiplier on g·sin(slope): gentler downhill pull
	UphillDecelFactor = 0.8, -- climbing genuinely costs speed

	-- Slingshot launch
	LaunchChargeTime = 1.5,
	LaunchMaxSpeed = 68,
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
	DriftBoostSpeeds = { 60, 66, 72 }, -- cap during release boost per stage
	DriftBoostDurations = { 1.0, 1.5, 2.2 }, -- s of boost per stage
	DriftChargeSteerBonus = 1.6, -- charge rate multiplier at full steering input

	-- Boost pads
	BoostPadSpeed = 78,
	BoostPadDuration = 1.5,

	-- Glide (airborne, hold Space)
	GlideFallSpeed = 14, -- max fall rate while gliding (studs/s)
	GlideAirSteerMult = 2.0,

	-- Airborne (not gliding)
	AirControlDeg = 25,
	LevelOutRate = 2.5,

	-- Hover suspension (docs/11; surface-relative since the Wild Geometry update)
	RideHeight = 2.5,
	HoverGain = 10,
	HoverMaxVel = 60,
	GroundRayMargin = 4,
	InvertMinSpeed = 16, -- slower than this on walls/ceiling (normal.Y < 0.15) = you fall off (halved with speeds so loops stay drivable)

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
