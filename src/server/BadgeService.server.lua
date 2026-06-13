--!strict
-- docs/15 P9: awards badges on milestones. Listens to DataService's MilestoneBus.
-- Every award is gated on a configured badge id (0 = skip) and checked against
-- ownership first, so it's a safe no-op until the owner creates badges on
-- roblox.com and pastes the ids into GameConfig.badges.

local BadgeService = game:GetService("BadgeService")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local milestoneBus = ServerStorage:WaitForChild("MilestoneBus") :: BindableEvent

local function award(player: Player, badgeId: number)
	if not badgeId or badgeId == 0 then
		return
	end
	task.spawn(function()
		local okHas, has = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
		end)
		if okHas and has then
			return
		end
		pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)
	end)
end

milestoneBus.Event:Connect(function(player: Player, kind: string)
	local B = Config.badges
	if kind == "race" then
		award(player, B.firstRace)
	elseif kind == "clear" then
		award(player, B.firstClear)
	elseif kind == "recruit" then
		award(player, B.firstBoss)
	elseif kind == "allRecruited" then
		award(player, B.allChampions)
	end
end)
