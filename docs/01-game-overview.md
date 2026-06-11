# 01 — Game Overview

## What Angry Birds Go! was

Angry Birds Go! (developed by Exient, published by Rovio, released **11 December 2013**) was a **free-to-play 3D downhill kart racing game** set on Piggy Island. The birds and pigs put their war on hold to race soapbox karts down mountain tracks made of dirt, planks, candy, and ice.

Its identity in one paragraph: **Mario Kart's soul filtered through Angry Birds' physics-toy DNA.** Races start by launching your kart from a giant slingshot. Every track runs downhill, so there's no gas pedal — gravity is the engine, and the player only steers, drifts, uses one character power per race, and smashes through destructible scenery. Wrapped around the racing was a deep collect-and-upgrade metagame: dozens of karts, upgrade parts, a CC power rating gating harder challenges, characters unlocked by beating them in boss duels, weekly tournaments, and (infamously) aggressive free-to-play monetization.

### Key facts
- 100M downloads by Nov 2014; **130M by April 2015** (Rovio claimed it had outsold the entire Mario Kart series' unit sales at that point).
- Reception: Metacritic ~60/100 — controls/graphics/charm praised, **microtransactions universally panned** ("repetitive, costly, exploitative").
- Online multiplayer added v1.4.0 (July 2014); local multiplayer April 2015; Hasbro **Telepods** toys-to-life integration (scan a physical toy kart into the game).
- A heavily reworked **v2.0** (2016) changed progression to blueprints/chests/tickets; an MTX-free **Turbo Edition** ran on the Hatch cloud service in 2019.
- **Stopped receiving updates 2018, delisted from App Store/Google Play in 2019.** Rovio's stated reason (2021 fan letter): the game was built on old technology they couldn't maintain to modern live-ops standards. Servers are off; the game is functionally extinct. This is the gap our remake fills.

## The core loop

```
GARAGE / MAP (Piggy Island hub)
   → pick episode → pick track → pick challenge (Race / Time Boom / Fruit Splat / Versus / Champion Chase)
   → CC check: is your kart powerful enough for this challenge? (no → upgrade or grind)
   → pick character (each has 1 special power per race)
        RACE:
        → slingshot launch (timing/pull = starting boost)
        → steer + drift downhill, auto-accelerating
        → collect coins & fruit on track, smash crates/scenery, hit ramps & shortcuts
        → fire your special power (once, at the right moment)
        → avoid TNT, rocks, opponents' powers; kart takes visible damage from impacts
   → finish → placement rewards (coins, stars 1–3) 
   → spend coins/gems: upgrade kart stats (raises CC) or buy/unlock new karts
   → beat episode boss 3× in Champion Chase duels → that character joins your roster
   → next track / next episode (each episode = new theme + new boss + higher CC requirements)
```

Two interlocking loops:
1. **Moment-to-moment racing** (60–90 second races, downhill flow, near-miss dodges, power timing).
2. **The garage metagame** (earn → upgrade → raise CC → unlock harder challenges and new episodes → earn more). CC requirements are the pacing valve for the whole game.

## What made it feel special (preserve these)

1. **The slingshot start** — the franchise signature welded onto racing. Pull back, feel the tension, release for a flying start. (A timing/power mechanic replacing Mario Kart's boost-start.)
2. **Downhill-only racing** — no throttle means total focus on line choice, drifting, and air time. Tracks feel like waterslides/roller coasters, not circuits. Constantly accelerating = constant thrill.
3. **Toybox physics** — karts are rickety soapbox contraptions; they bounce, rattle, lose doors and bumpers when smashed, and scenery (crates, fruit, fences) explodes satisfyingly on contact.
4. **Character powers as one-shot trump cards** — one use per race, so timing is a decision, not spam.
5. **Boss-duel unlocks** — you don't buy Terence, you *beat* Terence three times and he joins you. Recruitment-as-gameplay.
6. **Kart collecting/upgrading** — the "my ride" pride loop. Our remake doubles down with a true kart *builder* (see doc 03).

## What was wrong with it (fix these)

| Original sin | Our fix |
|---|---|
| **Energy system**: each character could only race ~5 times, then was "tired" — wait or pay gems | Removed entirely. Race forever |
| Coin grind walls tuned to push $$ crystal purchases (some karts cost ~$50 real money) | Honest earn rates; cosmetics-led monetization (doc 06) |
| Late-game CC gates required repetitive replay of old tracks | Gentler CC curve + multiple earning paths (tournaments, dailies, multiplayer) |
| Online multiplayer bolted on late, then died with the servers | Multiplayer is native to Roblox — design for it from day one |

## Session anatomy (what a 10-minute play session looked like)

Open game → land in hub/garage → claim daily reward → run 2–3 challenges on the current track (one Race for placement, one Time Boom for stars, retry a failed Fruit Splat) → earn ~800–1,500 coins → dump coins into an upgrade (Speed +1 → CC rises) → see the next challenge unlock → "one more race" → out.

Races themselves: **60–90 seconds**, 8 racers in classic Race mode, instant restart on failure-modes.

## Glossary

| Term | Meaning |
|---|---|
| CC | Kart power rating ("cake capacity" joke on engine cc) — sum of upgrade levels; gates challenges |
| Champion Chase | 1v1 boss duel; win 3 to recruit the boss character |
| Time Boom | Solo time trial — reach the finish before the bomb timer ends |
| Fruit Splat | Smash enough fruit on the track before finishing |
| Slalom | Gate-to-gate variant (miss a gate = TNT + time penalty) |
| Telepods | Hasbro physical toys scanned into the game (we replace with code/badge redeems) |
| Episode | Themed world: Seedway, Rocky Road, Air, Stunt, Sub Zero + Weekly Tournament |
| Gems/Crystals | Premium currency (real money) in the original |
