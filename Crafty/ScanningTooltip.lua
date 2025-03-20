--
-- Scanning Tooltip Module
--

Crafty_ScanningTooltip = {}

-- Import
local ScanTip = Crafty_ScanningTooltip
local CreateFrame = CreateFrame
local GetItemInfo = GetItemInfo
local WorldFrame = WorldFrame
local type = type
local unpack = unpack

-- Make sure we don't polute the global environment
setfenv(1, {})

function ScanTip:Create()
    self.tooltip = CreateFrame("GameTooltip", "Crafty_ScanningTooltip")
    self.tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    -- Allow tooltip SetX() methods to dynamically add new lines based on these
    self.tooltip:AddFontStrings(
	self.tooltip:CreateFontString("$parentTextLeft1", nil, 
	    "GameTooltipText"),
	self. tooltip:CreateFontString("$parentTextRight1", nil, 
	    "GameTooltipText")
    )
end

-- Fill the tooltip with data from an itemLink
function ScanTip:Set(itemLink)
    self.tooltip:ClearLines()
    self.tooltip:SetHyperlink(itemLink)
end

function ScanTip:GetText()
    local text = {}
    local regions = { self.tooltip:GetRegions() }
    for i = 1, #regions do
	local region = regions[i]
        if region and region:GetObjectType() == "FontString" then
            text[#text + 1] = region:GetText()
        end
    end

    return unpack(text)
end
