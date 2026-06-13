--!strict
-- docs/15 P7–P9: the OWNER PLUG-IN SHEET. Every external asset / Roblox-account
-- id the shipped systems need lives here. Everything defaults to 0 / "" so the
-- systems run as safe no-ops until you paste real ids. Nothing else needs editing.
--
-- IP SAFETY (docs/07 §4): only use ORIGINAL or CC0 audio you have the rights to.
-- NO Rovio / Angry Birds audio. Create sounds/badges/products on roblox.com,
-- then drop their ids below.

return {
	-- ===== Sound asset ids (rbxassetid numbers; 0 = silent no-op) =====
	sounds = {
		uiClick = 0,
		uiOpen = 0,
		launch = 0, -- slingshot release whoosh
		skidBoost = 0, -- mini-turbo release
		boostPad = 0,
		shield = 0,
		shieldBlocked = 0,
		frozen = 0,
		gatePassed = 0,
		gateMissed = 0,
		finishWin = 0,
		finishLose = 0,
		coin = 0,
		engineLoop = 0, -- looped; pitch tracks speed
		windLoop = 0, -- looped ambient
		music = 0, -- looped background track
	},

	-- ===== Badge ids (create on roblox.com ▸ your game ▸ Badges; 0 = skip) =====
	badges = {
		firstRace = 0, -- finish your first race
		firstClear = 0, -- clear your first challenge
		firstBoss = 0, -- recruit your first champion
		allChampions = 0, -- recruit every champion
		loopMaster = 0, -- complete a full loop track
	},

	-- ===== Monetization (create Developer Products / Passes; 0 = disabled) =====
	-- Developer products grant coins (consumable). productCoins maps a product id
	-- to the number of coins it grants.
	productCoins = {
		-- [123456789] = 1000,
	} :: { [number]: number },
	-- Game passes (one-time). starterPack grants a bonus on first owned-check.
	gamepasses = {
		starterPack = 0, -- e.g. bonus coins + a part
		vipDoubleCoins = 0, -- doubles race coin rewards while owned
	},

	-- ===== Tunable economy multipliers (safe to tweak) =====
	vipCoinMultiplier = 2,
}
