--[[
    MythicPulse - Main Frame
    Primary HUD overlay that anchors all module sub-frames.
    Auto-shows in Mythic+ and provides drag/lock/toggle behavior.
    
    MIDNIGHT COMPLIANCE:
    - All SetBackdrop* calls guarded by InCombatLockdown()
    - Frame does not interact with any protected Blizzard frames
    - Purely cosmetic display overlay
]]

local _, MP = ...

MP.MainFrame = {}

local FRAME_WIDTH        = 310
local FRAME_PADDING      = 14
local SECTION_GAP        = 16
local ADDON_HEADER_H     = 14   -- "MythicPulse Timer" label
local ADDON_HEADER_GAP   = 3

----------------------------------------------------------------------
-- Create the main frame
----------------------------------------------------------------------
local function CreateMainFrame()
    local f = CreateFrame("Frame", "MythicPulseMainFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, 10)  -- height set dynamically
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()

    -- Small addon header label
    f.addonHeader = f:CreateFontString(nil, "OVERLAY")
    f.addonHeader:SetFontObject(MP.Fonts.Label)
    f.addonHeader:SetPoint("TOPLEFT", FRAME_PADDING, -FRAME_PADDING)
    f.addonHeader:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
    f.addonHeader:SetText(MP:Loc("MAIN_ADDON_HEADER"))

    -- Title bar (dungeon name + key level), shifted below the addon header
    f.titleBar = CreateFrame("Frame", nil, f)
    f.titleBar:SetHeight(24)
    f.titleBar:SetPoint("TOPLEFT",  FRAME_PADDING,  -(FRAME_PADDING + ADDON_HEADER_H + ADDON_HEADER_GAP))
    f.titleBar:SetPoint("TOPRIGHT", -FRAME_PADDING, -(FRAME_PADDING + ADDON_HEADER_H + ADDON_HEADER_GAP))

    f.titleText = f.titleBar:CreateFontString(nil, "OVERLAY")
    f.titleText:SetFontObject(MP.Fonts.Header)
    f.titleText:SetPoint("LEFT")
    f.titleText:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
    f.titleText:SetText(MP:Loc("MAIN_ADDON_HEADER"))

    -- Key level display (immediately right of dungeon name)
    f.keyLevelText = f.titleBar:CreateFontString(nil, "OVERLAY")
    f.keyLevelText:SetFontObject(MP.Fonts.Header)
    f.keyLevelText:SetPoint("LEFT", f.titleText, "RIGHT", 6, 0)
    f.keyLevelText:SetTextColor(0.95, 0.95, 0.95)

    -- Separator under title
    f.titleSep = f:CreateTexture(nil, "ARTWORK")
    f.titleSep:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.titleSep:SetHeight(1)
    f.titleSep:SetPoint("TOPLEFT", f.titleBar, "BOTTOMLEFT", 0, -3)
    f.titleSep:SetPoint("TOPRIGHT", f.titleBar, "BOTTOMRIGHT", 0, -3)
    f.titleSep:SetVertexColor(MP.COLORS.border.r, MP.COLORS.border.g, MP.COLORS.border.b, 0.4)
    f._mpTitleSep = f.titleSep

    -- Content area (modules attach here)
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f.titleSep, "BOTTOMLEFT", 0, -SECTION_GAP)
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
            MP.db.mainFrame.point    = point
            MP.db.mainFrame.relPoint = relPoint
            MP.db.mainFrame.x        = x
            MP.db.mainFrame.y        = y
        end
    end)

    return f
end

----------------------------------------------------------------------
-- Section creator for modules
----------------------------------------------------------------------
function MP.MainFrame:CreateSection(title, height)
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
function MP.MainFrame:Layout()
    if not self.frame or not self.frame.content then return end
    if not self.sections then return end

    local yOff = 0
    local visibleSections = 0
    for _, section in ipairs(self.sections) do
        if section:IsShown() then
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOff)
            section:SetPoint("TOPRIGHT", self.frame.content, "TOPRIGHT", 0, -yOff)
            yOff = yOff + section:GetHeight() + SECTION_GAP
            visibleSections = visibleSections + 1
        end
    end

    if visibleSections == 0 then
        self.frame:Hide()
        return
    end

    -- Resize main frame to fit content
    local totalHeight = FRAME_PADDING + ADDON_HEADER_H + ADDON_HEADER_GAP + 24 + 3 + SECTION_GAP + yOff + FRAME_PADDING
    self.frame:SetHeight(math.max(totalHeight, 60))
    self:UpdateVisibility()
end

----------------------------------------------------------------------
-- Add a section to the layout
----------------------------------------------------------------------
function MP.MainFrame:AddSection(section)
    if not self.sections then self.sections = {} end
    table.insert(self.sections, section)
end

----------------------------------------------------------------------
-- Toggle visibility
----------------------------------------------------------------------
function MP.MainFrame:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
        self.manualState = "hidden"
    else
        self.frame:Show()
        self.manualState = "shown"
    end
end

----------------------------------------------------------------------
-- Auto-show/hide based on M+ state
----------------------------------------------------------------------
function MP.MainFrame:UpdateVisibility()
    if not self.frame then return end
    if self.manualState == "hidden" then
        self.frame:Hide()
        return
    end
    if self.manualState == "shown" then
        self.frame:Show()
        return
    end

    if MP:ShouldShowHUD() then
        self.frame:Show()
    else
        -- Keep visible briefly after leaving M+, then auto-hide
        if not self.hideTimer then
            self.hideTimer = C_Timer.NewTimer(5, function()
                if not MP:ShouldShowHUD() and self.manualState ~= "shown" and self.frame then
                    self.frame:Hide()
                end
                self.hideTimer = nil
            end)
        end
    end
end

----------------------------------------------------------------------
-- Update lock state
----------------------------------------------------------------------
function MP.MainFrame:UpdateLock()
    if InCombatLockdown() then
        C_Timer.After(0.5, function() MP.MainFrame:UpdateLock() end)
        return
    end
    local f = self.frame
    if MP.db and MP.db.locked then
        f:SetBackdrop(nil)
    else
        f:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
        f:SetBackdropColor(0, 0, 0, 0.20)
    end
end

----------------------------------------------------------------------
-- Reset position
----------------------------------------------------------------------
function MP.MainFrame:ResetPosition()
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOP", UIParent, "TOP", 0, -120)
    if MP.db then
        MP.db.mainFrame.point    = "TOP"
        MP.db.mainFrame.relPoint = "TOP"
        MP.db.mainFrame.x        = 0
        MP.db.mainFrame.y        = -120
    end
end

----------------------------------------------------------------------
-- Stub kept for backwards-compat; Timer module owns death display now.
----------------------------------------------------------------------
function MP.MainFrame:SetDeathInfo(_count, _totalPenalty) end

----------------------------------------------------------------------
-- Set the dungeon header info
----------------------------------------------------------------------
function MP.MainFrame:SetDungeonInfo(dungeonName, keyLevel)
    -- Guard against early calls before the frame is constructed.
    -- This module is created during PLAYER_ENTERING_WORLD, but other
    -- modules' OnPlayerEnteringWorld callbacks may fire first depending
    -- on event-handler registration order.
    if not self.frame then return end
    if not self.frame.titleText or not self.frame.keyLevelText then return end

    if dungeonName then
        self.frame.titleText:SetText(dungeonName)
    else
        self.frame.titleText:SetText("MythicPulse")
    end
    if keyLevel and keyLevel > 0 then
        self.frame.keyLevelText:SetText("+" .. keyLevel)
    else
        self.frame.keyLevelText:SetText("")
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    if not MP.MainFrame.frame then
        MP.MainFrame.frame = CreateMainFrame()
        MP.MainFrame.sections = {}
        MP.MainFrame.manualState = nil

        -- Restore saved position
        if MP.db and MP.db.mainFrame then
            local mf = MP.db.mainFrame
            MP.MainFrame.frame:ClearAllPoints()
            MP.MainFrame.frame:SetPoint(
                mf.point or "TOP",
                UIParent,
                mf.relPoint or "TOP",
                mf.x or 0,
                mf.y or -120
            )
            MP.MainFrame.frame:SetScale(mf.scale or 1.0)
            MP.MainFrame.frame:SetAlpha(mf.alpha or 1.0)
        end

        -- Notify modules that the frame is ready
        C_Timer.After(0.1, function()
            for name, mod in pairs(MP.modules) do
                if mod.enabled and mod.OnFrameReady then
                    mod:OnFrameReady()
                end
            end
            MP.MainFrame:Layout()
        end)
    end

    -- Always update visibility on zone changes
    C_Timer.After(0.5, function()
        MP.MainFrame:UpdateVisibility()
    end)
end)
