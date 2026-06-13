--!strict
-- Challenge ladders, generated per track (docs/13 M6). Six challenge types
-- per track × 9 tracks = 54 challenges. CC gates scale by episode (docs/06).

local Tracks = require(script.Parent:WaitForChild("Tracks"))

export type ChallengeDef = {
	id: string,
	trackId: string,
	name: string,
	mode: "Race" | "TimeBoom" | "FruitSplat" | "Slalom" | "Versus" | "ChampionChase",
	bots: number,
	ccRequired: number,
	timeLimit: number?,
	fruitTarget: number?,
	fruitCount: number?,
	gates: number?,
	gatePenalty: number?,
	rivalCruise: number?,
	bossId: string?,
	winsNeeded: number?,
}

-- CC gates per episode (docs/06 curve), per rung of the ladder
local CC_BASE = { 0, 260, 410 } -- episode 1/2/3 entry
local CC_RUNG = { 0, 15, 30, 45, 60, 80 } -- added per challenge position

local ladders: { [string]: { ChallengeDef } } = {}
local byId: { [string]: ChallengeDef } = {}

for _, t in Tracks.list do
	local base = CC_BASE[t.episode] + (t.order - 1) * 30
	local ladder: { ChallengeDef } = {
		{
			id = t.id .. "_race", trackId = t.id, name = "Race!", mode = "Race",
			bots = 7, ccRequired = base + CC_RUNG[1],
		},
		{
			id = t.id .. "_boom", trackId = t.id, name = "Time Boom", mode = "TimeBoom",
			bots = 0, ccRequired = base + CC_RUNG[2], timeLimit = t.timeLimit,
		},
		{
			id = t.id .. "_fruit", trackId = t.id, name = "Fruit Splat", mode = "FruitSplat",
			bots = 0, ccRequired = base + CC_RUNG[3], fruitTarget = 16 + t.episode * 2, fruitCount = 26 + t.episode * 2,
		},
		{
			id = t.id .. "_slalom", trackId = t.id, name = "Slalom", mode = "Slalom",
			bots = 0, ccRequired = base + CC_RUNG[4], timeLimit = t.timeLimit + 12, gates = 10 + t.episode * 2, gatePenalty = 4,
		},
		{
			id = t.id .. "_versus", trackId = t.id, name = "Versus", mode = "Versus",
			bots = 1, ccRequired = base + CC_RUNG[5], rivalCruise = t.rivalCruise - 4,
		},
		{
			id = t.id .. "_chase", trackId = t.id, name = "Champion Chase", mode = "ChampionChase",
			bots = 1, ccRequired = base + CC_RUNG[6], rivalCruise = t.rivalCruise, bossId = t.bossId, winsNeeded = 3,
		},
	}
	ladders[t.id] = ladder
	for _, c in ladder do
		byId[c.id] = c
	end
end

local function ladderFor(trackId: string): { ChallengeDef }
	return ladders[trackId] or ladders[Tracks.DEFAULT]
end

return {
	byId = byId,
	ladderFor = ladderFor,
	DEFAULT = Tracks.DEFAULT .. "_race",
}
