--
-- Bag/Container Module
--

Crafty_Bag = {}

-- Import
local Bag = Crafty_Bag
local Data = Crafty_Data
local TradeSkill = Crafty_TradeSkill
local BACKPACK_CONTAINER = BACKPACK_CONTAINER
local NUM_BAG_SLOTS = NUM_BAG_SLOTS
local GetContainerNumSlots = GetContainerNumSlots
local GetContainerItemID = GetContainerItemID
local type = type

-- Make sure we don't polute the global environment
setfenv(1, {})

function Bag:FindItem(itemID)
    for bagID = BACKPACK_CONTAINER, NUM_BAG_SLOTS do
	for slot = 1, GetContainerNumSlots(bagID) do
	    local slotItemID = GetContainerItemID(bagID, slot)
	    if slotItemID == itemID then
		return bagID, slot
	    end
	end
    end

    return nil, nil
end
