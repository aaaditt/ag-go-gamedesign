--!strict
-- docs/15 P9: monetization scaffolding. Developer products grant coins; game
-- passes set feature attributes (VIP double coins, starter pack). Everything is
-- gated on GameConfig ids (0 = disabled) so it's dormant until the owner creates
-- the products/passes on roblox.com and fills GameConfig.
--
-- Grants route through DataService's GrantCoinsBus (the single coin authority),
-- so balances stay server-authoritative and persist immediately.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local grantCoinsBus = ServerStorage:WaitForChild("GrantCoinsBus") :: BindableEvent

-- ============ game passes → feature attributes ============
local function refreshPasses(player: Player)
	local vip = Config.gamepasses.vipDoubleCoins
	if vip and vip ~= 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, vip)
		end)
		if ok and owns then
			player:SetAttribute("VIPDoubleCoins", true) -- DataService applies the multiplier
		end
	end
	local starter = Config.gamepasses.starterPack
	if starter and starter ~= 0 then
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, starter)
		end)
		if ok and owns then
			player:SetAttribute("HasStarterPack", true)
		end
	end
end

Players.PlayerAdded:Connect(function(p)
	task.spawn(refreshPasses, p)
end)
for _, p in Players:GetPlayers() do
	task.spawn(refreshPasses, p)
end

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, _passId, purchased)
	if purchased then
		task.spawn(refreshPasses, player)
	end
end)

-- ============ developer products → coin grants ============
-- Only one script may own ProcessReceipt; this is it (no other script sets it).
MarketplaceService.ProcessReceipt = function(receipt)
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		-- player left before we could grant; let Roblox retry when they return
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local coins = Config.productCoins[receipt.ProductId]
	if coins and coins > 0 then
		grantCoinsBus:Fire(player, coins)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	-- Unknown product: don't consume money for nothing — leave it unprocessed so
	-- it retries after the owner adds it to GameConfig.productCoins.
	warn(("[Monetization] Unconfigured product %d — add it to GameConfig.productCoins"):format(receipt.ProductId))
	return Enum.ProductPurchaseDecision.NotProcessedYet
end
