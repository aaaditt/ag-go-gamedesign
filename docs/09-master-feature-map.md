# 09 — Master Feature Map

The exhaustive inventory: every feature in the game, its sub-features, where it's specced, and what data it owns. If something isn't on this list, it isn't in the game. (Legend: 📄 = spec doc §, v1 = launch, PL = post-launch.)

## A. Driving & race core (📄 05)
- A1. Slingshot launch — pull gesture, power meter, sweet-zone timing, launch impulse + decay. v1
- A2. Downhill speed model — slope accel, drag/terminal velocity, top-speed cap, recovery accel, surface multipliers (road/ice/offroad/boost pad). v1
- A3. Steering — touch halves, tilt (optional), keyboard/gamepad; handling-stat scaling; speed-scaled authority. v1
- A4. Drift — initiate/hold/release, grip model, duration-scaled mini-boost. v1
- A5. Air control + landing alignment speed retention. v1 (expanded glide/tricks: PL Air/Stunt episode)
- A6. Collisions — kart-vs-kart (strength-weighted shove), destructibles (smash-through), solid hazards, TNT blast. v1
- A7. Kart damage — 4-pip cosmetic damage, panel detach thresholds, high-damage speed penalty. v1
- A8. Respawn — off-track/fall detection, node respawn, 50% speed + 1 s ghost. v1
- A9. Pickups — coin trails, fruit, gems(rare), part-token drops ⚠ only via results, not on-track (decided: on-track = coins/fruit only). v1
- A10. Camera — chase rig, speed-reactive FOV, shake (toggleable), finish flyby. v1
- A11. Race state machine — load → intro flyby → countdown+sling → racing → finish → results; per-mode objective layer. v1

## B. Characters & powers (📄 02)
- B1. 10-racer roster, starter Red-alike. v1
- B2. Power framework — one charge (Foreman-type ×3), arm/fire/expire, server arbitration + client prediction. v1
- B3. The 10 powers — Boost, Mega Boost, Freeze, Explosion, Forward Lob, Whirlwind, Lightning, Shield+Magnet, Knockback Balloon, Triple Throw. v1
- B4. Boss-enhanced power variants (Champion Chase). v1
- B5. Character presentation — models, drive/idle/win/lose anims, voice barks, power VFX/SFX. v1
- B6. AI power usage (dramatic-moment heuristic). v1
- B7. Character outfits (cosmetic). PL

## C. Karts & garage (📄 03, 08-S10)
- C1. Modular builder — 6 slots (chassis, wheels, front, rear, topper, paint/decals). v1
- C2. Part stats + CC math — stats from parts, CC = Σ part levels, stat budget per tier. v1
- C3. Upgrades — per-part levels, coin costs, stat/CC preview. v1
- C4. Paint/decals/patterns. v1
- C5. Loadouts — 3 slots, active selection, rename; +slots via pass. v1
- C6. Part acquisition matrix — race rewards, episode/star milestones, Champion Chase, tournament prizes, codes, shop (cosmetic only). v1
- C7. Test ramp. v1
- C8. Kart showcase (hub display, lobby row, leaderboard thumbnails). v1

## D. Tracks & world (📄 04)
- D1. Spline track system — center spline, progress %, offset AI lines, respawn nodes, validation tooling. v1
- D2. Track kit — segment library + 3 episode theme sets. v1
- D3. 9 tracks (3 episodes × 3). v1; episode 4+ PL
- D4. Track furniture — destructibles, hazards, TNT, shortcuts, ramps, coin/fruit/gate layouts. v1
- D5. Hub plaza (social space + all entry points). v1
- D6. Mirrored/night variants. PL
- D7. Jenga-style destruction minigame. PL

## E. Modes (📄 04, HUD 📄 08-S7)
- E1. Race (8-grid vs AI). v1
- E2. Time Boom. v1
- E3. Fruit Splat (+Ice Splat reskin in ep3). v1
- E4. Slalom. v1
- E5. Versus (1v1 AI). v1
- E6. Champion Chase (boss ×3 → recruit). v1
- E7. Multiplayer quick race (brackets, vote, bots-fill). v1
- E8. Private lobbies (codes, host rules). v1
- E9. Ghosts (record/store/race, leaderboard replays). v1 record+race; spectate replay PL-ok
- E10. Weekly tournament (5 events, points, prizes, season reset). v1

## F. Progression & economy (📄 06)
- F1. Stars (1–3 per challenge; criteria per mode). v1
- F2. Challenge ladder unlock chain (prev ≥1★ + CC gate). v1
- F3. CC gates + UI surfacing ("what to upgrade" hints). v1
- F4. Coins — sources/sinks table, payout tuning. v1
- F5. Premium currency = Robux products directly (no intermediate gem currency v1 — simpler, more transparent). v1
- F6. Character recruitment chain (B/E6). v1
- F7. Daily quests + login streak. v1
- F8. Badges (Roblox) — first win, recruits, episode 100%, smash milestones, tournament top-100. v1
- F9. Redeem codes (Telepods homage). v1
- F10. Monetization — cosmetic shop, game passes (Garage Plus, VIP cosmetics). v1
- F11. NO energy system, NO loot chests, NO paid power. (Anti-features — enforced by design review.) v1

## G. AI (📄 05 §5)
- G1. Line-following bots with noise, drift on marked corners. v1
- G2. Rubber-banding (placement-aware, boss-reduced). v1
- G3. Difficulty bands tied to challenge CC. v1
- G4. Boss AI (better lines, enhanced power, scripted taunts). v1
- G5. Bots as MP grid-fillers. v1

## H. Multiplayer infrastructure (📄 06, 07)
- H1. Client-owned kart physics + replication smoothing. v1
- H2. Server race authority (countdown, positions, finish, rewards). v1
- H3. Matchmaking queue (in-server first; cross-server via MessagingService PL). v1
- H4. CC brackets. v1
- H5. Anti-cheat — node-sequence, min-time floors, teleport/speed sanity, validated-run flag for leaderboards. v1
- H6. Disconnect/rejoin/DNF handling. v1
- H7. Spectate ⚠ scoped: post-rejoin spectator cam only. v1-minimal

## I. Persistence & live ops (📄 06, 07)
- I1. Profile DataStore (schema 📄 06) + session cache + BindToClose flush + retry/backoff. v1
- I2. OrderedDataStore leaderboards (per-track, tournament season). v1
- I3. Tournament season rotation service. v1
- I4. Analytics funnel events (FTUE steps, first upgrade, first recruit, D1/D7). v1
- I5. Update cadence plan — weekly tournament refresh, monthly content. v1 process
- I6. Promo code admin tooling. v1-minimal (hardcoded table → PL dashboard)

## J. UI/UX (📄 08 — all screens S1–S23)
- J1. Screen set: Loading, FTUE, Hub, Episode Map, Challenge List, Pre-Race, Race HUD ×7 variants, Pause, Results, Recruit, Garage ×5 tabs, Shop, Tournament, Dailies, Leaderboards, Settings, Test Ramp, MP Queue, Private Lobby, Codes. v1
- J2. FTUE tutorial flow (race-first, guided upgrade, sling lesson, hub tour, resume-on-quit). v1
- J3. Global UI systems — toasts, badge-dots, currency strip, locked-content transparency, back-everywhere. v1
- J4. Input schemes — touch / tilt / KB+M / gamepad, remap-lite via settings. v1
- J5. Accessibility — colorblind markers, reduced flash, shake toggle, 44px targets. v1

## K. Audio (📄 08 + this list is the spec)
- K1. Music — hub loop, garage loop, race themes ×3 episodes, tournament sting, results win/lose stings, recruit fanfare. v1
- K2. SFX — sling stretch/release, wind/speed layer, drift skid + boost chirp, surface rumbles (wood/stone/ice), smash (crate/fruit/snow), TNT, power sounds ×10, coin/fruit pickup, UI clicks, countdown beeps, finish crowd. v1
- K3. Voice barks — per racer: launch yell, power yell, hit grunt, win/lose lines. v1 (text-free gibberish — localization-proof)
- K4. All audio original/licensed (no Rovio assets). v1

## L. Art (📄 06-art-direction notes + 07 IP)
- L1. Original bird-like/pig-like racer designs ×10. v1
- L2. Kart part library ≥30 parts visual. v1
- L3. 3 episode theme sets + hub. v1
- L4. VFX library — powers, smash debris, confetti, speed lines. v1
- L5. Icon, thumbnails, off-platform key art. v1

## M. Compliance & platform (📄 07)
- M1. Original IP/branding (no "Angry Birds" anywhere). v1
- M2. Roblox experience questionnaire / maturity rating. v1
- M3. Monetization policy compliance (no paid RNG with Robux v1 — we have no chests anyway). v1
- M4. Performance budget — 60 fps mid-phone, <5 s track load, StreamingEnabled. v1

## Coverage cross-check
Every feature above traces to: a spec section (docs 01–08), a build phase (doc 07 §2), and — where player-facing — a screen (doc 08). The runthrough in [10-logic-runthrough.md](10-logic-runthrough.md) walks the player journey end-to-end against this map.
