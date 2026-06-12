--!strict
-- Shared mutable input state: TouchHUD (and future gamepad mapper) writes,
-- KartController merges with keyboard each frame.

return {
	steer = 0, -- -1..1
	throttle = false,
	brake = false,
	drift = false,
	launchHeld = false, -- pre-launch sling charge
	glideHeld = false, -- airborne glide
}
