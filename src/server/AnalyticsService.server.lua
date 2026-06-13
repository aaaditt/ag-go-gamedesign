--!strict
-- docs/15 P9: lightweight analytics. Logs the onboarding funnel (race → clear →
-- recruit → all champions) and coin economy via Roblox AnalyticsService. All
-- calls are pcall-guarded, so this is a safe no-op until the owner enables
-- analytics in the game's dashboard (no ids needed in GameConfig for this one).

local AnalyticsService = game:GetService("AnalyticsService")
local ServerStorage = game:GetService("ServerStorage")

local milestoneBus = ServerStorage:WaitForChild("MilestoneBus") :: BindableEvent
local grantCoinsBus = ServerStorage:WaitForChild("GrantCoinsBus") :: BindableEvent

local FUNNEL_STEP = { race = 1, clear = 2, recruit = 3, allRecruited = 4 }

milestoneBus.Event:Connect(function(player: Player, kind: string)
	local step = FUNNEL_STEP[kind]
	if step then
		pcall(function()
			AnalyticsService:LogOnboardingFunnelStepEvent(player, step, kind)
		end)
	end
end)

-- coin grants from purchases (MonetizationService → GrantCoinsBus)
grantCoinsBus.Event:Connect(function(player: Player, coins: number)
	pcall(function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			"Coins",
			coins,
			(player:GetAttribute("Coins") :: number?) or coins,
			"IAP"
		)
	end)
end)
