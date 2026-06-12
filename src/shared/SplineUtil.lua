--!strict
-- Catmull-Rom spline over an ordered point list, arc-length sampled.
-- Used for the AI racing line (M2) and later for progress/positions (docs/13).

local SplineUtil = {}
SplineUtil.__index = SplineUtil

export type Spline = typeof(setmetatable(
	{} :: { samples: { Vector3 }, cumDist: { number }, total: number },
	SplineUtil
))

local function catmullRom(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
	local t2 = t * t
	local t3 = t2 * t
	return 0.5
		* ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

function SplineUtil.new(points: { Vector3 }, samplesPerSegment: number?): Spline
	assert(#points >= 2, "spline needs at least 2 points")
	local perSeg = samplesPerSegment or 8
	local samples: { Vector3 } = {}
	local cumDist: { number } = {}
	local total = 0

	for i = 1, #points - 1 do
		local p0 = points[math.max(i - 1, 1)]
		local p1 = points[i]
		local p2 = points[i + 1]
		local p3 = points[math.min(i + 2, #points)]
		local from = (i == 1) and 0 or 1 -- avoid duplicating segment endpoints
		for s = from, perSeg do
			local pos = catmullRom(p0, p1, p2, p3, s / perSeg)
			local n = #samples
			if n > 0 then
				total += (pos - samples[n]).Magnitude
			end
			table.insert(samples, pos)
			table.insert(cumDist, total)
		end
	end

	return setmetatable({ samples = samples, cumDist = cumDist, total = total }, SplineUtil)
end

-- index of the last sample at or before distance d (binary search)
local function indexAt(self: Spline, d: number): number
	local lo, hi = 1, #self.cumDist
	while lo < hi do
		local mid = (lo + hi + 1) // 2
		if self.cumDist[mid] <= d then
			lo = mid
		else
			hi = mid - 1
		end
	end
	return lo
end

function SplineUtil.PosAt(self: Spline, d: number): Vector3
	d = math.clamp(d, 0, self.total)
	local i = indexAt(self, d)
	if i >= #self.samples then
		return self.samples[#self.samples]
	end
	local segLen = self.cumDist[i + 1] - self.cumDist[i]
	local alpha = segLen > 0 and (d - self.cumDist[i]) / segLen or 0
	return self.samples[i]:Lerp(self.samples[i + 1], alpha)
end

function SplineUtil.TangentAt(self: Spline, d: number): Vector3
	local ahead = self:PosAt(math.min(d + 4, self.total))
	local here = self:PosAt(d)
	local diff = ahead - here
	return diff.Magnitude > 0.001 and diff.Unit or Vector3.zAxis
end

-- nearest distance-along-spline for a world position, searched in a window
-- around a hint index (cheap incremental progress tracking)
function SplineUtil.NearestDist(self: Spline, pos: Vector3, hintIndex: number?, window: number?): (number, number)
	local n = #self.samples
	local from = 1
	local to = n
	if hintIndex then
		local w = window or 40
		from = math.max(1, hintIndex - 5)
		to = math.min(n, hintIndex + w)
	end
	local bestD2, bestI = math.huge, from
	for i = from, to do
		local d2 = (self.samples[i] - pos).Magnitude
		if d2 < bestD2 then
			bestD2, bestI = d2, i
		end
	end
	return self.cumDist[bestI], bestI
end

return SplineUtil
