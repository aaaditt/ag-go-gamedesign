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

## M3 — Characters & powers ✅

- [x] W3.1 Power framework: server-tracked charges, self powers client-executed, bot powers server-applied
- [x] W3.2 The 10 powers (docs/02 archetypes) — boosts, freeze, explosion, lob, whirlwind, lightning, shield, balloon, triple throw
- [x] W3.3 Character roster config + picker UI (recruit gating lands with M4/M5)
- [x] W3.4 Power button HUD with charge count (Q key)
- [→] W3.5 Bot power usage vs player — lands with Champion Chase boss in M4
- [x] W3.6 Placeholder character visuals (kart recolor; real models in M8)

## M4 — Modes & challenge ladder ✅

- [x] W4.1 Challenge config schema (Challenges.lua)
- [x] W4.2 Time Boom (countdown timer, red pulse, BOOM fail; checkpoint pickups → M8 juice)
- [x] W4.3 Fruit Splat (fruit on racing line, gauge, fail/retry)
- [x] W4.4 Slalom (gate pairs, miss = time penalty; TNT spawn visual → M8)
- [x] W4.5 Versus (1v1 vs configured rival)
- [x] W4.6 Champion Chase (boss enhanced freeze vs player, shield counters it, 3-win recruit flow)
- [→] W4.7 Stars + rewards + CC gating + recruit persistence — lands in M5 with the economy

## M5 — Garage, karts & economy ✅

- [x] W5.1 Kart part catalog (4 build slots, 13 parts v1; paint/topper slots + more parts → M8)
- [x] W5.2 Stat/CC math module (shared)
- [x] W5.3 Coins: finish-validated awards per docs/06 (anti-farm decay → M7 with dailies)
- [x] W5.4 Garage UI (browse/equip/buy/upgrade; tabbed polish → M8)
- [x] W5.5 Kart visual assembly from equipped parts
- [→] W5.6 Test ramp — lands with the hub in M7
- [x] W5.7 DataStore persistence with BindToClose
- [→] W5.8 Daily quests + login streak — M7 live-ops cluster

## M6 — Tracks, episodes & navigation UI ✅ (validation pass pending playtest)

- [x] W6.1 Track generator presets: 3 episodes × 3 tracks
- [x] W6.2 Episode theming (grassland / canyon / ice + ice grip physics; prop dressing → M8)
- [x] W6.3 Episode Map UI → per-track Challenge List → launch flow
- [x] W6.4 Bosses per track (9 = full roster); episode unlocks via recruitment
- [ ] W6.5 Track validation pass — **requires in-Studio playtesting (user gate)**

## ⛔ VERIFICATION GATE — everything above must be playtested before M7/M8 continue
M0–M6 + leaderboards are code-complete but unverified in Studio. Per execution
rule 3, multiplayer (M7) and polish (M8) must not stack on an untested core.
Next session: run the test protocol, fix what breaks, then resume M7.

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
