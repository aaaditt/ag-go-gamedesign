# 02 — Characters & Special Powers

In Angry Birds Go! every racer has **one special power, usable once per race** (a big glowing button appears when charged/available; some descriptions say "limited number of times" — v1 behavior was effectively one use, with extra uses purchasable in some modes). Racers have **no stat differences** — stats live entirely on the kart — so character choice = power choice + personality. In Champion Chase duels, bosses use an upgraded version of their own power against you.

## Roster & powers

Characters unlock by **defeating them 3× in Champion Chase** duels at the end of episode areas (Red is the starter). Confirmed power details from period guides; entries marked ⚠ are lower-confidence (sources are thin since the game is dead — verify against gameplay videos during development).

| Character | Power (in-race effect) | Notes |
|---|---|---|
| **Red** (starter) | **Speed boost** — straightforward burst of acceleration | The tutorial-friendly baseline power |
| **Chuck** | **Mega boost** — much bigger, longer speed burst than Red's | The pure-speed pick; bosses' version is brutal in duels |
| **The Blues** (Jay/Jake/Jim) | **Freeze** ⚠ — temporarily freezes/slows nearby opponents | One character, three birds stacked in the kart |
| **Bomb** | **Explosion** — detonates, blasting nearby karts away/spinning them out | Area denial at corners/cluster starts |
| **Matilda** | **Egg bomb lob** — throws her egg *ahead* to damage karts in front | The catch-up/attack-the-leader power |
| **Hal** | **Whirlwind** — boomerang-style spinning attack hitting racers around him | Mid-pack brawler power |
| **Terence** | **Lightning strike** — zaps nearby competitors | Endgame-tier menace; his Champion Chase is a wall |
| **Stella** | **Bubble shield** — pink bubble that blocks all damage AND vacuums up coins/fruit in radius | Defense + economy power; fan favorite |
| **Bubbles** | **Inflation** ⚠ — balloons up, shoving aside nearby racers | |
| **King Pig** | **Pig magnetism/minion chaos** ⚠ — summons minion pigs / shoves racers | Pig-side headliner |
| **Foreman/Moustache Pig** | **Dynamite bundles** — carries 3 bundles, throws them forward separately or in a burst | The only confirmed multi-charge power |
| **Corporal Pig** ⚠ | Helmet charge/ram | |
| **Ayrton Senna** (July 2015 promo) | Speed boost; came with the McLaren MP4/4 kart | Real F1 legend licensed in — for our remake, replace with an original "legend racer" |

## How powers behave (implementation contract)

1. **One charge per race** (Foreman Pig: three smaller charges). The power button lights up after launch; player taps it whenever they choose; it greys out after use.
2. Powers are **instant-cast** at the user's position — no aiming, except Matilda's forward lob (auto-targets ahead).
3. **Offensive powers** (Bomb, Terence, Hal, Matilda, Foreman) apply to opponents in radius/path: spin-out + speed loss + kart damage. They never destroy a racer outright.
4. **Defensive/utility powers** (Stella's bubble, boosts, Bubbles) modify self: invulnerability window, speed multiplier, collection magnet, knockback aura.
5. AI opponents use their powers too — typically once, at semi-scripted "dramatic" moments (when overtaking or being overtaken).
6. In **Champion Chase**, the boss has an enhanced power version (e.g., Chuck's boost lasts ~2×) — the duel is partly "survive their power, time yours better."

## Champion Chase (boss/recruitment system)

- Each episode area ends with a named boss racer guarding progression. **Our remake structure: 1 boss per track → 3 bosses per episode → 9 recruits + the starter = the 10-racer roster. Episode N+1 unlocks when all of Episode N's bosses are recruited.**
- The duel is a **1v1 race**; beat them **3 times** (3 separate challenge entries, increasing difficulty/CC requirement) and they **join your roster permanently**. **Losing costs nothing — instant retry, and the win counter never resets.**
- Boss races are where the power system shines: it's you + your power vs. them + their enhanced power on a track they're "at home" on.
- Recruitment order in v1 roughly: Red → (Seedway) Stella, Moustache Pig → (Rocky Road) Terence at Oink Canyon, Bomb → (Air) Matilda, Hal → (Stunt) Bubbles, Corporal Pig → (Sub Zero) The Blues, King Pig ⚠ — exact per-episode boss mapping needs verification from longplay videos; treat as a tunable for our remake.

## Our remake roster plan

- **Launch with 10 racers**: 8 bird-likes + 2 pig-likes (original designs — see IP note in doc 07), each mapping to one of the power archetypes above: Boost, Mega Boost, Freeze, Explosion, Forward Lob, Whirlwind, Lightning, Shield+Magnet, Knockback Balloon, Triple Throw.
- Starter: the Red-alike. All others recruited via Champion Chase (no paid character unlocks).
- Characters are cosmetic+power only; karts carry stats (doc 03) — this keeps multiplayer fair-ish and the unlock chase guilt-free.
- Each character needs: idle/drive/victory/defeat animations, power VFX+SFX, voice barks (launch yell, power yell, hit grunt, win/lose).

Sources: [Angry Birds Go! — Wikipedia](https://en.wikipedia.org/wiki/Angry_Birds_Go!), [AB Go! gameplay guide — AngryBirdsNest](https://www.angrybirdsnest.com/angry-birds-go-first-look-and-guide/), [Stella character guide — Pocket Gamer](https://www.pocketgamer.com/angry-birds-go/stella-pink-bird-angry-birds-go-character-guide/), [Gameplay (Version 1) — Angry Birds Wiki](https://angrybirds.fandom.com/wiki/Angry_Birds_Go!/Gameplay_(Version_1)).
