# 13 — Master Build Plan (execution roadmap to "complete game")

The stepwise plan to build everything in docs 01–12, from the current prototype to the full shippable game. Worked through **in order**; every work unit ends committed, pushed, and runnable. Checkboxes are updated as units land.

**Status legend:** ✅ done · 🔨 in progress · ⬜ pending

---

## M0 — Foundation ✅ (already complete)

- [x] Rojo project, repo, docs 01–12
- [x] Hover-suspension kart physics (docs/11)
- [x] Driving model v3: throttle/coast/brake, slope momentum, 3-stage skid boosts, glide, boost pads (docs/12)
- [x] Slingshot launch with sweet zone
- [x] Smooth ribbon track generator v2 with editor-authored workflow
- [x] Respawn nodes, fall recovery, chase camera, greybox HUD

## M1 — Race loop core ✅

- [x] W1.1 ClientBus (shared client signal module) — cross-script events (launch, reset, finish)
- [x] W1.2 Race timer: starts on launch, live HUD readout
- [x] W1.3 Finish detection derived from FinishPad at runtime (no track regen needed)
- [x] W1.4 Results overlay: time, session best, Retry / Continue
- [x] W1.5 Race state machine formalized: PreLaunch → Racing → Finished (drives HUD visibility)

## M2 — AI opponents & placement ✅

- [x] W2.1 Racing-line builder: Catmull-Rom spline from respawn nodes (SplineUtil)
- [x] W2.2 Bot kart spawner — kinematic line-followers v1 (physical hover bots: parked → M8 polish)
- [x] W2.3 Bot driver: line following with lateral offsets + difficulty speed spread + downhill bonus
- [x] W2.4 Rubber-banding (placement-aware, tunable)
- [x] W2.5 Live race positions (spline progress, player attributes) + position HUD
- [x] W2.6 Results with placement (reward hooks land with economy in M5)
- [→] W2.7 Countdown start gate — moved into M4 challenge flow (it belongs to mode start UX)

## M3 — Characters & powers

- [ ] W3.1 Power framework: arm/fire/expire, one charge, server arbitration + client prediction
- [ ] W3.2 The 10 powers (docs/02): Boost, Mega Boost, Freeze, Explosion, Forward Lob, Whirlwind, Lightning, Shield+Magnet, Knockback Balloon, Triple Throw
- [ ] W3.3 Character roster config + simple character select on Pre-Race
- [ ] W3.4 Power button HUD (+ Foreman ×3 pips)
- [ ] W3.5 Bot power usage (dramatic-moment heuristic)
- [ ] W3.6 Placeholder character visuals on karts (colored riders; real models in M8)

## M4 — Modes & challenge ladder

- [ ] W4.1 Challenge config schema (mode, track, CC req, star thresholds, rewards) in ReplicatedStorage/Config
- [ ] W4.2 Time Boom (bomb timer + checkpoint time pickups)
- [ ] W4.3 Fruit Splat (fruit objects, gauge, fail/retry)
- [ ] W4.4 Slalom (gate pairs, miss = TNT + time cut)
- [ ] W4.5 Versus (1v1 vs configured rival)
- [ ] W4.6 Champion Chase (boss with enhanced power, 3-win recruit, recruit celebration)
- [ ] W4.7 Stars per mode (docs/06 criteria) + challenge unlock chain + CC gating

## M5 — Garage, karts & economy

- [ ] W5.1 Kart part catalog config (6 slots, ≥30 parts, stats, costs) per docs/03
- [ ] W5.2 Stat/CC math module (shared, used by garage + gates)
- [ ] W5.3 Coins: earn rules (docs/06 payout table incl. anti-farm decay), spend
- [ ] W5.4 Garage UI: Build / Upgrade / Paint / Loadouts tabs
- [ ] W5.5 Kart visual assembly from equipped parts
- [ ] W5.6 Test ramp behind garage area
- [ ] W5.7 DataStore persistence (profile schema docs/06, session cache, BindToClose, retry)
- [ ] W5.8 Daily quests + login streak

## M6 — Tracks, episodes & navigation UI

- [ ] W6.1 Track generator presets: 3 episodes × 3 tracks (segment lists + theming params)
- [ ] W6.2 Episode theming kits (grassland / canyon / ice; colors, materials, props, ice surface physics)
- [ ] W6.3 Episode Map UI → Challenge List UI → Pre-Race flow (docs/08 S4–S6)
- [ ] W6.4 Boss assignments per track; roster recruitment chain wired to episode unlocks
- [ ] W6.5 Track validation pass (all challenges completable at min CC; star calibration)

## M7 — Hub, multiplayer & competition

- [ ] W7.1 Hub plaza (spawn, race gates, garage door, kiosks; walkable avatar mode ↔ kart mode)
- [ ] W7.2 In-server quick race: lobby gate, ready-up, multi-player race instances, bots fill
- [ ] W7.3 Server race authority hardening + anti-cheat floors (node sequence, min-time)
- [ ] W7.4 Per-track leaderboards (OrderedDataStore) + validated-run flag
- [ ] W7.5 Ghosts: record best run telemetry, replay as translucent kart in Time Boom
- [ ] W7.6 Weekly tournament service (5-event rotation, points, season reset)
- [ ] W7.7 Private lobbies (join codes, host rules, reduced rewards)

## M8 — Presentation, FTUE & ship

- [ ] W8.1 Kart/character visuals pass (original designs — IP-safe), wheels, damage states
- [ ] W8.2 VFX juice: skid sparks (stage colors), boost trails, landing dust, power effects
- [ ] W8.3 Audio pass: music loops, engine/wind/skid/boost/power SFX, UI sounds (original/CC0)
- [ ] W8.4 Mobile touch controls + optional tilt; gamepad mapping; input QA
- [ ] W8.5 FTUE tutorial (docs/08 S2) + hint system
- [ ] W8.6 Badges, analytics events, settings screen, codes kiosk
- [ ] W8.7 Performance pass (streaming, pooling, 60fps mid-phone) + monetization products
- [ ] W8.8 Icon/thumbnails, questionnaire, publish checklist (docs/07 §3)

---

## Execution rules

1. Strict order within a milestone; milestones may interleave only when blocked on feel-test feedback.
2. Every work unit: implement → `rojo build` validation → commit → push.
3. Anything needing an in-Studio feel test gets flagged in the commit and queued for the user's next session; building continues meanwhile.
4. Scope guard: no new features beyond docs 01–12 until the plan completes — new ideas get parked in this doc's "Parking lot" below.

## Parking lot (ideas deferred until after completion)

- (empty)
