# Angry Birds GO! → Roblox: Complete Game Documentation

This folder is the single source of truth for recreating **Angry Birds Go!** (Rovio/Exient, December 2013) — the discontinued downhill kart-racing game — as a Roblox experience built in Roblox Studio and published to the Roblox platform.

> **Why this game?** Angry Birds Go! was delisted from app stores in 2019 (Rovio retired it because it ran on old tech they couldn't keep updating) and its multiplayer servers are dead. The game effectively no longer exists — 130M+ downloads' worth of nostalgia with zero legal way to play it. A faithful spiritual successor on Roblox fills a real gap.

## Document index

| File | Contents |
|------|----------|
| [01-game-overview.md](01-game-overview.md) | What the game was, its history and death, the core loop, session structure |
| [02-characters-and-powers.md](02-characters-and-powers.md) | Every racer, their special power, unlock method (Champion Chase bosses) |
| [03-karts-and-customization.md](03-karts-and-customization.md) | Kart roster, the 4 stats, CC rating, upgrades, and the **kart builder/editor** (our headline feature) |
| [04-tracks-and-game-modes.md](04-tracks-and-game-modes.md) | All episodes (Seedway → Sub Zero), track design language, every race mode |
| [05-physics-and-driving.md](05-physics-and-driving.md) | Slingshot start, downhill auto-acceleration, steering/drift, kart damage, hazards |
| [06-progression-economy-multiplayer.md](06-progression-economy-multiplayer.md) | Currencies, unlock flow, energy system (and what to fix), tournaments, multiplayer |
| [07-roblox-implementation-plan.md](07-roblox-implementation-plan.md) | Architecture, technology decisions, phased build plan, publishing checklist, IP risk |
| [08-screens-and-ui.md](08-screens-and-ui.md) | Every screen (S1–S23): navigation map, contents, edge states, input schemes |
| [09-master-feature-map.md](09-master-feature-map.md) | Exhaustive feature inventory (A–M) with spec cross-refs — if it's not here, it's not in the game |
| [10-logic-runthrough.md](10-logic-runthrough.md) | Start-to-finish player-journey verification; 12 gaps found and resolved |

## How to use these docs

1. Read **01** for the big picture.
2. **02–06** are the design spec — when implementing a feature, the behavior described there is the acceptance criterion. Each doc separates **"what the original did"** from **"what we'll do in the remake"** (we deliberately fix its worst part: the predatory monetization).
3. **07** is the build plan — work through its phases in order; each phase ends playable.

## Scope decision (one-line summary)

We recreate the **v1-era Angry Birds Go! experience**: slingshot-launched downhill kart racing through themed episodes, boss races that unlock characters with unique powers, kart collecting/upgrading with a CC power rating — **plus** a full custom kart *builder* (the "design your own bird car" fantasy), and real online multiplayer races, which Roblox gives us natively. We drop the energy/fatigue paywall system entirely.
