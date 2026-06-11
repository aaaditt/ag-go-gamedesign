# 04 — Tracks, Episodes & Game Modes

## Episode structure (the world map)

Piggy Island is the hub; episodes are themed mountain zones, each containing multiple **tracks**, each track hosting a ladder of **challenges** (the modes below) with rising CC requirements, capped by **Champion Chase** boss duels that unlock characters. Stars (1–3 per challenge, by placement/performance) gate later content alongside CC.

### The five episodes + tournament

| # | Episode | Theme & track character | Notable |
|---|---|---|---|
| 1 | **Seedway** | Lush farmland/jungle; wide roads, gentle turns, few hazards | Tutorial zone; first boss duels |
| 2 | **Rocky Road** | Canyon/desert; bumpy wavy roads, big ramps, bridges and caves | **Oink Canyon** — cliff area where you duel **Terence** |
| 3 | **Air** | High-altitude/airborne; huge jumps, glide sections, mid-air fruit | Air-time control matters; karts with fins/balloons shine |
| 4 | **Stunt** | Stunt-park; loops, half-pipes, chained ramps, trick lines | The "roller coaster" episode |
| 5 | **Sub Zero** | (Added Dec 2014) Ice/snow; slippery low-grip surface, ice-cream scenery | Fruit Splat becomes "**Ice Splat**" (frozen treats) |
| ∞ | **Weekly Tournament** | Rotating 5-event series vs friends'/global ghosts & scores | Exclusive kart prizes |

(There was also an unlockable **Jenga mode** — launch your kart from the slingshot into giant block towers to topple them; a destruction minigame tied to Telepods toys.)

### Track design language (what makes an ABGo! track)

- **Always downhill** — start high, finish low. Slope varies: steep chutes (max speed), flats (momentum management), counter-slopes before ramps.
- **Width rhythm**: wide forgiving sections → pinch points (rock gates, bridges) → wide again. Pinches are where AI contact happens.
- **Multiple lines**: outer safe line vs. inner risky line; **shortcuts** behind breakable fences/crates or off side-ramps, usually trading risk (TNT, narrow planks) for seconds.
- **Destructible dressing everywhere**: crates, fruit stands, fences, snowmen — smashing is point/coin positive, not punished.
- **Hazards**: TNT crates (big knock + damage), static rocks/trees, swinging/rolling obstacles, off-track drops (auto-respawn on track with speed penalty).
- **Collectibles on the racing line**: coin trails teach the ideal line; fruit clusters mark Fruit Splat routes; gems hide on shortcut lines.
- **Ramps & air**: ramps give air time (and in Air/Stunt, glide control); landing aligned = keep speed, landing sideways = scrub speed.
- Track length tuned for **60–90 second** races.

## Game modes (the challenge types)

### 1. Race
Classic 8-racer (v1: you + 7 AI) downhill race. Placement = reward tier (coins + stars: 1st = 3★). AI uses powers and bumps you.

### 2. Time Boom
Solo time trial: **reach the finish before the bomb timer detonates**. Checkpoints add time ⚠ (verify). Pure line-mastery test; the mode where boost powers shine.

### 3. Fruit Splat
Smash enough fruit (fill the fruit gauge) before crossing the finish. Forces you OFF the optimal racing line to chase fruit clusters — inverted incentives vs. Race. On Sub Zero it's themed "Ice Splat."

### 4. Slalom (later addition)
Pass through gate pairs; **missing a gate spawns 5 TNT crates ahead and cuts remaining time**. Time Boom × precision steering hybrid.

### 5. Versus
1v1 race against a single AI rival. Tighter, duel-like; the warm-up format for…

### 6. Champion Chase
The boss duel (see doc 02): 1v1 vs. an episode boss with an enhanced power; **beat them 3 times to recruit them**.

### 7. Weekly Tournament
5 events across the week vs. friends' scores (Facebook-linked in the original); leaderboard placement pays exclusive karts/gems.

### 8. Multiplayer
- **Online** (v1.4.0+): real-time races vs. other players (up to 4 in Turbo Edition; party sizes varied by version).
- **Local** (2015+): same-wifi private races.
- Both died with the servers — our Roblox version makes this the centerpiece instead (doc 06).

## Our remake content plan (right-sized v1)

- **3 episodes at launch** (Seedway-like, Canyon-like, Ice-like) × **3 tracks each** × challenge ladder per track:
  `Race → Time Boom → Fruit Splat → Race (harder CC) → Versus → … → Champion Chase ×3`
  ≈ 8–10 challenges per track → **~80 challenges at launch**, reusing 9 track builds. (This mirrors the original's economy of content: few tracks, many challenge wrappers.)
- Every track also runs in **online multiplayer rotation** from day one.
- Tournament = weekly rotating challenge set on existing tracks with a seasonal leaderboard (Roblox `OrderedDataStore`).
- Post-launch: Air/Stunt-style episode (the aerial tricks tech), Jenga-style destruction minigame, mirrored/night track variants (cheap content multipliers).

## Track building spec (for our level designers)

- Build tracks as **spline-based road segments** (kit: straight, curve L/R ×3 radii, chute, ramp, gap, pinch, half-pipe) with theming skins per episode → one kit, three episodes.
- Each track ships with: racing-line coin trail, 2+ shortcuts, 6–10 destructible clusters, 3–5 hazards, fruit layout (for Fruit Splat), gate layout (for Slalom), respawn nodes every ~50 studs of progress, and a CC/difficulty tag.
- Validation checklist per track: finishable with 0 steering inputs? (must be NO), beatable at min CC? (Race: barely; that's the point), all shortcuts net-positive for a clean execution, 60–90 s at target CC.
