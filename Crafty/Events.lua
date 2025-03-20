--
-- Events Module
--
-- Frames deal with their own events (mostly)
--

-- Import
local AH = Crafty_AH
local AHFrameList = Crafty_AHFrameList
local Data = Crafty_Data
local Wait = Crafty_Wait
local QueueFrame = Crafty_QueueFrame
local ScanTip = Crafty_ScanningTooltip
local ShowUIPanel = ShowUIPanel
local TradeSkill = Crafty_TradeSkill
local CreateFrame = CreateFrame
local ERR_AUCTION_REMOVED = ERR_AUCTION_REMOVED
local ERR_AUCTION_STARTED = ERR_AUCTION_STARTED
local ERR_AUCTION_WON_S = ERR_AUCTION_WON_S
local hooksecurefunc = hooksecurefunc
local type = type

-- Make sure we don't polute the global environment
setfenv(1, {})

local function MatchMsg(msg, global)
    -- Remove pattern matching
    global = global:gsub("%%s", "")
    return msg:find(global)
end

local function HandleEvent(self, event, ...)
    --Data:Debug("HandleEvent", event)
    if event == "ADDON_LOADED" then
	self:UnregisterEvent("ADDON_LOADED")
	AH:OnLoad()
	Data:OnLoad()
	ScanTip:Create()
    elseif event == "PLAYER_ENTERING_WORLD" then
	self:UnregisterEvent("PLAYER_ENTERING_WORLD")
	TradeSkill:OnLoad()
    elseif event == "TRADE_SKILL_SHOW" then
	self:UnregisterEvent("TRADE_SKILL_SHOW")
	TradeSkill:OnOpen()
	-- Don't open Queue when AH is open as there is no room and causes a bug
	if AH.open then
	    -- NOOP
	else
	    ShowUIPanel(QueueFrame)
	end
	self:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
	self:RegisterEvent("TRADE_SKILL_CLOSE")
    elseif event == "TRADE_SKILL_LIST_UPDATE" then
	if TradeSkill.open then
	    TradeSkill:DetectChange()
	    if TradeSkill.scan then
		TradeSkill:Scan()
	    end
	end
    elseif event == "TRADE_SKILL_CLOSE" then
	self:UnregisterEvent("TRADE_SKILL_CLOSE")
	self:UnregisterEvent("TRADE_SKILL_LIST_UPDATE")
	TradeSkill:OnClose()
	self:RegisterEvent("TRADE_SKILL_SHOW")
    elseif event == "AUCTION_HOUSE_SHOW" then
	self:UnregisterEvent("AUCTION_HOUSE_SHOW")
	AH:OnOpen()
	self:RegisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:RegisterEvent("AUCTION_HOUSE_CLOSED")
	self:RegisterEvent("CHAT_MSG_SYSTEM")
    elseif event == "AUCTION_ITEM_LIST_UPDATE" then
	if AH.open and AH.scanningQuery then
	    AH:OnListUpdate()
	end
    elseif event == "AUCTION_HOUSE_CLOSED" then
	self:UnregisterEvent("AUCTION_HOUSE_CLOSED")
	self:UnregisterEvent("AUCTION_ITEM_LIST_UPDATE")
	self:UnregisterEvent("CHAT_MSG_SYSTEM")
	-- Can fire twice
	if AH.open then 
	    AH:OnClose()
	    AHFrameList:OnClose()
	end
	self:RegisterEvent("AUCTION_HOUSE_SHOW")
    elseif event == "CHAT_MSG_SYSTEM" then
	local arg1 = ...
	if arg1 == ERR_AUCTION_REMOVED then
	    AH:OnAuctionCancel()
	elseif MatchMsg(arg1, ERR_AUCTION_WON_S) then
	    AH:OnAuctionWon()
	elseif arg1 == ERR_AUCTION_STARTED then
	    AHFrameList:OnAuctionCreated()
	end
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("TRADE_SKILL_SHOW")
--frame:RegisterEvent("NEW_RECIPE_LEARNED") -- arg1 = recipeID
frame:RegisterEvent("AUCTION_HOUSE_SHOW")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", HandleEvent)
