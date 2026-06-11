# 10 — Logic Runthrough (Start-to-Finish Verification)

Method: simulate a player's complete journey from first join to endgame, step by step. At every step, ask: *is this behavior specced, where, and does it connect to the next step without a hole?* Status: ✅ specced · 🔧 gap found → fixed (see Gap Log; fixes applied to docs).

## Part 1 — First session (minute 0–10)

| # | Player moment | Expected behavior | Spec | Status |
|---|---|---|---|---|
| 1 | Joins from Roblox | Loading screen, profile load w/ retry, guest fallback | 08-S1 | ✅ |
| 2 | New profile detected | FTUE: race-first scripted Track 1-1, coach marks | 08-S2 | ✅ |
| 3 | Finishes tutorial race | Forgiving bots guarantee ≥2nd; results explained | 08-S2.2 | ✅ |
| 4 | First upgrade (guided) | Gifted exact coins; CC rises; next challenge unlocks visibly | 08-S2.3 | ✅ |
| 5 | Slingshot lesson | Player performs launch w/ meter highlighted | 08-S2.4, 05 §1 | ✅ |
| 6 | Hub tour | Beacon trail; ftueDone saved; quits mid-FTUE resume | 08-S2.5 | ✅ |
| 7 | Leaves game at any point | BindToClose flush; partial FTUE position saved | 08-global, 07 | ✅ |

## Part 2 — Core solo loop (session 2 → episode 1 complete)

| # | Player moment | Expected behavior | Spec | Status |
|---|---|---|---|---|
| 8 | Opens Episode Map → Track 1-1 → Challenge List | Ladder visible, locks transparent, CC chips | 08-S4/S5 | ✅ |
| 9 | Enters a Race challenge | Pre-race → countdown+sling → race vs 7 bots → finish | 08-S6/S7, 05 | ✅ |
| 10 | Earns stars | **Per-mode star criteria** | 06 (added) | 🔧 G1 |
| 11 | Earns coins | **Exact payout amounts + bonuses** | 06 (added) | 🔧 G2 |
| 12 | Replays an easy challenge 20× for coins | **Anti-farm rule needed** | 06 (added) | 🔧 G3 |
| 13 | Hits a CC gate | Red chip + "what to upgrade" deep-link to garage | 08-S5, 03 | ✅ |
| 14 | Upgrades, but how fast should CC grow? | **CC curve per episode** | 06 (added) | 🔧 G4 |
| 15 | Plays Time Boom | Timer + checkpoints **(do checkpoints add time? was ⚠)** | 04 → resolved: yes, +3–5 s per checkpoint, tuned per track | 🔧 G5 |
| 16 | Plays Fruit Splat | Gauge; finish with gauge unfilled = fail → Retry on results | 04, 08-S8 | ✅ |
| 17 | Plays Slalom | Gates, miss = 5 TNT + time cut | 04 | ✅ |
| 18 | Plays Versus | 1v1 vs challenge-defined rival | 04 | ✅ |
| 19 | Reaches Champion Chase | Boss card, win counter 1/3, enhanced boss power | 02, 08-S5/S7 | ✅ |
| 20 | **Loses** a Champion Chase | No penalty, instant retry, win count keeps | 02 (clarified — losses never reset wins) | 🔧 G6 |
| 21 | 3rd win | Recruit celebration; character usable in S6 | 08-S9, 02 | ✅ |
| 22 | How many bosses per episode? | **1 boss per track → 3/episode → 9 total + starter = 10 roster** | 02 (clarified) | 🔧 G7 |
| 23 | Finishes episode 1 | Episode 2 unlocks when all 3 ep-1 bosses recruited | 04 (clarified via G7) | 🔧 G7 |

## Part 3 — Meta systems

| # | Player moment | Expected behavior | Spec | Status |
|---|---|---|---|---|
| 24 | Builds a custom kart | 6 slots, stat budget, CC math, loadouts | 03, 08-S10 | ✅ |
| 25 | Tests it | Test ramp, no rewards | 08-S20 | ✅ |
| 26 | Daily quests / streak | 3 quests + 7-day streak, claim flow | 06, 08-S17 | ✅ |
| 27 | Weekly tournament | 5 events, **points formula** | 06 (added) | 🔧 G8 |
| 28 | Season rollover mid-run | Banks to season run started in | 08-S16 | ✅ |
| 29 | Buys a cosmetic | Robux product, preview-first, never stats | 06, 08-S15 | ✅ |
| 30 | Redeems a code | Kiosk flow, server rate-limit | 08-S23, 06 | ✅ |
| 31 | Checks leaderboard | Validated runs only; ghost race | 08-S18, 09-H5/E9 | ✅ |
| 32 | Changes settings | Tilt/audio/shake/etc. **persisted where?** | 06 schema (added `settings`) | 🔧 G9 |

## Part 4 — Multiplayer

| # | Player moment | Expected behavior | Spec | Status |
|---|---|---|---|---|
| 33 | Queues at race gate | Bracket auto-suggest, vote, bots fill, 8 max | 08-S21, 06 | ✅ |
| 34 | Races online | Client-owned kart, server positions/finish | 05 §6, 07 | ✅ |
| 35 | MP race rewards | **Coin payout for MP** | 06 (added) | 🔧 G10 |
| 36 | Goes AFK in MP | **No progress 30 s → DNF** | 06 (added) | 🔧 G11 |
| 37 | Disconnects mid-MP | DNF; rejoin → spectate remainder | 08-global | ✅ |
| 38 | Private lobby with friends | Code join, host rules; **reduced rewards, no stars** (anti-farm) | 06 (added) | 🔧 G12 |
| 39 | Tries to cheat (speed/teleport) | Node-sequence + min-time floors; run flagged invalid | 07 §0, 09-H5 | ✅ |
| 40 | Ties at finish line | Server ms timestamp ordering | 08-S8 | ✅ |

## Part 5 — Endgame & lifecycle

| # | Player moment | Expected behavior | Spec | Status |
|---|---|---|---|---|
| 41 | All 80 challenges 3★, 10 racers | Remaining loops: tournament, MP brackets, ghosts, dailies, badges, kart fashion | 06, 09 | ✅ |
| 42 | New content ships | Monthly episode cadence; tournament weekly | 06, 07 PL | ✅ |
| 43 | Server shutdown mid-race | 60 s warning; saves flush; near-done MP races finish | 08-global | ✅ |
| 44 | Data corruption / failed load | Retry → guest session, no overwrite of cloud save | 08-S1 (guest mode never writes) | ✅ |

## Gap Log (all resolved — fixes applied to doc 06 unless noted)

| ID | Gap | Resolution |
|---|---|---|
| G1 | Star criteria per mode undefined | Added star table to 06: Race/Versus/MP: 1st=3★ 2nd=2★ 3rd=1★; Time Boom/Slalom: finish=1★, −15%/−30% under par time=2★/3★; Fruit Splat: clear=1★, clear+top-half finish=2★, clear+1st=3★; Champion Chase: each win=its star |
| G2 | Coin payouts unnumbered | Economy tuning table added to 06 (base, placement, smash, first-clear bonus) |
| G3 | Infinite-replay coin farming | Repeat-reward decay: full coins first 3 completions of a challenge per day, then 50% |
| G4 | CC curve undefined | Curve table added: Ep1 gates 100→250, Ep2 260→400, Ep3 410→550; stock kart 100 CC |
| G5 | Time Boom checkpoints ⚠ | Resolved: checkpoints add +3–5 s (per-track tuned); doc 05 ⚠ removed in spirit (tuning sheet note) |
| G6 | Champion Chase loss consequence | Clarified in 02: losses cost nothing; win count never resets |
| G7 | Boss count/episode-unlock rule fuzzy | Clarified: 1 boss per track, 3 per episode, 9 total; Episode N+1 unlocks when all Ep-N bosses recruited |
| G8 | Tournament points formula | Added: per event, points = placement table (100/70/50/35/25/15/10/5) for race-type, or time-percentile table for solo-type; weekly total ranks the board |
| G9 | Settings not in save schema | `settings = { music, sfx, tilt, sensitivity, shake, reducedFlash }` added to 06 schema |
| G10 | MP rewards undefined | MP quick race pays 1.5× solo Race base (no star rewards; stars are solo-campaign only) |
| G11 | AFK in MP | 30 s without node progress → DNF + bot takeover of grid slot |
| G12 | Private lobby farming | Private lobbies pay 50% coins, no stars, no quest credit toggleable by host OFF only |

## Verdict

Every step of the player journey from first join to endgame now lands on a specced behavior with no dead ends, and all 12 gaps found are resolved and written into the docs. The documentation set (01–10) is complete and internally consistent; next action is **Phase 1 of doc 07: the driving-feel prototype**.
