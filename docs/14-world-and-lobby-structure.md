# 14 — World & Lobby Structure (the game's "site map")

How the whole experience is laid out — in the world, in the file tree, and in the player's journey. Written to match the hub-first flow: **you spawn in a lobby on foot; everything else is a place you walk to.**

## 1. The world layout (3D "site map")

```
                         ┌─────────────────────────────┐
                         │      LOBBY PLAZA (spawn)     │   ← you design this in Studio
                         │                              │
   [GARAGE PORTAL] ◄─────┤  center: spawn + your kart   ├─────► [SOLO PLAY PORTAL]
   (right side)          │          on display          │       (left side)
   opens garage UI       │                              │       seats you in your kart
                         │  [MAP BOARD]  [MULTIPLAYER   │       at the loaded track
                         │  (episode/      PORTAL]      │
                         │  track select)  (M7: real    │
                         └───────────────  lobbies)─────┘
                                      ▲
                                      │ "BACK TO LOBBY" button (always available in play mode)
                                      ▼
                         TRACK WORLD (one loaded at a time)
                         StartPad+slingshot → downhill ribbon → FinishPad
                         (9 preset tracks; your hand-edited versions preserved)
```

- **Lobby** sits at a fixed location far from the tracks. It is the ONLY spawn.
- **Portals are named anchor parts** — scripts find them by name (`PlayPortal`, `GaragePortal`, `MultiplayerPortal`, `MapBoard`). You can move them, re-skin them, build a whole castle around them — as long as the names survive, everything keeps working. Same rule as the track pieces.
- **Track world**: one track loaded at a time (selected at the Map Board). Entering the Play portal spawns your kart on its StartPad.

## 2. Player journey (gameplay structure)

```
Spawn in LOBBY (on foot, avatar)
 ├─► walk LEFT  → SOLO PLAY portal → kart spawns at track → slingshot → race ladder
 │       challenges per track: Race → Time Boom → Fruit Splat → Slalom → Versus → CHAMPION CHASE (boss ×3 = recruit)
 │       stars + coins → garage upgrades → CC unlocks next rungs → recruit all 3 bosses = next EPISODE
 ├─► walk RIGHT → GARAGE portal → build/buy/upgrade kart (CC, stats)
 ├─► MAP BOARD  → pick episode/track (locked until previous episode's bosses recruited)
 ├─► MULTIPLAYER portal → (M7) matchmade races on set maps with other players; bots fill seats
 └─► results screen → Retry / Back to Lobby
```

This is the full progression model (docs/05, 06, 13): **race → earn → upgrade → unlock → recruit → new episode**, all entered from the lobby.

## 3. File structure (what's code vs what's yours to edit)

```
place.rbxl  (committed)            ← YOUR canvas: lobby + hand-edited tracks live here
└── Workspace
    ├── Lobby/                     ← generated ONCE as a greybox; then 100% yours to redesign
    │   ├── SpawnPlatform          (keep name — only SpawnLocation in the game)
    │   ├── PlayPortal             (keep name — touch = enter solo play)
    │   ├── GaragePortal           (keep name — touch = open garage)
    │   ├── MultiplayerPortal      (keep name — M7 wires it; shows "SOON" now)
    │   ├── MapBoard               (keep name — touch = open episode map)
    │   └── …anything else you build: walls, décor, NPCs, trees — free space
    └── Track/                     ← managed by TrackService (preset or your custom version)

src/ (Rojo-synced code — my domain)
    shared/   Tuning, Characters, Tracks, Challenges, KartParts, SplineUtil, ClientBus
    server/   TrackService+TrackGen, LobbyService+LobbyGen, KartService, AIService,
              ChallengeService, PowerService, DataService
    client/   KartController, CameraRig, RaceFlow, ModeRunner, PowerController,
              ChallengeSelect, EpisodeMap, GarageUI, LobbyController
docs/         design docs 01–14
```

**The editing contract (same as tracks):** generators only build things that don't exist. Once `Lobby` is in your saved place, the code never touches its looks — it only searches for the named anchor parts. Delete the folder to get a fresh greybox.

## 4. What changed vs the old flow

| Before | Now |
|---|---|
| Spawn directly seated on kart at the track | Spawn on foot in the Lobby |
| Kart exists always | Kart spawns when you enter the Play portal; despawns on Back to Lobby |
| Track UI panels floating everywhere | Map/garage reachable from lobby portals (toggle buttons still exist in play mode) |
| No finisher in your last build | Finish line + results + rewards landed in M1–M5 — test it this session |

## 5. Still pending (per docs/13)

- **M7:** real multiplayer through the Multiplayer portal (matchmade races, set maps), test ramp by the garage, ghosts, weekly tournament, daily quests, hub social polish.
- **M8:** character/kart visuals, audio, VFX, mobile controls, FTUE tutorial, publish.
