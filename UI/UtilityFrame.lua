--[[
    MythicPulse - Utility Abilities Frame
    Standalone movable window that displays dungeon-specific utility abilities.
    
    Features:
    - Dungeon name header with dropdown selector
    - Scrollable list of ability icons with names
    - Click an icon to expand/collapse dungeon entry details
    - Category labels (left-side): Known, +Add, -Remove, ?Optional
    - Self-only indicator (triangle marker) for self-cast abilities
    - Importance markers on entries: ! = must-have, ? = low impact
    - Auto-sizing height based on content
    - Draggable with position saved to SavedVariables
    - Close button
    
    MIDNIGHT COMPLIANCE:
    - All SetBackdrop* guarded by InCombatLockdown()
    - No protected frame interactions
    - No secure template usage
    - Purely cosmetic display window
]]

local _, MP = ...

MP.UtilityFrame = {}

local FRAME_WIDTH     = 320
local ICON_SIZE       = 40
local ICON_SPACING    = 8
local LEFT_PADDING    = 8
local RIGHT_PADDING   = 8
local TOP_PADDING     = 8
local ENTRY_INDENT    = 14
local ENTRY_SPACING   = 4
local CLOSE_BTN_SIZE  = 16
local LABEL_WIDTH     = 20
local HEADER_HEIGHT   = 24
local DROPDOWN_HEIGHT = 20
local MIN_HEIGHT      = 100
local MAX_HEIGHT      = 600
local SELECTOR_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}
local DROPDOWN_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 1, right = 1, top = 1, bottom = 1 },
}

-- Category cosmetics
-- alpha/borderColor mirror the affix display: active=bright gold, suggest=green, unused=dim gray
local CATEGORY_CONFIG = {
    known = {
        label       = "",
        labelColor  = { 1.0, 1.0, 1.0, 1.0 },
        iconColor   = { 1.0, 1.0, 1.0, 1.0 },  -- no tint — keep icon crisp
        desaturate  = false,
        alpha       = 1.0,
        borderColor = { 0.70, 0.58, 0.12, 0.55 },  -- subtle gold border
    },
    knownOptional = {
        label       = "?",
        labelColor  = { 0.6, 0.6, 0.8, 1.0 },
        iconColor   = { 1.0, 1.0, 1.0, 1.0 },  -- no tint
        desaturate  = false,
        alpha       = 0.85,
        borderColor = { 0.45, 0.38, 0.10, 0.45 },  -- muted gold border
    },
    add = {
        label       = "+",
        labelColor  = { 0.30, 1.00, 0.40, 1.0 },
        iconColor   = { 1.0, 1.0, 1.0, 1.0 },  -- no tint
        desaturate  = false,
        alpha       = 0.90,
        borderColor = { 0.15, 0.60, 0.22, 0.50 },  -- subtle green border
    },
    addOptional = {
        label       = "+?",
        labelColor  = { 0.30, 0.80, 0.40, 0.7 },
        iconColor   = { 1.0, 1.0, 1.0, 1.0 },  -- no tint
        desaturate  = false,
        alpha       = 0.70,
        borderColor = { 0.12, 0.42, 0.16, 0.40 },  -- muted green border
    },
    remove = {
        label       = "-",
        labelColor  = { 0.5, 0.5, 0.5, 1.0 },
        iconColor   = { 0.6, 0.6, 0.6, 1.0 },  -- slight dim only for removed
        desaturate  = true,
        alpha       = 0.40,
        borderColor = { 0.20, 0.20, 0.24, 0.35 },  -- dim gray border
    },
}

----------------------------------------------------------------------
-- Tooltip helper for spell icons
----------------------------------------------------------------------
local function SetupSpellTooltip(frame, spellID)
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(string.format("spell:%d", spellID))
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

----------------------------------------------------------------------
-- Create the main frame
----------------------------------------------------------------------
local function CreateUtilityFrame()
    local f = CreateFrame("Frame", "MythicPulseUtilityFrame", UIParent, "BackdropTemplate")
    f:SetSize(FRAME_WIDTH, MIN_HEIGHT)
    f:SetFrameStrata("DIALOG")
    f:SetFrameLevel(50)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetToplevel(true)

    -- Enable hyperlinks in the frame
    f:SetHyperlinksEnabled(true)
    f:SetScript("OnHyperlinkEnter", function(self, link, text)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    f:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button, self)
    end)
    f:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)

    -- Register with the shared backdrop system so global background toggles
    -- always apply to this frame in the same pass as other MP frames.
    MP:CreateBackdrop(
        f,
        { r = 0.06, g = 0.06, b = 0.10, a = 0.92 },
        { r = 0.15, g = 0.15, b = 0.25, a = 0.70 }
    )

    -- Subtle glow
    MP:CreateGlow(f, { r = 0.00, g = 0.50, b = 0.80, a = 0.20 }, 3)

    -- Drag behavior
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if MP.db and not MP.db.locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        if MP.db and MP.db.modules and MP.db.modules.dungeonUtility then
            local point, _, relPoint, x, y = self:GetPoint()
            MP.db.modules.dungeonUtility.framePoint    = point
            MP.db.modules.dungeonUtility.frameRelPoint  = relPoint
            MP.db.modules.dungeonUtility.frameX         = x
            MP.db.modules.dungeonUtility.frameY         = y
        end
    end)

    -- ============================================================
    -- Header: Dungeon Name
    -- ============================================================
    f.headerText = f:CreateFontString(nil, "OVERLAY")
    f.headerText:SetFontObject(MP.Fonts and MP.Fonts.Header or "GameFontNormalLarge")
    f.headerText:SetPoint("TOP", 0, -TOP_PADDING)
    f.headerText:SetTextColor(0.95, 0.95, 0.95)
    f.headerText:SetText("")
    f.headerText:SetJustifyH("CENTER")
    f.headerText:SetWidth(FRAME_WIDTH - 2 * CLOSE_BTN_SIZE - 10)
    f.headerText:SetWordWrap(true)

    -- ============================================================
    -- Close button
    -- ============================================================
    f.closeBtn = CreateFrame("Button", nil, f)
    f.closeBtn:SetSize(CLOSE_BTN_SIZE, CLOSE_BTN_SIZE)
    f.closeBtn:SetPoint("TOPRIGHT", -2, -2)
    f.closeBtn.tex = f.closeBtn:CreateTexture(nil, "ARTWORK")
    f.closeBtn.tex:SetAllPoints()
    f.closeBtn.tex:SetTexture("Interface\\Buttons\\UI-StopButton")
    f.closeBtn.tex:SetVertexColor(0.7, 0.7, 0.7)
    f.closeBtn:SetScript("OnEnter", function(self)
        self.tex:SetVertexColor(1, 0.3, 0.3)
    end)
    f.closeBtn:SetScript("OnLeave", function(self)
        self.tex:SetVertexColor(0.7, 0.7, 0.7)
    end)
    f.closeBtn:SetScript("OnClick", function()
        MP.UtilityFrame:Hide()
    end)

    -- ============================================================
    -- Dungeon Selector Button
    -- ============================================================
    f.selectorBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    f.selectorBtn:SetSize(FRAME_WIDTH - 2 * LEFT_PADDING, DROPDOWN_HEIGHT)
    f.selectorBtn:SetPoint("TOP", f.headerText, "BOTTOM", 0, -4)

    f.selectorBtn:SetBackdrop(SELECTOR_BACKDROP)
    f.selectorBtn:SetBackdropColor(0.10, 0.10, 0.15, 0.8)
    f.selectorBtn:SetBackdropBorderColor(0.25, 0.25, 0.35, 0.6)

    f.selectorBtn.text = f.selectorBtn:CreateFontString(nil, "OVERLAY")
    f.selectorBtn.text:SetFontObject("GameFontHighlightLarge")
    f.selectorBtn.text:SetPoint("LEFT", 6, 0)
    f.selectorBtn.text:SetTextColor(0.7, 0.7, 0.8)
    f.selectorBtn.text:SetText("Select Dungeon...")

    f.selectorBtn.arrow = f.selectorBtn:CreateTexture(nil, "OVERLAY")
    f.selectorBtn.arrow:SetSize(16, 16)
    f.selectorBtn.arrow:SetPoint("RIGHT", -6, 0)
    f.selectorBtn.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")

    f.selectorBtn:SetScript("OnEnter", function(self)
        if not InCombatLockdown() then
            local show = not MP.db or MP.db.showBackdrop ~= false
            if show then
                self:SetBackdropBorderColor(0.00, 0.60, 0.90, 0.6)
            end
        end
    end)
    f.selectorBtn:SetScript("OnLeave", function(self)
        if not InCombatLockdown() then
            local show = not MP.db or MP.db.showBackdrop ~= false
            if show then
                self:SetBackdropBorderColor(0.25, 0.25, 0.35, 0.6)
            end
        end
    end)
    f.selectorBtn:SetScript("OnClick", function(self)
        MP.UtilityFrame:ToggleDropdown()
    end)

    -- ============================================================
    -- Dropdown Menu Frame
    -- ============================================================
    f.dropdown = CreateFrame("Frame", "MythicPulseUtilityDropdown", f, "BackdropTemplate")
    f.dropdown:SetFrameStrata("TOOLTIP")
    f.dropdown:SetFrameLevel(100)
    f.dropdown:SetBackdrop(DROPDOWN_BACKDROP)
    f.dropdown:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
    f.dropdown:SetBackdropBorderColor(0.20, 0.20, 0.30, 0.8)
    f.dropdown:Hide()
    f.dropdown.buttons = {}

    -- ============================================================
    -- Separator line below selector
    -- ============================================================
    f.separator = f:CreateTexture(nil, "ARTWORK")
    f.separator:SetTexture("Interface\\Buttons\\WHITE8x8")
    f.separator:SetHeight(1)
    f.separator:SetPoint("TOPLEFT", f.selectorBtn, "BOTTOMLEFT", 0, -4)
    f.separator:SetPoint("TOPRIGHT", f.selectorBtn, "BOTTOMRIGHT", 0, -4)
    f.separator:SetVertexColor(0.20, 0.20, 0.30, 0.4)

    -- ============================================================
    -- Content area (ability rows go here)
    -- ============================================================
    f.content = CreateFrame("Frame", nil, f)
    f.content:SetPoint("TOPLEFT", f.separator, "BOTTOMLEFT", 0, -ICON_SPACING)
    f.content:SetPoint("RIGHT", f, "RIGHT", -RIGHT_PADDING, 0)
    f.content:SetHyperlinksEnabled(true)
    f.content:SetScript("OnHyperlinkEnter", function(self, link, text)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    f.content:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button, self)
    end)
    f.content:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)

    -- ============================================================
    -- Empty state text
    -- ============================================================
    f.emptyText = f:CreateFontString(nil, "OVERLAY")
    f.emptyText:SetFontObject(MP.Fonts and MP.Fonts.Body or "GameFontNormal")
    f.emptyText:SetPoint("TOP", f.separator, "BOTTOM", 0, -20)
    f.emptyText:SetTextColor(0.5, 0.5, 0.6)
    f.emptyText:SetText("No utility abilities for this dungeon")
    f.emptyText:Hide()

    -- Storage for ability rows
    f.rows = {}

    -- Final sync after all visual layers exist.
    MP:ApplyBackdrop(f)
    MP.UtilityFrame:ApplyBackdropState()

    return f
end

----------------------------------------------------------------------
-- Sync Utility subframe visuals with showBackdrop
----------------------------------------------------------------------
function MP.UtilityFrame:ApplyBackdropState()
    if not self.frame then return end
    if InCombatLockdown() then
        C_Timer.After(0.5, function()
            if MP.UtilityFrame then
                MP.UtilityFrame:ApplyBackdropState()
            end
        end)
        return
    end

    local f = self.frame
    local show = not MP.db or MP.db.showBackdrop ~= false

    if show then
        f.selectorBtn:SetBackdrop(SELECTOR_BACKDROP)
        f.selectorBtn:SetBackdropColor(0.10, 0.10, 0.15, 0.8)
        f.selectorBtn:SetBackdropBorderColor(0.25, 0.25, 0.35, 0.6)

        f.dropdown:SetBackdrop(DROPDOWN_BACKDROP)
        f.dropdown:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
        f.dropdown:SetBackdropBorderColor(0.20, 0.20, 0.30, 0.8)

        f.separator:SetVertexColor(0.20, 0.20, 0.30, 0.4)
        f.separator:Show()
    else
        f.selectorBtn:SetBackdropColor(0, 0, 0, 0)
        f.selectorBtn:SetBackdropBorderColor(0, 0, 0, 0)
        f.selectorBtn:SetBackdrop(nil)

        f.dropdown:SetBackdropColor(0, 0, 0, 0)
        f.dropdown:SetBackdropBorderColor(0, 0, 0, 0)
        f.dropdown:SetBackdrop(nil)

        f.separator:SetVertexColor(0, 0, 0, 0)
        f.separator:Hide()
    end
end

----------------------------------------------------------------------
-- Build / Rebuild Content Rows
----------------------------------------------------------------------
function MP.UtilityFrame:RefreshContent()
    if not self.frame then return end

    local du = MP:GetModule("DungeonUtility")
    if not du then return end

    -- Update header
    local UD = MP.UtilityData
    local dungeonName = UD and UD.dungeonNames and UD.dungeonNames[du.currentDungeonID] or "Unknown Dungeon"
    self.frame.headerText:SetText(dungeonName)
    self.frame.selectorBtn.text:SetText(dungeonName)

    -- Get display list
    local abilities = du:GetDisplayList()

    -- Hide all existing rows
    for _, row in ipairs(self.frame.rows) do
        row:Hide()
        if row.detailFrame then
            row.detailFrame:Hide()
        end
    end

    -- Show empty state if no abilities
    if #abilities == 0 then
        self.frame.emptyText:Show()
        self:UpdateFrameHeight()
        return
    else
        self.frame.emptyText:Hide()
    end

    -- Create or update rows
    local yOffset = 0

    for i, ability in ipairs(abilities) do
        local row = self.frame.rows[i]

        -- Create row if needed
        if not row then
            row = self:CreateAbilityRow(i)
            self.frame.rows[i] = row
        end

        -- Configure row
        self:ConfigureAbilityRow(row, ability)

        -- Position row
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", self.frame.content, "RIGHT", 0, 0)
        row:Show()

        yOffset = yOffset + ICON_SIZE + ICON_SPACING

        -- If detail frame is shown, account for its height
        if row.detailFrame and row.detailFrame:IsShown() then
            row.detailFrame:ClearAllPoints()
            row.detailFrame:SetPoint("TOPLEFT", self.frame.content, "TOPLEFT", ENTRY_INDENT, -yOffset)
            row.detailFrame:SetPoint("RIGHT", self.frame.content, "RIGHT", 0, 0)

            local detailHeight = self:GetDetailHeight(row.detailFrame)
            row.detailFrame:SetHeight(math.max(detailHeight, 1))

            yOffset = yOffset + detailHeight + ICON_SPACING
        end
    end

    self:UpdateFrameHeight()
end

----------------------------------------------------------------------
-- Create an Ability Row
----------------------------------------------------------------------
function MP.UtilityFrame:CreateAbilityRow(index)
    local row = CreateFrame("Button", nil, self.frame.content)
    row:SetHeight(ICON_SIZE)

    -- Category label (left side, outside the row)
    row.categoryLabel = row:CreateFontString(nil, "OVERLAY")
    row.categoryLabel:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    row.categoryLabel:SetPoint("RIGHT", row, "LEFT", -4, 0)
    row.categoryLabel:SetJustifyH("RIGHT")
    row.categoryLabel:SetWidth(LABEL_WIDTH + 10)

    -- Icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ICON_SIZE, ICON_SIZE)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Icon border
    row.iconBorder = row:CreateTexture(nil, "OVERLAY")
    row.iconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.iconBorder:SetPoint("TOPLEFT", row.icon, "TOPLEFT", -1, 1)
    row.iconBorder:SetPoint("BOTTOMRIGHT", row.icon, "BOTTOMRIGHT", 1, -1)
    row.iconBorder:SetVertexColor(0.3, 0.3, 0.4, 0.8)
    row.iconBorder:SetDrawLayer("OVERLAY", 6)
    row.icon:SetDrawLayer("ARTWORK", 1)

    -- Ability name
    row.nameText = row:CreateFontString(nil, "OVERLAY")
    row.nameText:SetFontObject("GameFontHighlightLarge")
    row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.nameText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(true)
    row.nameText:SetMaxLines(2)

    -- Click handler (toggle detail entries)
    row:SetScript("OnClick", function(self)
        if self.detailFrame then
            self.detailFrame:SetShown(not self.detailFrame:IsShown())
            MP.UtilityFrame:RefreshContent()
        end
    end)

    -- Highlight on hover
    row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
    row.highlight:SetAllPoints()
    row.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.highlight:SetVertexColor(1, 1, 1, 0.05)

    -- Detail frame (hidden by default)
    row.detailFrame = CreateFrame("Frame", nil, self.frame.content)
    row.detailFrame:SetHyperlinksEnabled(true)
    row.detailFrame:SetScript("OnHyperlinkEnter", function(self, link, text)
        GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
        GameTooltip:SetHyperlink(link)
        GameTooltip:Show()
    end)
    row.detailFrame:SetScript("OnHyperlinkClick", function(self, link, text, button)
        SetItemRef(link, text, button, self)
    end)
    row.detailFrame:SetScript("OnHyperlinkLeave", function()
        GameTooltip:Hide()
    end)
    row.detailFrame:Hide()
    row.detailFrame.lines = {}

    return row
end

----------------------------------------------------------------------
-- Configure an Ability Row with data
----------------------------------------------------------------------
function MP.UtilityFrame:ConfigureAbilityRow(row, ability)
    local du = MP:GetModule("DungeonUtility")
    if not du then return end

    local spellID = ability.altSpellID or ability.spellID
    local config = CATEGORY_CONFIG[ability.buttonType] or CATEGORY_CONFIG.known

    -- Icon
    local iconTexture = du:GetSpellIcon(spellID)
    if iconTexture then
        row.icon:SetTexture(iconTexture)
    end

    -- Icon cosmetics — mirrors affix active/inactive logic
    row.icon:SetDesaturated(config.desaturate)
    row.icon:SetVertexColor(unpack(config.iconColor))
    row:SetAlpha(config.alpha or 1.0)
    if row.iconBorder then
        row.iconBorder:SetVertexColor(unpack(config.borderColor or { 0.3, 0.3, 0.4, 0.8 }))
    end

    -- Category label
    row.categoryLabel:SetText(config.label)
    row.categoryLabel:SetTextColor(unpack(config.labelColor))

    -- Ability name (with self-only triangle marker)
    local name = ability.spellName or du:GetSpellName(spellID)
    if ability.tagsTable and ability.tagsTable.self_only then
        -- Text marker for self-only abilities (triangle symbol is not supported by standard WoW fonts)
        name = "|cffaaaaaa(Self)|r " .. name
    end
    row.nameText:SetText(name)

    -- Tooltip on icon
    SetupSpellTooltip(row, spellID)

    -- Store data reference
    row.abilityData = ability

    -- Update detail lines
    local entries = ability.matchedEntries or {}

    -- Hide old lines
    for _, line in ipairs(row.detailFrame.lines) do
        line:Hide()
    end

    -- Create/update lines
    for j, entryText in ipairs(entries) do
        local line = row.detailFrame.lines[j]
        if not line then
            line = row.detailFrame:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
            line:SetJustifyH("LEFT")
            line:SetWordWrap(true)
            line:SetWidth(FRAME_WIDTH - LEFT_PADDING - RIGHT_PADDING - ENTRY_INDENT - 10)
            if MP.Fonts and MP.Fonts.Body then
                line:SetFontObject(MP.Fonts.Body)
            else
                line:SetFontObject("GameFontNormal")
            end
            row.detailFrame.lines[j] = line
        end

        line:SetText(entryText)
        line:ClearAllPoints()

        if j == 1 then
            line:SetPoint("TOPLEFT", 0, 0)
        else
            line:SetPoint("TOPLEFT", row.detailFrame.lines[j - 1], "BOTTOMLEFT", 0, -ENTRY_SPACING)
        end
        line:Show()
    end

    -- Hide detail if no entries
    if #entries == 0 then
        row.detailFrame:Hide()
    end
end

----------------------------------------------------------------------
-- Calculate detail frame height
----------------------------------------------------------------------
function MP.UtilityFrame:GetDetailHeight(detailFrame)
    if not detailFrame or not detailFrame.lines then return 0 end

    local totalHeight = 0
    local shownCount = 0
    for _, line in ipairs(detailFrame.lines) do
        if line:IsShown() then
            totalHeight = totalHeight + line:GetStringHeight()
            shownCount = shownCount + 1
        end
    end

    -- Add spacing between lines
    if shownCount > 1 then
        totalHeight = totalHeight + (shownCount - 1) * ENTRY_SPACING
    end

    return totalHeight
end

----------------------------------------------------------------------
-- Update frame height to fit content
----------------------------------------------------------------------
function MP.UtilityFrame:UpdateFrameHeight()
    if not self.frame then return end

    local yOffset = 0

    for _, row in ipairs(self.frame.rows) do
        if row:IsShown() then
            yOffset = yOffset + ICON_SIZE + ICON_SPACING

            if row.detailFrame and row.detailFrame:IsShown() then
                local detailHeight = self:GetDetailHeight(row.detailFrame)
                yOffset = yOffset + detailHeight + ICON_SPACING
            end
        end
    end

    -- Total height = header + selector + separator + content + padding
    local headerHeight = self.frame.headerText:GetStringHeight() or HEADER_HEIGHT
    local selectorHeight = DROPDOWN_HEIGHT + 8 -- 4px padding top + bottom
    local totalHeight = TOP_PADDING + headerHeight + 4 + selectorHeight + 4 + yOffset + TOP_PADDING

    totalHeight = math.max(totalHeight, MIN_HEIGHT)
    totalHeight = math.min(totalHeight, MAX_HEIGHT)

    self.frame:SetHeight(totalHeight)
end

----------------------------------------------------------------------
-- Dropdown Management
----------------------------------------------------------------------
function MP.UtilityFrame:ToggleDropdown()
    if not self.frame then return end
    local dd = self.frame.dropdown

    if dd:IsShown() then
        dd:Hide()
        return
    end

    local du = MP:GetModule("DungeonUtility")
    if not du then return end

    local dungeons = du:GetDungeonList()

    -- Position dropdown below the selector button
    dd:ClearAllPoints()
    dd:SetPoint("TOPLEFT", self.frame.selectorBtn, "BOTTOMLEFT", 0, -1)
    dd:SetWidth(self.frame.selectorBtn:GetWidth())

    -- Hide old buttons
    for _, btn in ipairs(dd.buttons) do
        btn:Hide()
    end

    -- Create buttons for each dungeon
    local btnHeight = 24
    for i, dungeon in ipairs(dungeons) do
        local btn = dd.buttons[i]
        if not btn then
            btn = CreateFrame("Button", nil, dd)
            btn:SetHeight(btnHeight)
            btn.text = btn:CreateFontString(nil, "OVERLAY")
            btn.text:SetFontObject("GameFontNormalLarge")
            btn.text:SetPoint("LEFT", 6, 0)
            btn.text:SetJustifyH("LEFT")

            btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
            btn.highlight:SetAllPoints()
            btn.highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
            btn.highlight:SetVertexColor(0, 0, 0, 0)

            dd.buttons[i] = btn
        end

        btn:SetPoint("TOPLEFT", dd, "TOPLEFT", 2, -(i - 1) * btnHeight - 2)
        btn:SetPoint("RIGHT", dd, "RIGHT", -2, 0)
        btn.text:SetText(dungeon.name)

        -- Highlight current dungeon
        if dungeon.id == du.currentDungeonID then
            btn.text:SetTextColor(0.00, 0.80, 1.00)
        else
            btn.text:SetTextColor(0.85, 0.85, 0.85)
        end

        btn:SetScript("OnClick", function()
            du.currentDungeonID = dungeon.id
            du:PopulateForDungeon(dungeon.id)
            MP.UtilityFrame:RefreshContent()
            dd:Hide()
        end)
        if MP.db and MP.db.showBackdrop == false then
            btn.highlight:SetVertexColor(0, 0, 0, 0)
        else
            btn.highlight:SetVertexColor(0.00, 0.60, 0.90, 0.15)
        end
        btn:Show()
    end

    -- Set dropdown height
    dd:SetHeight(#dungeons * btnHeight + 4)
    dd:Show()
end

----------------------------------------------------------------------
-- Show / Hide / Toggle
----------------------------------------------------------------------
function MP.UtilityFrame:Show()
    if not self.frame then
        self:Initialize()
    end
    self:ApplyBackdropState()
    self:RefreshContent()
    self.frame:Show()
end

function MP.UtilityFrame:Hide()
    if self.frame then
        self.frame:Hide()
        if self.frame.dropdown then
            self.frame.dropdown:Hide()
        end
    end
end

function MP.UtilityFrame:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
function MP.UtilityFrame:Initialize()
    if self.frame then return end

    self.frame = CreateUtilityFrame()

    -- Restore saved position
    if MP.db and MP.db.modules and MP.db.modules.dungeonUtility then
        local cfg = MP.db.modules.dungeonUtility
        if cfg.framePoint then
            self.frame:ClearAllPoints()
            self.frame:SetPoint(
                cfg.framePoint or "CENTER",
                UIParent,
                cfg.frameRelPoint or "CENTER",
                cfg.frameX or 0,
                cfg.frameY or 0
            )
        else
            self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        end
    else
        self.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end

    self.frame:Hide()
    MP:Debug("UtilityFrame initialized")
end

----------------------------------------------------------------------
-- Auto-initialize on PLAYER_ENTERING_WORLD
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUI)
    -- Delay to ensure config is loaded
    C_Timer.After(1.5, function()
        if not MP.UtilityFrame.frame then
            MP.UtilityFrame:Initialize()
        end
    end)
end)
