--
-- Merchant Module
--

Crafty_Merchant = {}

-- Import
local Merchant = Crafty_Merchant
local Data = Crafty_Data
local BuyMerchantItem = BuyMerchantItem
local GetMerchantItemLink = GetMerchantItemLink
local GetMerchantItemMaxStack = GetMerchantItemMaxStack
local GetMerchantNumItems = GetMerchantNumItems
local type = type

-- Make sure we don't polute the global environment
setfenv(1, {})

-- Search for the item at the merchant
function Merchant:FindMerchantIndex(matID)
    -- GetMerchantNumItems returns 0 if not at merchant
    for i = 1, GetMerchantNumItems() do
	local itemLink = GetMerchantItemLink(i)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	if itemID == matID then
	    --[[
	    Data:Debug("Merchant:FindMerchantIndex", "Found item", matID, 
		"index", i)
	    --]]
	    return i
	end
    end

    return nil
end

-- Buys an item from a merchant, up to the max stack
function Merchant:BuyItem(matID, num)
    local index = self:FindMerchantIndex(matID)
    if index then
	local maxStack = GetMerchantItemMaxStack(index)
	local buy = num < maxStack and num or maxStack
	--[[
	Data:Debug("Merchant:BuyItem", "Buying item", matID, "buy", buy, 
	    "index", index)
	--]]
	BuyMerchantItem(index, buy)
    end
end
