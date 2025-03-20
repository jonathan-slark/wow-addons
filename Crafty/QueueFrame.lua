--
-- QueueFrame Module
--

-- Queue data persists between sessions
Crafty_Queue = {}
Crafty_QueueIntermediates = {}

-- Import
local QueueFrame = Crafty_QueueFrame
local QueueFrameList = Crafty_QueueFrameList
local Bag = Crafty_Bag
local Data = Crafty_Data
local L = Crafty_Localisation
local ShopFrame = Crafty_ShopFrame
local ShopFrameList = Crafty_ShopFrameList
local Tooltip = Crafty_Tooltip
local TradeSkill = Crafty_TradeSkill
local C_TradeSkillUI = C_TradeSkillUI
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetProfessionInfo = GetProfessionInfo
local HybridScrollFrame_CreateButtons = HybridScrollFrame_CreateButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local ShowUIPanel = ShowUIPanel
local UseItemByName = UseItemByName
local math = math
local pairs = pairs
local next = next
local table = table
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe
local _G = _G

-- TradeSkillUI
LoadAddOn("Blizzard_TradeSkillUI")
local TradeSkillFrame = TradeSkillFrame

-- Make sure we don't polute the global environment
setfenv(1, {})

-- The built list of recipes and headers to display
QueueFrameList.list = {}

function QueueFrameList:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:OnLoad()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
	--Data:Debug("QueueFrameList:OnEvent", event, ...)
	local unit, spellName = ...
	if unit == "player" then
	    self:CraftSucceeded(spellName)
	end
    elseif event == "UNIT_SPELLCAST_FAILED" or
	event == "UNIT_SPELLCAST_INTERRUPTED" then
	--Data:Debug("QueueFrameList:OnEvent", event, ...)
	local unit, spellName = ...
	if unit == "player" then
	    self:CraftFailed(spellName)
	end
    end
end

function QueueFrameList:OnLoad()
    HybridScrollFrame_CreateButtons(self, "Crafty_WindowRowTemplate", 0, 0)

    -- Hijack the redundant TradeSkillFrame exit button
    TradeSkillFrame.DetailsFrame.ExitButton:SetText("Queue")
    TradeSkillFrame.DetailsFrame.ExitButton:SetScript("OnClick", function ()
	ShowUIPanel(QueueFrame)
	self:QueueAdd()
    end)

    self:BuildList()

    self:SetScript("OnUpdate", self.OnUpdate)
end

local function HasReagents(tradeSkillID, itemID, intermediate)
    local item = _G.Crafty_Items[itemID]
    local crafts = 0
    if intermediate then
	crafts = _G.Crafty_QueueIntermediates[itemID]
    else
	local queueItem = _G.Crafty_Queue[tradeSkillID][itemID]
	if queueItem then
	    crafts = queueItem.crafts
	end
    end

    if item and item.reagents then
	for reagentID, reagentNum in pairs(item.reagents) do
	    local count = GetItemCount(reagentID, true)
	    if count < crafts * reagentNum then
		return false
	    end
	end
	return true
    else
	return nil
    end
end

function QueueFrameList:BuildList()
    wipe(self.list)

    local top = true
    local queueInter = _G.Crafty_QueueIntermediates
    for itemID in pairs(queueInter) do
	if top then
	    self.list[#self.list + 1] = {
		header = "Intermediates"
	    }
	    top = false
	end

	local item = _G.Crafty_Items[itemID]
	if item then
	    self.list[#self.list + 1] = {
		tradeSkillID = item.tradeSkillID,
		isIntermediate = true,
		itemID = itemID
	    }
	end
    end

    local queue = _G.Crafty_Queue
    for tradeSkillID in pairs(queue) do
	if top then
	    top = false
	else
	    self.list[#self.list + 1] = {
		space = true
	    }
	end
	self.list[#self.list + 1] = {
	    header = tradeSkillID
	}
	for itemID in pairs(queue[tradeSkillID]) do
	    self.list[#self.list + 1] = {
		tradeSkillID = tradeSkillID,
		itemID = itemID
	    }
	end
    end
end

function QueueFrameList:SelectedRemoved(button, lastButton)
    button.SelectedTexture:Hide()
    if lastButton then
	self.selected = lastButton
	lastButton.SelectedTexture:Show()
    else
	self.selected = nil
    end
end

local timer = 0

function QueueFrameList:OnUpdate(elapsed)
    if not TradeSkill.open then return end

    local offset = HybridScrollFrame_GetOffset(self)
    local lastButton
    for i = 1, #self.buttons do
	local button = self.buttons[i]
	local listItem = self.list[offset + i]
	if listItem then
	    if listItem.header then
		local headerIsString = (type(listItem.header) == "string")
		local name = ""
		local tradeSkill = _G.Crafty_TradeSkills[listItem.header]
		if tradeSkill then
		   name = tradeSkill.name
		end
		local text = headerIsString and listItem.header or name
		local colour = (headerIsString or listItem.header == 
		    TradeSkill.tradeSkillID) and Data.colour.white or 
		    Data.colour.greyMid
		button.listIndex = nil
		button.Text:SetText(text)
		button.Text:SetTextColor(unpack(colour))
		button.Count:Hide()
		button:Show()

		if button == self.selected then
		    self:SelectedRemoved(button, lastButton)
		end
	    elseif listItem.space then
		button:Hide()

		if button == self.selected then
		    self:SelectedRemoved(button, lastButton)
		end
	    else
		local queueNum = listItem.isIntermediate and
		    _G.Crafty_QueueIntermediates[listItem.itemID] or
		_G.Crafty_Queue[listItem.tradeSkillID][listItem.itemID].crafts
		if queueNum then
		    local itemName = GetItemInfo(listItem.itemID)
		    if itemName then
			button.listIndex = offset + i

			local colour
			local hasReagents = HasReagents(listItem.tradeSkillID, 
			    listItem.itemID, listItem.isIntermediate)
			if button.highlight or self.selected == button then
			    colour = hasReagents and Data.colour.green or 
				Data.colour.red
			else
			    colour = hasReagents and Data.colour.greenMid or 
				Data.colour.redMid
			end
			textureColour = hasReagents and Data.colour.greenMid or 
			    Data.colour.redMid
			button.Text:SetText("  " .. itemName)
			button.Text:SetTextColor(unpack(colour))
			button.SelectedTexture:SetVertexColor(
			    unpack(textureColour))
			button.Count:SetText(tostring(queueNum))
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
	    end
	else
	    -- Check if selected button has been removed
	    if button == self.selected then
		self:SelectedRemoved(button, lastButton)
	    end
	    button:Hide()
	end
    end

    local rowHeight = self.buttons[1]:GetHeight()
    local height = self:GetHeight()
    HybridScrollFrame_Update(self, #self.list * rowHeight, height)
end

-- Temporary list of all intermediates required
local inters = {}

-- Check for intermediate crafts
local function CheckForIntermediates(forProfit)
    wipe(_G.Crafty_QueueIntermediates)
    wipe(inters)

    -- Get the required intermediates
    local queue = _G.Crafty_Queue
    for tradeSkillID in pairs(queue) do
	for itemID in pairs(queue[tradeSkillID]) do
	    local item = _G.Crafty_Items[itemID]
	    if item and item.reagents then
		for reagentID, reagentNum in pairs(item.reagents) do
		    local reagent = _G.Crafty_Items[reagentID]
		    -- Intermediate craft
		    if reagent and reagent.reagents then
			local total = reagentNum * 
			    queue[tradeSkillID][itemID].crafts
			if inters[reagentID] then
			    inters[reagentID] = inters[reagentID] + total
			else
			    inters[reagentID] = total
			end
		    end
		end
	    end
	end
    end

    -- Take off what we do have and add to intermediate queue
    for itemID in pairs(inters) do
	local item = _G.Crafty_Items[itemID]
	if item and item.reagents and item.tradeSkillID and item.numProduced 
	    then
	    -- Include what's already in the queue(s)
	    local itemNum = inters[itemID]
            local queueItem
            if queue[item.tradeSkillID] then
                queueItem = queue[item.tradeSkillID][itemID]
            end
	    local queueNum = queueItem and
		queueItem.crafts * item.numProduced or 0
	    local itemNeeded = queueItem and queueItem.needed or 0
	    local count = GetItemCount(itemID, true) + queueNum - itemNeeded
	    local make = itemNum - count
	    if make > 0 then
		local cost = Data:CraftingCost(itemID)
		local minBuyout = item.minBuyout
		-- For profit only queue if none on AH or profitable
		if not forProfit or (forProfit and cost and minBuyout and 
		    (minBuyout == -1 or minBuyout - cost > 0)) then
		    local crafts = math.ceil(make / item.numProduced)
		    -- Check if it exists already and update
		    local interItem = _G.Crafty_QueueIntermediates[itemID]
		    if interItem then
			_G.Crafty_QueueIntermediates[itemID] = interItem +
			    crafts
		    else
			_G.Crafty_QueueIntermediates[itemID] = crafts
		    end
		end
	    end
	end
    end
end

-- Add an item to the queue
function QueueFrameList:QueueItem(tradeSkillID, itemID, crafts, needed)
    local queue = _G.Crafty_Queue
    if queue[tradeSkillID] then
	-- Check if it exists already and update
	local queueItem = queue[tradeSkillID][itemID]
	if queueItem then
	    local craftsTotal = queueItem.crafts + crafts
	    local neededTotal = queueItem.needed + needed
	    _G.Crafty_Queue[tradeSkillID][itemID].crafts = craftsTotal
	    _G.Crafty_Queue[tradeSkillID][itemID].needed = neededTotal
	    return
	end
    else
	_G.Crafty_Queue[tradeSkillID] = {}
    end

    _G.Crafty_Queue[tradeSkillID][itemID] = { crafts = crafts, needed = needed }
end

-- Queue items that are profitable
function QueueFrameList:QueueProfitable()
    if not TradeSkill.open then return end

    local tradeSkillID = TradeSkill.tradeSkillID
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    local recipeInfo = {}
    for i = 1, #recipeIDs do
	local recipeID = recipeIDs[i]
	C_TradeSkillUI.GetRecipeInfo(recipeID, recipeInfo)
	if recipeInfo.learned then
	    local itemID = TradeSkill:GetItemInfoFromRecipeID(recipeID)
	    local item = _G.Crafty_Items[itemID]
	    if item and not item.isBoP and item.stackSize and 
		item.stackSize > 0 and item.stackNum and item.stackNum > 0 and 
		item.minBuyout and item.reagents then
		local _, isProfitable = Data:GetProfit(itemID, true)
		if isProfitable then
		    -- Include what's already in the queue
		    local queueNum = 0
		    if _G.Crafty_Queue[tradeSkillID] and 
			_G.Crafty_Queue[tradeSkillID][itemID] then
			queueNum = _G.Crafty_Queue[tradeSkillID][itemID].crafts
		    end
		    local count = GetItemCount(itemID, true) + 
			queueNum * item.numProduced
		    local needed = item.stackSize * item.stackNum
		    if count < needed then
			local make = needed - count
			local crafts = math.ceil(make / item.numProduced)
			self:QueueItem(tradeSkillID, itemID, crafts, make)
		    end
		end
	    end
	end
    end
    CheckForIntermediates(true)

    self:BuildList()
end

function QueueFrameList:QueueClear()
    wipe(_G.Crafty_Queue)
    wipe(_G.Crafty_QueueIntermediates)
    wipe(self.list)
    if self.selected then
	self.selected.SelectedTexture:Hide()
	self.selected = nil
    end
end

function QueueFrameList:ButtonOnEnter(button)
    if not button.listIndex then return end
    local listItem = self.list[button.listIndex]
    if not listItem or not listItem.itemID then return end

    -- Tooltip
    local rowHeight = self.buttons[1]:GetHeight()
    local _, itemLink = GetItemInfo(listItem.itemID)
    if itemLink then
	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT", 0, rowHeight)
	GameTooltip:SetHyperlink(itemLink)
    else
	return
    end

    local queueNum = listItem.isIntermediate and
	_G.Crafty_QueueIntermediates[listItem.itemID] or
	_G.Crafty_Queue[listItem.tradeSkillID][listItem.itemID].crafts
    Tooltip:AddPrice(GameTooltip, listItem.itemID, false, queueNum)

    local item = _G.Crafty_Items[listItem.itemID]
    if item and item.reagents then
	GameTooltip:AddLine(" ")
	GameTooltip:AddLine("Reagents".. (queueNum > 1 and " (x" .. queueNum  
	    .. ")" or "") .. ":")
	for reagentID, num in pairs(item.reagents) do
	    local _, itemLink = GetItemInfo(reagentID)
	    if itemLink then
		-- true means include bank
		local count = GetItemCount(reagentID, true)
		local total = num * queueNum
		local colour = (count < total) and Data.colour.red or 
		    Data.colour.green
		GameTooltip:AddDoubleLine(itemLink .. " ", 
		    count .. "/" .. total, nil, nil, nil, unpack(colour))
	    end
	end
	local total = item.numProduced * queueNum
	if total > queueNum then
	    GameTooltip:AddLine(" ")
	    GameTooltip:AddDoubleLine("Total produced:", total, nil, nil, nil, 
		unpack(Data.colour.white))
	end
    end

    GameTooltip:Show()
    button.highlight = true
end

function QueueFrameList:ButtonOnLeave(button)
    GameTooltip:Hide()
    button.highlight = nil
end

local function RemoveItemFromQueue(tradeSkillID, itemID)
    local queue = _G.Crafty_Queue[tradeSkillID][itemID]
    if queue then
	_G.Crafty_Queue[tradeSkillID][itemID] = nil
	-- Remove profession if this is the last item
	if next(_G.Crafty_Queue[tradeSkillID]) == nil then
	    _G.Crafty_Queue[tradeSkillID] = nil
	end
    else
	local queueInter = _G.Crafty_QueueIntermediates[itemID]
	if queueInter then
	    _G.Crafty_QueueIntermediates[itemID] = nil
	end
    end
end

function QueueFrameList:ButtonOnClick(button, mouseButton)
    if mouseButton == "LeftButton" then
	if button.listIndex then
	    local listItem = self.list[button.listIndex]
	    if not listItem or listItem.header or listItem.space then
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
		RemoveItemFromQueue(listItem.tradeSkillID, listItem.itemID)
		CheckForIntermediates(true)
		self:BuildList()
		self:ButtonOnEnter(button)
	    end
	end
    end
end

function QueueFrameList:QueueAdd()
    if not TradeSkill.open then return end

    local recipeID = TradeSkillFrame.DetailsFrame.selectedRecipeID
    local itemID = TradeSkill:GetItemInfoFromRecipeID(recipeID)
    local num = TradeSkillFrame.DetailsFrame.CreateMultipleInputBox:GetValue()
    local item = _G.Crafty_Items[itemID]
    if item then
	self:QueueItem(TradeSkill.tradeSkillID, itemID, num, item.numProduced)
	CheckForIntermediates(false)
	self:BuildList()
	TradeSkillFrame.DetailsFrame.CreateMultipleInputBox:ClearFocus()
    end
end

function QueueFrameList:QueueCraft()
    if not TradeSkill.open then return end

    if self.selected and self.selected.listIndex then
	local listItem = self.list[self.selected.listIndex]
	local queueNum = listItem.isIntermediate and
	    _G.Crafty_QueueIntermediates[listItem.itemID] or
	    _G.Crafty_Queue[listItem.tradeSkillID][listItem.itemID].crafts
	if queueNum then
	    self:CraftItem(listItem.tradeSkillID, listItem.itemID, queueNum)
	end
    end
end

function QueueFrameList:RegisterSpellcast()
    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:RegisterEvent("UNIT_SPELLCAST_FAILED")
    self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
end

function QueueFrameList:UnregisterSpellcast()
    self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
    self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
end

function QueueFrameList:CraftItem(tradeSkillID, itemID, num)
    if not TradeSkill.open  or TradeSkill.tradeSkillID ~= tradeSkillID then 
	return end

    item = _G.Crafty_Items[itemID]
    if item then
	recipeID = item.recipeID
	if recipeID then
	    C_TradeSkillUI.CraftRecipe(recipeID, num)
	    if Data.enchantScrolls[recipeID] then
		UseItemByName(L["Enchanting Vellum"])
	    end
	    self.craftingItemID = itemID
	    self.craftingNum = num
	    self.craftingItemName = Data:GetSpellName(itemID)
	    self:RegisterSpellcast()
	end
    end
end

function QueueFrameList:CraftSucceeded(spellName)
    if spellName == self.craftingItemName then
	local itemID = self.craftingItemID
	-- Check intermediates
	local interItem = _G.Crafty_QueueIntermediates[itemID]
	if interItem then
	    _G.Crafty_QueueIntermediates[itemID] = interItem - 1
	    if _G.Crafty_QueueIntermediates[itemID] == 0 then
		_G.Crafty_QueueIntermediates[itemID] = nil
		self:BuildList()
	    end
	else
	    local item = _G.Crafty_Items[itemID]
	    if item then
		local tradeSkillID = item.tradeSkillID
		local queueItem = _G.Crafty_Queue[tradeSkillID][itemID]
		if queueItem then
		    _G.Crafty_Queue[tradeSkillID][itemID].crafts = 
			queueItem.crafts - 1
		    if _G.Crafty_Queue[tradeSkillID][itemID].crafts == 0 then
			RemoveItemFromQueue(tradeSkillID, itemID)
			self:BuildList()
		    end
		end
	    end
	end

	self.craftingNum = self.craftingNum - 1
	if self.craftingNum == 0 then
	    self.craftingItemName = nil
	    self:UnregisterSpellcast()
	end
    end
end

function QueueFrameList:CraftFailed(spellName)
    if spellName == self.craftingItemName then
	self.craftingItemName = nil
	self:UnregisterSpellcast()
    end
end

function QueueFrameList:OpenShop()
    ShopFrameList:GetMats()
    ShowUIPanel(ShopFrame)
end
