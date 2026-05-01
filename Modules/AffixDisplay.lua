--[[
    MythicPulse - Affix Display Module
    Shows current weekly affixes with icons and tooltips.
    Section tooltip shows key-level activation thresholds.
]]

local _, MP = ...

local AffixDisplay = {
    registeredEvents = {
        "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_MAPS_UPDATE",   -- fires when keystone map info loads
    },
    affixes = {},
}

----------------------------------------------------------------------
-- Key-level activation thresholds for affix slots.
-- Slot 1 activates at +2, slot 2 at +7, slot 3 at +12, slot 4 at +17/seasonal.
-- This pattern has been stable across recent seasons; if Blizzard adjusts
-- it for a future season, only this table needs to change.
----------------------------------------------------------------------
local AFFIX_SLOT_THRESHOLDS = { 2, 7, 12, 17 }

local function GetSlotThreshold(idx)
    return AFFIX_SLOT_THRESHOLDS[idx] or 0
end

----------------------------------------------------------------------
-- UI
----------------------------------------------------------------------
local section
local affixIcons = {}

local ICON_SIZE = 36
local ICON_GAP  = 6

local function CreateUI()
    section = MP.MainFrame:CreateSection(MP.L["AFFIXES"], 26 + ICON_SIZE + 8)
    affixIcons = {}

    -- Hover overlay on the section label for the schedule tooltip
    -- (FontStrings don't capture mouse; use a transparent Frame overlay)
    if section.label then
        local labelHover = CreateFrame("Frame", nil, section)
        labelHover:SetPoint("TOPLEFT", section.label, "TOPLEFT", 0, 2)
        labelHover:SetPoint("BOTTOMRIGHT", section.label, "BOTTOMRIGHT", 4, -2)
        labelHover:EnableMouse(true)
        labelHover:SetScript("OnEnter", ShowSectionTooltip)
        labelHover:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    MP.MainFrame:AddSection(section)
    return section
end

----------------------------------------------------------------------
-- Create affix icon with tooltip
----------------------------------------------------------------------
local function CreateAffixIcon(parent, index)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(ICON_SIZE, ICON_SIZE)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Border (subtle ring — light enough to not cover icon edges)
    frame.border = frame:CreateTexture(nil, "OVERLAY")
    frame.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.border:SetPoint("TOPLEFT", -1, 1)
    frame.border:SetPoint("BOTTOMRIGHT", 1, -1)
    frame.border:SetVertexColor(0.30, 0.30, 0.35, 0.45)
    frame.border:SetDrawLayer("OVERLAY", 7)

    -- Inner bg (border effect)
    frame.innerBg = frame:CreateTexture(nil, "BACKGROUND")
    frame.innerBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.innerBg:SetPoint("TOPLEFT", -1, 1)
    frame.innerBg:SetPoint("BOTTOMRIGHT", 1, -1)
    frame.innerBg:SetVertexColor(0, 0, 0, 1)

    -- Tooltip with name, description, and activation threshold
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if self.affixID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local name, desc = C_ChallengeMode.GetAffixInfo(self.affixID)
            GameTooltip:SetText(name or "Unknown", 1, 0.8, 0)

            local threshold = GetSlotThreshold(self.slotIndex or 0)
            if threshold > 0 then
                -- The icon's gold/gray visual already shows active vs inactive.
                -- Tooltip just shows the threshold so the player knows the number.
                GameTooltip:AddLine(string.format("|cff7ed6ffActivates at +%d|r", threshold))
            end

            if desc then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(desc, 1, 1, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return frame
end

----------------------------------------------------------------------
-- Section-wide tooltip: shows full affix schedule with activation thresholds.
----------------------------------------------------------------------
local function ShowSectionTooltip(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText("Weekly Affixes", 0.95, 0.8, 0.2)

    local affixes = AffixDisplay.affixes or {}
    if #affixes == 0 then
        GameTooltip:AddLine("No active affixes.", 0.7, 0.7, 0.7)
        GameTooltip:Show()
        return
    end

    GameTooltip:AddLine(" ")
    for i, affix in ipairs(affixes) do
        local name = C_ChallengeMode.GetAffixInfo(affix.id)
        local threshold = GetSlotThreshold(i)
        local thresholdStr = threshold > 0 and string.format("+%d", threshold) or "?"
        GameTooltip:AddDoubleLine(
            string.format("|cffffd866%s|r  %s", thresholdStr, name or "Unknown"),
            "",
            1, 1, 1, 1, 1, 1
        )
    end

    -- Helpful key-level reminders
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cff7ed6ffKey-Level Activation:|r")
    GameTooltip:AddLine("  +2  = First affix", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("  +7  = Second affix", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("  +12 = Third affix", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("  +17 = Seasonal affix", 0.85, 0.85, 0.85)

    GameTooltip:Show()
end

----------------------------------------------------------------------
-- Resolve the effective key level for active/inactive highlighting.
-- Priority: active M+ run → owned keystone → Timer module (demo) → 0.
----------------------------------------------------------------------
local function GetKeyLevel()
    -- Active run (real or entering world mid-run)
    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local level = C_ChallengeMode.GetActiveKeystoneInfo()
        if level and level > 0 then return level end
    end
    -- Owned keystone in bags (works in lobby / out of dungeon)
    if C_MythicPlus and C_MythicPlus.GetOwnedKeystoneLevel then
        local level = C_MythicPlus.GetOwnedKeystoneLevel()
        if level and level > 0 then return level end
    end
    -- Demo mode: Timer module carries the synthetic key level
    local timer = MP:GetModule("Timer")
    if timer and (timer.keyLevel or 0) > 0 then
        return timer.keyLevel
    end
    return 0
end

----------------------------------------------------------------------
-- Update affix display
----------------------------------------------------------------------
local function UpdateAffixes()
    local currentAffixes = C_MythicPlus.GetCurrentAffixes()
    if not currentAffixes or not section then return end

    AffixDisplay.affixes = currentAffixes
    local keyLevel = GetKeyLevel()

    -- Collect only affixes that are active at the current key level.
    -- When keyLevel == 0 (lobby / unknown), show all so the section is useful.
    local activeList = {}
    for i, affixInfo in ipairs(currentAffixes) do
        local threshold = GetSlotThreshold(i)
        if keyLevel == 0 or keyLevel >= threshold then
            table.insert(activeList, { id = affixInfo.id, slotIndex = i })
        end
    end

    -- Lay out active icons compactly (no gaps for inactive slots)
    for i, entry in ipairs(activeList) do
        local icon = affixIcons[i]
        if not icon then
            icon = CreateAffixIcon(section, i)
            affixIcons[i] = icon
        end

        icon.affixID   = entry.id
        icon.slotIndex = entry.slotIndex

        local _, _, fileDataID = C_ChallengeMode.GetAffixInfo(entry.id)
        if fileDataID then icon.icon:SetTexture(fileDataID) end

        icon.icon:SetDesaturated(false)
        icon:SetAlpha(1.0)

        icon:ClearAllPoints()
        icon:SetPoint("TOPLEFT", section, "TOPLEFT", (i - 1) * (ICON_SIZE + ICON_GAP), -26)
        icon:Show()
    end

    -- Hide unused icon slots
    for i = #activeList + 1, #affixIcons do
        affixIcons[i]:Hide()
    end

    -- Resize section to exactly contain the label + icons (no overflow)
    local newHeight = #activeList > 0 and (26 + ICON_SIZE + 8) or 34
    if section:GetHeight() ~= newHeight then
        section:SetHeight(newHeight)
        MP.MainFrame:Layout()
    end
end

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function AffixDisplay:OnEvent(event, ...)
    if event == "MYTHIC_PLUS_CURRENT_AFFIX_UPDATE"
    or event == "CHALLENGE_MODE_START"
    or event == "CHALLENGE_MODE_MAPS_UPDATE" then
        UpdateAffixes()
    end
end

function AffixDisplay:OnFrameReady()
    CreateUI()
    -- Register as M+-only section
    if section then
        MP:RegisterMythicOnlySection(section)
    end
    C_Timer.After(1, UpdateAffixes)
end

function AffixDisplay:OnPlayerEnteringWorld()
    C_Timer.After(2, UpdateAffixes)
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("AffixDisplay", AffixDisplay)
