--!strict
-- 9 tracks across 3 themed episodes (docs/04, docs/13 M6, docs/15 P3).
-- Each track: segment list for the ribbon generator + theme + boss.
-- Episode unlocks: all previous episode's bosses recruited (docs/06 G7).
--
-- docs/15 P3: tracks are now composed from reusable MOTIFS (esses, rollers,
-- switchbacks, jumps, loops, spirals) so every track is long enough to last
-- ≥60 s at the casual (half-speed) tuning, and varied in pacing. Loops are big
-- (radius 95–120) set-pieces with flat lead-ins (see loopSet).

export type Segment = {
	length: number,
	pitchDeg: number,
	yawDeg: number,
	gap: boolean?,
	boostPad: boolean?,
	loop: boolean?, -- full vertical loop (length ignored; uses radius)
	radius: number?,
}

export type Opts = { gap: boolean?, boostPad: boolean?, loop: boolean?, radius: number? }

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

local function seg(length: number, pitchDeg: number, yawDeg: number, opts: Opts?): Segment
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

-- ============ motif builders (docs/15 P3) ============
-- Each returns a { Segment } chunk; tracks are assembled with chain{ ... }.

local function chain(parts: { { Segment } }): { Segment }
	local out: { Segment } = {}
	for _, part in parts do
		for _, s in part do
			table.insert(out, s)
		end
	end
	return out
end

-- a single descending straight (or a gentle climb if pitch > 0)
local function run(length: number, pitchDeg: number, opts: Opts?): { Segment }
	return { seg(length, pitchDeg, 0, opts) }
end

-- one long sweeping turn
local function sweep(length: number, pitchDeg: number, yawDeg: number, opts: Opts?): { Segment }
	return { seg(length, pitchDeg, yawDeg, opts) }
end

-- S-bends: n pairs of opposite sweepers
local function esses(n: number, amp: number, pitchDeg: number?): { Segment }
	local p = pitchDeg or -7
	local out: { Segment } = {}
	for _ = 1, n do
		table.insert(out, seg(62, p, amp))
		table.insert(out, seg(62, p, -amp))
	end
	return out
end

-- rollers: alternating dip/rise "whoops"
local function rollers(n: number): { Segment }
	local out: { Segment } = {}
	for _ = 1, n do
		table.insert(out, seg(44, -15, 0))
		table.insert(out, seg(34, 9, 0))
	end
	return out
end

-- hairpin switchback (down-left then down-right; flip with dir = -1)
local function switchback(pitchDeg: number, dir: number?): { Segment }
	local d = dir or 1
	return { seg(72, pitchDeg, -70 * d), seg(72, pitchDeg, 70 * d) }
end

-- kicker ramp + gap jump (boost into a flight over a gap)
local function jump(gapLen: number): { Segment }
	return { seg(40, 13, 0, { boostPad = true }), seg(gapLen, 0, 0, { gap = true }) }
end

-- big vertical loop set-piece: flat lead-in (clean entry) + loop + boosted runout
local function loopSet(radius: number): { Segment }
	return { seg(70, -2, 0), loop(radius), seg(54, -7, 0, { boostPad = true }) }
end

-- descending corkscrew spiral (yaw accumulates over one long boosted arc)
local function spiral(length: number, turns: number, pitchDeg: number?): { Segment }
	return { seg(length, pitchDeg or -7, 360 * turns, { boostPad = true }) }
end

-- gentle finishing runout into the FinishPad
local function finishRun(): { Segment }
	return { seg(70, -10, 0, { boostPad = true }), seg(90, -4, 0), seg(64, -1, 0) }
end

local Tracks: { TrackDef } = {
	-- ============ Episode 1: Sproutway (grassland) — ~60-72 s ============
	{
		id = "e1t1", name = "Sprout Hill", episode = 1, order = 1, theme = GRASS, bossId = "chuck", rivalCruise = 44, timeLimit = 95,
		segments = chain({
			run(60, -5), run(90, -13),
			esses(2, 46), run(70, -8, { boostPad = true }),
			rollers(2), switchback(-10),
			run(84, -6), jump(44), run(80, -14),
			esses(2, 52), sweep(74, -8, -44),
			rollers(2), switchback(-8, -1),
			run(92, -10, { boostPad = true }), esses(3, 46), sweep(74, -6, 30),
			rollers(3), run(84, -12), jump(48),
			esses(2, 50), switchback(-8),
			finishRun(),
		}),
	},
	{
		id = "e1t2", name = "Meadow Spiral", episode = 1, order = 2, theme = GRASS, bossId = "blues", rivalCruise = 45, timeLimit = 95,
		segments = chain({
			run(60, -10), sweep(70, -8, 40),
			esses(2, 44), run(60, -16, { boostPad = true }),
			spiral(220, 1),
			sweep(64, -4, -56), rollers(3), run(70, -12),
			esses(3, 48), switchback(-9),
			run(80, -8, { boostPad = true }), jump(46),
			esses(2, 50), spiral(180, 1),
			rollers(2), switchback(-8, -1), run(84, -10),
			esses(3, 46), sweep(70, -6, 30),
			finishRun(),
		}),
	},
	{
		id = "e1t3", name = "Loop-de-Grove", episode = 1, order = 3, theme = GRASS, bossId = "bomb", rivalCruise = 46, timeLimit = 110,
		segments = chain({
			run(50, -6), run(80, -18, { boostPad = true }),
			loopSet(95), -- first big loop of the game
			esses(2, 46), rollers(2), switchback(-10),
			run(84, -8), jump(46),
			esses(3, 48), run(80, -14, { boostPad = true }), sweep(70, -6, -50),
			rollers(3), switchback(-8, -1),
			esses(2, 50), run(84, -10), jump(48),
			finishRun(),
		}),
	},
	-- ============ Episode 2: Oink Canyon (desert) — ~74-100 s ============
	{
		id = "e2t1", name = "Dust Gulch", episode = 2, order = 1, theme = CANYON, bossId = "matilda", rivalCruise = 48, timeLimit = 110,
		segments = chain({
			run(56, -7), sweep(80, -12, -30),
			esses(3, 48), rollers(2), run(70, -15, { boostPad = true }), jump(50),
			esses(2, 52), switchback(-9), sweep(86, -6, 65),
			rollers(3), run(80, -12, { boostPad = true }),
			esses(3, 50), switchback(-10, -1), jump(48), run(84, -8),
			esses(3, 48), rollers(3), sweep(74, -6, -60), switchback(-8),
			run(90, -10, { boostPad = true }), esses(2, 50),
			finishRun(),
		}),
	},
	{
		id = "e2t2", name = "Hoodoo Helix", episode = 2, order = 2, theme = CANYON, bossId = "hal", rivalCruise = 49, timeLimit = 115,
		segments = chain({
			run(60, -11), sweep(50, -6, 70),
			esses(2, 46), run(50, -16, { boostPad = true }),
			spiral(300, 1.5), -- 1.5-turn corkscrew down the hoodoo
			run(50, -14), rollers(3), esses(3, 48), switchback(-9),
			run(80, -10, { boostPad = true }), jump(48),
			esses(2, 50), spiral(220, 1),
			rollers(2), switchback(-8, -1), run(84, -12),
			esses(3, 46), sweep(74, -6, -55), rollers(3),
			run(80, -10, { boostPad = true }), esses(2, 50),
			finishRun(),
		}),
	},
	{
		id = "e2t3", name = "Mesa Madness", episode = 2, order = 3, theme = CANYON, bossId = "stella", rivalCruise = 50, timeLimit = 140,
		segments = chain({
			run(50, -5), run(80, -22, { boostPad = true }),
			loopSet(100), loopSet(100), -- double loop!
			esses(3, 48), rollers(2), switchback(-9), sweep(84, -6, 45), jump(50),
			esses(3, 50), switchback(-10, -1), rollers(3),
			sweep(74, -6, -60), run(84, -12), esses(2, 50),
			finishRun(),
		}),
	},
	-- ============ Episode 3: Frostfall (ice) — ~85-110 s ============
	{
		id = "e3t1", name = "Powder Corkscrew", episode = 3, order = 1, theme = ICE, bossId = "terence", rivalCruise = 51, timeLimit = 125,
		segments = chain({
			run(50, -8), sweep(70, -14, 35),
			esses(2, 46), run(50, -3, { boostPad = true }),
			spiral(240, 1.25), -- icy corkscrew
			sweep(70, -14, -45), rollers(3), run(50, -10),
			loopSet(95),
			esses(3, 48), switchback(-9), run(80, -8, { boostPad = true }), jump(48),
			esses(2, 50), rollers(3), switchback(-8, -1), sweep(74, -6, 55),
			esses(3, 46), run(84, -10),
			finishRun(),
		}),
	},
	{
		id = "e3t2", name = "Glacier Gap", episode = 3, order = 2, theme = ICE, bossId = "bubbles", rivalCruise = 53, timeLimit = 125,
		segments = chain({
			run(50, -10), run(60, -18, { boostPad = true }), jump(50),
			esses(2, 46), sweep(60, -14, -40),
			loopSet(105),
			esses(3, 48), rollers(3), jump(52), switchback(-9),
			run(80, -8, { boostPad = true }), esses(3, 50), sweep(74, -6, 60),
			rollers(2), jump(50), switchback(-10, -1),
			esses(3, 46), run(84, -12), esses(2, 50),
			finishRun(),
		}),
	},
	{
		id = "e3t3", name = "Avalanche Apocalypse", episode = 3, order = 3, theme = ICE, bossId = "foreman", rivalCruise = 54, timeLimit = 155,
		segments = chain({
			run(46, -8), run(86, -26, { boostPad = true }), -- monster dive
			loopSet(120),
			sweep(60, -8, -55), spiral(220, 1),
			esses(3, 48), rollers(3), jump(54), switchback(-12),
			run(80, -10, { boostPad = true }), esses(3, 50),
			loopSet(110),
			rollers(3), switchback(-10, -1), jump(52),
			esses(3, 46), sweep(74, -8, 60), rollers(2),
			esses(2, 50), sweep(90, -20, 25),
			finishRun(),
		}),
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
