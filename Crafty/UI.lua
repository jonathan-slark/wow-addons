--
-- UI Module
--

Crafty_UI = {}

-- Import
local UI = Crafty_UI
local CreateFrame = CreateFrame
local type = type
local unpack = unpack

-- Make sure we don't polute the global environment
setfenv(1, {})

function UI:CreateButton(name, parent, text, width, height, point, relativeTo, 
    relativePoint, offsetX, offsetY, func, ...)

    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(height)
    button:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    button:SetText(text)
    button.func = func
    button.param = { ... }
    button:SetScript("OnClick", function (self)
        self.func(unpack(self.param))
    end)
    return button
end

function UI:CreateInput(name, parent, focus, numeric, width, height, point, 
    relativeTo, relativePoint, offsetX, offsetY)
    
    local input = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    input:SetWidth(width)
    input:SetHeight(height)
    input:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    input:SetAutoFocus(focus)
    input:SetNumeric(numeric)
    return input
end

function UI:CreateText(name, parent, font, text, point, relativeTo, 
    relativePoint, offsetX, offsetY, colour, width)

    local font = parent:CreateFontString(name, "ARTWORK", font)
    font:SetPoint(point, relativeTo, relativePoint, offsetX, offsetY)
    font:SetText(text)
    if width then
	font:SetWidth(width)
    end
    if colour then
	font:SetTextColor(unpack(colour))
    end
    return font
end
