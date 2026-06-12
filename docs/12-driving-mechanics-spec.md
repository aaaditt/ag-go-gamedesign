# 12 — Driving Mechanics Spec v3 (throttle, skids, glide, boost pads, momentum)

Defines the complete driving model, based on feel-tester direction + genre research (Mario Kart's documented systems are the canon for arcade karting).

## Research basis

- **Mini-turbo drift** ([Super Mario Wiki](https://www.mariowiki.com/Mini-Turbo), [MK8D drift guide](https://www.nintendolife.com/guides/mario-kart-8-deluxe-drifting-guide-how-to-drift-slipstream-and-boost)): holding drift charges a counter (faster with sharper steering); thresholds upgrade spark color blue → orange → purple; releasing grants a speed boost whose strength/length scales with the stage reached.
- **Glider** ([Super Mario Wiki](https://www.mariowiki.com/Glider), [MK glider mechanics](https://mariokart.fandom.com/wiki/Glider)): while deployed, descent is slowed dramatically; player retains forward momentum and steers in the air; pitching down trades altitude for speed, up trades speed for altitude.
- **Arcade speed model** ([Car Physics for Games](https://asawicki.info/Mirror/Car%20Physics%20for%20Games/Car%20Physics%20for%20Games.html), [racing design guide](https://gamedesignskills.com/game-design/racing/)): arcade racers use designer-authored accel/decel constants, not engine simulation; slope force ∝ sin(slope) added on top; downhill exceeds engine cap, uphill bleeds it.
- **Smooth curved track** ([Red Blob: curved paths](https://www.redblobgames.com/articles/curved-paths/), [Roblox road threads](https://devforum.roblox.com/t/how-to-make-perfect-roads/355451)): curves = many short chord segments with overlap; per-joint turn angle small enough that the outer-edge wedge gap stays under the overlap length. Our standard: **≤4° of turn per step, ≥2.5 studs overlap** — outer gap ≈ halfWidth·tan(4°) ≈ 1.5 < 2.5 ✓ no holes.

## The speed model (grounded)

```
engine:   holding W            → +EngineAccel toward EngineTopSpeed (90)
coast:    no W, flat/uphill    → −CoastDecel (speed slowly decreases)
brake:    holding S            → −BrakeDecel
slope:    ±g·sin(slope)·SlopeFactor   — steeper downhill = faster gain (∝ sin)
          uphill applies at UphillFactor 0.8 (climbing genuinely costs speed)
caps:     engine can only push to 90; downhill may carry you to DownhillMaxSpeed 140;
          above your current cap on flat → ExcessDecay (slow bleed = "you retain the speed")
          boost (pads / drift release) raises the cap temporarily
```

Player-visible rules (the contract):
1. Steeper ramp down ⇒ faster speed gain, no hard ceiling until 140.
2. Speed earned downhill is **kept** on flats, decaying gently; only uphill eats it quickly.
3. W accelerates (up to 90), no W coasts down slowly, S brakes hard.

## Skid/drift (Mario Kart mini-turbo, 3 stages)

- Hold **Shift** while steering → skid state: looser grip (kart slides, visible slip angle), tighter steering authority.
- Charge while skidding (faster when steering hard): **Stage 1 at 1.0 s → Stage 2 at 2.2 s → Stage 3 at 3.5 s**.
- Release → boost by stage: +cap and surge for **1.0 s / 1.5 s / 2.2 s** at **115 / 125 / 135** studs/s.
- HUD shows charge color (blue/orange/purple). (Spark VFX later — juice pass.)
- Releasing before Stage 1 = no boost (prevents spam-tapping).

## Glide (airborne, hold Space)

- While airborne, hold **Space**: deploy glide — fall speed capped at **GlideFallSpeed −22** (vs ~−90 free fall), forward speed held, air steering improved ×2.
- Release = normal fall. Landing retracts automatically.
- Purpose: clear big gaps stylishly, line up landings; Air-episode tracks later are built around it.

## Boost pads

- Neon-orange strips on the road (`BoostPad` parts; hover rays detect them under the kart).
- Effect: speed instantly raised to ≥ **BoostPadSpeed 150**, cap held there for **1.5 s**, then normal decay rules.
- Placement grammar: before big jumps (guarantee clearance), on straights as racing-line rewards, at shortcut exits.

## The jump (designed with ballistics, not vibes)

Takeoff at ~140–150 (boost pad before the ramp) on a 14° ramp:
vy ≈ 145·sin14° ≈ 35; with g = 196.2, return-to-height time ≈ 0.36 s → ~50 studs range,
plus the landing zone sits ~15 studs lower (≈ +0.12 s) → ~65 studs of reach.
**Gap = 38 studs** ⇒ clearable with the boost pad, scary without (teaches pads). Glide makes it trivial (style choice).

## Track geometry standard (v2 builder)

- Build in **6-stud steps**; yaw distributed ≤4°/step; pitch eases ≤1.5°/step toward each segment's target (no more sudden creases).
- Road steps overlap 2.5 studs; rails overlap 3 and follow every step → **no outer-curve holes**.
- Respawn nodes every ~50 studs along the ribbon; same Track/StartPad/NodeAnchor names (scripts unchanged).
- This stays a *generator* (regenerate = delete Track folder, rerun command); hand-editing remains the post-generation workflow.

## Controls (updated)

| Action | PC |
|---|---|
| Throttle / Brake | **W / S** |
| Steer | **A/D** or ←/→ |
| Skid (hold) | **Shift** |
| Glide (hold, airborne) | **Space** |
| Slingshot charge (at start) | **Space** hold-release |
| Respawn to start | **R** |
