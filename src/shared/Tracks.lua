--!strict
-- 9 tracks across 3 themed episodes (docs/04, docs/13 M6).
-- Each track: segment list for the ribbon generator + theme + boss.
-- Episode unlocks: all previous episode's bosses recruited (docs/06 G7).

export type Segment = {
	length: number,
	pitchDeg: number,
	yawDeg: number,
	gap: boolean?,
	boostPad: boolean?,
	loop: boolean?, -- full vertical loop (length ignored; uses radius)
	radius: number?,
}

export type Theme = {
	roadColor: Color3,
	roadMaterial: Enum.Material,
	railColor: Color3,
	padColor: Color3,
	ice: boolean?,
}

export type TrackDef = {
	id: string,
	name: string,
	episode: number,
	order: number,
	theme: Theme,
	bossId: string,
	rivalCruise: number,
	timeLimit: number, -- Time Boom par
	segments: { Segment },
}

local GRASS: Theme = {
	roadColor = Color3.fromRGB(160, 160, 165),
	roadMaterial = Enum.Material.Concrete,
	railColor = Color3.fromRGB(220, 90, 60),
	padColor = Color3.fromRGB(120, 200, 120),
}
local CANYON: Theme = {
	roadColor = Color3.fromRGB(194, 154, 108),
	roadMaterial = Enum.Material.Slate,
	railColor = Color3.fromRGB(130, 80, 50),
	padColor = Color3.fromRGB(230, 190, 120),
}
local ICE: Theme = {
	roadColor = Color3.fromRGB(170, 215, 245),
	roadMaterial = Enum.Material.Ice,
	railColor = Color3.fromRGB(70, 120, 200),
	padColor = Color3.fromRGB(210, 235, 250),
	ice = true,
}

local function seg(length: number, pitchDeg: number, yawDeg: number, opts: { gap: boolean?, boostPad: boolean?, loop: boolean?, radius: number? }?): Segment
	local s: Segment = { length = length, pitchDeg = pitchDeg, yawDeg = yawDeg }
	if opts then
		s.gap = opts.gap
		s.boostPad = opts.boostPad
		s.loop = opts.loop
		s.radius = opts.radius
	end
	return s
end

local function loop(radius: number): Segment
	return seg(0, 0, 0, { loop = true, radius = radius })
end

local Tracks: { TrackDef } = {
	-- ============ Episode 1: Sproutway (grassland) ============
	{
		id = "e1t1", name = "Sprout Hill", episode = 1, order = 1, theme = GRASS, bossId = "chuck", rivalCruise = 44, timeLimit = 75,
		segments = {
			seg(50, -5, 0), seg(80, -13, 0), seg(70, -8, -50), seg(50, -16, 0, { boostPad = true }),
			seg(80, -10, 55), seg(50, -4, 0), seg(40, -12, -25), seg(45, -3, 0, { boostPad = true }),
			seg(30, 14, 0), seg(38, 0, 0, { gap = true }), seg(70, -14, 0), seg(80, -8, -35), seg(90, -4, 0), seg(50, -1, 0),
		},
	},
	{
		id = "e1t2", name = "Meadow Spiral", episode = 1, order = 2, theme = GRASS, bossId = "blues", rivalCruise = 45, timeLimit = 75,
		segments = {
			seg(60, -10, 0), seg(70, -8, 40), seg(50, -18, 0, { boostPad = true }),
			seg(200, -7, 360, { boostPad = true }), -- full descending corkscrew spiral
			seg(60, -4, -60), seg(50, -14, 0), seg(80, -8, 30), seg(70, -6, -30), seg(60, -2, 0),
		},
	},
	{
		id = "e1t3", name = "Loop-de-Grove", episode = 1, order = 3, theme = GRASS, bossId = "bomb", rivalCruise = 46, timeLimit = 85,
		segments = {
			seg(40, -6, 0), seg(70, -20, 0, { boostPad = true }),
			loop(24), -- first vertical loop of the game
			seg(50, -8, 45), seg(30, 12, 0, { boostPad = true }), seg(32, 0, 0, { gap = true }),
			seg(60, -18, 0), seg(70, -10, -50), seg(40, -2, 0, { boostPad = true }), seg(30, 13, 0), seg(36, 0, 0, { gap = true }),
			seg(60, -16, -20), seg(80, -6, 20), seg(60, -2, 0),
		},
	},
	-- ============ Episode 2: Oink Canyon (desert) ============
	{
		id = "e2t1", name = "Dust Gulch", episode = 2, order = 1, theme = CANYON, bossId = "matilda", rivalCruise = 48, timeLimit = 80,
		segments = {
			seg(50, -7, 0), seg(70, -12, -30), seg(70, -12, 30), seg(50, -3, 0, { boostPad = true }), seg(35, 13, 0),
			seg(40, 0, 0, { gap = true }), seg(70, -15, 0), seg(60, -5, -65), seg(70, -9, 0), seg(70, -4, 35), seg(60, -2, 0),
		},
	},
	{
		id = "e2t2", name = "Hoodoo Helix", episode = 2, order = 2, theme = CANYON, bossId = "hal", rivalCruise = 49, timeLimit = 95,
		segments = {
			seg(60, -11, 0), seg(50, -6, 70), seg(50, -16, 0, { boostPad = true }),
			seg(280, -6, 540, { boostPad = true }), -- 1.5-turn corkscrew down the hoodoo
			seg(50, -14, 0), seg(40, -2, 0, { boostPad = true }), seg(34, 15, 0), seg(44, 0, 0, { gap = true }),
			seg(70, -16, -25), seg(80, -5, 0),
		},
	},
	{
		id = "e2t3", name = "Mesa Madness", episode = 2, order = 3, theme = CANYON, bossId = "stella", rivalCruise = 50, timeLimit = 100,
		segments = {
			seg(40, -5, 0), seg(70, -24, 0, { boostPad = true }),
			loop(26), seg(40, -10, 0, { boostPad = true }), loop(26), -- double loop!
			seg(60, -6, -45), seg(70, -20, 0, { boostPad = true }), seg(60, -6, 45),
			seg(36, 15, 0, { boostPad = true }), seg(48, 0, 0, { gap = true }), seg(70, -18, 0), seg(60, -8, -60),
			seg(60, -8, 60), seg(70, -3, 0),
		},
	},
	-- ============ Episode 3: Frostfall (ice) ============
	{
		id = "e3t1", name = "Powder Corkscrew", episode = 3, order = 1, theme = ICE, bossId = "terence", rivalCruise = 51, timeLimit = 95,
		segments = {
			seg(50, -8, 0), seg(70, -14, 35), seg(50, -3, 0, { boostPad = true }),
			seg(220, -8, 450, { boostPad = true }), -- icy 1.25-turn corkscrew
			seg(70, -14, -45), seg(50, -10, 0), loop(24), seg(60, -6, 55), seg(70, -8, 0), seg(60, -2, 0),
		},
	},
	{
		id = "e3t2", name = "Glacier Gap", episode = 3, order = 2, theme = ICE, bossId = "bubbles", rivalCruise = 53, timeLimit = 100,
		segments = {
			seg(50, -10, 0), seg(60, -18, 0, { boostPad = true }), seg(34, 13, 0), seg(46, 0, 0, { gap = true }),
			seg(60, -14, -40), loop(28),
			seg(60, -6, 0), seg(34, 14, 0, { boostPad = true }), seg(52, 0, 0, { gap = true }),
			seg(70, -18, 30), seg(70, -8, -30), seg(70, -3, 0),
		},
	},
	{
		id = "e3t3", name = "Avalanche Apocalypse", episode = 3, order = 3, theme = ICE, bossId = "foreman", rivalCruise = 54, timeLimit = 110,
		segments = {
			seg(40, -8, 0), seg(80, -26, 0, { boostPad = true }), -- monster dive
			loop(30),
			seg(60, -8, -55), seg(180, -9, 360, { boostPad = true }), -- spiral
			seg(50, -16, 0), seg(38, 16, 0, { boostPad = true }), seg(54, 0, 0, { gap = true }),
			seg(60, -12, -45), loop(22), seg(50, -4, 0),
			seg(36, 15, 0, { boostPad = true }), seg(48, 0, 0, { gap = true }), seg(80, -20, 25), seg(90, -4, 0),
		},
	},
}

local byId: { [string]: TrackDef } = {}
for _, t in Tracks do
	byId[t.id] = t
end

local EPISODE_NAMES = { "Sproutway", "Oink Canyon", "Frostfall" }

local function bossesOfEpisode(ep: number): { string }
	local out = {}
	for _, t in Tracks do
		if t.episode == ep then
			table.insert(out, t.bossId)
		end
	end
	return out
end

return {
	list = Tracks,
	byId = byId,
	DEFAULT = "e1t1",
	EPISODE_NAMES = EPISODE_NAMES,
	bossesOfEpisode = bossesOfEpisode,
}
