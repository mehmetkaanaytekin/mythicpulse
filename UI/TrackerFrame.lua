--[[
    MythicPulse - Tracker Frame
    Standalone secondary HUD for party tracking modules (Interrupts, Cooldowns).
    Can be moved and scaled independently from the main Mythic+ timer HUD.
]]

local _, MP = ...

MP.TrackerFrame = {}

local FRAME_WIDTH  = 260
local FRAME_PADDING = 8
local SECTION_GAP  = 6

----------------------------------------------------------------------
-- Create the tracker frame
----------------------------------------------------------------------
local function CreateTrackerFrame()
    local f = CreateFrame("Frame", "MythicPulseTrackerFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, 10)  -- height set dynamically
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(9)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)

    -- Backdrop
    MP:CreateBackdrop(f)

    -- Subtle glow
    MP:CreateGlow(f, MP.COLORS.borderGlow, 4)

    -- Content area (modules attach here)
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f, "TOPLEFT", FRAME_PADDING, -FRAME_PADDING)
    f.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -FRAME_PADDING, FRAME_PADDING)

    -- Drag behavior
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
            MP.db.trackerFrame.point    = point
            MP.db.trackerFrame.relPoint = relPoint
            MP.db.trackerFrame.x        = x
            MP.db.trackerFrame.y        = y
        end
    end)

    -- Final sync after all visual layers exist (glow/title separator).
    MP:ApplyBackdrop(f)

    return f
end

----------------------------------------------------------------------
-- Section creator for modules
----------------------------------------------------------------------
function MP.TrackerFrame:CreateSection(title, height)
    local section = CreateFrame("Frame", nil, self.frame.content)
    section:SetHeight(height or 40)
    section:SetPoint("TOPLEFT", 0, 0)
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
function MP.TrackerFrame:Layout()
    if not self.sections then return end

    local yOff = 0
    local visibleSections = 0

    for _, section in ipairs(self.sections) do
        if section:IsShown() and section:GetHeight() > 0 then
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOff)
            section:SetPoint("TOPRIGHT", self.frame.content, "TOPRIGHT", 0, -yOff)
            yOff = yOff + section:GetHeight() + SECTION_GAP
            visibleSections = visibleSections + 1
        end
    end

    -- Hide the frame whenever there is nothing to show
    if visibleSections == 0 then
        self.frame:Hide()
        return
    end

    -- Resize main frame to fit content
    local totalHeight = FRAME_PADDING + yOff + FRAME_PADDING
    self.frame:SetHeight(math.max(totalHeight, 40))

    -- Re-evaluate visibility
    self:UpdateVisibility()
end

----------------------------------------------------------------------
-- Add a section to the layout
----------------------------------------------------------------------
function MP.TrackerFrame:AddSection(section)
    if not self.sections then self.sections = {} end
    table.insert(self.sections, section)
end

----------------------------------------------------------------------
-- Toggle visibility
----------------------------------------------------------------------
function MP.TrackerFrame:Toggle()
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
function MP.TrackerFrame:UpdateVisibility()
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
function MP.TrackerFrame:UpdateLock()
    if InCombatLockdown() then
        C_Timer.After(0.5, function() MP.TrackerFrame:UpdateLock() end)
        return
    end
    local hasBackdrop = self.frame:GetBackdrop() ~= nil
    if MP.db and MP.db.locked then
        if hasBackdrop then
            self.frame:SetBackdropBorderColor(0.15, 0.15, 0.2, 0.4)
        end
    else
        if hasBackdrop then
            self.frame:SetBackdropBorderColor(
                MP.COLORS.border.r, MP.COLORS.border.g, MP.COLORS.border.b, MP.COLORS.border.a
            )
        end
        self.frame:Show() -- Show to drag
        self:Layout()
    end
end

----------------------------------------------------------------------
-- Reset position
----------------------------------------------------------------------
function MP.TrackerFrame:ResetPosition()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("LEFT", UIParent, "LEFT", 50, 0)
    if MP.db then
        MP.db.trackerFrame.point    = "LEFT"
        MP.db.trackerFrame.relPoint = "LEFT"
        MP.db.trackerFrame.x        = 50
        MP.db.trackerFrame.y        = 0
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    if not MP.TrackerFrame.frame then
        MP.TrackerFrame.frame = CreateTrackerFrame()
        MP.TrackerFrame.sections = {}
        MP.TrackerFrame.manualState = nil

        -- Restore saved position
        if MP.db and MP.db.trackerFrame then
            local mf = MP.db.trackerFrame
            MP.TrackerFrame.frame:ClearAllPoints()
            MP.TrackerFrame.frame:SetPoint(
                mf.point or "LEFT",
                UIParent,
                mf.relPoint or "LEFT",
                mf.x or 50,
                mf.y or 0
            )
            MP.TrackerFrame.frame:SetScale(mf.scale or 1.0)
            MP.TrackerFrame.frame:SetAlpha(mf.alpha or 1.0)
        end
    end

    C_Timer.After(0.5, function()
        MP.TrackerFrame:UpdateVisibility()
        MP.TrackerFrame:Layout()
    end)
end)
