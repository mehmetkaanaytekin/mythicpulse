--[[
    MythicPulse - Combat Utilities Frame
    Standalone HUD for Bloodlust and Battle Res tracking.
    Independently draggable, like the Interrupt Frame.
]]

local _, MP = ...

MP.CombatResFrame = {}

local FRAME_PADDING = 8
local HEADER_HEIGHT = 18

----------------------------------------------------------------------
-- Create the frame
----------------------------------------------------------------------
local function CreateCombatResFrame()
    local f = CreateFrame("Frame", "MythicPulseCombatResFrame", UIParent, "BackdropTemplate")
    f:SetSize(130, 10)   -- width resized in SetWidth(); height set by Layout()
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(9)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT",     f, "TOPLEFT",     FRAME_PADDING,  -(FRAME_PADDING + HEADER_HEIGHT))
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -FRAME_PADDING,  FRAME_PADDING)

    f.header = f:CreateFontString(nil, "OVERLAY")
    f.header:SetFontObject(MP.Fonts and MP.Fonts.Label or "GameFontHighlight")
    f.header:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PADDING, -2)
    f.header:SetTextColor(0.85, 0.85, 0.85)
    f.header:SetText("Combat")

    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not MP.db or not MP.db.locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if MP.db then
            local point, _, relPoint, x, y = self:GetPoint()
            MP.db.combatResFrame.point    = point
            MP.db.combatResFrame.relPoint = relPoint
            MP.db.combatResFrame.x        = x
            MP.db.combatResFrame.y        = y
        end
    end)

    return f
end

----------------------------------------------------------------------
-- Section creator (mirrors InterruptFrame API)
----------------------------------------------------------------------
function MP.CombatResFrame:CreateSection(title, height)
    local section = CreateFrame("Frame", nil, self.frame.content)
    section:SetHeight(height or 40)
    section:SetPoint("TOPLEFT",  0, 0)
    section:SetPoint("TOPRIGHT", 0, 0)
    if title then
        section.label = section:CreateFontString(nil, "OVERLAY")
        section.label:SetFontObject(MP.Fonts.Label)
        section.label:SetPoint("TOPLEFT", 0, 0)
        section.label:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
        section.label:SetText(title)
    end
    return section
end

----------------------------------------------------------------------
-- Layout
----------------------------------------------------------------------
function MP.CombatResFrame:Layout()
    if not self.sections then return end
    local yOff, visible = 0, 0
    for _, section in ipairs(self.sections) do
        if section:IsShown() and section:GetHeight() > 0 then
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT",  self.frame.content, "TOPLEFT",  0, -yOff)
            section:SetPoint("TOPRIGHT", self.frame.content, "TOPRIGHT", 0, -yOff)
            yOff    = yOff + section:GetHeight()
            visible = visible + 1
        end
    end
    if visible == 0 then
        self.frame:Hide()
        return
    end
    local totalH = math.max(FRAME_PADDING + HEADER_HEIGHT + yOff + FRAME_PADDING, 40)
    if math.abs(self.frame:GetHeight() - totalH) > 0.5 then
        self.frame:SetHeight(totalH)
    end
    self:UpdateVisibility()
end

----------------------------------------------------------------------
-- Add section
----------------------------------------------------------------------
function MP.CombatResFrame:AddSection(section)
    if not self.sections then self.sections = {} end
    table.insert(self.sections, section)
end

----------------------------------------------------------------------
-- Resize frame width to snugly fit content (called by CombatRes)
----------------------------------------------------------------------
function MP.CombatResFrame:SetWidth(contentWidth)
    if self.frame then
        self.frame:SetWidth(contentWidth + FRAME_PADDING * 2)
    end
end

----------------------------------------------------------------------
-- Toggle visibility
----------------------------------------------------------------------
function MP.CombatResFrame:Toggle()
    if self.frame:IsShown() then
        self.frame:Hide()
        self.manualState = "hidden"
    else
        self.frame:Show()
        self.manualState = "shown"
    end
end

----------------------------------------------------------------------
-- Auto-show/hide
----------------------------------------------------------------------
function MP.CombatResFrame:UpdateVisibility()
    if self.manualState == "hidden" then self.frame:Hide(); return end
    if self.manualState == "shown"  then self.frame:Show(); return end
    local shouldShow = MP:ShouldShowHUD()
    if shouldShow then self.frame:Show() else self.frame:Hide() end
end

----------------------------------------------------------------------
-- Lock state
----------------------------------------------------------------------
function MP.CombatResFrame:UpdateLock()
    if InCombatLockdown() then
        C_Timer.After(0.5, function() MP.CombatResFrame:UpdateLock() end)
        return
    end
    local f = self.frame
    if MP.db and MP.db.locked then
        f:SetBackdrop(nil)
    else
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        f:SetBackdropColor(0, 0, 0, 0.25)
        f:Show()
        self:Layout()
    end
end

----------------------------------------------------------------------
-- Reset position
----------------------------------------------------------------------
function MP.CombatResFrame:ResetPosition()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", 200, -200)
    if MP.db then
        MP.db.combatResFrame.point    = "CENTER"
        MP.db.combatResFrame.relPoint = "CENTER"
        MP.db.combatResFrame.x        = 200
        MP.db.combatResFrame.y        = -200
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    if not MP.CombatResFrame.frame then
        MP.CombatResFrame.frame    = CreateCombatResFrame()
        MP.CombatResFrame.sections = {}
        MP.CombatResFrame.manualState = nil

        if MP.db and MP.db.combatResFrame then
            local cf = MP.db.combatResFrame
            MP.CombatResFrame.frame:ClearAllPoints()
            MP.CombatResFrame.frame:SetPoint(
                cf.point    or "CENTER",
                UIParent,
                cf.relPoint or "CENTER",
                cf.x        or 200,
                cf.y        or -200
            )
            MP.CombatResFrame.frame:SetScale(cf.scale or 1.0)
            MP.CombatResFrame.frame:SetAlpha(cf.alpha or 1.0)
        end
    end

    C_Timer.After(0.5, function()
        MP.CombatResFrame:UpdateVisibility()
        MP.CombatResFrame:Layout()
    end)
end)
