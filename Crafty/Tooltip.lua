--
-- Tooltip Module
--

Crafty_Tooltip = {}

-- Import
local Tooltip = Crafty_Tooltip
local Data = Crafty_Data
local TradeSkill = Crafty_TradeSkill
local C_TradeSkillUI = C_TradeSkillUI
local GameTooltip = GameTooltip
local GameTooltipTextLeft1 = GameTooltipTextLeft1
local GameTooltipTextLeft2 = GameTooltipTextLeft2
local GameTooltipTextLeft3 = GameTooltipTextLeft3
local GetAuctionItemLink = GetAuctionItemLink
local GetAuctionSellItemInfo = GetAuctionSellItemInfo
local GetBuybackItemLink = GetBuybackItemLink
local GetContainerItemID = GetContainerItemID
local GetGuildBankItemLink = GetGuildBankItemLink
local GetInboxItem = GetInboxItem
local GetInventoryItemID = GetInventoryItemID
local GetItemInfo = GetItemInfo
local GetLootRollItemLink = GetLootRollItemLink
local GetLootSlotLink = GetLootSlotLink
local GetMerchantItemLink = GetMerchantItemLink
local GetQuestItemLink = GetQuestItemLink
local GetQuestLogItemLink = GetQuestLogItemLink
local GetSendMailItem = GetSendMailItem
local ItemRefTooltip = ItemRefTooltip
local hooksecurefunc = hooksecurefunc
local unpack = unpack
local math = math
local tonumber = tonumber
local type = type
local _G = _G

-- Make sure we don't polute the global environment
setfenv(1, {})

-- Remove default vendor price text
_G.GameTooltip_OnTooltipAddMoney = function() end

function Tooltip:AddPrice(tooltip, itemID, show, num)
    local num = num or 1
    local header = false
    local function AddHeader()
	tooltip:AddLine(" ")
	tooltip:AddLine("Crafty Prices" .. (num > 1 and " (x" .. num  .. ")" 
	    or "") .. ":")
	header = true
    end

    local _, _, _, _, _, _, _, _, _, _, itemSellPrice = GetItemInfo(itemID)
    if itemSellPrice and itemSellPrice > 0 then
	AddHeader()
	tooltip:AddDoubleLine("Sell to vendor: ", 
	Data:GetCoinTextureString(itemSellPrice * num), 
	    unpack(Data.colour.white))
    end

    -- Get the real rarity and ilvl from the tooltip
    local r, g, b = GameTooltipTextLeft1:GetTextColor()
    local rarity = Data.rgbToRarity[math.floor((r + g + b) * 1000)]
    local text = GameTooltipTextLeft2:GetText()
    local ilvl
    if text then
	ilvl = text:match("Item Level (%d+)")
    end
    if ilvl then
	-- NOOP
    else
	text = GameTooltipTextLeft3:GetText()
	if text then
	    ilvl = text:match("Item Level (%d+)")
	end
    end
    if rarity and ilvl then 
	local disenchant = Data:DisenchantValue(itemID, rarity, tonumber(ilvl))
	if disenchant > 0 then
	    tooltip:AddDoubleLine("Disenchant value: ", 
		Data:GetCoinTextureString(disenchant * num), 
		unpack(Data.colour.white))
	end
    end

    local vendorCost = Data.vendorIDs[itemID]
    if vendorCost then
	if not header then AddHeader() end
	tooltip:AddDoubleLine("Buy from vendor: ", 
	Data:GetCoinTextureString(vendorCost * num), unpack(Data.colour.white))
    else
	local item = _G.Crafty_Items[itemID]
	if item then
	    local minBuyout = item.minBuyout
	    if minBuyout and minBuyout > 0 then
		if not header then AddHeader() end
		tooltip:AddDoubleLine("AH min buyout: ", 
		    Data:GetCoinTextureString(item.minBuyout * num), 
			unpack(Data.colour.white))
	    end
	    -- Trader value
	    if Data.Traders[itemID] then
		if not header then AddHeader() end
		local cost = Data:TraderValue(itemID)
		if cost then
		    tooltip:AddDoubleLine("Trader value: ", 
			Data:GetCoinTextureString(cost * num), 
			    unpack(Data.colour.white))
		end
	    else
		local cost = Data:CraftingCost(itemID)
		if cost and cost > 0 then
		    if not header then AddHeader() end
		    tooltip:AddDoubleLine("Crafting cost: ", 
			Data:GetCoinTextureString(cost * num), 
			    unpack(Data.colour.white))
		    if minBuyout and minBuyout > 0 then
			local profit = minBuyout - cost
			local colour
			local text
			if profit < 0 then
			    colour = Data.colour.red
			    text = "Loss: "
			    profit = -profit
			elseif profit > Data.ProfitThreshold then
			    colour = Data.colour.green
			    text = "Profit: "
			else
			    colour = Data.colour.yellow
			    text = "Profit: "
			end
			tooltip:AddDoubleLine(text, Data:GetCoinTextureString(
			    profit * num), unpack(colour))
		    end
		end
	    end
	    -- Debug
	    --[[
	    local debugHeader = false
	    local function AddDebugHeader()
		tooltip:AddLine(" ")
		tooltip:AddLine("Debug:")
		debugHeader = true
	    end
	    if item.isBoP then
		if not debugHeader then AddDebugHeader() end
		local colour = Data.colour.white
		tooltip:AddLine("isBoP", unpack(colour))
	    end
	    if Data.vendorIDs[itemID] then
		if not debugHeader then AddDebugHeader() end
		local colour = Data.colour.white
		tooltip:AddLine("isVendor", unpack(colour))
	    end
	    if item.minBuyout == -1 then
		if not debugHeader then AddDebugHeader() end
		local colour = Data.colour.white
		tooltip:AddLine("No minBuyout", unpack(colour))
	    end
	    --]]
	end
    end

    if show then
	tooltip:Show()
    end
end

hooksecurefunc(GameTooltip, "SetBagItem", 
    function (tooltip, bag, slot)
	local itemID = GetContainerItemID(bag, slot)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetInventoryItem", 
    function (tooltip, unit, slot)
	local itemID = GetInventoryItemID(unit, slot)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetAuctionItem", 
    function (tooltip, tab, index)
	local itemLink = GetAuctionItemLink(tab, index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetAuctionSellItem", 
    function (tooltip)
	local name = GetAuctionSellItemInfo();
	local _, itemLink = GetItemInfo(name)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetBuybackItem", 
    function (tooltip, slot)
	local itemLink = GetBuybackItemLink(slot)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetGuildBankItem", 
    function (tooltip, tab, slot)
	local itemLink = GetGuildBankItemLink(tab, slot)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetInboxItem", 
    function (tooltip, index, attachIndex)
	attachIndex = attachIndex or 1

	local _, itemID = GetInboxItem(index, attachIndex)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetSendMailItem",
    function (tooltip, index)
	local _, itemID = GetSendMailItem(index)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetRecipeResultItem",
    function (tooltip, recipeID)
	local itemID = TradeSkill:GetItemInfoFromRecipeID(recipeID)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetRecipeReagentItem",
    function (tooltip, recipeID, index)
	local itemLink = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, 
	    index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetTradePlayerItem",
    function (tooltip, itemID)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetTradeTargetItem",
    function (tooltip, itemID)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(ItemRefTooltip, "SetHyperlink", 
    function (tooltip, itemLink)
	local itemID = Data:GetItemInfoFromLink(itemLink)

	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetQuestItem",
    function (tooltip, itemType, index)
	local itemLink = GetQuestItemLink(itemType, index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetQuestLogItem",
    function (tooltip, itemType, index)
	local itemLink = GetQuestLogItemLink(itemType, index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetMerchantItem",
    function (tooltip, index)
	local itemLink = GetMerchantItemLink(index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetLootItem",
    function (tooltip, index)
	local itemLink = GetLootSlotLink(index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)

hooksecurefunc(GameTooltip, "SetLootRollItem",
    function (tooltip, index)
	local itemLink = GetLootRollItemLink(index)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID then
	    Tooltip:AddPrice(tooltip, itemID, true)
	end
    end
)
