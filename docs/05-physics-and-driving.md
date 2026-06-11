# 05 — Physics & Driving Model

The driving feel is the product. This doc specifies the slingshot start, the downhill speed model, steering/drift, collisions/damage, and tuning targets.

## 1. The slingshot start

The franchise signature, welded onto racing:

- Kart sits in a giant slingshot at the start gate. During the 3-2-1 countdown the player **pulls back** (drag down/back on screen); pull distance = stored launch power, shown by stretch + creak audio.
- **Release timing** matters: release as the countdown hits GO for the full boost; early/late release wastes power. (Pocket Gamer's guide framed mastering the sling as the #1 skill for race starts.)
- Launch applies a large forward impulse — typically enough to carry you past mid-pack AI before the first corner if perfectly timed.
- In our remake: pull = drag gesture (touch) / hold-release (mouse/gamepad trigger). Power meter UI with a "sweet zone." Max launch ≈ 1.5× normal top speed, decaying to terminal speed within ~2 s.

## 2. Downhill speed model (no throttle!)

There is **no accelerator**. The core model:

```
speed += slopeAccel(track gradient) * dt        -- gravity is the engine
speed -= drag * speed * dt                      -- terminal velocity per gradient
speed = min(speed, kartTopSpeed * surfaceMult)  -- stat cap
events: collisions (-speed, +damage), drift boost (+speed), powers (+/-),
        offroad/rough surface (extra drag), ramps (convert speed→air)
```

- **Top Speed** stat raises the cap; **Acceleration** stat scales how quickly you return to cap after losing speed. Since you're always accelerating, "acceleration" is effectively *recovery* — this is why crashes hurt low-accel karts so much.
- Surfaces: normal road ×1.0, ice ×1.05 cap but low grip (Sub Zero), rough/offroad ×0.7 with high drag, boost pads ×1.3 momentary ⚠ (pads existed sparsely; verify).
- **The player's real job is conservation of momentum**: clean lines, minimal wall contact, drift instead of brake-steering, land jumps straight.

## 3. Steering & drift

- **Steering input**: original offered tilt (accelerometer) or touch (tap/hold left-right halves). Our remake: A/D or left-stick or touch halves; steering authority scales with the **Handling** stat and inversely with current speed (fast = floatier).
- **Drift**: swipe/hold into a turn to break rear grip — kart angles into the corner, scrubbing less speed than hard steering, and **releasing a held drift grants a mini speed boost** scaled by drift duration (Mario-Kart-style, subtler). Drifting is the main skill expression on twisty episodes.
- **Air control**: small pitch/yaw authority while airborne (bigger in Air/Stunt episodes). Landing within ~15° of the track direction keeps speed; sideways landings scrub hard.
- No brake in v1 feel terms (there's nothing to brake *for* — hazards are dodged, not stopped at). We follow suit: no brake button.

## 4. Collisions & kart damage

- **Kart vs kart**: momentum exchange weighted by **Strength** stat — strong karts shove light karts off-line. Powers add scripted impulses (Bomb blast = radial knock; Terence lightning = brief stun+slow).
- **Kart vs scenery**: destructibles (crates, fruit, fences) shatter with negligible speed loss (smashing feels good); solid obstacles (rocks, TNT) cost real speed and damage.
- **Visible damage model**: karts accumulate cosmetic damage in-race — panels dent, bumpers/doors detach at thresholds (25%/50%/75%), full wreck = brief auto-respawn-style recovery ⚠ (in the original, damage was mostly cosmetic + Time Boom's material-hazard mode made stone hits "very harmful"; tune so damage reduces top speed slightly at high damage to make Strength matter).
- **TNT**: big radial blast — major speed loss + damage + dramatic tumble. Placed at shortcut risk-points and Slalom punishments.
- **Off-track/fall**: auto-respawn on the track at the last node, ~50% speed, 1 s ghost invulnerability.

## 5. Rubber-banding & AI

- v1 AI was placement-aware: backmarkers speed up, leaders ease off (standard kart-racer rubber-banding), plus AI fires powers at dramatic moments. Champion Chase bosses rubber-band *less* and have better lines + enhanced powers.
- Our remake: 7-bot grid for solo Race mode with 3 difficulty bands tied to challenge CC; bots take racing-line splines with noise, drift on marked corners, and one power use each. In online multiplayer, bots only fill empty grid slots.

## 6. Roblox implementation notes

- **Karts**: single dynamic chassis part (+ visual model welded on) driven by `VectorForce`/`LinearVelocity` for the speed model and `AlignOrientation` toward the steering heading — i.e., **arcade controller, not realistic wheel-collider physics**. Wheels are visual spinners. This is how every successful Roblox racer does it; full physical suspension is uncontrollable at toy scale.
- **Track gravity**: real slope + a constant forward "gravity along spline" assist so flow never stalls; terminal velocity from tuned drag.
- **Client simulates own kart** (network ownership) for zero-latency steering; opponents replicate; server validates finish times (anti-cheat: teleport/speed sanity checks against per-track theoretical minimums).
- **Respawn nodes + finish/checkpoint triggers** as invisible parts along the spline; lap/progress tracked by node index (also feeds position/placement UI and rubber-banding).
- **Destructibles**: anchored props swapped to debris + particles on contact (client-side VFX, server-side score), pooled for performance.
- 60–90 s races at 60 fps on mobile = budget ~5k visible parts per track view; use StreamingEnabled and theme kits with mesh instancing.

## 7. Tuning sheet (initial values — calibrate in Phase 1)

| Constant | Initial | Notes |
|---|---|---|
| Base top speed (stock kart) | 90 studs/s | ~Roblox sprint ×5; readable at toy scale |
| Max top speed (maxed kart) | 140 studs/s | |
| Slope accel | 30–60 studs/s² by gradient | |
| Recovery accel (stat-scaled) | 20–50 studs/s² | |
| Slingshot launch | up to 135 studs/s instant | decays to terminal in ~2 s |
| Drift mini-boost | +15% for 1.2 s | after ≥0.8 s held drift |
| Steering rate | 60–110°/s by Handling | scaled down 30% at top speed |
| TNT blast | -60% speed, radial 25 studs | |
| Respawn penalty | 50% speed, +1 s ghost | |
| Race length target | 60–90 s | track spline 1,800–2,600 studs |

Sources: [Angry Birds Go! — Wikipedia](https://en.wikipedia.org/wiki/Angry_Birds_Go!), [Slingshot mastery — Pocket Gamer](https://www.pocketgamer.com/angry-birds-go/how-to-master-the-slingshot-in-angry-birds-go/), [Gameplay guide — AngryBirdsNest](https://www.angrybirdsnest.com/angry-birds-go-first-look-and-guide/), [Gameplay (V1) — Angry Birds Wiki](https://angrybirds.fandom.com/wiki/Angry_Birds_Go!/Gameplay_(Version_1)).
