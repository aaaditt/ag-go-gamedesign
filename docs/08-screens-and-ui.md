# 08 — Screens & UI (Complete Map)

Every screen/UI surface in the game, what's on it, where it leads, and its edge states. The game is a Roblox experience: "screens" are a mix of 3D world spaces (hub, garage interior) and ScreenGui overlays. Navigation is diagrammed first, then each screen is specified.

## 0. Master navigation map

```
[Roblox Join] → S1 Loading → (first time? → S2 FTUE Tutorial) → S3 HUB (3D plaza)
                                                                  │
   ┌───────────────┬──────────────┬───────────────┬──────────────┼──────────────┬─────────────┐
   ▼               ▼              ▼               ▼              ▼              ▼             ▼
S4 Episode Map  S10 Garage     S15 Shop      S16 Tournament  S17 Daily      S18 Leaderboards  S19 Settings
   │            (Build/Upgrade/  (cosmetics,    (board)        Quests         (per track)      (anywhere via
   ▼             Paint/Loadouts)  Robux)            │             │                              top-right gear)
S5 Challenge List   │                               ▼             ▼
   │                └──────► S20 Test Ramp     S16b Event run  claim → S3
   ▼
S6 Pre-Race (character + loadout confirm)
   │
   ▼
S7 RACE (HUD variants: Race / TimeBoom / FruitSplat / Slalom / Versus / ChampionChase / Multiplayer)
   │                                   │
   ▼                                   ▼
S8 Results (rewards, stars)      S7p Pause (solo only)
   │         │
   │         └─ (Champion Chase 3rd win) → S9 Recruit Celebration → S3/S4
   ▼
 Next / Retry / Exit → S5 or S3

Hub side-doors: S21 Multiplayer Queue (race gates), S22 Private Lobby, S23 Codes Redeem (shop kiosk)
```

Rules that apply everywhere:
- **Back** always exists and never dead-ends; top-left back arrow on overlays, leave-zone for 3D spaces.
- **Settings gear** accessible from hub, garage, and pre-race (not mid-race; mid-race pause has a settings shortcut in solo).
- **Currency strip** (coins + premium) pinned top-right on all meta screens (S3–S6, S10–S18); tapping it deep-links to S15 Shop.
- All overlays must work at 16:9, 4:3 (tablets), and tall phone aspect; min touch target 44px.

---

## S1 — Loading screen
- Artwork: kart silhouette on a downhill + game logo; loading bar with % and rotating tips ("Release the sling exactly on GO!").
- Background work: DataService loads profile (retry ×3 → on total failure show "Couldn't load your save — Retry / Play as guest (progress not saved this session)" modal); StreamingEnabled preloads hub.
- Exit: profile loaded → fade to S3 (or S2 if `profile.ftueDone == false`).

## S2 — FTUE tutorial (first session only, ~5 min)
Scripted sequence, skippable after step 3 ("Skip tutorial?" confirm):
1. Spawn directly into a **scripted race** on Track 1-1 with the starter racer + stock kart (no menus first — game feel before UI). Pop-up coach marks: steer → drift → slingshot already pre-launched for them this once.
2. Race tuned so player finishes ≥2nd regardless (forgiving bots).
3. Results screen explained (stars, coins) → auto-navigate to Garage; guided **first upgrade** (gifted exactly enough coins) → CC number visibly rises → "Challenge 2 unlocked!".
4. Guided to slingshot lesson: second race where THE PLAYER does the launch (meter UI highlighted).
5. End: hub tour beacon trail (Episode Map → Garage → Shop glow once). `ftueDone = true`.
- Edge: player leaves mid-FTUE → resume at last completed step next join.

## S3 — Hub (3D plaza, the "main menu")
A small Piggy-Island-style plaza the avatar walks around. Interaction points (all also reachable via a bottom dock of buttons for speed):
| Hub object | Opens | Notes |
|---|---|---|
| **Race Gate (big slingshot arch)** | S21 Multiplayer Queue | Shows live "players in queue" counter |
| **Episode Map board (giant island map)** | S4 | Primary solo path; glows if new content/unlocks |
| **Garage building** | S10 (walk in = interior 3D space) | Your current kart parked out front, visible to others |
| **Tournament podium** | S16 | Shows countdown to weekly reset + your rank |
| **Daily kiosk (mailbox)** | S17 | Badge dot when unclaimed |
| **Shop stand** | S15 | Rotating featured cosmetic on display |
| **Leaderboard pillar** | S18 | |
| **Private Race flag** | S22 | |
- Other players visible with their karts (showcase = retention/social proof). Emotes wheel.
- HUD: currency strip, settings gear, quest tracker chip (next unclaimed quest), event banner (tournament/new episode).

## S4 — Episode Map
- Side-scrolling island map: Episode 1 → 2 → 3 zones; each shows star total ("34/72★"), completion %, lock state + unlock requirement text ("Finish Champion Chase: Canyon").
- Tap episode → zooms to its 3 tracks (thumbnail, name, your best stars per track) → tap track → S5.
- Locked content: visible but greyed, with explicit requirement (never mystery-locked).

## S5 — Challenge List (per track)
- Vertical ladder of 8–10 challenges (doc 04): each row = mode icon + name, star slots (0–3), reward preview, **CC requirement chip** (green if met, red "needs 240 CC — Upgrade" deep-link to S10 if not), lock state (previous challenge ≥1★).
- Champion Chase rows styled as boss cards (boss portrait, "Wins: 1/3").
- Buttons: back to S4; "Multiplayer on this track" shortcut → S21 (pre-filtered).

## S6 — Pre-Race
- Left: **character carousel** (recruited racers; locked ones shown silhouetted with "Defeat in Champion Chase — Episode 2"). Selected character's power icon + 1-line description.
- Right: **kart loadout** summary (current loadout, CC, 4 stat bars) + "Change" → S10 Loadouts tab (returns here).
- Mode briefing strip: objective text per mode ("Smash 25 fruit before the finish!").
- CTA: **RACE!** (disabled+reason if CC unmet). Back → S5.
- Multiplayer variant: same screen during matchmaking wait, with lobby player list + ready states + 30s auto-start timer.

## S7 — Race HUD (per-mode variants)
**Common (all modes):** speed lines/FOV feedback (not a speedo number), countdown 3-2-1-GO with slingshot meter active, power button (bottom-right, lights when armed, greys after use; Foreman variant shows ×3 pips), damage pips on kart icon (4 pips), position spline-tracked, restart/leave via pause (solo) or hold-to-leave button (MP), respawn fade flash, +coin/+score pickup ticks, finish banner.
| Mode | Adds |
|---|---|
| Race / Versus / Multiplayer | Position badge ("3/8"), final-stretch rival arrows |
| Time Boom | Big bomb timer center-top (fuse VFX, red pulse < 5 s), checkpoint +time popups |
| Fruit Splat | Fruit gauge bar top (fill target marker), fruit-cluster direction hints |
| Slalom | Next-gate arrows, gate pass ✓ / miss ✗ flash + "TNT ahead!" warning, timer |
| Champion Chase | Boss portrait + gap meter (ahead/behind), "Win 2/3" pips |
- **Touch layout:** steer = left/right screen halves; drift = swipe-hold into turn; power = button. **Tilt** optional (settings). Gamepad/keyboard mapped equivalents.

## S7p — Pause (SOLO modes only)
- Overlay: Resume / Restart / Quit to Challenge List / sound+tilt quick toggles. Game world freezes (solo race instance is private, so freezing is safe).
- **Multiplayer never pauses**: menu button instead opens a non-blocking panel (Leave Race? hold-confirm; leaving mid-MP-race = DNF, no reward, no penalty v1).

## S8 — Results
- Placement banner ("2nd!" / "BOOM!💥 Out of time" / "Gauge cleared!").
- Reward count-up: coins (base + placement + smash bonus + first-win bonus), stars earned (slam in 1-by-1), parts drops if any, quest progress ticks ("Win a Fruit Splat ✓").
- New record callout; CC-gate teaser if next challenge now affordable-to-reach ("Upgrade Speed to unlock Challenge 6").
- Buttons: **Next Challenge** (primary if unlocked) / Retry / Exit to S5. Multiplayer: Requeue / Hub.
- Edge: tie on finish → ranked by server timestamp (ms); DNF/disconnected players listed greyed at bottom.

## S9 — Recruit Celebration (Champion Chase 3rd win)
- Cinematic: boss kart pulls up, character hops out, joins your side, confetti; "TERENCE-ALIKE JOINED YOUR FLOCK!" + power card showcase.
- Unlocks: character added to S6 carousel; badge granted. CTA: "Try their power" (quick race with them pre-selected) / Continue.

## S10 — Garage (3D interior + tabbed UI)
Kart on turntable, character beside it. Tabs:
1. **Build** — 6 part slots (doc 03); part drawer per slot (owned / earnable "how to get" / premium); equipping previews stat + CC delta live.
2. **Upgrade** — 4 stat rows (level pips, cost, +delta preview), CC readout big, "next gate" hint ("240 CC needed for Canyon Challenge 4").
3. **Paint** — color picker per region, decals, patterns; premium paints marked.
4. **Loadouts** — slots 1–3 (more via game pass), rename, set-active, duplicate.
5. **Shop** shortcut → S15.
- **Test Ramp door (S20)**: instantly drive current build down a 15-second hill behind the garage; returns to garage.

## S15 — Shop
- Tabs: Featured (rotating) / Cosmetic Parts / Paints & Decals / Character Outfits / Game Passes / **Redeem Code** (S23 entry).
- Every item: preview-on-your-kart button before purchase. Robux purchases via MarketplaceService prompts; coins purchases confirm-dialog over 1,000.
- Hard rule surfaced in UI: stat-affecting parts are **never** sold for Robux (earn-only badge on them elsewhere).

## S16 — Tournament
- This week's 5 events (mode + track + modifier), your best per event, total points, prize tiers (cosmetic part art), countdown to reset.
- Leaderboard tab: global + friends. Enter event → S6 (tournament-flagged) → S7.
- Edge: season rollover mid-session → results bank to the season the run STARTED in.

## S17 — Daily Quests
- Login streak track (7-day, escalating), 3 daily quests with progress bars + claim buttons, refresh timer. Claim-all button.

## S18 — Leaderboards
- Per-track best times (validated runs only), global/friends filter; tap row → watch ghost (if stored) → spectate replay on track.

## S19 — Settings
- Audio: music / SFX sliders. Controls: tilt on/off + sensitivity, steering sensitivity, invert ⚠ no, camera shake toggle. Graphics: effects quality (auto by device). Accessibility: colorblind-safe gate/fruit markers, reduced flash mode. Account: reset tutorial, privacy/credits links.

## S20 — Test Ramp
- 15-second hill, no UI but speed feel + a fruit line + one ramp; ends in foam-pit, auto-return to S10. No rewards (no farmability).

## S21 — Multiplayer Queue
- Pick bracket (Rookie ≤200 CC / Pro ≤400 / Unlimited — auto-suggested from active loadout), track vote (3 options), queue status ("4/8 — starting in 0:18, bots fill empty slots"). Cancel anytime → S3.

## S22 — Private Lobby
- Create (generates join code) / Join (enter code). Host picks track + mode + power toggle; player list with ready checks; host start. In-lobby kart showcase row.

## S23 — Redeem Code
- Single text field + Redeem; success = item reveal animation; failures: invalid / expired / already-claimed messages. Rate-limited server-side.

---

## Global systems UI
- **Toasts** (top, queue of 1): quest complete, friend joined hub, tournament rank change.
- **Badge-dots** propagate: kiosk/dock buttons show dots when something is claimable.
- **Disconnect/rejoin**: rejoin mid-MP-race → spectator of remainder → results screen with DNF; solo race in progress is simply abandoned (no save-state v1).
- **Data-save failure** during play: silent retry with exponential backoff; persistent failure → warning banner "Progress may not save" (never block play).
- **Server shutdown** (Roblox update): 60 s warning toast; BindToClose flushes saves; MP races ending within 60 s are allowed to finish.
