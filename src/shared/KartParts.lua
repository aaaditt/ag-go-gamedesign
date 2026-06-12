--!strict
-- Kart part catalog + stat/CC math (docs/03, docs/13 W5.1–W5.2).
-- Stats: topSpeed, accel, handling, strength (multipliers on Tuning bases).
-- CC = Σ (part baseCC × level). Levels 1–3, upgrade cost scales.

export type Part = {
	id: string,
	slot: "chassis" | "wheels" | "front" | "rear",
	name: string,
	cost: number, -- coins (0 = starter part)
	baseCC: number,
	topSpeed: number, -- multiplier deltas (+0.1 = +10%)
	accel: number,
	handling: number,
	strength: number,
	color: Color3,
}

local Parts: { Part } = {
	-- chassis
	{ id = "crate", slot = "chassis", name = "Soapbox Crate", cost = 0, baseCC = 40, topSpeed = 0, accel = 0, handling = 0, strength = 0, color = Color3.fromRGB(160, 120, 70) },
	{ id = "tub", slot = "chassis", name = "Rocket Tub", cost = 600, baseCC = 55, topSpeed = 0.08, accel = -0.02, handling = 0, strength = 0.04, color = Color3.fromRGB(230, 230, 240) },
	{ id = "log", slot = "chassis", name = "Log Roller", cost = 900, baseCC = 60, topSpeed = 0.02, accel = 0.04, handling = -0.04, strength = 0.12, color = Color3.fromRGB(110, 75, 45) },
	{ id = "aero", slot = "chassis", name = "Aero Shell", cost = 1500, baseCC = 75, topSpeed = 0.14, accel = 0.02, handling = 0.04, strength = -0.06, color = Color3.fromRGB(220, 60, 60) },
	-- wheels
	{ id = "wood", slot = "wheels", name = "Wooden Discs", cost = 0, baseCC = 25, topSpeed = 0, accel = 0, handling = 0, strength = 0, color = Color3.fromRGB(140, 100, 60) },
	{ id = "rubber", slot = "wheels", name = "Rubber Slicks", cost = 500, baseCC = 35, topSpeed = 0.03, accel = 0.03, handling = 0.08, strength = 0, color = Color3.fromRGB(40, 40, 45) },
	{ id = "monster", slot = "wheels", name = "Monster Treads", cost = 1100, baseCC = 45, topSpeed = -0.02, accel = 0.02, handling = 0.02, strength = 0.14, color = Color3.fromRGB(70, 70, 80) },
	-- front
	{ id = "none_f", slot = "front", name = "No Bumper", cost = 0, baseCC = 10, topSpeed = 0, accel = 0, handling = 0, strength = 0, color = Color3.fromRGB(120, 120, 120) },
	{ id = "ram", slot = "front", name = "Ram Plank", cost = 400, baseCC = 20, topSpeed = -0.01, accel = 0, handling = 0, strength = 0.1, color = Color3.fromRGB(150, 110, 60) },
	{ id = "beak", slot = "front", name = "Beak Cone", cost = 800, baseCC = 28, topSpeed = 0.06, accel = 0.01, handling = 0, strength = 0.02, color = Color3.fromRGB(250, 180, 50) },
	-- rear
	{ id = "none_r", slot = "rear", name = "No Spoiler", cost = 0, baseCC = 10, topSpeed = 0, accel = 0, handling = 0, strength = 0, color = Color3.fromRGB(120, 120, 120) },
	{ id = "spoiler", slot = "rear", name = "Plank Spoiler", cost = 450, baseCC = 22, topSpeed = 0.02, accel = 0, handling = 0.06, strength = 0, color = Color3.fromRGB(90, 90, 100) },
	{ id = "rockets", slot = "rear", name = "Bottle Rockets", cost = 1000, baseCC = 30, topSpeed = 0.05, accel = 0.08, handling = -0.02, strength = 0, color = Color3.fromRGB(200, 60, 60) },
}

local byId: { [string]: Part } = {}
for _, p in Parts do
	byId[p.id] = p
end

local SLOTS = { "chassis", "wheels", "front", "rear" }
local DEFAULT_LOADOUT: { [string]: string } = { chassis = "crate", wheels = "wood", front = "none_f", rear = "none_r" }
local MAX_LEVEL = 3

local function upgradeCost(part: Part, level: number): number
	return math.floor((part.cost * 0.5 + 200) * level)
end

export type Stats = { topSpeed: number, accel: number, handling: number, strength: number, cc: number }

-- loadout: slot → partId; levels: partId → level (1..3)
local function computeStats(loadout: { [string]: string }, levels: { [string]: number }): Stats
	local stats = { topSpeed = 1, accel = 1, handling = 1, strength = 1, cc = 0 }
	for _, slot in SLOTS do
		local part = byId[loadout[slot] or DEFAULT_LOADOUT[slot]]
		if not part then
			continue
		end
		local level = math.clamp(levels[part.id] or 1, 1, MAX_LEVEL)
		local levelBonus = 1 + (level - 1) * 0.25 -- each level adds 25% of the part's deltas
		stats.topSpeed += part.topSpeed * levelBonus
		stats.accel += part.accel * levelBonus
		stats.handling += part.handling * levelBonus
		stats.strength += part.strength * levelBonus
		stats.cc += part.baseCC * level
	end
	return stats
end

return {
	list = Parts,
	byId = byId,
	SLOTS = SLOTS,
	DEFAULT_LOADOUT = DEFAULT_LOADOUT,
	MAX_LEVEL = MAX_LEVEL,
	upgradeCost = upgradeCost,
	computeStats = computeStats,
}
