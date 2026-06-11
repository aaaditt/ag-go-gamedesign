# 03 — Karts, Upgrades & the Kart Builder

The kart is where ALL the stats live (characters only bring powers). The garage metagame — collecting, upgrading, and showing off karts — was the retention engine of Angry Birds Go!, and the "design your own bird car" fantasy is what our remake should amplify.

## Kart stats (the original four)

| Stat | In-race effect |
|---|---|
| **Top Speed** | Maximum velocity cap on straights/steeps |
| **Acceleration** | How fast you regain speed after crashes, drifts, and the launch |
| **Handling** | Steering responsiveness + drift grip |
| **Strength** | Resistance to impact damage; heavier shoves in collisions (you bully light karts) |

Each stat upgrades in discrete levels (coins; later tiers also rare parts in v2.0). **CC rating = aggregate of all upgrade levels** — a single power number (like "320 CC") used to gate content: each challenge/track shows a minimum CC; below it you literally can't compete (AI runs away from you). CC is the game's main pacing valve.

Design tension worth copying: stats trade off in feel — a max-speed/low-handling kart is a rocket you can't steer; strength karts win demolition-derby starts but lag on twisty tracks.

## The original kart roster (v1 structure)

- **~50+ karts** organized in series/tiers themed per episode (soapbox crates → jungle/wooden karts → stone/rock karts → candy karts → air/stunt frames → ice karts), plus premium/special editions (e.g., the real-money "Big Bang Special Edition" bundle, Senna's McLaren MP4/4, Telepods-exclusive karts).
- Karts were bought with **coins** (soft) or **gems/crystals** (premium); weekly tournament prizes awarded exclusive karts.
- Each kart has its own upgrade track: higher-tier karts start with higher base stats and higher upgrade ceilings.
- **Visible damage**: bumpers, panels and wheels visually dent/detach as the kart takes hits in a race (cosmetic in-race; resets after).
- v2.0 reworked acquisition: basic karts unlocked via level stars, the rest cost **Blueprints** (50/100/200/500/800/1000), upgraded with **parts** (regular/rare/epic) from ticket-opened chests. We are NOT copying the chest/ticket layer (gacha-ish); noting it for completeness.

## Our remake: the Kart Builder (headline feature)

The original only let you buy preset karts and upgrade their numbers (plus minor appearance changes via upgrades). Our remake upgrades this into a **modular kart construction garage** — this is the "design your own angry bird car" dream and a perfect fit for Roblox's customization culture:

### Builder slots
| Slot | Examples | Affects |
|---|---|---|
| **Chassis/Body** | Crate, bathtub, log, rocket, sofa, egg-carton | Base stats + silhouette |
| **Wheels (set)** | Wooden discs, balloons, stone rollers, monster truck | Handling/strength flavor + small stat mods |
| **Front attachment** | Ram plank, plow, bird-beak bumper | Strength mod |
| **Rear attachment** | Spoiler, balloon bundle, rocket fins | Speed/air-control mod |
| **Topper/decoration** | Flags, horns, antenna, snorkel | Cosmetic |
| **Paint + decals + pattern** | Color picker, team decals, bird motifs | Cosmetic |

### Builder rules
- **Stats come from parts** (chassis dominant, wheels/attachments minor) → your build IS your stat spread; upgrades then level up the installed parts. CC = sum of part levels, same gating role as the original.
- **Hard stat budget per tier** so cosmetic freedom never becomes pay-to-win; in ranked multiplayer, karts are bracketed by CC.
- Parts are earned: race rewards, episode completion, Champion Chase victories, tournament prizes, daily streaks. Premium currency buys **cosmetic** parts/paints only.
- Save **multiple loadouts** ("garage slots"); show off your kart in the multiplayer lobby and on leaderboards (thumbnail render).
- Stretch goal: a "test ramp" in the garage to instantly feel a build (mini downhill strip behind the garage).

### Why this matters strategically
Roblox players expect avatar-grade self-expression. A kart builder converts AB Go!'s *purchase* loop into a *creative* loop — better retention, cleaner monetization (cosmetics), and our biggest differentiator from both the dead original and other Roblox racers.

## Garage screen spec

- 3D kart on a turntable; character standing beside it (current selection).
- Tabs: **Build** (slots), **Upgrade** (4 stats + CC readout), **Paint**, **Loadouts**, **Shop**.
- Upgrade UX: cost in coins, preview of stat bar delta and new CC, big satisfying "WRENCH IT" button + confetti/clank on purchase.
- Show next CC gate: "Next challenge requires 240 CC — you have 215" with a direct "what to upgrade" hint. (The original made you discover gates by failing; we surface them.)
