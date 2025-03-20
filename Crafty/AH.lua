--
-- Auction House Module
--

Crafty_AH = {}

-- Import
local AH = Crafty_AH
local Data = Crafty_Data
local L = Crafty_Localisation
local QueueFrameList = Crafty_QueueFrameList
local TradeSkill = Crafty_TradeSkill
local UI = Crafty_UI
local Wait = Crafty_Wait
local CancelAuction = CancelAuction
local CanSendAuctionQuery = CanSendAuctionQuery
local CreateFrame = CreateFrame
local FauxScrollFrame_GetOffset = FauxScrollFrame_GetOffset
local GetItemInfo = GetItemInfo
local GetAuctionItemInfo = GetAuctionItemInfo
local GetAuctionItemLink = GetAuctionItemLink
local GetAuctionSellItemInfo = GetAuctionSellItemInfo
local GetNumAuctionItems = GetNumAuctionItems
local GetSelectedAuctionItem = GetSelectedAuctionItem
local GetServerTime = GetServerTime
local IsAltKeyDown = IsAltKeyDown
local IsAuctionSortReversed = IsAuctionSortReversed
local MoneyInputFrame_SetCopper = MoneyInputFrame_SetCopper
local PlaceAuctionBid = PlaceAuctionBid
local PriceDropDown = PriceDropDown
local QueryAuctionItems = QueryAuctionItems
local SortAuctionItems = SortAuctionItems
local StaticPopup_Show = StaticPopup_Show
local UIDropDownMenu_SetSelectedValue = UIDropDownMenu_SetSelectedValue
local NUM_AUCTIONS_TO_DISPLAY = NUM_AUCTIONS_TO_DISPLAY
local hooksecurefunc = hooksecurefunc
local math = math
local pairs = pairs
local string = string
local type = type
local wipe = wipe
local _G = _G

-- AuctionUI
LoadAddOn("Blizzard_AuctionUI")
local AuctionFrame = AuctionFrame
local AuctionFrameAuctions = AuctionFrameAuctions
local AuctionFrameBrowse = AuctionFrameBrowse
local AuctionFrameAuctions_Update = AuctionFrameAuctions_Update
local AuctionFrame_SetSort = AuctionFrame_SetSort
local AuctionsCancelAuctionButton = AuctionsCancelAuctionButton
local AuctionsStackSizeEntry = AuctionsStackSizeEntry
local BrowseBidPrice = BrowseBidPrice
local BrowseButton1 = BrowseButton1
local BrowseBuyoutButton = BrowseBuyoutButton
local BrowseCurrentBidSort = BrowseCurrentBidSort
--local BrowseDropDown = BrowseDropDown
local BrowseDurationSort = BrowseDurationSort
local BrowseHighBidderSort = BrowseHighBidderSort
local BrowseLevelSort = BrowseLevelSort
local BrowseMinLevel = BrowseMinLevel
local BrowseMaxLevel = BrowseMaxLevel
local BrowseName = BrowseName
local BrowseNextPageButton = BrowseNextPageButton
local BrowsePrevPageButton = BrowsePrevPageButton
local BrowseQualitySort = BrowseQualitySort
local BrowseResetButton = BrowseResetButton
local BrowseScrollFrame = BrowseScrollFrame
local BrowseSearchButton = BrowseSearchButton
local BuyoutPrice = BuyoutPrice
local ExactMatchCheckButton = ExactMatchCheckButton
local GetEffectiveAuctionsScrollFrameOffset = 
    GetEffectiveAuctionsScrollFrameOffset
local GetEffectiveSelectedOwnerAuctionItemIndex = 
    GetEffectiveSelectedOwnerAuctionItemIndex
local IsUsableCheckButton = IsUsableCheckButton
local SetEffectiveSelectedOwnerAuctionItemIndex = 
    SetEffectiveSelectedOwnerAuctionItemIndex
local ShowOnPlayerCheckButton = ShowOnPlayerCheckButton
local StartPrice = StartPrice

-- Make sure we don't polute the global environment
setfenv(1, {})

local SCAN_DELAY = 0.3		-- Delay between AH scan attempts
local BATCH_DELAY = 0.1		-- Delay between batches of item processing
local BATCH_LIMIT = 200		-- Max number of items to process in one batch
local PRICE_TYPE_STACK = 2	-- For Auctions "per stack"
local PROGRESS_CLOSE_DELAY = 3	-- How long to leave "scan done" up
local NOTICE_CLOSE_DELAY = 10   -- How long to leave no data notice up
local GETALL_CD = 900		-- Cooldown of getAll scan, in seconds
local SECS_PER_MIN = 60
local BUYOUT_LIMIT = 100000000	-- Limit buyout button with no confirmation
local SELECT_DELAY = 0.1        -- How long to wait before selecting new Auction

local WARN_TEXT = Data.escapeColour.red .. "Warning:" .. Data.escapeColour.grey .. " If you have problems using the fast scan, ie disconnections or lockups, try the slow scan. This is enabled by holding the Alt key down whilst clicking the Scan button."

local SLOW_SCAN_TEXT = Data.escapeColour.yellow .. "Note:" .. Data.escapeColour.grey .. " Slow scan is limited to items from this character's professions that are being crafted for profit and reagents. This is so the scan can complete in a reasonable amount of time."

local NO_DATA_TEXT = Data.escapeColour.red .. "Notice:" .. Data.escapeColour.grey .. " You need to open your profession window(s) briefly before scanning the AH. This is so Crafty knows about all your recipes, this only needs to be done once for each character."

AH.list = {}			-- List of items to scan
AH.seen = {}			-- List of items seen in a scan
AH.open = false
AH.stop = false

local ownerButton, listButton	-- Track Browse and Auctions tab selection

function AH:EnableButtons()
    self.scanButton:Enable()
    self.stopButton:Disable()

    -- Enable AH interface
    BrowseSearchButton:Enable()
    BrowseResetButton:Enable()
    BrowsePrevPageButton:Enable()
    BrowseNextPageButton:Enable()
    BrowseQualitySort:Enable()
    BrowseLevelSort:Enable()
    BrowseDurationSort:Enable()
    BrowseHighBidderSort:Enable()
    BrowseCurrentBidSort:Enable()
    ExactMatchCheckButton:Enable()
    BrowseName:Enable()
    BrowseMinLevel:Enable()
    BrowseMaxLevel:Enable()
    --BrowseDropDown:Enable()
    IsUsableCheckButton:Enable()
    ShowOnPlayerCheckButton:Enable()
end

function AH:DisableButtons()
    self.scanButton:Disable()
    self.stopButton:Enable()
    self.progressFrame:Show()

    -- Disable AH interface
    BrowseSearchButton:Disable()
    BrowseResetButton:Disable()
    BrowsePrevPageButton:Disable()
    BrowseNextPageButton:Disable()
    BrowseQualitySort:Disable()
    BrowseLevelSort:Disable()
    BrowseDurationSort:Disable()
    BrowseHighBidderSort:Disable()
    BrowseCurrentBidSort:Disable()
    ExactMatchCheckButton:Disable()
    BrowseName:Disable()
    BrowseMinLevel:Disable()
    BrowseMaxLevel:Disable()
    -- Can't disable a drop down
    --BrowseDropDown:Disable()
    IsUsableCheckButton:Disable()
    ShowOnPlayerCheckButton:Disable()
end 

function AH:OnOpen()
    self.open = true
    self.stop = false
end

function AH:OnClose()
    self:StopScan()
    self.open = false
end

function AH:IsScanRunning()
    return (type(self.scanningScan) == "string")
end

function AH:StopScan()
    self.stop = true
    self.scanningScan = nil
    wipe(self.list)
    self:EnableButtons()
    self.progressFrame:Hide()
end

local function SetSort()
    -- Make sure we're sorting by unit price and the direction is right
    AuctionFrame_SetSort("list", "unitprice", false)
end

function AH:OnLoad()
    -- Move bid price across to the right
    BrowseBidPrice:ClearAllPoints()
    BrowseBidPrice:SetPoint("TOPRIGHT", "BrowseBidButton", "TOPLEFT")

    -- Browse Tab
    UI:CreateText("Crafty_ScanText", AuctionFrameBrowse, "GameFontNormalSmall",
	"Crafty:", "TOPLEFT", "AuctionFrameMoneyFrame", "TOPRIGHT", 4, -2)
    self.scanButton = UI:CreateButton("Crafty_ScanButton", 
	AuctionFrameBrowse, "Scan", 50, 22, "TOPLEFT", "Crafty_ScanText", 
	"TOPRIGHT", 0, 6, self.ScanAll, self)
    self.stopButton = UI:CreateButton("Crafty_StopButton", AuctionFrameBrowse, 
	"Stop", 50, 22, "TOPLEFT", "Crafty_ScanButton", "TOPRIGHT", 0, 0, 
	self.StopScan, self)
    self.stopButton:Disable()
    UI:CreateButton("Crafty_ShopButton", AuctionFrameBrowse, "Shop", 50, 22, 
	"TOPLEFT", "Crafty_StopButton", "TOPRIGHT", 0, 0, 
	QueueFrameList.OpenShop, QueueFrameList)

    -- Auctions Tab
    UI:CreateText("Crafty_UndercutText", AuctionFrameAuctions, 
	"GameFontNormalSmall", "Crafty:", "TOPLEFT", "AuctionFrameMoneyFrame", 
	"TOPRIGHT", 4, -2)
    UI:CreateButton("Crafty_UndercutButton", AuctionFrameAuctions, "Undercut", 
	80, 22, "TOPLEFT", "Crafty_UndercutText", "TOPRIGHT", 0, 6, 
	self.UndercutButton, self)
    self.undercutText = UI:CreateText("Crafty_AHUndercutText", 
	AuctionFrameAuctions, "GameFontNormalSmall", "", "TOPLEFT", 
	"Crafty_UndercutButton", "TOPRIGHT", 2, -6)

    -- Scan progress
    self.progressFrame = CreateFrame("Frame", "Crafty_AHProgressFrame", 
	AuctionFrameBrowse)
    self.progressFrame:SetFrameStrata("DIALOG")
    self.progressFrame:SetWidth(630)
    self.progressFrame:SetHeight(304)
    self.progressFrame:SetPoint("TOPLEFT", 190, -105)
    self.progressFrame:SetBackdrop({
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	tile = true, tileSize = 16, edgeSize = 16,
    })
    self.progressFrame:SetBackdropColor(0, 0, 0, 0.99)
    self.progressFrame.Text = UI:CreateText("Crafty_AHProgressText", 
	self.progressFrame, "GameFontNormal", "", "CENTER", 
	self.progressFrame, "CENTER", 0, 0)
    self.progressFrame.Warn = UI:CreateText("Crafty_AHProgressWarn", 
	self.progressFrame, "GameFontNormal", "", "TOP", 
	"Crafty_AHProgressText", "BOTTOM", 0, -32, nil, 400)

    -- Remove Cancel Auction popup
    AuctionsCancelAuctionButton:SetScript("OnClick", function ()
	local item = GetSelectedAuctionItem("owner")
	if item and item > 0 then
	    CancelAuction(item)
	end
    end)

    -- Remove Buyout popup, unless it's over the limit
    BrowseBuyoutButton:SetScript("OnClick", function (self)
	local buyout = AuctionFrame.buyoutPrice
	if buyout and buyout < BUYOUT_LIMIT then
	    local item = GetSelectedAuctionItem("list")
	    if item and item > 0 then
		PlaceAuctionBid("list", item, buyout)
	    end
	else
	    StaticPopup_Show("BUYOUT_AUCTION")
	    self:Disable()
	end
    end)

    SetSort()
    self:EnableButtons()
    self.progressFrame:Hide()
end

-- Track the selected buttons
hooksecurefunc("AuctionsButton_OnClick", function (button)
    ownerButton = button:GetID()
end)
hooksecurefunc("BrowseButton_OnClick", function (button)
    listButton = button:GetID()
end)

-- Import the hooked functions
local AuctionsButton_OnClick = _G.AuctionsButton_OnClick
local BrowseButton_OnClick = _G.BrowseButton_OnClick

-- Select another auction after cancel/buyout
function AH:SelectOwnerAuction()
    if ownerButton then
	local offset = GetEffectiveAuctionsScrollFrameOffset()
	-- Check if there is still an auction to select
	local name = GetAuctionItemInfo("owner", ownerButton + offset)
	if name then
	    -- NOOP
	else
	    if ownerButton == 1 then
		return
	    else
		ownerButton = ownerButton - 1
		-- Check if the only auctions left are sold
		local _, _, count = GetAuctionItemInfo("owner", ownerButton + 
		    offset)
		if count == 0 then
		    return
		end
	    end
	end
	local button = _G["AuctionsButton" .. ownerButton]
	AuctionsButton_OnClick(button)
    end
end
function AH:SelectListAuction()
    if listButton then
        local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
        -- Check if there is still an auction to select
        local name = GetAuctionItemInfo("list", listButton + offset)
        if name then
            -- NOOP
        else
            if listButton == 1 then
                return
            else
                listButton = listButton - 1
            end
        end
        local button = _G["BrowseButton" .. listButton]
        BrowseButton_OnClick(button)
    end
end

-- Select an auction when switching to the Auctions tab
hooksecurefunc("AuctionFrameTab_OnClick", function (self)
    local index = self:GetID()
    if (index == 3 and not ownerButton) then
        local offset = GetEffectiveAuctionsScrollFrameOffset()
	local id
	for i = 1, NUM_AUCTIONS_TO_DISPLAY do
	    -- Check if there is an auction to select
	    local name = GetAuctionItemInfo("owner", i + offset)
	    if name then
		-- Check if the auction is sold
		local _, _, count = GetAuctionItemInfo("owner", i + offset)
		if count == 0 then
		    -- NOOP
		else
		    id = i
		    break
		end
	    else
		return
	    end
	end
	if id then
	    AuctionsButton_OnClick(_G["AuctionsButton" .. id])
	end
    end
end)

--[[
function AH:OnAuctionCreated()
    -- Doesn't fix update bug
    AuctionFrameAuctions_Update()
end
--]]

-- Do a search for one item
function AH:SearchItem(item, exact)
    if self.stop or not self.open then return end

    -- Supports item to be either an itemID or itemName
    if type(item) == "number" then
	local itemName = GetItemInfo(item)
	if itemName then
	    item = itemName
	else
	    -- Not seen the item before so need to retry
	    --Data:Debug("AH:SearchItem", "Retrying GetItemInfo for", item)
	    Wait:Start(SCAN_DELAY, self.SearchItem, self, item, exact)
	    return
	end
    elseif type(item) == "string" then
	-- NOOP
    else
	return
    end

    if CanSendAuctionQuery() then
	-- Reset search
	BrowseResetButton:Click()
	if (exact and not ExactMatchCheckButton:GetChecked()) or 
	    (not exact and ExactMatchCheckButton:GetChecked()) then
	    ExactMatchCheckButton:Click()
	end
	-- Fill out the AH frame, rather than do a query, the result is 
	-- much nicer for the user!
	BrowseName:SetText(item)
	BrowseSearchButton:Click()
    else
	Wait:Start(SCAN_DELAY, self.SearchItem, self, item, exact)
	return
    end
end

function AH:HideProgress()
    -- If a scan has been started then cancel hiding the progress
    if self.scanningScan then
	-- NOOP
    else
	self.progressFrame:Hide()
    end
end

-- Do a fast or slow scan of whole AH
function AH:ScanAll()
    if not self.open then return end

    if TradeSkill:HasTradeSkillData() then
	self.stop = false
	if IsAltKeyDown() then
	    self.progressFrame.Warn:SetText(SLOW_SCAN_TEXT)
	    self:SlowScan()
	else
	    self.progressFrame.Warn:SetText(WARN_TEXT)
	    self:GetAll()
	end
    else
	self.progressFrame.Warn:SetText(NO_DATA_TEXT)
	self.progressFrame.Text:SetText("")
	self.progressFrame:Show()
	Wait:Start(NOTICE_CLOSE_DELAY, self.HideProgress, self)
    end
end

-- Fast scan
function AH:GetAll()
    if self.stop or not self.open then return end

    local canQuery, canQueryAll = CanSendAuctionQuery()
    if canQueryAll then
	if canQuery then
	    wipe(self.seen)
	    self:DisableButtons()
	    self.lastGetAll = GetServerTime()
	    self.progressFrame.Text:SetText(Data.escapeColour.green .. 
		"Starting fast scan")
	    
	    -- "name", minLevel, maxLevel, page, isUsable, qualityIndex, getAll,
	    -- exactMatch, filterData
	    QueryAuctionItems(nil, nil, nil, nil, nil, nil, true, nil, nil)
	    self.scanningScan = "getAll"
	    self.scanningQuery = true
	else
	    Wait:Start(SCAN_DELAY, self.GetAll, self)
	    return
	end
    else
	local text = Data.escapeColour.red .. "Fast scan on cooldown"
	local time
	if self.lastGetAll then
	    time = GETALL_CD - (GetServerTime() - self.lastGetAll)
	    if time > 0 then
		local mins = math.ceil(time / SECS_PER_MIN)
		text = text .. " for about " .. mins .. " |4minute:minutes;"
	    end
	end
	self.progressFrame.Text:SetText(text)
	self.progressFrame:Show()
	Wait:Start(PROGRESS_CLOSE_DELAY, self.HideProgress, self)
	return
    end
end

-- Remove the "of the" part of an item name, if it's Armor
local function GetAuctionName(itemName, itemType)
    if itemType == "Armor" then
	return itemName:gsub(L["of the .*"], "")
    else
	return itemName
    end
end

-- Get undercut price
function AH:Undercut()
    if self.stop or not self.open then return end

    -- Make sure price is per stack
    if AuctionFrameAuctions.priceType ~= PRICE_TYPE_STACK then
	AuctionFrameAuctions.priceType = PRICE_TYPE_STACK
	UIDropDownMenu_SetSelectedValue(PriceDropDown, PRICE_TYPE_STACK)
    end

    local itemName, _, _, _, _, _, _, _, num = GetAuctionSellItemInfo()
    local itemType
    if itemName then
	_, _, _, _, _, itemType = GetItemInfo(itemName)
    end
    if itemName and itemType then
	itemName = GetAuctionName(itemName, itemType)
	--Data:Debug("AH:Undercut", itemName)
	self.list = { itemName }
	self:ScanList(function(item, _, buyoutEach)

	    if buyoutEach then
		if item == itemName then
		    local stackSize = AuctionsStackSizeEntry:GetNumber()
		    local buyout = buyoutEach * 
		    (num > stackSize and stackSize or num) - 1
		    MoneyInputFrame_SetCopper(BuyoutPrice, buyout)
		    MoneyInputFrame_SetCopper(StartPrice, buyout)
		    self.undercutText:SetText("Filled in undercut price")
		    Wait:Start(PROGRESS_CLOSE_DELAY, self.undercutText.SetText,
			self.undercutText, "")
		end
	    else
		self.undercutText:SetText("No auctions to undercut")
		Wait:Start(PROGRESS_CLOSE_DELAY, self.undercutText.SetText,
		    self.undercutText, "")
	    end
	end)
    else
	-- If we've retried already then there is no item to sell
	if self.retry then
	    self.undercutText:SetText("")
	else
	    --Data:Debug("AH:Undercut", "Retrying GetAuctionSellItemInfo")
	    Wait:Start(SCAN_DELAY, self.Undercut, self)
	    self.retry = true
	    return
	end
    end
end

-- Undercut button
function AH:UndercutButton()
    self.stop = false
    self.retry = false
    self.undercutText:SetText("Getting undercut price")
    self:Undercut()
end

-- Query one item from a list
function AH:QueryItem(item)
    if self.stop or not self.open then return end

    -- Supports item to be either an itemID or itemName
    if type(item) == "number" then
	local itemName = GetItemInfo(item)
	if itemName then
	    item = itemName
	else
	    -- Not seen the item before so need to retry
	    --Data:Debug("AH:QueryItem", "Retrying GetItemInfo for", item)
	    Wait:Start(SCAN_DELAY, self.QueryItem, self, item)
	    return
	end
    elseif type(item) == "string" then
	-- NOOP
    else
	return
    end

    if CanSendAuctionQuery() then
	-- "name", minLevel, maxLevel, page, isUsable, qualityIndex, getAll, 
	-- exactMatch, filterData
	QueryAuctionItems(item, nil, nil, self.scanningPage, nil, nil, false, 
	    false, nil)
	self.scanningScan = "list"
	self.scanningQuery = true
    else
	Wait:Start(SCAN_DELAY, self.QueryItem, self, item)
	return
    end
end

-- Scan items in AH.list and callback with the AH data
function AH:ScanList(callback)
    if self.stop or not self.open then return end

    -- Order doesn't matter so go from the end for efficiency
    item = self.list[#self.list]
    if item then 
	SetSort()
	self.scanningCallback = callback
	self.scanningItem = item
	self.scanningPage = 0
	self:QueryItem(item)
    end
end

-- Get the prices for the ScanList search and start the next query
function AH:GetListPrices(batch, total)
    if self.stop or not self.open then return end

    local found = false

    for i = 1, batch do
	-- name, texture, count, quality, canUse, level, levelColHeader, minBid,
	-- minIncrement, buyoutPrice, bidAmount, highBidder, bidderFullName, 
	-- owner, ownerFullName, saleStatus, itemId, hasAllInfo
	local itemName, _, count, _, _, _, _, _, _, buyout, _, _, _, seller,
	    _, _, itemID = GetAuctionItemInfo("list", i)
	local _, _, _, _, _, itemType = GetItemInfo(itemID)
	    
	if itemID and itemName and itemType then
	    itemName = GetAuctionName(itemName, itemType)
	    --Data:Debug("AH:GetListPrices", itemName)
	    if itemID == self.scanningItem or itemName == self.scanningItem 
		then
		if count and count > 0 and buyout and buyout > 0 then
		    if seller then
			local buyoutEach = math.floor(buyout / count)
			-- If buyout is so low it could be rounded down to 0
			if buyoutEach == 0 then buyoutEach = 1 end
			local item = _G.Crafty_Items[itemID]
			if item and item.minBuyout then
			    _G.Crafty_Items[itemID].minBuyout = buyoutEach
			end
			self.scanningCallback(self.scanningItem, seller, 
			    buyoutEach)
			found = true
			break
		    else
			-- Assume we'll get the info on next update
			self.scanningQuery = true
			--[[
			Data:Debug("AH:GetListPrices", 
			    "Retrying GetAuctionItemInfo")
			--]]
			return
		    end
		end
	    end
	else
	    -- Assume we'll get the info on next update
	    self.scanningQuery = true
	    --Data:Debug("AH:GetListPrices", "Retrying GetAuctionItemInfo")
	    return
	end
    end

    local numPages = 0
    if batch > 0 then
	numPages = math.ceil(total / batch)
    end
    self.scanningPage = self.scanningPage + 1

    if not found and self.scanningPage > numPages - 1 then
	local _, itemLink = GetItemInfo(self.scanningItem)
	local itemID = Data:GetItemInfoFromLink(itemLink)
	local item = _G.Crafty_Items[itemID]
	if item and item.minBuyout then
	    _G.Crafty_Items[itemID].minBuyout = -1
	end
	self.scanningCallback(self.scanningItem, nil, nil)
    end

    if found or self.scanningPage > numPages - 1 then
	-- Next item
	self.list[#self.list] = nil
	if #self.list > 0 then
	    local item = self.list[#self.list]
	    self.scanningItem = item
	    self.scanningPage = 0
	    self:QueryItem(item)
	else
	    self.scanningScan = nil
	    --Data:Debug("AH:GetListPrices", "Scanning done")
	    return
	end
    else
	-- Next page
	self:QueryItem(self.scanningItem)
    end
end

function AH:SetProgressText(num, total)
    self.progressFrame.Text:SetText("Slow scanning " .. num ..  " of " .. 
	total ..  " items")
end

-- Do a slow scan, which is really just a ScanList of a big list
function AH:SlowScan()
    if self.stop or not self.open then return end

    local total = 0

    local items = _G.Crafty_Items
    for itemID in pairs(items) do
	local item = items[itemID]
	local hasTradeSkill = false
	if item and item.tradeSkillID then
	    -- Limit scan to professions this char has
	    hasTradeSkill = TradeSkill:HasTradeSkill(item.tradeSkillID)
	end
	-- Also limit to items we would want to stock for profit and reagents
	if item and ((hasTradeSkill and item.stackNum and item.stackNum > 0 and
	    item.stackSize and item.stackSize > 0 and item.minBuyout and 
	    item.reagents) or (not item.reagents and item.minBuyout)) then
	    self.list[#self.list + 1] = itemID
	end
    end
    total = #self.list

    if total > 0 then
	self:SetProgressText(1, total)
	self:DisableButtons()
	self:ScanList(function (itemID, _, _)

	    -- This item hasn't been removed yet
	    local left = #self.list - 1

	    if left == 0 then 
		self.scanningScan = nil
		self:EnableButtons()
		self.progressFrame.Text:SetText("Slow scanning finished (" .. 
		    total ..  " total)")
		Wait:Start(PROGRESS_CLOSE_DELAY, self.HideProgress, self)
		return
	    else
		self:SetProgressText(total - left + 1, total)
	    end
	end)
    end
end

-- Actually get the prices for a range of items on one page
function AH:GetPricesRange(first, last, singleItem)
    if self.stop or not self.open then return end

    for i = first, last do
	local _, _, total, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID = 
	    GetAuctionItemInfo("list", i)
	if itemID and total and buyout and total > 0 then
	    if buyout > 0 then
		local item = _G.Crafty_Items[itemID]
		if item and item.minBuyout then
		    local buyoutEach = math.ceil(buyout / total)
		    -- If buyout is so low it could be rounded down to 0
		    if buyoutEach == 0 then buyoutEach = 1 end
		    if not self.seen[itemID] or buyoutEach < item.minBuyout 
			then
			_G.Crafty_Items[itemID].minBuyout = buyoutEach
			self.seen[itemID] = true
		    end
		    if singleItem then
			break
		    end
		end
	    end
	else
	    -- itemID, total and buyout never appear to fail
	    --Data:Debug("AH:GetPricesRange", "Retrying GetAuctionItemInfo")
	    Wait:Start(SCAN_DELAY, self.GetPricesRange, self, first, last, 
		singleItem)
	    return
	end
    end
end

-- Break up fast scan item processing into batches
--   All 100k  - locked up :p
--   Batch 50  - small lock up then smooth
--   Batch 500 - some lock ups
--   Batch 250 - small lock ups
function AH:GetBatchPrices(first, num, total)
    if self.stop or not self.open then return end

    -- Check total as old items expire
    local _, newTotal = GetNumAuctionItems("list")
    -- Offset the scan
    local offset = newTotal - total
    if offset == 0 then
	-- NOOP
    else
	--Data:Debug("AH:GetBatchPrices", "Offset", offset)
	first = first + offset
    end

    local last = first + num - 1
    self.progressFrame.Text:SetText("Getting prices for items " .. first .. 
	" to " ..  last .. " (".. total .. " total)")
    self:GetPricesRange(first, last, false)

    local left = newTotal - last
    if left > 0 then
	Wait:Start(BATCH_DELAY, self.GetBatchPrices, self, last + 1,
	    left < BATCH_LIMIT and left or BATCH_LIMIT, newTotal)
	return
    else
	self.scanningScan = nil
	self:EnableButtons()
	self.progressFrame.Text:SetText("Fast scan finished (".. total .. 
	    " total)")
	Wait:Start(PROGRESS_CLOSE_DELAY, self.HideProgress, self)
	--Data:Debug("AH:GetBatchPrices", "Scanning done")

	-- Debug: Check for missed items, really none on AH?
	--[[
	local items = _G.Crafty_Items
	for itemID in pairs(items) do
	    local item = items[itemID]
	    if self.seen[itemID] or (Data.vendorIDs[itemID] or (item and 
		item.isBoP)) then
		-- NOOP
	    else
		self.list[#self.list + 1] = itemID
	    end
	end
	if #self.list > 0 then
	    self:ScanList(function(itemID, seller, buyoutEach)

		if seller == nil and buyoutEach == nil then
		    -- None on AH, as expected
		else
		    Data:Debug("AH:GetBatchPrices", "Missed item", itemID, 
			"seller", seller, "buyoutEach", buyoutEach)
		end
	    end)
	end
	--]]
    end
end

-- AH List Update
function AH:OnListUpdate()
    if not self.open then return end

    self.scanningQuery = nil
    if self.stop then
	self.stop = false
	return
    end

    local batch, total = GetNumAuctionItems("list")
    -- getAll scan
    if self.scanningScan == "getAll" then
	self:GetBatchPrices(1, batch < BATCH_LIMIT and batch or BATCH_LIMIT, 
	    total)
    -- Item list scan
    elseif self.scanningScan == "list" then
	self:GetListPrices(batch, total)
    -- Update prices after a search
    elseif self.scanningScan == "search" then
	-- Select an auction
	if listButton then
	    -- NOOP
	else
	    local offset = FauxScrollFrame_GetOffset(BrowseScrollFrame)
	    -- Check if there is an auction to select
	    local name = GetAuctionItemInfo("list", 1 + offset)
	    if name then
		BrowseButton_OnClick(BrowseButton1)
	    end
	end

	self:GetPricesRange(1, batch < BATCH_LIMIT and batch or BATCH_LIMIT, 
	    true)
    end
end

hooksecurefunc("AuctionFrameBrowse_Search", function ()
    -- Always respond so we can select an Auction
    AH.scanningQuery = true
    AH.scanningScan = "search"
    AH.stop = false
    listButton = nil
    wipe(AH.seen)
end)

-- Stop buttons being enabled during getAll scan
-- BrowseSearchButton_OnUpdate doesn't appear to be used!
--[[
hooksecurefunc("BrowseSearchButton_OnUpdate", function ()
    if AH.scanningScan == "getAll" then
	AH:DisableButtons()
    end
end)
--]]

function AH:OnAuctionCancel()
    -- Need a short delay for Auctions tab to update
    Wait:Start(SELECT_DELAY, AH.SelectOwnerAuction, AH)
end

function AH:OnAuctionWon()
    -- Select a new auction
    Wait:Start(SELECT_DELAY, AH.SelectListAuction, AH)
end
