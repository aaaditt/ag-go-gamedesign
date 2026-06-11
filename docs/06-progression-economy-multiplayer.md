# 06 — Progression, Economy & Multiplayer

## How the original's progression worked (v1)

```
Stars + CC are the two gates:
  Challenge N cleared (1–3★ by placement/perf)
    → next challenge unlocks IF you also meet its minimum CC
    → CC comes from kart upgrades
    → upgrades cost coins
    → coins come from racing (placement rewards + track pickups)
  Episode boss (Champion Chase ×3) → new character → next episode area
```

- **Stars**: 1–3 per challenge (Race: 3★ = 1st place; objective modes: meet thresholds). Total stars gate some content; in v2.0 stars also unlocked basic karts.
- **CC gates**: each challenge lists a minimum kart CC. This is the soft paywall lever — late-game CC walls forced replaying old content for coins… or buying crystals.
- **Two currencies**: **Coins** (earned; upgrades + standard karts) and **Crystals/Gems** (real money; premium karts, energy refills, skipping grind).
- **Energy/fatigue system**: each *character* could race ~5 times, then needed rest (timer) or gems. With one starter character that meant ~5 races per session free — the most-hated system in the game.
- **Daily rewards**, achievement-ish goals, and the **Weekly Tournament** (5 events vs. Facebook friends, exclusive kart prizes) provided the live cadence.
- **Telepods**: physical Hasbro toys scanned via camera to unlock their in-game karts.
- v2.0 era switched to blueprints/parts/tickets/chests (see doc 03) — more systems, same grind intent.

## Our remake's economy (fixed, Roblox-native)

Principles: **never sell power, never sell time-locks**. Sell identity.

| System | Our version |
|---|---|
| Energy/fatigue | **Deleted.** Unlimited racing |
| Coins | Earned per race (placement + pickups + smash bonuses + dailies). Buys part upgrades and standard parts |
| Gems → **Robux products** | Cosmetic-only: paints, decals, toppers, character outfits, victory effects, garage themes |
| CC gates | Kept (they pace solo progression) but tuned generously; surfaced in UI ("need 240 CC — upgrade Speed?") |
| Stars | Kept: 3★ per challenge; star totals unlock bonus tracks/parts |
| Characters | 100% gameplay-earned via Champion Chase. Never sold |
| Tournaments | Weekly rotating event set; seasonal leaderboard (OrderedDataStore); prize = exclusive cosmetic part |
| Telepods homage | Promo **redeem codes** / Roblox badges granting special parts (no toys needed) |
| Dailies | Login streak + 3 daily quests ("smash 50 crates", "win a Fruit Splat") |
| Game passes (optional) | "Garage Plus" (extra loadout slots), VIP cosmetic pack — convenience/cosmetic only |

## Tuning rules (added by logic runthrough — doc 10)

### Star criteria per mode
| Mode | 1★ | 2★ | 3★ |
|---|---|---|---|
| Race / Versus | 3rd | 2nd | 1st |
| Time Boom / Slalom | finish in time | beat par by 15% | beat par by 30% |
| Fruit Splat | clear gauge | clear + finish top half | clear + finish 1st |
| Champion Chase | win 1 | win 2 | win 3 |

### Coin payouts (initial economy tuning)
| Source | Coins |
|---|---|
| Solo Race base (finish) | 100 + placement bonus: 1st +200 / 2nd +120 / 3rd +60 |
| Objective modes (Time Boom/Fruit Splat/Slalom) | 100 + 50 per star earned this run |
| On-track pickups | ~80–150 per clean run (coin trails) |
| Smash bonus | 2 per destructible, capped 60/race |
| First-clear bonus | +300 the first time a challenge is beaten |
| Champion Chase win | 250 / 350 / 500 (wins 1/2/3) |
| MP quick race | 1.5× solo Race base + placement (no stars — stars are solo-only) |
| Private lobby | 50% coins, no stars, no quest credit |
| **Anti-farm decay** | Full reward first 3 completions of a challenge per day, then 50% |

### CC curve
Stock kart = 100 CC. Challenge gates: Episode 1 spans 100→250, Episode 2 260→400, Episode 3 410→550. Max v1 CC ≈ 600 (all parts maxed).

### Tournament points
Per event: race-type placement table 100/70/50/35/25/15/10/5; solo-type by time percentile vs. field (top 10% = 100 … bottom = 10). Weekly sum ranks the board; prizes at reset.

### Multiplayer conduct rules
AFK (no node progress 30 s) → DNF, bot takes over the grid slot. Disconnect → DNF; rejoin = spectate remainder. Ties resolved by server ms timestamp.

## Multiplayer (our centerpiece — the original's was bolted-on and is now dead)

Roblox is inherently multiplayer; we invert the original's structure:

- **The hub is social**: players walk around a Piggy-Island-style plaza/garage with their avatars, see each other's karts on display, queue at race gates.
- **Quick Race (online)**: 6–8 player matchmade races on the track rotation, CC-bracketed (Rookie ≤200 / Pro ≤400 / Unlimited). Bots fill empty slots.
- **Private lobbies**: friends-only races, any track, custom rules (mode, laps ⚠ n/a — point-to-point, items on/off).
- **Solo campaign** (episodes/challenges/Champion Chase) runs inside the same server instance — solo challenges spawn a private track copy (or use a reserved place via TeleportService if perf demands).
- **Ghosts**: store best-run telemetry per track → race your own/friends' ghosts in Time Boom (cheap "async multiplayer," replaces the Facebook-friends tournament feel).
- **Leaderboards**: per-track best times + weekly tournament standings + global stars.

## Persistence (DataStore schema)

```lua
{
  coins = 12450,
  racers = { "red_alike", "stella_alike" },          -- recruited characters
  parts  = { ["chassis_crate"] = {owned=true, level=3}, ... },
  loadouts = { [1] = { chassis="crate", wheels="wood", front="ram", paint="#E33" } },
  progress = { [challengeId] = { stars=3, bestTime=62.41 } },
  episodeUnlocked = 2,
  tournament = { seasonId = 14, points = 880 },
  dailies = { streak = 6, lastClaim = 20260611 },
  settings = { music=0.8, sfx=1, tilt=false, sensitivity=0.5, shake=true, reducedFlash=false },
  stats = { races=312, wins=88, crates=4102, distance=812345 }  -- badges feed
}
```

Badges: first win, each character recruited, episode 100%'d, 1000 crates smashed, tournament top-100.

## Session/retention design summary

- First session: tutorial race (auto-win-ish) → slingshot lesson → first upgrade → first Champion Chase tease. Target < 8 minutes to "I made my kart faster and beat a boss."
- Core cadence: dailies (3–5 min) + tournament (weekly) + new-episode drops (monthly live-ops).
- Roblox discovery depends on session time + retention metrics — the hub's social hangout value (showing off builds) is as load-bearing as the racing.
