# 16 — In-Studio Verification Protocol (the playtest gate)

**Why this exists.** M0–M7 are code-complete but were never run in Roblox Studio
(docs/13 ⛔ VERIFICATION GATE). Claude can't run Studio — only you can. This is the
exact script to follow so the playtest is systematic, not vibes. Work top to
bottom, tick boxes, and **write what broke** in the Results log at the bottom.
Hand that log back to Claude and it fixes the failures, then you re-run the
affected sections.

> Pairs with [15-production-overhaul.md](15-production-overhaul.md) (what changed
> this session) and [13-master-build-plan.md](13-master-build-plan.md) (the gate).

---

## 0. Setup (once)

1. Terminal in the repo: `bin\rojo.exe serve`.
2. Open the place in Studio → **Plugins ▸ Rojo ▸ Connect**. Confirm it syncs
   (status turns green, `src/*` appears under the services).
3. **Enable DataStores in Studio**: Game Settings ▸ Security ▸ *Enable Studio
   Access to API Services* = ON. (Needed for economy persistence + leaderboards.)
4. Open the **Output** window (View ▸ Output). Keep it visible the whole time —
   **any red error is a failure**, note it with the script name + line.
5. Single-player tests: press **Play** (F5). Multiplayer tests (§13): Test ▸
   *Clients and Servers* ▸ 2 players ▸ Start.

**Boot smoke test.** On Play, Output should show no red. Expected info prints:
`[TrackService] Preserved…` only if a custom track exists (none now). You spawn in
the **Lobby**, not on a track (docs/14). ☐ Boots clean, spawn is the lobby.

---

## 1. Lobby & portals (docs/14, M7)
- ☐ You spawn as a walking character in the hub plaza (not in a kart).
- ☐ Plaza reads correctly: ground, portals, signage visible.
- ☐ Walking into a **Play portal** switches you to kart mode on a track.
- ☐ Returning from a race drops you back in the lobby as a walker.

## 2. Kart spawn & slingshot launch (M0/M1)
- ☐ A kart spawns at the start pad with you seated (can't hop out with Space).
- ☐ The **charge bar** + "HOLD SPACE to charge" hint appear *(this was the crash
  bug — if you see them, the P5 fix worked; if the kart spawns but no hint/bar,
  check Output)*.
- ☐ Hold Space → fill rises; release in the **green** → "PERFECT LAUNCH!".
- ☐ Release outside green → weaker launch. Kart unanchors and moves on launch.

## 3. Driving feel — the new HALF-SPEED tuning (docs/12, docs/15 P1)
This is the headline change. It should feel **casual/cruisy, not twitchy.**
- ☐ Top speed on flat (hold W) tops out ~45 (speed readout, bottom-right).
- ☐ Downhill it climbs toward ~72 max, not 140.
- ☐ Brake (S) slows firmly; coast (no W) bleeds gently on flat/uphill.
- ☐ Steering (A/D) feels responsive at the lower speed (not floaty/heavy).
- ☐ **Skid boost** (hold Shift while turning, release): 3 stages, blue→orange→
   purple sparks, "SKID BOOST x N!" surge. Boost caps ~60/66/72.
- ☐ **Boost pads** (orange neon strips) shove you to ~78 briefly.
- ☐ **Glide** (airborne, hold Space) floats you down slowly (floatier now).

## 4. Surface-relative geometry — the LOOPS (docs/15 P2)
The loop was the explicit ask: bigger + properly integrated.
- ☐ First big loop is **e1t3 "Loop-de-Grove"** (radius ~95 — much bigger than the
   old cramped one). Drive it: smooth flat lead-in, up and over, no kink.
- ☐ Exit road lines up cleanly with / parallel to the entry (no weird off-axis
   veer), and the exit road **clears** the entry road (no overlap).
- ☐ You stay stuck to the road upside-down at the top (speed stayed > ~16).
- ☐ If you fall off the loop, you respawn **below** it, not before the lead-in.
- ☐ Corkscrew spirals (e1t2, e2t2, e3t1) drive without flipping the camera out.
- ☐ **e2t3 "Mesa Madness"** double loop and **e3t3 "Avalanche Apocalypse"** (dive
   → big loop → spiral → 2nd loop) complete without falling through anything.

## 5. Track length — the ≥60 s requirement (docs/15 P3)
**Time each track** start→finish and record below. Target ≥ 60 s; E3 ~90–110 s.
| Track | Target | Your time | OK? |
|---|---|---|---|
| e1t1 Sprout Hill | ~60 s | ___ | ☐ |
| e1t2 Meadow Spiral | ~62 s | ___ | ☐ |
| e1t3 Loop-de-Grove | ~70 s | ___ | ☐ |
| e2t1 Dust Gulch | ~74 s | ___ | ☐ |
| e2t2 Hoodoo Helix | ~75 s | ___ | ☐ |
| e2t3 Mesa Madness | ~100 s | ___ | ☐ |
| e3t1 Powder Corkscrew | ~85 s | ___ | ☐ |
| e3t2 Glacier Gap | ~85 s | ___ | ☐ |
| e3t3 Avalanche Apocalypse | ~110 s | ___ | ☐ |
- ☐ **Gaps are glideable** at the new speed (hold Space over each `jump` gap). If
   you fall short on any, note which track — Claude shortens that `jump()`.

## 6. AI bots (M2)
- ☐ 7 bots sit on the grid, launch when you do.
- ☐ They follow the racing line through loops/spirals without T-posing or flying
   off (pose guards).
- ☐ **Rubber-banding**: fall behind → they ease up; get ahead → they push.
- ☐ Position HUD ("P 3/8") updates live and is plausible.
- ☐ They feel competitive but **beatable** across the longer tracks (note if they
   run away or are trivially slow — `BOT_SPEEDS` tune).

## 7. The 10 powers (M3)
For the character you're driving, press **Q**:
- ☐ Power fires, charge count decrements, can't fire at 0.
- ☐ Self-powers (boosts) affect you; offensive powers visibly affect bots
   (freeze tint / knockback).
- ☐ Spot-check a few different characters (swap in garage/roster) cover the
   archetypes: boost, freeze, explosion, lob, whirlwind, lightning, shield,
   balloon, triple-throw.

## 8. The 6 modes (M4) — run one of each from a track's challenge list
- ☐ **Race** — placement at finish.
- ☐ **Time Boom** — countdown, red pulse near zero, BOOM on fail; par feels fair
   with the new `timeLimit`.
- ☐ **Fruit Splat** — fruit on the line, gauge fills, pass/fail.
- ☐ **Slalom** — gate pairs, miss = time penalty.
- ☐ **Versus** — 1v1 vs the rival (rival speed sane now, not 2× you).
- ☐ **Champion Chase** — boss freezes you, **shield** counters, 3 wins → recruit.

## 9. Garage, karts & economy (M5)
- ☐ Garage opens; browse/equip/buy/upgrade parts across the 4 slots.
- ☐ Equipping rebuilds the kart and the **visual reflects the parts** (colors;
   plus the new hood/lights from P4).
- ☐ Coins awarded on finish (placement-scaled); can't buy what you can't afford.
- ☐ Stats/CC update with the loadout.

## 10. Persistence (M5 W5.7) — needs API Services ON (§0.3)
- ☐ Earn coins / equip something / recruit → **Stop** → **Play** again → state
   persisted (coins, loadout, unlocks). (BindToClose saves on stop.)

## 11. Episode map, CC gates & recruiting (M6)
- ☐ Episode map shows 3 episodes; ep2/ep3 **locked** until prior bosses recruited.
- ☐ CC-gated challenges refuse entry below the required CC.
- ☐ Winning a Champion Chase 3× recruits the character + unlocks progression.

## 12. Leaderboards (M7 W7.4) — needs API Services ON
- ☐ Finishing a track posts your time; the per-track top-10 displays and sorts.

## 13. Multiplayer queue (M7 W7.2) — 2-player Studio test
- ☐ Both players enter the MP portal queue; countdown window (~12 s) syncs.
- ☐ Synchronized countdown, launch lock until GO, bots fill the grid.
- ☐ Each player appears in the other's positions; both can finish.

## 14. Daily login streak (M7 W5.8)
- ☐ First play awards the daily; streak/coins escalate (UTC day).

## 15. Graphics pass (docs/15 P4)
- ☐ **Atmosphere differs by episode**: ep1 bright midday green, ep2 warm golden
   canyon, ep3 cold blue overcast (drive one track in each).
- ☐ Roadside **props** line the track per theme (trees / rocks+cacti / pines+
   spikes) and are upright, beside the road, not on the loops.
- ☐ Dashed **centre line** on the road.
- ☐ Distant **valley floor** visible far below; you don't land on it (you respawn
   if you fall).
- ☐ Kart has the **hood + head/tail lights**; colors match the loadout.
- ☐ Frame rate acceptable on the long, prop-heavy tracks (note any chug — feeds
   the M8 perf pass / StreamingEnabled).

## 16. Mobile/touch (docs/13 W8.4) — Studio device emulator
- ☐ Test ▸ Device ▸ a phone. On-screen steer/gas/skid/sling-glide buttons appear
   and drive the kart.

---

## Results log (fill this in, hand back to Claude)

**Date:** ____   **Build commit:** ____

### ❌ Failures / red errors (script:line — what happened)
-

### ⚠️ Feel/tuning notes (too fast/slow, gap too long, par off, bot pacing…)
-

### ⏱ Track times (from §5)
-

### ✅ Sections that fully passed
-
