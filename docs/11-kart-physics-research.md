# 11 — Kart Physics Research & v2 Architecture

Triggered by Phase 1 feel-testing: seam ridges killed speed, and the kart decelerated hard before the ramp. This doc records why v1 failed, what the industry does, and the v2 design.

## Why v1 failed (diagnosis)

V1 was a **colliding box sliding on the road**. Problems inherent to that:

1. **Seam collisions.** The track is flat boxes meeting at angle changes. Each joint has a tiny lip. A sliding box SLAMS into every lip — each hit steals momentum ("small ridges that slow you down"). No amount of segment overlap fixes this; the box always finds the edge.
2. **Slope transitions are corners.** Where pitch changes, a sliding box momentarily digs its nose/tail into the new surface — more energy loss, jitter in orientation.
3. **Uphill = full physics deceleration.** The ramp before the jump applied the full gravity projection against motion + drag. Real physics, wrong feel — arcade racers preserve momentum into ramps.

## What everyone actually does: raycast suspension ("floating chassis")

The standard across Roblox racing games and arcade racers generally (Jailbreak-style vehicles, every open-source Roblox chassis, Unity arcade kart tutorials):

- The chassis **never collides with the ground**. It hovers at a fixed ride height.
- **Rays fired downward** (usually 4, at the corners) measure distance to the road.
- A **spring-damper force** (or a velocity servo) pushes the chassis up toward ride height:
  `springForce = compression * stiffness − verticalSpeed * damping` per corner.
- Drive/steering/grip are applied as forces or velocity edits on the floating body.
- Result: lips, seams, stairs, rough meshes — all get *averaged over* by the rays. Butter-smooth riding on any geometry. This is exactly our bug, solved by construction.

Reference implementations reviewed:
- Roblox DevForum: [Raycast Suspension Wheel Module](https://devforum.roblox.com/t/raycast-suspension-wheel-module-an-alternative-to-standard-physics-based-wheels/2170837), [Raycast Suspension Car System (ShapeCast-era)](https://devforum.roblox.com/t/raycast-suspension-car-system/4527231), [suspension math thread](https://devforum.roblox.com/t/help-with-calculating-physics-for-a-raycast-suspension-vehicle/839384)
- GitHub: [KChassis](https://github.com/Kyariko/KChassis-for-Roblox) (minimal raycast chassis), [Roblox-Dynamic-Suspension](https://github.com/Arctxrus/Roblox-Dynamic-Suspension) (single-script, corner auto-detect), [Racing-Kit-Roblox](https://github.com/Astrophsica/Racing-Kit-Roblox) (go-kart kit), [OpenChassis](https://github.com/OpenChassis/OpenChassis), [A-Chassis](https://github.com/lisphm/A-Chassis) (realistic wheel-based — NOT our style, noted for contrast)
- Unity/general: [SimpleRaycastVehicle-Unity](https://github.com/unity-car-tutorials/SimpleRaycastVehicle-Unity/), [Doofah bouncy vehicle tutorial](https://www.doofah.com/tutorials/unity/bouncy-vehicle-tutorial/) (the spring/damper formula above)

## v2 architecture (what we now build)

We keep the **velocity-servo** style (set velocity each frame via `LinearVelocity`) because it's deterministic and trivially tunable, and add the hover layer:

```
each Heartbeat (grounded path):
  1. Cast 4 rays straight down from chassis corners (length = rideHeight + margin)
  2. grounded = ≥2 hits → avgGroundY, avgNormal
  3. HOVER:  targetY = avgGroundY + rideHeight
             hoverVel = clamp((targetY − chassisY) * hoverGain, ±hoverMaxVel)   ← critically damped servo, no oscillation
  4. SPEED:  fwdOnSlope = heading projected on avgNormal plane
             slopeAccel = −fwdOnSlope.Y * g * slopeFactor
             if slopeAccel < 0 (uphill): slopeAccel *= uphillFactor (0.35)      ← momentum-preserving arcade rule
             speed += (slopeAccel + flowAssist) * dt;  speed −= drag * speed * dt
  5. GRIP:   velDir lerps toward fwdOnSlope at grip rate (drift = low grip + steer mult, boost on release)
  6. APPLY:  velocity = velDir * speed + (0, hoverVel, 0);  AlignOrientation to heading + avgNormal
airborne path (0–1 rays hit): unchanged — Plane-mode XZ control, gravity owns Y, level out, land aligned
```

Key consequences:
- **Chassis still has CanCollide** for rails/walls/props — but it can never touch the *road* (it floats 2.5 studs above), so seams are gone without touching the track geometry.
- The 4-ray average smooths pitch transitions (front rays read the new slope before the body reaches it) — no nose-digging.
- Uphill factor keeps ~80% of speed into the ramp instead of bleeding out.

## Tuning additions (Tuning.lua)

| Constant | Value | Meaning |
|---|---|---|
| RideHeight | 2.5 | Hover height above road (studs, from chassis underside) |
| HoverGain | 10 | Servo strength — higher snaps harder to ride height |
| HoverMaxVel | 60 | Cap on vertical correction speed (prevents teleport-y pops) |
| UphillDecelFactor | 0.35 | Fraction of uphill deceleration applied (momentum feel) |
| GroundRayMargin | 4 | Extra ray length beyond ride height (slope tolerance) |

## Future refinements (when feel demands)

- ShapeCast/SphereCast instead of rays (wider contact sampling on narrow ledges)
- Per-corner spring forces + visual chassis tilt/squash on landings (juice)
- Slip-angle drift model (velocity angle vs heading drives drift state, not just a button)
- Surface-type read from ray material → ice/offroad multipliers (doc 05 §2)
