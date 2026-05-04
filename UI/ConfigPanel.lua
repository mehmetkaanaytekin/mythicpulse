--[[
    MythicPulse - Config Panel
    Custom standalone settings panel with left sidebar and scrollable content pages.
]]

local _, MP = ...

MP.ConfigPanel = {}

----------------------------------------------------------------------
-- Layout constants
----------------------------------------------------------------------
local PANEL_W   = 680
local PANEL_H   = 540
local SIDEBAR_W = 160
local TITLE_H   = 36
local PAD       = 14
local ROW_H     = 26
local SLIDER_H  = 54
-- Usable width inside the scroll content area:
--   PANEL_W - SIDEBAR_W - sidebar_divider(1) - left_gap(4) - right_gap(4) - scrollbar(22) = ~489
-- Use a conservative constant for two-column slider math.
local CONTENT_W = PANEL_W - SIDEBAR_W - 50   -- 470

----------------------------------------------------------------------
-- Checkbox factory
----------------------------------------------------------------------
local function MakeCheckbox(parent, label, x, y, settingPath, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    cb.Text:SetFontObject(MP.Fonts.Body)
    cb:SetScript("OnClick", function(self)
        local v = self:GetChecked()
        MP:SetSetting(settingPath, v)
        if onChange then onChange(v) end
    end)
    function cb:Refresh()
        self:SetChecked(MP:GetSetting(settingPath))
    end
    return cb
end

----------------------------------------------------------------------
-- Slider factory
----------------------------------------------------------------------
local function MakeSlider(parent, label, x, y, w, minVal, maxVal, step, settingPath, onChange)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(MP.Fonts.Small)
    lbl:SetTextColor(0.75, 0.75, 0.80)
    lbl:SetPoint("TOPLEFT", x, y)
    lbl:SetText(label)

    local sl = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    sl:SetPoint("TOPLEFT", x, y - 16)
    sl:SetWidth(w or 200)
    sl:SetMinMaxValues(minVal, maxVal)
    sl:SetValueStep(step)
    sl:SetObeyStepOnDrag(true)
    if sl.Text  then sl.Text:SetText("") end
    if sl.Low   then sl.Low:SetText(tostring(minVal)) end
    if sl.High  then sl.High:SetText(tostring(maxVal)) end

    sl.valText = sl:CreateFontString(nil, "OVERLAY")
    sl.valText:SetFontObject(MP.Fonts.Small)
    sl.valText:SetPoint("TOP", sl, "BOTTOM", 0, -2)

    local fmt = (step < 1) and "%.2f" or "%.0f"
    sl:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / step + 0.5) * step
        self.valText:SetText(string.format(fmt, v))
        MP:SetSetting(settingPath, v)
        if onChange then onChange(v) end
    end)
    function sl:Refresh()
        local v = MP:GetSetting(settingPath) or minVal
        self:SetValue(v)
        self.valText:SetText(string.format(fmt, v))
    end
    return sl
end

----------------------------------------------------------------------
-- Cycle button factory
----------------------------------------------------------------------
local function MakeCycleBtn(parent, label, x, y, options, settingPath, onChange)
    local lbl = parent:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(MP.Fonts.Small)
    lbl:SetTextColor(0.75, 0.75, 0.80)
    lbl:SetPoint("TOPLEFT", x, y)
    lbl:SetText(label)

    local btn = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    btn:SetSize(140, 22)
    btn:SetPoint("TOPLEFT", x, y - 18)

    local function GetCur() return MP:GetSetting(settingPath) or options[1] end
    local function Refresh() btn:SetText(GetCur()) end
    btn:SetScript("OnClick", function()
        local cur, idx = GetCur(), 1
        for i, v in ipairs(options) do if v == cur then idx = i; break end end
        local nxt = options[(idx % #options) + 1]
        MP:SetSetting(settingPath, nxt)
        Refresh()
        if onChange then onChange(nxt) end
    end)
    function btn:Refresh() Refresh() end
    Refresh()
    return btn
end

----------------------------------------------------------------------
-- Page factory — each category gets one plain Frame (no scrollbar)
----------------------------------------------------------------------
local HALF_W = math.floor((CONTENT_W - PAD * 3) / 2)

local function MakePage(container)
    local body = CreateFrame("Frame", nil, container)
    body:SetAllPoints(container)
    body:Hide()

    local ctrls = {}
    local y = -PAD

    local p = { body = body, controls = ctrls, y = y }

    function p:Show() body:Show() end
    function p:Hide() body:Hide() end

    -- Section header with a faint rule
    function p:Header(text)
        local fs = body:CreateFontString(nil, "OVERLAY")
        fs:SetFontObject(MP.Fonts.Header)
        fs:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
        fs:SetPoint("TOPLEFT", PAD, self.y)
        fs:SetText(text)
        self.y = self.y - 22

        local rule = body:CreateTexture(nil, "ARTWORK")
        rule:SetTexture("Interface\\Buttons\\WHITE8x8")
        rule:SetHeight(1)
        rule:SetPoint("TOPLEFT",  PAD, self.y)
        rule:SetPoint("TOPRIGHT", body, "TOPRIGHT", -PAD, self.y)
        rule:SetVertexColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b, 0.25)
        self.y = self.y - 10
    end

    -- Checkbox
    function p:Check(label, path, onChange)
        local cb = MakeCheckbox(body, label, PAD, self.y, path, onChange)
        table.insert(ctrls, cb)
        self.y = self.y - ROW_H
        return cb
    end

    -- Single full-width slider
    function p:Slider(label, minV, maxV, step, path, onChange)
        local s = MakeSlider(body, label, PAD, self.y, 200, minV, maxV, step, path, onChange)
        table.insert(ctrls, s)
        self.y = self.y - SLIDER_H
        return s
    end

    -- Two sliders side by side
    function p:SliderRow(L, R)
        if L then
            local s = MakeSlider(body, L.label, PAD, self.y, HALF_W, L.min, L.max, L.step, L.path, L.onChange)
            table.insert(ctrls, s)
        end
        if R then
            local s = MakeSlider(body, R.label, PAD * 2 + HALF_W, self.y, HALF_W, R.min, R.max, R.step, R.path, R.onChange)
            table.insert(ctrls, s)
        end
        self.y = self.y - SLIDER_H
    end

    -- Two cycle buttons side by side
    function p:CycleRow(L, R)
        if L then
            local b = MakeCycleBtn(body, L.label, PAD, self.y, L.options, L.path, L.onChange)
            table.insert(ctrls, b)
        end
        if R then
            local b = MakeCycleBtn(body, R.label, PAD * 2 + HALF_W, self.y, R.options, R.path, R.onChange)
            table.insert(ctrls, b)
        end
        self.y = self.y - 46
    end

    -- Small gap
    function p:Gap(h) self.y = self.y - (h or 10) end

    -- Muted note/caption
    function p:Note(text)
        local fs = body:CreateFontString(nil, "OVERLAY")
        fs:SetFontObject(MP.Fonts.Small)
        fs:SetTextColor(0.52, 0.52, 0.58)
        fs:SetPoint("TOPLEFT", PAD, self.y)
        fs:SetText(text)
        self.y = self.y - 18
        return fs
    end

    -- Standard button
    function p:Btn(label, w, onClick)
        local btn = CreateFrame("Button", nil, body, "UIPanelButtonTemplate")
        btn:SetSize(w or 150, 24)
        btn:SetPoint("TOPLEFT", PAD, self.y)
        btn:SetText(label)
        btn:SetScript("OnClick", onClick)
        self.y = self.y - 30
        return btn
    end

    -- No-op: body fills container via SetAllPoints, no explicit height needed
    function p:Done() end

    -- Refresh all controls
    function p:Refresh()
        for _, c in ipairs(ctrls) do
            if c.Refresh then c:Refresh() end
        end
    end

    return p
end

----------------------------------------------------------------------
-- Sidebar button factory
----------------------------------------------------------------------
local function MakeSidebarBtn(sidebar, label, yOff, onClick)
    local btn = CreateFrame("Button", nil, sidebar)
    btn:SetHeight(36)
    btn:SetPoint("TOPLEFT",  sidebar, "TOPLEFT",  4, yOff)
    btn:SetPoint("TOPRIGHT", sidebar, "TOPRIGHT", -4, yOff)

    btn._bg = btn:CreateTexture(nil, "BACKGROUND")
    btn._bg:SetAllPoints()
    btn._bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    btn._bg:SetVertexColor(0, 0, 0, 0)

    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFontObject(MP.Fonts.Body)
    lbl:SetTextColor(0.78, 0.78, 0.84)
    lbl:SetJustifyH("LEFT")
    lbl:SetPoint("LEFT", btn, "LEFT", 14, 0)
    btn._lbl = lbl
    lbl:SetText(label)

    btn:SetScript("OnEnter", function(self)
        if not self._sel then
            self._bg:SetVertexColor(0.15, 0.15, 0.22, 0.55)
            lbl:SetTextColor(1, 1, 1)
        end
    end)
    btn:SetScript("OnLeave", function(self)
        if not self._sel then
            self._bg:SetVertexColor(0, 0, 0, 0)
            lbl:SetTextColor(0.78, 0.78, 0.84)
        end
    end)
    btn:SetScript("OnClick", onClick)

    function btn:Select(v)
        self._sel = v
        if v then
            local r, g, b = MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b
            self._bg:SetVertexColor(r * 0.22, g * 0.22, b * 0.22, 0.85)
            lbl:SetTextColor(1, 1, 1)
        else
            self._bg:SetVertexColor(0, 0, 0, 0)
            lbl:SetTextColor(0.78, 0.78, 0.84)
        end
    end

    return btn
end

----------------------------------------------------------------------
-- Build the full panel
----------------------------------------------------------------------
local function BuildPanel()
    local f = CreateFrame("Frame", "MythicPulseConfigPanel", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_W, PANEL_H)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetPoint("CENTER")
    f:Hide()

    -- Register with UISpecialFrames so Escape closes the panel
    tinsert(UISpecialFrames, "MythicPulseConfigPanel")

    MP:CreateBackdrop(f, MP.COLORS.bgDark)
    MP:CreateGlow(f, MP.COLORS.borderGlow, 3)

    -- Drag
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if MP.db then
            if not MP.db.configPanel then MP.db.configPanel = {} end
            local pt, _, rpt, x, y = self:GetPoint()
            MP.db.configPanel.point    = pt
            MP.db.configPanel.relPoint = rpt
            MP.db.configPanel.x        = x
            MP.db.configPanel.y        = y
        end
    end)

    -- Title bar background strip
    local titleBg = f:CreateTexture(nil, "BACKGROUND", nil, 1)
    titleBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleBg:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -1)
    titleBg:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    titleBg:SetHeight(TITLE_H)
    titleBg:SetVertexColor(0, 0, 0, 0.40)

    -- Title text
    local titleText = f:CreateFontString(nil, "OVERLAY")
    titleText:SetFontObject(MP.Fonts.Header)
    titleText:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
    titleText:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, -(TITLE_H / 2 - 7))
    titleText:SetText("MythicPulse  |cff666688Settings|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", 2, 2)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Hairline below title bar
    local hline = f:CreateTexture(nil, "ARTWORK")
    hline:SetHeight(1)
    hline:SetPoint("TOPLEFT",  f, "TOPLEFT",  1, -TITLE_H)
    hline:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -TITLE_H)
    hline:SetTexture("Interface\\Buttons\\WHITE8x8")
    hline:SetVertexColor(MP.COLORS.border.r, MP.COLORS.border.g, MP.COLORS.border.b, 0.70)

    -- Sidebar
    local sidebar = CreateFrame("Frame", nil, f)
    sidebar:SetPoint("TOPLEFT",    f, "TOPLEFT",    1, -(TITLE_H + 1))
    sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 1, 1)
    sidebar:SetWidth(SIDEBAR_W)

    local sidebarBg = sidebar:CreateTexture(nil, "BACKGROUND")
    sidebarBg:SetAllPoints()
    sidebarBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    sidebarBg:SetVertexColor(0, 0, 0, 0.20)

    -- Vertical divider between sidebar and content
    local sDiv = f:CreateTexture(nil, "ARTWORK")
    sDiv:SetWidth(1)
    sDiv:SetPoint("TOPLEFT",    sidebar, "TOPRIGHT",    0,  0)
    sDiv:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0,  0)
    sDiv:SetTexture("Interface\\Buttons\\WHITE8x8")
    sDiv:SetVertexColor(MP.COLORS.border.r, MP.COLORS.border.g, MP.COLORS.border.b, 0.55)

    -- Content area to the right of the sidebar
    local contentArea = CreateFrame("Frame", nil, f)
    contentArea:SetPoint("TOPLEFT",     sidebar, "TOPRIGHT",     4, -4)
    contentArea:SetPoint("BOTTOMRIGHT", f,       "BOTTOMRIGHT", -4,  4)

    -- Pages and sidebar buttons
    local pages    = {}
    local sideBtns = {}
    local active   = nil
    local sideY    = -8

    local function SelectPage(name)
        if active and pages[active] then pages[active]:Hide() end
        active = name
        if pages[name] then pages[name]:Show() end
        for n, btn in pairs(sideBtns) do btn:Select(n == name) end
    end

    local function AddCat(name, builder)
        local page = MakePage(contentArea)
        pages[name] = page
        builder(page)
        page:Done()

        local btn = MakeSidebarBtn(sidebar, name, sideY, function() SelectPage(name) end)
        sideBtns[name] = btn
        sideY = sideY - 38
    end

    local function RebuildCDs()
        local pc = MP:GetModule("PartyCooldowns")
        if pc and pc.RebuildAll then pc:RebuildAll() end
    end

    ----------------------------------------------------------------
    -- General
    ----------------------------------------------------------------
    AddCat("General", function(p)
        p:Header("Behavior")
        p:Check("Lock Frame Position", "locked", function()
            if MP.MainFrame and MP.MainFrame.UpdateLock then MP.MainFrame:UpdateLock() end
        end)

        p:Gap(12)
        p:Header("Actions")
        p:Btn("Reset HUD Position", 160, function()
            if MP.MainFrame and MP.MainFrame.ResetPosition then
                MP.MainFrame:ResetPosition()
                MP:Print("Main frame position reset.")
            end
        end)
        p:Btn("Reset All Settings", 160, function()
            StaticPopup_Show("MYTHICPULSE_RESET_CONFIRM")
        end)
        p:Btn("Reload UI", 140, ReloadUI)

        p:Gap(12)
        p:Header("About")
        p:Note("MythicPulse v" .. (MP.version or "1.0.0"))
        p:Note("/mp help  —  list all slash commands")
        p:Note("/mp config  —  toggle this panel")
    end)

    ----------------------------------------------------------------
    -- Display
    ----------------------------------------------------------------
    AddCat("Display", function(p)
        p:Header("Main HUD")
        p:SliderRow(
            {
                label = "Scale",
                min = 0.5, max = 2.0, step = 0.1,
                path = "mainFrame.scale",
                onChange = function(v)
                    if MP.MainFrame and MP.MainFrame.frame then MP.MainFrame.frame:SetScale(v) end
                end,
            },
            {
                label = "Opacity",
                min = 0.1, max = 1.0, step = 0.05,
                path = "mainFrame.alpha",
                onChange = function(v)
                    if MP.MainFrame and MP.MainFrame.frame then MP.MainFrame.frame:SetAlpha(v) end
                end,
            }
        )

        p:Gap(4)
        p:Header("Interrupt Frame")
        p:SliderRow(
            {
                label = "Scale",
                min = 0.5, max = 2.0, step = 0.1,
                path = "interruptFrame.scale",
                onChange = function(v)
                    if MP.InterruptFrame and MP.InterruptFrame.frame then MP.InterruptFrame.frame:SetScale(v) end
                end,
            },
            {
                label = "Opacity",
                min = 0.1, max = 1.0, step = 0.05,
                path = "interruptFrame.alpha",
                onChange = function(v)
                    if MP.InterruptFrame and MP.InterruptFrame.frame then MP.InterruptFrame.frame:SetAlpha(v) end
                end,
            }
        )

        p:Gap(4)
        p:Header("Font & Icon Sizes")
        p:SliderRow(
            {
                label = "Font Scale",
                min = 0.7, max = 2.0, step = 0.05,
                path = "fontScale",
                onChange = function()
                    if MP.Fonts and MP.Fonts.Apply then MP.Fonts:Apply() end
                end,
            },
            {
                label = "Party CD Icon Size",
                min = 20, max = 48, step = 1,
                path = "modules.partyCooldowns.iconSize",
                onChange = function() RebuildCDs() end,
            }
        )
        p:Slider("BRes / BL Icon Size", 28, 56, 1, "modules.combatRes.iconSize", function()
            MP:Print("|cff88ccffReload UI (/reload)|r to apply icon size changes.")
        end)
    end)

    ----------------------------------------------------------------
    -- Party Cooldowns
    ----------------------------------------------------------------
    local GROWTH_OPTS = { "RIGHT", "LEFT", "UP", "DOWN" }
    local ANCHOR_OPTS = {
        "LEFT", "RIGHT", "TOP", "BOTTOM",
        "TOPLEFT", "TOPRIGHT", "BOTTOMLEFT", "BOTTOMRIGHT", "CENTER",
    }

    AddCat("Party CDs", function(p)
        p:Header("Layout")
        p:SliderRow(
            {
                label = "Icon Gap",
                min = 0, max = 16, step = 1,
                path = "modules.partyCooldowns.iconGap",
                onChange = function() RebuildCDs() end,
            },
            {
                label = "Max Icons",
                min = 1, max = 12, step = 1,
                path = "modules.partyCooldowns.maxIcons",
                onChange = function() RebuildCDs() end,
            }
        )
        p:Slider("Icons Per Row", 1, 12, 1, "modules.partyCooldowns.iconsPerRow", function() RebuildCDs() end)
        p:Check("Show Dispel Bar", "modules.partyCooldowns.showDispelBar", function() RebuildCDs() end)

        p:Gap(4)
        p:Header("Anchoring")
        p:CycleRow(
            {
                label   = "Growth Direction",
                options = GROWTH_OPTS,
                path    = "modules.partyCooldowns.growthDirection",
                onChange = function() RebuildCDs() end,
            },
            {
                label   = "Row Anchor Point",
                options = ANCHOR_OPTS,
                path    = "modules.partyCooldowns.anchorPoint",
                onChange = function() RebuildCDs() end,
            }
        )
        p:CycleRow(
            {
                label   = "Unit Frame Anchor",
                options = ANCHOR_OPTS,
                path    = "modules.partyCooldowns.relativePoint",
                onChange = function() RebuildCDs() end,
            },
            nil
        )
        p:SliderRow(
            {
                label = "Offset X",
                min = -100, max = 100, step = 1,
                path = "modules.partyCooldowns.offsetX",
                onChange = function() RebuildCDs() end,
            },
            {
                label = "Offset Y",
                min = -100, max = 100, step = 1,
                path = "modules.partyCooldowns.offsetY",
                onChange = function() RebuildCDs() end,
            }
        )
    end)

    ----------------------------------------------------------------
    -- Combat
    ----------------------------------------------------------------
    AddCat("Combat", function(p)
        p:Header("Interrupts")
        p:Check("Auto-Announce Kick Rotation", "modules.interruptTracker.autoAnnounce")
        p:Check("Show Interrupt Tracker in Combat Only", "modules.interruptTracker.showInCombatOnly", function(v)
            local it = MP:GetModule("InterruptTracker")
            if it and it.UpdateVisibility then it:UpdateVisibility() end
        end)

        p:Gap(12)
        p:Header("Bloodlust / Battle Res")
        p:Note("Auto-detects: Shaman, Mage, and Hunter (with active pet).")
        p:Note("More options coming soon.")
    end)

    ----------------------------------------------------------------
    -- Utility
    ----------------------------------------------------------------
    AddCat("Utility", function(p)
        p:Header("Dungeon Utility Panel")
        p:Check("Auto-Show When Entering a Dungeon", "modules.dungeonUtility.autoShow")
        p:Check("Show Ability Remove Buttons", "modules.dungeonUtility.showRemove")
        p:Check("Hide Non-Important Entries", "modules.dungeonUtility.hideNotImportant")

        p:Gap(12)
        p:Header("Run History")
        p:Slider("Max History Entries", 50, 500, 10, "modules.dungeonHistory.maxEntries")
        p:Note("Older entries are pruned when the limit is reached.")
    end)

    ----------------------------------------------------------------
    -- Modules
    ----------------------------------------------------------------
    AddCat("Modules", function(p)
        p:Header("Enable / Disable Modules")
        p:Note("Changes take effect after /reload.")
        p:Gap(4)

        local function ModToggle(modName)
            return function(checked)
                if checked then MP:EnableModule(modName) else MP:DisableModule(modName) end
            end
        end

        local MODS = {
            { label = "Dungeon Timer",       path = "modules.timer.enabled",            mod = "Timer" },
            { label = "Death Tracker",       path = "modules.deathTracker.enabled",     mod = "DeathTracker" },
            { label = "Enemy Forces",        path = "modules.enemyForces.enabled",      mod = "EnemyForces" },
            { label = "Keystone Tracker",    path = "modules.keystoneTracker.enabled",  mod = "KeystoneTracker" },
            { label = "Party Cooldowns",     path = "modules.partyCooldowns.enabled",   mod = "PartyCooldowns" },
            { label = "Interrupt Tracker",   path = "modules.interruptTracker.enabled", mod = "InterruptTracker" },
            { label = "Dispel Tracker",      path = "modules.dispelTracker.enabled",    mod = "DispelTracker" },
            { label = "Trinket Tracker",     path = "modules.trinketTracker.enabled",   mod = "TrinketTracker" },
            { label = "Auto Gossip (coming soon)", path = "modules.autoGossip.enabled",   mod = "AutoGossip" },
            { label = "Battle Res Tracker",  path = "modules.combatRes.enabled",        mod = "CombatRes" },
            { label = "Dungeon History",     path = "modules.dungeonHistory.enabled",   mod = "DungeonHistory" },
            { label = "Auto Keystone Slot",  path = "modules.autoSlot.enabled",         mod = "AutoSlot" },
            { label = "Dungeon Teleports",   path = "modules.dungeonTeleport.enabled",  mod = "DungeonTeleport" },
            { label = "Dungeon Utility",     path = "modules.dungeonUtility.enabled",   mod = "DungeonUtility" },
        }

        -- Two-column layout
        local col2x  = PAD * 2 + HALF_W
        local split  = math.ceil(#MODS / 2)
        local leftY  = p.y
        local rightY = p.y
        for i, m in ipairs(MODS) do
            local cb
            if i <= split then
                cb = MakeCheckbox(p.body, m.label, PAD, leftY, m.path, ModToggle(m.mod))
                leftY = leftY - ROW_H
            else
                cb = MakeCheckbox(p.body, m.label, col2x, rightY, m.path, ModToggle(m.mod))
                rightY = rightY - ROW_H
            end
            table.insert(p.controls, cb)
        end
        p.y = math.min(leftY, rightY) - 4
    end)

    -- Start on General
    SelectPage("General")

    -- Confirmation dialog (define once)
    if not StaticPopupDialogs["MYTHICPULSE_RESET_CONFIRM"] then
        StaticPopupDialogs["MYTHICPULSE_RESET_CONFIRM"] = {
            text         = "Reset all MythicPulse settings to defaults?",
            button1      = "Yes",
            button2      = "No",
            OnAccept     = function()
                MP:ResetConfig()
                for _, page in pairs(pages) do page:Refresh() end
            end,
            timeout      = 0,
            whileDead    = true,
            hideOnEscape = true,
        }
    end

    -- Refresh all pages when shown
    function f:Refresh()
        for _, page in pairs(pages) do page:Refresh() end
    end
    f:SetScript("OnShow", function(self) self:Refresh() end)

    return f
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function MP.ConfigPanel:Init()
    if self.panel then return end
    self.panel = BuildPanel()

    -- Restore saved position
    if MP.db and MP.db.configPanel then
        local cp = MP.db.configPanel
        if cp.point then
            self.panel:ClearAllPoints()
            self.panel:SetPoint(cp.point, UIParent, cp.relPoint or cp.point, cp.x or 0, cp.y or 0)
        end
    end
end

function MP.ConfigPanel:Toggle()
    if not self.panel then self:Init() end
    if self.panel:IsShown() then
        self.panel:Hide()
    else
        self.panel:Show()
    end
end

----------------------------------------------------------------------
-- Init on login
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isLogin)
    if isLogin or not MP.ConfigPanel.panel then
        C_Timer.After(0.5, function()
            MP.ConfigPanel:Init()
        end)
    end
end)
