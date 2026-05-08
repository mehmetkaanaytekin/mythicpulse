--[[
    MythicPulse - Interrupt Frame
    Standalone secondary HUD for Interrupt tracking module.
    Can be moved and scaled independently from the main Mythic+ timer HUD and Party Cooldowns.
]]

local _, MP = ...

MP.InterruptFrame = {}

local FRAME_WIDTH  = 220
local FRAME_PADDING = 6
local HEADER_HEIGHT = 18
local SECTION_GAP  = 4

----------------------------------------------------------------------
-- Create the interrupt frame
----------------------------------------------------------------------
local function CreateInterruptFrame()
    local f = CreateFrame("Frame", "MythicPulseInterruptFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, 10)  -- height set dynamically
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(9)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    -- Content area (modules attach here) — offset below the header
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT",     f, "TOPLEFT",     FRAME_PADDING,  -(FRAME_PADDING + HEADER_HEIGHT))
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -FRAME_PADDING,  FRAME_PADDING)

    -- Drag behavior
    -- "Interrupts" header at the top-left
    f.header = f:CreateFontString(nil, "OVERLAY")
    f.header:SetFontObject(MP.Fonts and MP.Fonts.Label or "GameFontHighlight")
    f.header:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PADDING, -2)
    f.header:SetTextColor(0.85, 0.85, 0.85)
    f.header:SetText(MP:Loc("INTERRUPTS"))

    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not MP.db or not MP.db.locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        if MP.db then
            local point, _, relPoint, x, y = self:GetPoint()
            MP.db.interruptFrame.point    = point
            MP.db.interruptFrame.relPoint = relPoint
            MP.db.interruptFrame.x        = x
            MP.db.interruptFrame.y        = y
        end
    end)

    return f
end

----------------------------------------------------------------------
-- Section creator for modules
----------------------------------------------------------------------
function MP.InterruptFrame:CreateSection(title, height)
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
-- Layout: arrange sections vertically
----------------------------------------------------------------------
function MP.InterruptFrame:Layout()
    if not self.sections then return end

    local yOff = 0
    local visibleSections = 0

    for _, section in ipairs(self.sections) do
        if section:IsShown() and section:GetHeight() > 0 then
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT",  self.frame.content, "TOPLEFT",  0, -yOff)
            section:SetPoint("TOPRIGHT", self.frame.content, "TOPRIGHT", 0, -yOff)
            yOff = yOff + section:GetHeight() + SECTION_GAP
            visibleSections = visibleSections + 1
        end
    end

    -- If no sections are visible, hide the frame completely
    if visibleSections == 0 then
        self.frame:Hide()
        return
    end

    -- Resize main frame to fit content (header + content + padding)
    local totalHeight = math.max(FRAME_PADDING + HEADER_HEIGHT + yOff + FRAME_PADDING, 40)
    if math.abs(self.frame:GetHeight() - totalHeight) > 0.5 then
        self.frame:SetHeight(totalHeight)
    end

    -- Re-evaluate visibility
    self:UpdateVisibility()
end

----------------------------------------------------------------------
-- Add a section to the layout
----------------------------------------------------------------------
function MP.InterruptFrame:AddSection(section)
    if not self.sections then self.sections = {} end
    table.insert(self.sections, section)
end

----------------------------------------------------------------------
-- Toggle visibility
----------------------------------------------------------------------
function MP.InterruptFrame:Toggle()
    if self.frame:IsShown() then
        self.frame:Hide()
        self.manualState = "hidden"
    else
        self.frame:Show()
        self.manualState = "shown"
    end
end

----------------------------------------------------------------------
-- Auto-show/hide based on instance state
----------------------------------------------------------------------
function MP.InterruptFrame:UpdateVisibility()
    if self.manualState == "hidden" then 
        self.frame:Hide()
        return 
    end
    if self.manualState == "shown" then
        self.frame:Show()
        return
    end

    local shouldShow = MP:ShouldShowHUD()

    if shouldShow then
        self.frame:Show()
    else
        self.frame:Hide()
    end
end

----------------------------------------------------------------------
-- Update lock state
----------------------------------------------------------------------
function MP.InterruptFrame:UpdateLock()
    if InCombatLockdown() then
        C_Timer.After(0.5, function() MP.InterruptFrame:UpdateLock() end)
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
function MP.InterruptFrame:ResetPosition()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 320, -200)
    if MP.db then
        MP.db.interruptFrame.point    = "TOPLEFT"
        MP.db.interruptFrame.relPoint = "TOPLEFT"
        MP.db.interruptFrame.x        = 320
        MP.db.interruptFrame.y        = -200
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    if not MP.InterruptFrame.frame then
        MP.InterruptFrame.frame = CreateInterruptFrame()
        MP.InterruptFrame.sections = {}
        MP.InterruptFrame.manualState = nil

        -- Restore saved position
        if MP.db and MP.db.interruptFrame then
            local mf = MP.db.interruptFrame
            MP.InterruptFrame.frame:ClearAllPoints()
            MP.InterruptFrame.frame:SetPoint(
                mf.point or "TOPLEFT",
                UIParent,
                mf.relPoint or "TOPLEFT",
                mf.x or 320,
                mf.y or -200
            )
            MP.InterruptFrame.frame:SetScale(mf.scale or 1.0)
            MP.InterruptFrame.frame:SetAlpha(mf.alpha or 1.0)
        end
    end

    C_Timer.After(0.5, function()
        MP.InterruptFrame:UpdateVisibility()
        MP.InterruptFrame:Layout()
    end)
end)
