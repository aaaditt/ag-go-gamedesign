# 07 — Roblox Implementation Plan

How we actually build and ship this in Roblox Studio.

## 0. Key technology decisions

### Decision 1: Arcade kart controller, not physical vehicles
Roblox has `VehicleSeat`/wheel constraints, but realistic vehicle physics is wrong for this game. We build an **arcade controller**: one dynamic chassis part moved by `LinearVelocity`/`VectorForce` + `AlignOrientation`, implementing doc 05's speed model directly in Luau. Wheels and the kart model are welded visuals. Full authority over feel; trivially stable on loops/ramps.

### Decision 2: Client-authoritative driving, server-validated results
Each racer's kart has **network ownership on their client** → zero-latency steering. Opponents replicate (with light interpolation/extrapolation). The **server owns**: race state machine (countdown/positions/finish), reward grants, and anti-cheat sanity checks (progress-node sequence, per-track minimum-time floors, teleport detection). Power effects on other karts are server-arbitrated, client-predicted.

### Decision 3: One persistent hub place; tracks via streaming or reserved places
Start simple: hub + all 9 tracks in **one place** spaced far apart with StreamingEnabled; race instances claim a track copy. If perf/instance-collision bites, graduate to TeleportService reserved servers per race (standard Roblox racing architecture). Decide at Phase 4 with data.

### Decision 4: Splines are the spine
Every track is authored around a **center spline** (CatmullRom via control parts). The spline drives: progress %, race positions, respawn nodes, rubber-banding, AI racing lines (offset splines), minimum-time anti-cheat, and the coin-trail layout tool. Build `SplineUtil` first; everything depends on it.

## 1. Project structure

```
ReplicatedStorage/
  Config/          -- KartParts.lua, Characters.lua, Tracks.lua, Economy.lua, Tuning.lua
  Modules/         -- SplineUtil, SpeedModel, DriftModel, PowerDefs, CCMath (shared)
  Remotes/         -- RaceFlow, PowerFired, FinishReport, GarageOps, ShopOps
  Assets/
    Karts/Parts/   -- chassis/wheels/attachments prefabs (tagged, with stat attributes)
    Characters/    -- racer models, power VFX, voice barks
    TrackKit/      -- road segments, theming sets (3 episodes), destructibles, hazards
ServerScriptService/
  RaceService      -- lobby/matchmaking, countdown, positions, finish, rewards
  AIService        -- bot spawning, line-following, power usage
  DataService      -- ProfileStore-style session cache + DataStore saves
  EconomyService   -- coins, parts, validation; ShopService (Robux products)
  TournamentService-- weekly rotation, OrderedDataStore boards
StarterPlayerScripts/
  KartController   -- input, speed model, drift, slingshot launch (the game-feel script)
  CameraRig        -- chase cam: low, slightly wide FOV, speed-reactive
  PowerController  -- power button, cast, predicted effects
  HUD/             -- position, timer, fruit gauge, power button, damage pips
  GarageUI/        -- builder, upgrades, paint, loadouts, shop
  HubController    -- plaza interactions, race-gate queueing
```

CollectionService tags: `TrackSpline`, `RespawnNode`, `FinishLine`, `Destructible` (+`SmashScore`), `TNT`, `Coin`, `Fruit`, `Gate`, `ShortcutTrigger`, `BoostPad`.

## 2. Build phases (each ends playable)

### Phase 1 — The Feel Prototype ⚠ do nothing else first
One greybox downhill track (spline + ramps + 2 corners), one kart, full driving model: slingshot launch, downhill speed, steering, drift+boost, respawn, chase camera. Iterate until 10 consecutive runs are *fun*. This de-risks the entire project.

### Phase 2 — A real race
7 AI bots on offset racing lines with rubber-banding, countdown → finish flow, positions HUD, placement rewards. Collisions/shoving, destructibles, coins/TNT.

### Phase 3 — Powers & characters
Power framework + the 10 launch powers (doc 02), character models/animations/barks, AI power usage. Versus + Champion Chase modes (boss with enhanced power, 3-win recruitment).

### Phase 4 — Modes & track kit
Time Boom, Fruit Splat, Slalom. Track-building kit + authoring tooling (spline editor QoL, coin-trail painter, validation per doc 04). Build Episode 1's three real tracks themed.

### Phase 5 — Garage & economy
Kart builder (slots/parts/paint), stat/CC math, upgrades, coins economy, DataStore persistence, challenge ladder + star/CC gating, episode map UI. Episode 2–3 tracks in parallel (content team).

### Phase 6 — Multiplayer & hub
Social hub plaza, quick-race matchmaking (CC brackets), private lobbies, ghosts, leaderboards, weekly tournament service.

### Phase 7 — Ship
Audio pass (original soundalike music/SFX — see IP note), mobile tilt/touch + gamepad input QA (Roblox is majority mobile), performance pass (streaming, debris pooling, 60fps mid-phone), badges, monetization products, icon/thumbnails, publish.

### Post-launch
Air/Stunt-style episode (glide/trick tech), Jenga-style destruction minigame, mirrored/night variants, seasonal tournaments, UGC part drops, possibly a community track-builder.

## 3. Publishing checklist (Roblox)

1. File → **Publish to Roblox**; name, description, genre=Racing, devices: PC + Mobile + Tablet (console after gamepad QA).
2. Game Settings → Permissions → **Public** (new experiences default private).
3. Complete the **experience questionnaire** → cartoon vehicular mayhem, no blood ⇒ low maturity rating. Check Creator Dashboard for current publishing/evaluation requirements at ship time (Roblox tightened these recently).
4. Creator Dashboard: 512×512 icon, 3+ thumbnails (kart builder shot, race shot, boss duel shot), keyworded description ("kart racing", "downhill", "build your car", "racing").
5. Monetization: Robux products per doc 06 (cosmetic-only), game passes; enable analytics and track the funnel (tutorial completion → first upgrade → first Champion Chase → D1 retention).

## 4. ⚠️ Intellectual property (read before publishing)

"Angry Birds," the characters, art, and audio are **Rovio (now Sega) IP**, and the dead game's assets are still protected. Roblox enforces takedowns. Plan, same as any homage:

- **Original title** (e.g., "Sling & Go!", "Downhill Flock Racers", "Fling Kart"), original character designs/names (bird-like and pig-like is a *genre*, their specific designs are not), original music/SFX.
- Never use "Angry Birds" in title/description/assets. Don't import ripped models/sounds from the APK (they exist online; using them = takedown + account risk).
- **Mechanics are not protectable** — slingshot starts, downhill karts, CC gating, boss recruitment are all safe to recreate. The *expression* must be ours.
- These docs use AB Go! names as reference spec only; branding decided in Phase 5.

## 5. Risk register

| Risk | Mitigation |
|---|---|
| Driving feel is mushy (kills everything) | Phase 1 gate: don't proceed until fun; arcade controller = full tuning control |
| Replicated opponents jitter/rubber-band visually | Interpolation buffer + spline-progress reconciliation; standard Roblox racer problem with known fixes |
| Cheaters (client-authoritative karts) | Server progress-node + min-time validation; leaderboards filtered by validation flag |
| Scope: 10 powers + 9 tracks + builder is big | Phases ship standalone; cut to 6 powers/6 tracks for v1 if needed — builder and feel are non-negotiable, content count is |
| Mobile perf on big tracks | StreamingEnabled, mesh instancing, destructible pooling, LOD theming |
| IP takedown | Section 4: original branding from day one |
| Matchmaking dead-server cold start | Bots fill grids; solo campaign is fully offline-viable |

## 6. Definition of done (v1 ship criteria)

- [ ] Driving feel signed off (Phase 1 bar: external playtester asks to keep playing)
- [ ] 3 episodes / 9 tracks / ~80 challenges, all star/CC-calibrated and completable
- [ ] 10 racers with powers, recruited via Champion Chase
- [ ] Kart builder: 6 slots, ≥30 parts, paint/decals, multiple loadouts, CC math correct
- [ ] Online quick-race + private lobbies + ghosts + weekly tournament live
- [ ] Touch, tilt-optional, mouse/keyboard, gamepad all verified
- [ ] Persistence with retry/backoff; no data loss on server shutdown (BindToClose flush)
- [ ] 60 fps on mid-tier phone mid-race; < 5 s track load
- [ ] Original branding, rating questionnaire passed, experience Public
