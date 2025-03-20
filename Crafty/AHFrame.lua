--
-- AH Frame Module
--

-- Import
local AHFrame = Crafty_AHFrame
local AHFrameCreateText = Crafty_AHFrameCreateText
local AHFrameProgressText = Crafty_AHFrameProgressText
local AHFrameList = Crafty_AHFrameList
local AHFrameListActionSort = Crafty_AHFrameListActionSort
local AHFrameListCreate = Crafty_AHFrameListCreate
local AHFrameListPriceSort = Crafty_AHFrameListPriceSort
local AHFrameListRaritySort = Crafty_AHFrameListRaritySort
local AHFrameListSellerSort = Crafty_AHFrameListSellerSort
local AHFrameListScan = Crafty_AHFrameListScan
local AHFrameListStackNumSort = Crafty_AHFrameListStackNumSort
local AHFrameListStackSizeSort = Crafty_AHFrameListStackSizeSort
local AHFrameListStop = Crafty_AHFrameListStop
local AH = Crafty_AH
local Bag = Crafty_Bag
local Data = Crafty_Data
local Tooltip = Crafty_Tooltip
local TradeSkill = Crafty_TradeSkill
local Wait = Crafty_Wait
local ClearCursor = ClearCursor
local CreateFrame = CreateFrame
local GameTooltip = GameTooltip
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local HybridScrollFrame_CreateButtons = HybridScrollFrame_CreateButtons
local HybridScrollFrame_GetOffset = HybridScrollFrame_GetOffset
local HybridScrollFrame_Update = HybridScrollFrame_Update
local PanelTemplates_SetNumTabs = PanelTemplates_SetNumTabs
local PanelTemplates_SetTab = PanelTemplates_SetTab
local PickupContainerItem = PickupContainerItem
local hooksecurefunc = hooksecurefunc
local _G = _G
local math = math
local pairs = pairs
local tostring = tostring
local type = type
local unpack = unpack
local wipe = wipe

-- AuctionUI
LoadAddOn("Blizzard_AuctionUI")
local AuctionFrame = AuctionFrame
local AuctionFrameBot = AuctionFrameBot
local AuctionFrameBotLeft = AuctionFrameBotLeft
local AuctionFrameBotRight = AuctionFrameBotRight
local AuctionFrameMoneyFrame = AuctionFrameMoneyFrame
local AuctionFrameTab3 = AuctionFrameTab3
local AuctionFrameTab_OnClick = AuctionFrameTab_OnClick
local AuctionFrameTop = AuctionFrameTop
local AuctionFrameTopLeft = AuctionFrameTopLeft
local AuctionFrameTopRight = AuctionFrameTopRight
local ClickAuctionSellItemButton = ClickAuctionSellItemButton
local SetAuctionsTabShowing = SetAuctionsTabShowing
local StartAuction = StartAuction

-- Make sure we don't polute the global environment
setfenv(1, {})

-- Build list of items to display
AHFrameList.list = {}
-- Information about the stock we have
AHFrameList.stock = {}

local PROGRESS_CLOSE_DELAY = 1  -- How to long to leave "Created auction" up

local scanNoProfit = 1
local scanNoStock  = 2
local scanUndercut = 3
local scanNoSeller = 4

-- Reasons for actions
local scanReasons = {
    [scanNoProfit] = {
	text = "Not enough profit",
	colourNormal = Data.colour.redMid,
	colourHighlight = Data.colour.red
    },
    [scanNoStock] = {
	text = "Not enough stock in bags",
	colourNormal = Data.colour.yellowMid,
	colourHighlight = Data.colour.yellow
    },
    [scanUndercut] = {
	text = "Undercutting competition",
	colourNormal = Data.colour.greenMid,
	colourHighlight = Data.colour.green
    },
    [scanNoSeller] = {
	text = "No competition",
	colourNormal = Data.colour.greenMid,
	colourHighlight = Data.colour.green
    }
}

function AHFrameList:OnEvent(event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	self:OnLoad()
    end
end

function AHFrameList:OnLoad()
    HybridScrollFrame_CreateButtons(self, "Crafty_AHRowTemplate")

    -- Add Crafty Tab
    self.tab = AuctionFrame.numTabs + 1
    local button = CreateFrame("Button", "AuctionFrameTab" .. self.tab, 
	AuctionFrame, "AuctionTabTemplate")
    button:SetID(self.tab)
    button:SetText("Crafty")
    button:SetPoint("LEFT", "AuctionFrameTab" .. self.tab - 1, "RIGHT", -8, 0)
    PanelTemplates_SetNumTabs(AuctionFrame, self.tab)
    -- Avoid some errors
    AuctionFrameTab_OnClick(AuctionFrameTab3)

    -- Disable sort arrows (for now!)
    AHFrameListRaritySort.Arrow:SetShown(false)
    AHFrameListStackNumSort.Arrow:SetShown(false)
    AHFrameListStackSizeSort.Arrow:SetShown(false)
    AHFrameListPriceSort.Arrow:SetShown(false)
    AHFrameListSellerSort.Arrow:SetShown(false)
    AHFrameListActionSort.Arrow:SetShown(false)

    self:EnableButton()
end

function AHFrameList:EnableButton()
    AHFrameListScan:Enable()
    AHFrameListStop:Disable()
    AHFrameProgressText:SetText(" ")
end

function AHFrameList:DisableButton()
    AHFrameListScan:Disable()
    AHFrameListStop:Enable()
end

function AHFrameList:OnClose()
    self:StopScan()
end

function AHFrameList:StopScan()
    AH:StopScan()
    self:EnableButton()
end

hooksecurefunc("AuctionFrameTab_OnClick", function (self)
    local index = self:GetID()
    if (index == AHFrameList.tab) then
	-- Based on Bid tab
	AuctionFrameTopLeft:SetTexture(
	    "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-TopLeft")
	AuctionFrameTop:SetTexture(
	    "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Top")
	AuctionFrameTopRight:SetTexture(
	    "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-TopRight")
	AuctionFrameBotLeft:SetTexture(
	    "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotLeft")
	AuctionFrameBot:SetTexture(
	    "Interface\\AuctionFrame\\UI-AuctionFrame-Auction-Bot")
	AuctionFrameBotRight:SetTexture(
	    "Interface\\AuctionFrame\\UI-AuctionFrame-Bid-BotRight")
	AHFrame:Show()
	-- *Cough* Auctionator
	AuctionFrameMoneyFrame:Show()
	SetAuctionsTabShowing(false)
    else
	AHFrame:Hide()
    end
end)

function AHFrameList:BuildList()
    if not AH.open then return end

    wipe(self.list)
    for itemID in pairs(self.stock) do
	self.list[#self.list + 1] = itemID
    end
end

local function SetProgressText(num, total)
    AHFrameProgressText:SetText("Scanning " .. num .. " of " .. total ..  
	" auctions")
end

-- Scan for profitable stock, in bags
function AHFrameList:Scan()
    if not AH.open then return end

    wipe(self.stock)

    local items = _G.Crafty_Items
    for itemID in pairs(items) do
	local item = items[itemID]
	local hasTradeSkill = false
	if item and item.tradeSkillID then
	    -- Limit scan to professions this char has
	    hasTradeSkill = TradeSkill:HasTradeSkill(item.tradeSkillID)
	end
	if hasTradeSkill and item and item.stackNum and item.stackNum > 0 and 
	    item.stackSize and item.stackSize > 0 and item.minBuyout and 
	    item.reagents then
	    -- Post if profitable or none on AH
	    local _, isProfitable = Data:GetProfit(itemID, true)
	    if isProfitable then
		-- Just check bags
		local count = GetItemCount(itemID, false)
		-- As long as we have at least one stack
		if count >= item.stackSize then
		    self.stock[itemID] = { reason = scanUndercut }
		    AH.list[#AH.list + 1] = itemID
		else
		    self.stock[itemID] = { reason = scanNoStock }
		end
	    else
		self.stock[itemID] = { reason = scanNoProfit }
	    end
	end
    end

    local total = #AH.list
    if total > 0 then

	SetProgressText(1, total)
	self:DisableButton()
	AH.stop = false
	AH:ScanList(function(itemID, seller, buyoutEach)
	    if type(itemID) ~= "number" then return end

	    -- This item hasn't been removed yet
	    local left = #AH.list - 1

	    local item = _G.Crafty_Items[itemID]
	    if item then
		if buyoutEach then
		    self.stock[itemID].seller = seller
		    self.stock[itemID].price = buyoutEach * item.stackSize - 1
		else
		    -- No competition
		    local cost = Data:CraftingCost(itemID)
		    if cost then
			self.stock[itemID].seller = "None"
			self.stock[itemID].reason = scanNoSeller
			self.stock[itemID].price = cost * item.stackSize * 
			    Data.ProfitMarkup
			self:BuildList()
		    end
		end
	    end

	    if left == 0 then
		self:EnableButton()
	    else
		SetProgressText(total - left + 1, total)
	    end
	end)
    end

    self:BuildList()
end

function AHFrameList:Refresh()
    if not AH.open then return end

    local offset = HybridScrollFrame_GetOffset(self)

    for i = 1, #self.buttons do
	local button = self.buttons[i]
	local itemID = self.list[offset + i]
	if itemID then
	    local _, itemLink = GetItemInfo(itemID)
	    if itemLink then
		local stockItem = self.stock[itemID]
		if stockItem and stockItem.reason then
		    local item = _G.Crafty_Items[itemID]
		    local reason = scanReasons[stockItem.reason].text
		    local colour
		    if button.highlight then
			colour = scanReasons[stockItem.reason].colourHighlight
		    else
			colour = scanReasons[stockItem.reason].colourNormal
		    end
		    local textureColour = 
			scanReasons[stockItem.reason].colourNormal

		    if self.selected == button then
			if not AH:IsScanRunning() and 
			    (stockItem.reason == scanUndercut or 
			    stockItem.reason == scanNoSeller) then
			    AHFrameListCreate:Enable()
			else
			    AHFrameListCreate:Disable()
			end
		    end

		    button.Item:SetText(itemLink)
		    if item and item.stackNum and item.stackSize then
			button.listIndex = offset + i
			button.StackNum:SetText(tostring(item.stackNum))
			button.StackNum:SetTextColor(unpack(Data.colour.white))
			button.StackSize:SetText(tostring(item.stackSize))
			button.StackSize:SetTextColor(unpack(Data.colour.white))
		    end
		    button.Seller:SetText(stockItem.seller)
		    button.Seller:SetTextColor(unpack(Data.colour.white))
		    if stockItem.price then
			button.Price:SetText(
			    Data:GetCoinTextureString(stockItem.price))
			button.Price:SetTextColor(
			    unpack(Data.colour.white))
		    else
			button.Price:SetText(" ")
		    end
		    button.Action:SetText(reason)
		    button.Action:SetTextColor(unpack(colour))
		    button.SelectedTexture:SetVertexColor(unpack(textureColour))
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
		button.SelectedTexture:Hide()
		if lastButton then
		    self.selected = lastButton
		    lastButton.SelectedTexture:Show()
		else
		    self.selected = nil
		end
	    end
	    button:Hide()
	end
    end

    local rowHeight = self.buttons[1]:GetHeight()
    local height = self:GetHeight()
    HybridScrollFrame_Update(self, #self.list * rowHeight, height)
end

function AHFrameList:ButtonOnClick(button, mouseButton)
    if not AH.open then return end

    if mouseButton == "LeftButton" then
	if button.listIndex then
	    local listItem = self.list[button.listIndex]
	    if not listItem then
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
    end
end

function AHFrameList:Create()
    if not AH.open then return end

    if self.selected and self.selected.listIndex then
	local itemID = self.list[self.selected.listIndex]
	local item = _G.Crafty_Items[itemID]
	local stockItem = self.stock[itemID]
	if item and stockItem and item.stackNum and item.stackSize then
	    local price = stockItem.price
	    if price then
		local bagID, slotID = Bag:FindItem(itemID)
		if bagID and slotID then
		    -- Just check bags
		    local count = GetItemCount(itemID, false)
		    local stacks = math.floor(count / item.stackSize)
		    stacks = stacks > item.stackNum and item.stackNum or stacks
		    ClearCursor() 
		    PickupContainerItem(bagID, slotID)
		    ClickAuctionSellItemButton()
		    ClearCursor()
		    StartAuction(price, price, Data.AH24Hours, item.stackSize, 
			stacks)
		end
	    end
	end
    end
end

function AHFrameList:OnAuctionCreated()
    AHFrameCreateText:SetText("Auction created")
    Wait:Start(PROGRESS_CLOSE_DELAY, AHFrameCreateText.SetText, 
	AHFrameCreateText, "")
end

function AHFrameList:ButtonOnEnter(button)
    if not button.listIndex then return end

    local itemID = self.list[button.listIndex]

    -- Tooltip
    local rowHeight = self.buttons[1]:GetHeight()
    local _, itemLink = GetItemInfo(itemID)
    if itemLink then
	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT", 0, rowHeight)
	GameTooltip:SetHyperlink(itemLink)
    else
	return
    end

    local item = _G.Crafty_Items[itemID]
    if item then
	local num = item.stackNum * item.stackSize
	Tooltip:AddPrice(GameTooltip, itemID, false, num)
    end

    GameTooltip:Show()
    button.highlight = true
end

function AHFrameList:ButtonOnLeave(button)
    GameTooltip:Hide()
    button.highlight = nil
end
