# Downhill Flock Racers (working title)

A Roblox recreation of the spirit of **Angry Birds Go!** — the discontinued 2013 downhill kart racer. Full design docs in [docs/](docs/README.md). Built with [Rojo](https://rojo.space) (binary vendored in `bin/`, not committed).

> ⚠️ Working title only. Ships with 100% original branding — see [docs/07 §4 (IP)](docs/07-roblox-implementation-plan.md).

## Current status: Phase 1 — driving-feel prototype

Greybox hill + one kart. Goal: make driving FUN before building anything else.

**Controls (PC):** hold **Space** to charge the slingshot, release in the green zone · **A/D** steer · hold **LeftShift** to drift (release after 0.8s+ for a boost) · **R** respawn.

## Running it (feel-test loop)

1. **One-time:** open Roblox Studio → any new Baseplate → delete the baseplate part. Install the Rojo Studio plugin: run `bin\rojo.exe plugin install` (or get "Rojo" from the Creator Marketplace plugins).
2. Start the sync server from this folder: `bin\rojo.exe serve`
3. In Studio: Plugins tab → Rojo → **Connect** (localhost:34872).
4. Press **Play** (F5). The track builds itself at runtime; your kart spawns on the start pad.
5. Tell Claude what feels wrong → numbers live in [src/shared/Tuning.lua](src/shared/Tuning.lua) → Rojo syncs edits live → just press Play again.

## Layout

```
default.project.json   Rojo mapping (src/* → Roblox services)
src/shared/Tuning.lua  every feel number (THE file for feel-testing)
src/server/            TrackBuilder (procedural greybox hill), KartService (spawn/seat/ownership/respawn)
src/client/            KartController (driving model), CameraRig (chase cam)
docs/                  complete design documentation (01–10)
```

## Phase roadmap

See [docs/07-roblox-implementation-plan.md](docs/07-roblox-implementation-plan.md). Phase 1 (now) → real race vs bots → powers & characters → modes & track kit → garage & economy → multiplayer & hub → ship.
