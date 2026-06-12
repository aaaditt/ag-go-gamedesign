--!strict
-- Character roster + power definitions (docs/02). Names are working
-- placeholders — final IP-safe names/designs land in M8.

export type PowerDef = {
	id: string,
	kind: "self" | "bots",
	charges: number,
	-- self powers
	boostCap: number?,
	boostDuration: number?,
	shieldDuration: number?,
	-- bot powers
	range: number?, -- studs from player progress (along-track)
	targets: number?, -- max bots affected (nearest first); nil = all in range
	aheadOnly: boolean?,
	freezeTime: number?,
	knockback: number?, -- studs pushed back along the line
}

export type CharacterDef = {
	id: string,
	name: string,
	color: Color3,
	power: PowerDef,
	powerName: string,
	unlockEpisode: number, -- 0 = starter; 1..3 = recruited via Champion Chase
}

local Characters: { CharacterDef } = {
	{
		id = "red",
		name = "Ruby",
		color = Color3.fromRGB(200, 60, 50),
		powerName = "Speed Boost",
		unlockEpisode = 0,
		power = { id = "boost", kind = "self", charges = 1, boostCap = 115, boostDuration = 1.2 },
	},
	{
		id = "chuck",
		name = "Bolt",
		color = Color3.fromRGB(250, 200, 60),
		powerName = "Mega Boost",
		unlockEpisode = 1,
		power = { id = "megaboost", kind = "self", charges = 1, boostCap = 135, boostDuration = 2.0 },
	},
	{
		id = "blues",
		name = "Trio",
		color = Color3.fromRGB(80, 160, 250),
		powerName = "Flash Freeze",
		unlockEpisode = 1,
		power = { id = "freeze", kind = "bots", charges = 1, range = 130, freezeTime = 2.0 },
	},
	{
		id = "bomb",
		name = "Boomer",
		color = Color3.fromRGB(60, 60, 70),
		powerName = "Blast Wave",
		unlockEpisode = 1,
		power = { id = "explosion", kind = "bots", charges = 1, range = 70, knockback = 35, freezeTime = 1.0 },
	},
	{
		id = "matilda",
		name = "Pearl",
		color = Color3.fromRGB(240, 240, 245),
		powerName = "Egg Lob",
		unlockEpisode = 2,
		power = { id = "lob", kind = "bots", charges = 1, range = 250, targets = 1, aheadOnly = true, knockback = 45, freezeTime = 1.5 },
	},
	{
		id = "hal",
		name = "Rang",
		color = Color3.fromRGB(120, 200, 90),
		powerName = "Whirlwind",
		unlockEpisode = 2,
		power = { id = "whirlwind", kind = "bots", charges = 1, range = 90, knockback = 25 },
	},
	{
		id = "terence",
		name = "Tank",
		color = Color3.fromRGB(150, 40, 40),
		powerName = "Thunder Strike",
		unlockEpisode = 3,
		power = { id = "lightning", kind = "bots", charges = 1, targets = 3, freezeTime = 2.5 },
	},
	{
		id = "stella",
		name = "Blush",
		color = Color3.fromRGB(250, 130, 190),
		powerName = "Bubble Shield",
		unlockEpisode = 2,
		power = { id = "shield", kind = "self", charges = 1, shieldDuration = 4.0 },
	},
	{
		id = "bubbles",
		name = "Puff",
		color = Color3.fromRGB(250, 150, 60),
		powerName = "Balloon Burst",
		unlockEpisode = 3,
		power = { id = "balloon", kind = "bots", charges = 1, range = 80, knockback = 30 },
	},
	{
		id = "foreman",
		name = "Wrench",
		color = Color3.fromRGB(110, 180, 110),
		powerName = "Triple Dynamite",
		unlockEpisode = 3,
		power = { id = "tripledyn", kind = "bots", charges = 3, range = 200, targets = 1, aheadOnly = true, knockback = 25 },
	},
}

local byId: { [string]: CharacterDef } = {}
for _, c in Characters do
	byId[c.id] = c
end

return {
	list = Characters,
	byId = byId,
	DEFAULT = "red",
}
