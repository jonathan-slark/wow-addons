--
-- ShopFrame Module
--

-- Import
local ShopFrame = Crafty_ShopFrame
local ShopFrameList = Crafty_ShopFrameList
local AH = Crafty_AH
local Data = Crafty_Data
local Merchant = Crafty_Merchant
local ShopFrameListAH = Crafty_ShopFrameListAH
local ShopFrameListVendor = Crafty_ShopFrameListVendor
local Tooltip = Crafty_Tooltip
local GameTooltip = GameTooltip
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local HybridScrollFrame_CreateButtons = HybridScrollFrame_CreateButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local PlaySound = PlaySound
local ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS
local SOUNDKIT = SOUNDKIT
local next = next
local pairs = pairs
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe
local _G = _G

-- Make sure we don't polute the global environment
setfenv(1, {})

-- The built list of mats to display
ShopFrameList.list = {}

-- List of mats and number required
ShopFrameList.matIDs = {}
ShopFrameList.vendorIDs = {}

SELECTED_ALPHA = 0.5	-- Alpha value of the selected texture, tones it down

function ShopFrameList:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:OnLoad()
    end
end

function ShopFrameList:OnLoad()
    HybridScrollFrame_CreateButtons(self, "Crafty_WindowRowTemplate", 0, 0)
    
    self:ClearSelection()
end

function ShopFrameList:ClearSelection()
    if self.selected then
	self.selected.SelectedTexture:Hide()
	self.selected = nil
    end
    ShopFrameListAH:Disable()
    ShopFrameListVendor:Disable()
end

function ShopFrameList:BuildList()
    wipe(self.list)

    local top = true
    for matID, num in pairs(self.matIDs) do
	if top then
	    self.list[#self.list + 1] = {
		header = "Reagents"
	    }
	    top = false
	end
	self.list[#self.list + 1] = {
	    isReagent = true,
	    matID = matID,
	    num = num
	}
    end

    local doneHeader = false
    for vendorID, num in pairs(self.vendorIDs) do
	if doneHeader then
	    -- NOOP
	else
	    if top then
		top = false
	    else
		self.list[#self.list + 1] = {
		    space = true
		}
	    end
	    self.list[#self.list + 1] = {
		header = "Vendor"
	    }
	    doneHeader = true
	end
	self.list[#self.list + 1] = {
	    isVendor = true,
	    matID = vendorID,
	    num = num
	}
    end
end

-- Temporary list of all mats required
local mats = {}

local function AddMats(item, crafts)
    if item and item.reagents then
	for reagentID, reagentNum in pairs(item.reagents) do
	    local total = reagentNum * crafts
	    if mats[reagentID] then
		mats[reagentID] = mats[reagentID] + total
	    else
		mats[reagentID] = total
	    end
	end
    end
end

function ShopFrameList:GetMats()
    wipe(self.matIDs)
    wipe(self.vendorIDs)
    self:ClearSelection()
    wipe(mats)

    -- Get the required mats
    local queue = _G.Crafty_Queue
    for tradeSkillID in pairs(queue) do
	for itemID in pairs(queue[tradeSkillID]) do
	    local crafts = queue[tradeSkillID][itemID].crafts
	    local item = _G.Crafty_Items[itemID]
	    AddMats(item, crafts)
	end
    end
    local queueInter = _G.Crafty_QueueIntermediates
    for itemID in pairs(queueInter) do
	local crafts = queueInter[itemID]
	local item = _G.Crafty_Items[itemID]
	AddMats(item, crafts)
    end

    -- Take off what we do have and seperate into the two lists
    for itemID in pairs(mats) do
	local item = _G.Crafty_Items[itemID]
	local list = Data.vendorIDs[itemID] and self.vendorIDs or self.matIDs
	local count

	if item and item.reagents and item.tradeSkillID and 
	    item.numProduced then
	    local interItem = queueInter[itemID]
	    local itemCrafts = interItem or 0
            local queueItem
            if queue[item.tradeSkillID] then
                queueItem = queue[item.tradeSkillID][itemID]
            end
	    if queueItem then
		itemCrafts = itemCrafts + queueItem.crafts
	    end
	    local itemNeeded = queueItem and queueItem.needed or 0
	    count = GetItemCount(itemID, true) + itemCrafts * 
		item.numProduced - itemNeeded
	else
	    count = GetItemCount(itemID, true)
	end

	if count then
	    local buy = mats[itemID] - count
	    if buy > 0 then
		if list[itemID] then
		    list[itemID] = list[itemID] + buy
		else
		    list[itemID] = buy
		end
	    end
	end
    end

    self:BuildList()
end

function ShopFrameList:SelectedRemoved(lastButton)
    self:ClearSelection()
    if lastButton then
	self.selected = lastButton
	lastButton.SelectedTexture:Show()
    end
end

function ShopFrameList:Refresh()
    local offset = HybridScrollFrame_GetOffset(self);
    local lastButton
    for i = 1, #self.buttons do
	local button = self.buttons[i]

	local listItem = self.list[offset + i]
	if listItem then
	    if listItem.header then
		button.listIndex = nil
		button.Text:SetText(listItem.header)
		button.Text:SetTextColor(unpack(Data.colour.white))
		button.Count:Hide()
		button:Show()

		if button == self.selected then
		    self:SelectedRemoved(lastButton)
		end
	    elseif listItem.space then
		button:Hide()

		if button == self.selected then
		    self:SelectedRemoved(lastButton)
		end
	    else
		button.listIndex = offset + i
		local _, itemLink, itemRarity = GetItemInfo(listItem.matID)
		if itemLink and itemRarity then
		    if self.selected == button then
			if listItem.isVendor then
			    ShopFrameListAH:Disable()
			    ShopFrameListVendor:Enable()
			elseif listItem.isReagent then
			    ShopFrameListAH:Enable()
			    ShopFrameListVendor:Disable()
			end
		    end

		    button.Text:SetText("  " .. itemLink)
		    local r = ITEM_QUALITY_COLORS[itemRarity].r
		    local g = ITEM_QUALITY_COLORS[itemRarity].g
		    local b = ITEM_QUALITY_COLORS[itemRarity].b
		    button.SelectedTexture:SetVertexColor(r, g, b, 
			SELECTED_ALPHA)
		    button.Count:SetText(tostring(listItem.num))
		    button.Count:SetTextColor(unpack(Data.colour.white))
		    button.Count:Show()
		    button:Show()
		end
		if self.selected then
		    lastButton = button
		else
		    -- Make first item the selected button
		    self.selected = button
		    button.SelectedTexture:Show()
		end
	    end
	else
	    -- Check if selected button has been removed
	    if button == self.selected then
		self:SelectedRemoved(lastButton)
	    end
	    button:Hide()
	end
    end

    local rowHeight = self.buttons[1]:GetHeight()
    local height = self:GetHeight()
    HybridScrollFrame_Update(self, #self.list * rowHeight, height)
end

function ShopFrameList:ButtonOnEnter(button)
    if not button.listIndex then return end
    local listItem = self.list[button.listIndex]
    if not listItem or not listItem.matID then return end

    -- Tooltip
    local rowHeight = self.buttons[1]:GetHeight()
    local _, itemLink = GetItemInfo(listItem.matID)
    if itemLink then
	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT", 0, rowHeight)
	GameTooltip:SetHyperlink(itemLink)
    else
	return
    end

    Tooltip:AddPrice(GameTooltip, listItem.matID, false, listItem.num)
    GameTooltip:Show()
end

function ShopFrameList:ButtonOnLeave(button)
    GameTooltip:Hide()
end

function ShopFrameList:ButtonOnClick(button, mouseButton)
    if mouseButton == "LeftButton" then
	if button.listIndex then
	    local listItem = self.list[button.listIndex]
	    if not listItem or listItem.header then
		return
	    end
	else
	    return
	end
	if self.selected then
	    self.selected.SelectedTexture:Hide()
	end
	button.SelectedTexture:Show()
	self.selected = button
    elseif mouseButton == "RightButton" then
	if button.listIndex then
	    local listItem = self.list[button.listIndex]
	    if listItem then
		self.matIDs[listItem.matID] = nil
		self.vendorIDs[listItem.matID] = nil
		self:BuildList()
		self:ButtonOnEnter(button)
	    end
	end
    end
end

function ShopFrameList:SearchAH()
    if not AH.open or not self.selected or not self.selected.listIndex then 
	return end

    local matID = self.list[self.selected.listIndex].matID
    AH:SearchItem(matID, true)
end

function ShopFrame:OnShow()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_OPEN);
end

function ShopFrame:OnHide()
    PlaySound(SOUNDKIT.UI_PROFESSIONS_WINDOW_CLOSE);
end

function ShopFrameList:BuyVendor()
    if not self.selected or not self.selected.listIndex then return end

    local matID = self.list[self.selected.listIndex].matID
    local num = self.list[self.selected.listIndex].num
    Merchant:BuyItem(matID, num)
end
