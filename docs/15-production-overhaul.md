# 15 — Production Overhaul (living tracker)

**Purpose.** This is the single living document for the "make it slower, longer,
prettier, and production-ready" overhaul requested 2026-06-13. It records the
**decisions**, the **target numbers**, the **phase checklist**, and a running
**changelog** so context survives across sessions. Update it as each phase lands.

> Sister docs: [13-master-build-plan.md](13-master-build-plan.md) is the milestone
> tracker (M0–M8); this doc is the overhaul tracker that sits on top of it. Feel
> numbers live in [../src/shared/Tuning.lua](../src/shared/Tuning.lua).

---

## The directive (verbatim intent)

1. **Carts a lot slower** — roughly half speed. It's a casual downhill racer, not
   a hyper-speed game. Half speed ⇒ a given track lasts ~2× longer.
2. **Every track ≥ 60 s** to complete — no more races that end in a few seconds.
3. **The loop**: it isn't properly integrated; fix it and make it **much bigger**
   ("~10× bigger so it takes a bit") so it reads as a real set-piece.
4. **Full graphics pass** — karts, the road surface, roadside elements/props, the
   environment, per-episode atmosphere. 100 % original / procedural (IP-safe).
5. **Production-ready** — buildable, hardened, playtest-prepped, uploadable.

---

## Design decisions (locked unless noted)

### A. Speed rebalance — uniform ×0.5 on linear speeds
Halving **both** caps and accelerations preserves the *feel* (time-to-top-speed
stays the same) while covering half the distance — exactly "everything at half
speed." Angular/time values (steer deg/s, grip /s, drift charge seconds) are
**not** scaled; they're rates, not speeds.

| Tuning key | Old | New | Note |
|---|---|---|---|
| EngineTopSpeed | 90 | 45 | W-only cap |
| EngineAccel | 35 | 18 | |
| CoastDecel | 7 | 4 | |
| BrakeDecel | 60 | 30 | |
| DownhillMaxSpeed | 140 | 72 | gravity ceiling |
| ExcessDecay | 8 | 5 | |
| SlopeAccelFactor | 1.7 | 1.3 | gentler downhill pull (casual) |
| LaunchMaxSpeed | 135 | 68 | |
| DriftBoostSpeeds | 115/125/135 | 60/66/72 | |
| BoostPadSpeed | 150 | 78 | |
| GlideFallSpeed | 22 | 14 | slower, floatier glide |
| **InvertMinSpeed** | 32 | **16** | loops stay drivable at half speed |

Off-sheet, in lockstep:
- `AIService.lua` `BOT_SPEEDS` 62/68/73/78/83/88/93 → **31/34/37/39/42/44/47**.
- `Tracks.lua` `rivalCruise` (88–108) → halved (44–54).
- `Challenges.lua:52` `rivalCruise - 8` → `- 4` (offset halves too).

### B. Track length — target ≥ 60 s, authored by distance budget
Effective average speed after rebalance ≈ **45–55 studs/s**. So 60 s ⇒ **~2,800
studs** of drivable length minimum; later/episode-3 tracks aim higher (90–110 s).
Current tracks are ~800–1,100 studs, so each is rebuilt to roughly **3× length**
with more varied pacing (dives, sweepers, technical chicanes, set-pieces).
`timeLimit` (Time Boom par) is raised per track to match the new durations.

### C. The loop — grand and clean
- Radius scaled from 22–30 to a **grand 90–140** range (a true centrepiece). The
  fake-centripetal model makes big loops *easier*, so this is free pacing.
- **Lead-in rule:** every loop is preceded by a near-flat (pitch ~0) segment so it
  launches without a kink — fixes the "not integrated" feel at the entry.
- **Exit clearance:** the per-step yaw incline is recomputed so total lateral
  offset ≈ road width + margin (exit road clears the entry road cleanly) instead
  of a fixed 0.7°/step that drifted 18° on every loop regardless of size.
- Loop step count scales with radius (smoothness on big loops).

### D. Graphics / art direction (IP-safe, procedural)
- **Per-episode atmosphere** via `Lighting` (ClockTime, Atmosphere, fog, sky tint)
  applied on track build/swap, driven from the `Theme`: warm midday grassland /
  hazy golden canyon / cold blue overcast ice.
- **Road surface** dressing: centre-line stripes + edge accents; themed rail look.
- **Roadside elements**: procedural props placed alongside the ribbon per theme
  (grassland: trees/bushes; canyon: mesas/cacti/rock spires; ice: pines/ice
  spikes) + a ground/valley plane below so the track reads as *in a world*.
- **Karts**: enrich `buildKart` — rounder body, spoiler, headlights, driver seat
  block — still assembled from the equipped loadout (keeps the garage meaningful).
- Branding stays 100 % original (docs/07 §4): no Rovio names/characters/audio.

---

## Phase checklist

- [x] **P1 — Speed rebalance** (Tuning + AIService + rivalCruise + Challenges). ✅ 2026-06-13
- [x] **P2 — Loop fix + scale-up** (TrackGen loop geometry; lead-in/exit rules). ✅ 2026-06-13
- [x] **P3 — Track length redesign** (all 9 tracks ≥ 60 s; timeLimit pars). ✅ 2026-06-13
- [ ] **P4 — Graphics pass** (atmosphere, road dressing, roadside props, karts).
- [ ] **P5 — Hardening + bug hunt** (fix found bugs; DataStore/MP edge cases).
- [ ] **P6 — Verification-gate protocol** (in-Studio test script + results sheet).

Each phase: `rojo build` validates → commit → push → tick the box here and the
matching box in docs/13.

---

## Bugs found during the pass (fix in P5 unless urgent)

- **KartController HUD scoping bug** — `findKart()` (defined ~L58) references
  `chargeBack`/`chargeFill`/`hint`, but those locals are declared later (~L119+).
  In Lua those resolve to *globals* (nil) at definition time, so `findKart` throws
  "attempt to index nil" the moment a kart spawns. Never caught because M0–M6 was
  never playtested. Fix: declare the HUD block **above** `findKart`.

---

## Playtest watch-list (for the in-Studio verification pass, P6)

- **Gap clearance.** At half speed, crossing a `jump` gap (44–54 studs) relies on
  gliding (hold Space; fall capped at 14 studs/s) more than raw momentum. Confirm
  every gap is glideable; shorten any that aren't (edit the `jump()` gapLen).
- **Exact lap times.** Targets are ~60–110 s but the true average speed depends on
  how aggressively a player boosts/drifts. Time each track; if any is < 60 s, add
  a motif or two; if a track drags, trim. Then tune `timeLimit` pars to match.
- **Big-loop entry/exit.** Confirm loops (radius 95–120) drive cleanly: flat
  lead-in, no kink, exit road clears the entry road, respawn lands below the loop.
- **Bot pacing.** With halved `BOT_SPEEDS`, confirm bots are competitive but
  beatable across the longer tracks; nudge `BOT_SPEEDS`/`rubberband` if needed.

## Changelog

- 2026-06-13 — Doc created; plan + target numbers locked.
- 2026-06-13 — **P1 landed**: halved player speeds (Tuning), bot speeds (AIService),
  rivalCruise (Tracks ×9), Versus offset (Challenges −8→−4), InvertMinSpeed 32→16.
  `rojo build` clean. Races now last ~2× longer on the existing track layouts.
- 2026-06-13 — **P2+P3 landed**: TrackGen loop rewritten (clean vertical loop,
  parallel exit, radius-independent sideways clearance, step count scales with
  radius). All 9 tracks rebuilt from a new motif library (esses/rollers/
  switchback/jump/loopSet/spiral/finishRun) to ~3,200–5,000 studs each for ≥60 s
  laps; loops are now grand radius-95–120 set-pieces; `timeLimit` pars raised.
  `rojo build` clean. Exact lap timings pending the P6 playtest.
