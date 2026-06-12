--!strict
-- Challenge ladder config (docs/13 W4.1). One ladder per track; the
-- prototype track carries the full mode set. CC requirements activate in M5.

export type ChallengeDef = {
	id: string,
	name: string,
	mode: "Race" | "TimeBoom" | "FruitSplat" | "Slalom" | "Versus" | "ChampionChase",
	bots: number,
	ccRequired: number,
	-- mode params
	timeLimit: number?, -- TimeBoom / Slalom (seconds)
	fruitTarget: number?, -- FruitSplat: how many to smash
	fruitCount: number?, -- FruitSplat: how many spawn
	gates: number?, -- Slalom: gate count
	gatePenalty: number?, -- Slalom: seconds lost per missed gate
	rivalCruise: number?, -- Versus / ChampionChase: rival speed
	bossId: string?, -- ChampionChase: character recruited on 3 wins
	winsNeeded: number?,
}

local Challenges: { ChallengeDef } = {
	{ id = "c1_race", name = "Race!", mode = "Race", bots = 7, ccRequired = 0 },
	{ id = "c2_timeboom", name = "Time Boom", mode = "TimeBoom", bots = 0, ccRequired = 0, timeLimit = 75 },
	{ id = "c3_fruit", name = "Fruit Splat", mode = "FruitSplat", bots = 0, ccRequired = 0, fruitTarget = 18, fruitCount = 28 },
	{ id = "c4_slalom", name = "Slalom", mode = "Slalom", bots = 0, ccRequired = 0, timeLimit = 85, gates = 12, gatePenalty = 4 },
	{ id = "c5_versus", name = "Versus", mode = "Versus", bots = 1, ccRequired = 0, rivalCruise = 82 },
	{
		id = "c6_chase",
		name = "Champion Chase: Bolt",
		mode = "ChampionChase",
		bots = 1,
		ccRequired = 0,
		rivalCruise = 92,
		bossId = "chuck",
		winsNeeded = 3,
	},
}

local byId: { [string]: ChallengeDef } = {}
for _, c in Challenges do
	byId[c.id] = c
end

return { list = Challenges, byId = byId, DEFAULT = "c1_race" }
