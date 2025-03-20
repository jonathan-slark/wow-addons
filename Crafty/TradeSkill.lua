--
-- TradeSkill Module
--

Crafty_TradeSkill = {}

-- Import
local TradeSkill = Crafty_TradeSkill
local Data = Crafty_Data
local QueueFrame = Crafty_QueueFrame
local QueueFrameList = Crafty_QueueFrameList
local UI = Crafty_UI
local Wait = Crafty_Wait
local C_TradeSkillUI = C_TradeSkillUI
local CreateFrame = CreateFrame
local GetItemCount = GetItemCount
local GetItemInfo = GetItemInfo
local GetItemQualityColor = GetItemQualityColor
local GetProfessions = GetProfessions
local GetProfessionInfo = GetProfessionInfo
local GetRealmName = GetRealmName
local GetUnitName = GetUnitName
local HideUIPanel = HideUIPanel
local SetPortraitToTexture = SetPortraitToTexture
local hooksecurefunc = hooksecurefunc
local string = string
local tostring = tostring
local type = type
local wipe = wipe
local _G = _G

-- TradeSkillUI
LoadAddOn("Blizzard_TradeSkillUI")
local TradeSkillFrame = TradeSkillFrame
local TradeSkillFrame_CalculateRankInfoFromRankLinks = 
    TradeSkillFrame_CalculateRankInfoFromRankLinks
local TradeSkillFrame_GenerateRankLinks = TradeSkillFrame_GenerateRankLinks
local TradeSkillRecipeListMixin = TradeSkillRecipeListMixin

-- Make sure we don't polute the global environment
setfenv(1, {})

-- How long to delay before second TradeSkill scan
local SCAN_DELAY = 0.5
-- How long to delay before unregister spell events
local CLOSE_UNREGISTER_DELAY = 2

-- By default only queue profitable Legion recipes
local legionCategoryIDs = {
    [426] = true, -- "Legion Plans", Blacksmithing
    [430] = true, -- "Legion Patterns", Tailoring
    [433] = true, -- "Alchemy of the Broken Isles", Alchemy
    [443] = true, -- "Legion Enchanting", Enchanting
    [450] = true, -- "Legion Inscription", Inscription
    [460] = true, -- "Legion Patterns", Leatherworking
    [464] = true, -- "Legion Designs", Jewelcrafting
    [469] = true, -- "Legion Engineering", Engineering
    [475] = true  -- "Food of the Broken Isles", Cooking
}

function TradeSkill:GetLevel(tradeSkillID)
    local prof1, prof2 = GetProfessions()
    local _, _, profLevel, _, _, _, profID = GetProfessionInfo(prof1)
    if profID == tradeSkillID then
	return profLevel
    else
        _, _, profLevel, _, _, _, profID = GetProfessionInfo(prof2)
        if tradeSkillID == tradeSkillID then
	    return profLevel
        else
	    --[[
            Data:Debug("TradeSkill:GetLevel", "Couldn't find profession", 
		tradeSkillID)
	    --]]
            return nil
        end
    end
end

function TradeSkill:OnLoad()
    -- Move search box a bit left
    TradeSkillFrame.SearchBox:ClearAllPoints()
    TradeSkillFrame.SearchBox:SetPoint("TOPLEFT", 196, -60)
    -- Move filter button up and move link to button back where it was
    TradeSkillFrame.LinkToButton:ClearAllPoints()
    TradeSkillFrame.FilterButton:ClearAllPoints()
    TradeSkillFrame.LinkToButton:SetPoint("TOPRIGHT", -4, -18)
    TradeSkillFrame.FilterButton:SetPoint("TOPRIGHT", 
	TradeSkillFrame.LinkToButton, "TOPLEFT", 0, -6)
    -- Move rank frame over to the left
    TradeSkillFrame.RankFrame:ClearAllPoints()
    TradeSkillFrame.RankFrame:SetPoint("TOPLEFT", 85, -28)

    local function GetStackInput()
	local num = self.stackNumInput:GetNumber()
	local size = self.stackSizeInput:GetNumber()
	local recipeID = TradeSkillFrame.RecipeList:GetSelectedRecipeID()
	if recipeID then
	    local itemID = self:GetItemInfoFromRecipeID(recipeID)
	    if itemID and _G.Crafty_Items[itemID] then
		_G.Crafty_Items[itemID].stackNum = num
		_G.Crafty_Items[itemID].stackSize = size
	    else
		--Data:Debug("GetStackInput", "No item data")
	    end
	end
    end

    -- Stack number
    self.stackNumInput = UI:CreateInput("Crafty_StackNumInput", TradeSkillFrame,
	false, true, 25, 16, "TOPRIGHT", TradeSkillFrame, "TOPRIGHT", -310, -62)
    self.stackNumInput:SetScript("OnTextChanged", GetStackInput)
    UI:CreateText("Crafty_StackNumText", TradeSkillFrame, "GameFontNormal",
	"Stack Number", "TOPLEFT", "Crafty_StackNumInput", "TOPRIGHT", 3, -4,
	Data.colour.white)
    UI:CreateText("Crafty_RestockText", TradeSkillFrame, "GameFontNormalSmall",
	"Crafty: Restock for Profit", "BOTTOMLEFT", "Crafty_StackNumInput", 
	"TOPLEFT", -2, 4)

    -- Stack size
    self.stackSizeInput = UI:CreateInput("Crafty_StackSizeInput", 
	TradeSkillFrame, false, true, 25, 16, "TOPLEFT", "Crafty_StackNumText", 
	"TOPRIGHT", 8, 3)
    self.stackSizeInput:SetScript("OnTextChanged", GetStackInput)
    UI:CreateText("Crafty_StackSizeText", TradeSkillFrame, 
	"GameFontNormal", "Stack Size", "TOPLEFT", "Crafty_StackSizeInput",
	"TOPRIGHT", 3, -3, Data.colour.white)
end

-- Get the itemID from the recipeID, works with enchant scrolls
function TradeSkill:GetItemInfoFromRecipeID(recipeID)
    if not self.open then return end

    local itemLink = C_TradeSkillUI.GetRecipeItemLink(recipeID)
    local itemID = Data:GetItemInfoFromLink(itemLink)
    local numProduced
    if itemID then
	numProduced = C_TradeSkillUI.GetRecipeNumItemsProduced(recipeID)
    else
	itemID = Data.enchantScrolls[recipeID]
	numProduced = 1
	if itemID then
	    -- NOOP
	else
	    --[[
	    local _, itemLink = GetItemInfo(itemID)
	    Data:Debug("TradeSkill:GetItemInfoFromRecipeID", 
		"No scroll itemID for", itemLink)
	    --]]
	end
    end
    return itemID, numProduced
end

-- Does this player have TradeSkill data yet?
function TradeSkill:HasTradeSkillData()
    local realmName = GetRealmName()
    local realm = _G.Crafty_Characters[realmName]
    if realm then
	local playerName = GetUnitName("player", false)
	local player = realm[playerName]
	if player then
	    return (player.tradeSkills ~= nil)
	end
    end

    return false
end

function TradeSkill:HasTradeSkill(tradeSkillID)
    local realmName = GetRealmName()
    local realm = _G.Crafty_Characters[realmName]
    if realm then
	local playerName = GetUnitName("player", false)
	local player = realm[playerName]
	if player then
	    local tradeSkills = player.tradeSkills
	    if tradeSkills then
		return (tradeSkills[tradeSkillID] == true)
	    end
	end
    end

    return false
end

local recipeInfo = {}
local recipeLinks = {}
local categoryInfo = {}

-- Scrape recipe information from the TradeSkill window
function TradeSkill:Scan()
    if not self.open or (not self.scan and not self.secondScan) then return end

    self.scan = false
    self.secondScan = false
    --Data:Debug("TradeSkill:Scan", "scanning")
    wipe(recipeLinks)

    local tradeSkillID, tradeSkillName = C_TradeSkillUI.GetTradeSkillLine()
    if _G.Crafty_TradeSkills[tradeSkillID] then
	-- NOOP
    else
	_G.Crafty_TradeSkills[tradeSkillID] = { name = tradeSkillName }
    end
    local realmName = GetRealmName()
    if _G.Crafty_Characters[realmName] then
	-- NOOP
    else
	_G.Crafty_Characters[realmName] = {}
    end
    local playerName = GetUnitName("player", false)
    if _G.Crafty_Characters[realmName][playerName] then
	-- NOOP
    else
	_G.Crafty_Characters[realmName][playerName] = {}
    end
    if _G.Crafty_Characters[realmName][playerName].tradeSkills then
    else
	_G.Crafty_Characters[realmName][playerName].tradeSkills = {}
    end
    _G.Crafty_Characters[realmName][playerName].tradeSkills[tradeSkillID] = true

    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    local parent, cat
    for i = 1, #recipeIDs do
	local recipeID = recipeIDs[i]
	wipe(recipeInfo)
	C_TradeSkillUI.GetRecipeInfo(recipeID, recipeInfo)
	--[[
	if recipeInfo.categoryID and cat ~= recipeInfo.categoryID then
	    cat = recipeInfo.categoryID
	    C_TradeSkillUI.GetCategoryInfo(cat, categoryInfo)
	    Data:Debug("TradeSkill:Scan", "Category:", categoryInfo.name, 
		"("..cat..")")
	end
	--]]
	C_TradeSkillUI.GetCategoryInfo(recipeInfo.categoryID, categoryInfo)
	if categoryInfo.parentCategoryID and
	    parent ~= categoryInfo.parentCategoryID then
	    parent = categoryInfo.parentCategoryID
	    --[[
	    C_TradeSkillUI.GetCategoryInfo(parent, categoryInfo)
	    Data:Debug("TradeSkill:Scan", "-- ")
	    Data:Debug("TradeSkill:Scan", "Parent category:", categoryInfo.name,
		"(" ..  parent..")")
	    --]]
	end

	if recipeInfo.learned and not recipeLinks[recipeID] then

	TradeSkillFrame_GenerateRankLinks(recipeInfo, recipeLinks)
	local totalRanks = 
	    TradeSkillFrame_CalculateRankInfoFromRankLinks(recipeInfo)
	local bestRecipeInfo = 
	    TradeSkillRecipeListMixin:FindBestStarRankLinksForRecipe(recipeInfo)
	recipeID = bestRecipeInfo.recipeID

	local itemID, numProduced = self:GetItemInfoFromRecipeID(recipeID)

	if itemID then

	local item = _G.Crafty_Items[itemID]

	if item then
	    -- If the item exists and it has ranks then redo
	    if totalRanks > 1 then
		wipe(_G.Crafty_Items[itemID].reagents)
	    else
		item = nil
	    end
	else
	    local _, itemLink = GetItemInfo(itemID)
	    -- If this fails we can update on secondScan
	    if itemLink then
		_G.Crafty_Items[itemID] = {
		    tradeSkillID = tradeSkillID,
		    isBoP = Data:IsBoP(itemLink),
		    minBuyout = -1, 
		    reagents = {}
		}
		item = _G.Crafty_Items[itemID]
	    else
		self.secondScan = true
	    end
	end

	if item then

	_G.Crafty_Items[itemID].numProduced = numProduced
	_G.Crafty_Items[itemID].recipeID = recipeID

	-- Store used reagents in the main list as well
	local numReagents = C_TradeSkillUI.GetRecipeNumReagents(recipeID);
	for i = 1, numReagents do
	    itemLink = C_TradeSkillUI.GetRecipeReagentItemLink(recipeID, i)
	    local reagentID = Data:GetItemInfoFromLink(itemLink)
	    if reagentID then
		local _, _, num = C_TradeSkillUI.GetRecipeReagentInfo(
		    recipeID, i)
		_G.Crafty_Items[itemID].reagents[reagentID] = num

		-- Check if we know about the reagent yet
		if _G.Crafty_Items[reagentID] then
		    -- NOOP
		else
		    _, itemLink = GetItemInfo(reagentID)
		    if itemLink then
			-- We already have a list of vendor items
			if Data.vendorIDs[reagentID] then
			    -- NOOP
			elseif Data:IsBoP(itemLink) then
			    _G.Crafty_Items[reagentID] = { isBoP = true }
			else
			    _G.Crafty_Items[reagentID] = { minBuyout = -1 }
			end
		    else
			-- We'll redo the item on next scan
			--[[
			Data:Debug("TradeSkill:Scan", 
			    "Retrying GetItemInfo for", reagentID)
			--]]
			self.secondScan = true
		    end
		end
	    else
		-- We'll redo the item on next scan
		--Data:Debug("TradeSkill:Scan", "reagentID is nil")
		_G.Crafty_Items[itemID] = nil
		self.secondScan = true
	    end
	end

	-- If a legion recipe use sensible defaults for restocking
	if item and not item.stackSize and legionCategoryIDs[parent] then
	    -- Don't restock items that have charges or a cooldown
	    local cooldown, isDayCooldown, charges, _ = 
		C_TradeSkillUI.GetRecipeCooldown(recipeID)
	    if charges == 0 and not cooldown and not isDayCooldown then
		if Data.enchantScrolls[recipeID] then
		    _G.Crafty_Items[itemID].stackSize = 1
		    _G.Crafty_Items[itemID].stackNum = 1
		else
		    local _, _, _, _, _, _, _, stackSize = GetItemInfo(itemID)
		    if stackSize then
			_G.Crafty_Items[itemID].stackSize = stackSize > 
			Data.ProfitStackSize and Data.ProfitStackSize or 1
			_G.Crafty_Items[itemID].stackNum = Data.ProfitStackNum
		    else
			-- We'll redo the item on next scan
			--[[
			Data:Debug("TradeSkill:Scan", "stackSize is nil, item",
			    itemID)
			--]]
			_G.Crafty_Items[itemID] = nil
			self.secondScan = true
		    end
		end
	    end
	end
	end -- if item
	end -- if itemID
	end -- if recipeInfo.learned and not recipeLinks[recipeID]
    end	    -- for i = 1, #recipeIDs

    -- Relying on the second TRADE_SKILL_UPDATE doesn't work so schedule it
    if self.secondScan then
	Wait:Start(SCAN_DELAY, self.Scan, self)
	return
    end
end

function TradeSkill:OnOpen()
    self.open = true
    self.scan = true
    self.tradeSkillID = C_TradeSkillUI.GetTradeSkillLine()
end

function TradeSkill:OnClose()
    self.open = false
    HideUIPanel(QueueFrame)
    -- Really need to avoid getting blocked! But delay to allow cast to finish
    Wait:Start(CLOSE_UNREGISTER_DELAY, QueueFrameList.UnregisterSpellcast, 
	QueueFrameList)
end

function TradeSkill:DetectChange()
    if not self.open then return end

    local tradeSkillID = C_TradeSkillUI.GetTradeSkillLine()
    if tradeSkillID == self.tradeSkillID then
	-- NOOP
    else
	--Data:Debug("TradeSkill:DetectChange", "Trade Skill changed")
	self.tradeSkillID = C_TradeSkillUI.GetTradeSkillLine()
    end
end

-- Don't disable the input box as it's used for the queue
hooksecurefunc(TradeSkillFrame.DetailsFrame, "RefreshButtons", function (self)
    self.CreateMultipleInputBox:SetEnabled(true)
end)

-- Respond to recipe list selection change
hooksecurefunc(TradeSkillFrame.RecipeList, "SetSelectedRecipeID",
    function (self, recipeID)
    if not recipeID then return end

    local itemID = TradeSkill:GetItemInfoFromRecipeID(recipeID)
    local item = _G.Crafty_Items[itemID]
    if itemID and item then
	local num = item.stackNum or 0
	local _, _, _, _, _, _, _, stackSize = GetItemInfo(itemID)
	local size = stackSize == 1 and 1 or item.stackSize or 1
	TradeSkill.stackNumInput:SetNumber(num)
	TradeSkill.stackSizeInput:SetNumber(size)
	TradeSkill.stackNumInput:ClearFocus()
	TradeSkill.stackSizeInput:ClearFocus()
	if stackSize == 1 then
	    TradeSkill.stackSizeInput:Disable()
	else
	    TradeSkill.stackSizeInput:Enable()
	end
	TradeSkill.stackNumInput:Enable()
    else
	TradeSkill.stackSizeInput:SetText("")
	TradeSkill.stackNumInput:SetText("")
	TradeSkill.stackSizeInput:Disable()
	TradeSkill.stackNumInput:Disable()
    end
end)
