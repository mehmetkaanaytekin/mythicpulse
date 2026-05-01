--[[
    MythicPulse - Config Panel
    Settings UI panel registered in Interface > AddOns.
]]

local _, MP = ...

MP.ConfigPanel = {}

local PANEL_WIDTH  = 400
local ROW_HEIGHT   = 26
local INDENT       = 16

----------------------------------------------------------------------
-- Checkbox Factory
----------------------------------------------------------------------
local function CreateCheckbox(parent, label, x, y, settingPath, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    cb.Text:SetText(label)
    cb.Text:SetFontObject(MP.Fonts.Body)

    cb:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        MP:SetSetting(settingPath, checked)
        if onChange then onChange(checked) end
    end)

    function cb:Refresh()
        self:SetChecked(MP:GetSetting(settingPath))
    end

    return cb
end

----------------------------------------------------------------------
-- Slider Factory
----------------------------------------------------------------------
local function CreateSlider(parent, label, x, y, minVal, maxVal, step, settingPath, onChange)
    local slider = CreateFrame("Slider", nil, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(200)
    slider:SetMinMaxValues(minVal, maxVal)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)

    slider.Text:SetText(label)
    slider.Low:SetText(tostring(minVal))
    slider.High:SetText(tostring(maxVal))

    slider.valueText = slider:CreateFontString(nil, "OVERLAY")
    slider.valueText:SetFontObject(MP.Fonts.Body)
    slider.valueText:SetPoint("TOP", slider, "BOTTOM", 0, -2)

    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value / step + 0.5) * step
        self.valueText:SetText(string.format("%.1f", value))
        MP:SetSetting(settingPath, value)
        if onChange then onChange(value) end
    end)

    function slider:Refresh()
        local val = MP:GetSetting(settingPath) or minVal
        self:SetValue(val)
        self.valueText:SetText(string.format("%.1f", val))
    end

    return slider
end

----------------------------------------------------------------------
-- Build Panel
----------------------------------------------------------------------
local function BuildPanel()
    -- The Settings canvas frame must be a top-level UIParent child with an
    -- explicit size; SettingsPanel resizes it dynamically when shown.
    local panel = CreateFrame("Frame", "MythicPulseConfigPanel", UIParent)
    panel:SetSize(PANEL_WIDTH + 220, 620)
    panel:Hide()
    panel.name = "MythicPulse"
    -- Stubs the Settings API expects on canvas categories
    panel.OnCommit  = function() end
    panel.OnDefault = function() end
    panel.OnRefresh = function() end

    -- Scrollable body to prevent overflow on smaller settings canvases.
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 6, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    -- Derive content width from panel width so columns adapt better.
    local contentWidth = math.max(PANEL_WIDTH + 40, panel:GetWidth() - 44)
    content:SetSize(contentWidth, 1)
    scrollFrame:SetScrollChild(content)

    -- Title
    local title = content:CreateFontString(nil, "OVERLAY")
    title:SetFontObject(MP.Fonts.Title)
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
    title:SetText("MythicPulse Settings")

    -- Version subtitle
    local ver = content:CreateFontString(nil, "OVERLAY")
    ver:SetFontObject(MP.Fonts.Small)
    ver:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    ver:SetTextColor(0.5, 0.5, 0.55)
    ver:SetText("v" .. (MP.version or "1.0.0"))

    local y = -60
    panel.controls = {}

    -- Two-column slider layout constants
    local COL1_X          = 16 + INDENT
    local SLIDER_WIDTH    = 200
    local RIGHT_COL_PAD   = 24
    local MIN_COL_GAP     = 24
    local COL2_X          = math.max(
        COL1_X + SLIDER_WIDTH + MIN_COL_GAP,
        contentWidth - SLIDER_WIDTH - RIGHT_COL_PAD
    )
    local SLIDER_ROW_STEP = 54                   -- vertical space per slider row
    local SLIDER_TOP_PAD  = 14                   -- space for the slider's top label

    local function AddSliderRow(left, right)
        if left then
            local s = CreateSlider(content, left.label, COL1_X, y - SLIDER_TOP_PAD,
                left.min, left.max, left.step, left.path, left.onChange)
            table.insert(panel.controls, s)
        end
        if right then
            local s = CreateSlider(content, right.label, COL2_X, y - SLIDER_TOP_PAD,
                right.min, right.max, right.step, right.path, right.onChange)
            table.insert(panel.controls, s)
        end
        y = y - SLIDER_ROW_STEP
    end

    -- === General Section ===
    local genHeader = content:CreateFontString(nil, "OVERLAY")
    genHeader:SetFontObject(MP.Fonts.Header)
    genHeader:SetPoint("TOPLEFT", 16, y)
    genHeader:SetTextColor(0.9, 0.9, 0.9)
    genHeader:SetText("General")
    y = y - ROW_HEIGHT

    local lockCB = CreateCheckbox(content, "Lock Frame Position", COL1_X, y, "locked")
    table.insert(panel.controls, lockCB)
    y = y - ROW_HEIGHT

    local bgCB = CreateCheckbox(content, "Show Panel Backgrounds", COL1_X, y, "showBackdrop")
    bgCB:SetScript("OnClick", function(self)
        MP:SetSetting("showBackdrop", self:GetChecked())
        if MP.RefreshAllBackdrops then MP:RefreshAllBackdrops() end
        if MP.UtilityFrame and MP.UtilityFrame.ApplyBackdropState then
            MP.UtilityFrame:ApplyBackdropState()
        end
        if MP.UtilityFrame and MP.UtilityFrame.frame and MP.UtilityFrame.frame:IsShown() and MP.UtilityFrame.RefreshContent then
            MP.UtilityFrame:RefreshContent()
        end
    end)
    table.insert(panel.controls, bgCB)
    y = y - ROW_HEIGHT

    -- Scale sliders (3 frames × 2 = 6 sliders in a 2-column grid → 3 rows)
    -- Each slider applies the change immediately to the corresponding frame.
    AddSliderRow(
        {
            label = "Main HUD Scale",  min = 0.5, max = 2.0, step = 0.1,
            path = "mainFrame.scale",
            onChange = function(v)
                if MP.MainFrame and MP.MainFrame.frame then MP.MainFrame.frame:SetScale(v) end
            end,
        },
        {
            label = "Main HUD Opacity", min = 0.3, max = 1.0, step = 0.05,
            path = "mainFrame.alpha",
            onChange = function(v)
                if MP.MainFrame and MP.MainFrame.frame then MP.MainFrame.frame:SetAlpha(v) end
            end,
        }
    )
    AddSliderRow(
        {
            label = "Party CDs Scale", min = 0.5, max = 2.0, step = 0.1,
            path = "trackerFrame.scale",
            onChange = function(v)
                if MP.TrackerFrame and MP.TrackerFrame.frame then MP.TrackerFrame.frame:SetScale(v) end
            end,
        },
        {
            label = "Party CDs Opacity", min = 0.3, max = 1.0, step = 0.05,
            path = "trackerFrame.alpha",
            onChange = function(v)
                if MP.TrackerFrame and MP.TrackerFrame.frame then MP.TrackerFrame.frame:SetAlpha(v) end
            end,
        }
    )
    AddSliderRow(
        {
            label = "Interrupts Scale", min = 0.5, max = 2.0, step = 0.1,
            path = "interruptFrame.scale",
            onChange = function(v)
                if MP.InterruptFrame and MP.InterruptFrame.frame then MP.InterruptFrame.frame:SetScale(v) end
            end,
        },
        {
            label = "Interrupts Opacity", min = 0.3, max = 1.0, step = 0.05,
            path = "interruptFrame.alpha",
            onChange = function(v)
                if MP.InterruptFrame and MP.InterruptFrame.frame then MP.InterruptFrame.frame:SetAlpha(v) end
            end,
        }
    )

    y = y - 4  -- small gap between sections

    -- === Display (font + icon scaling) ===
    local dispHeader = content:CreateFontString(nil, "OVERLAY")
    dispHeader:SetFontObject(MP.Fonts.Header)
    dispHeader:SetPoint("TOPLEFT", 16, y)
    dispHeader:SetTextColor(0.9, 0.9, 0.9)
    dispHeader:SetText("Display")
    y = y - ROW_HEIGHT

    AddSliderRow(
        {
            label = "Font Scale", min = 0.7, max = 2.0, step = 0.05,
            path = "fontScale",
            onChange = function()
                if MP.Fonts and MP.Fonts.Apply then MP.Fonts:Apply() end
            end,
        },
        {
            label = "Party CD Icon Size", min = 20, max = 48, step = 1,
            path = "modules.partyCooldowns.iconSize",
        }
    )

    AddSliderRow(
        {
            label = "Battle Res/BL Icon Size", min = 28, max = 56, step = 1,
            path = "modules.combatRes.iconSize",
            onChange = function()
                MP:Print("|cff88ccffReload UI (/reload)|r to apply Battle Res icon size changes.")
            end,
        },
        nil
    )

    y = y - 4

    -- === Module Toggles ===
    local modHeader = content:CreateFontString(nil, "OVERLAY")
    modHeader:SetFontObject(MP.Fonts.Header)
    modHeader:SetPoint("TOPLEFT", 16, y)
    modHeader:SetTextColor(0.9, 0.9, 0.9)
    modHeader:SetText("Modules")
    y = y - ROW_HEIGHT

    -- Helper: creates an onChange that enables/disables the runtime module
    local function MakeModuleToggle(moduleName)
        return function(checked)
            if checked then
                MP:EnableModule(moduleName)
            else
                MP:DisableModule(moduleName)
            end
        end
    end

    local moduleList = {
        { label = "Dungeon Timer",       path = "modules.timer.enabled",            modName = "Timer" },
        { label = "Death Tracker",       path = "modules.deathTracker.enabled",     modName = "DeathTracker" },
        { label = "Enemy Forces",        path = "modules.enemyForces.enabled",      modName = "EnemyForces" },
        { label = "Affix Display",       path = "modules.affixDisplay.enabled",     modName = "AffixDisplay" },
        { label = "Keystone Tracker",    path = "modules.keystoneTracker.enabled",  modName = "KeystoneTracker" },
        { label = "Party Cooldowns",     path = "modules.partyCooldowns.enabled",   modName = "PartyCooldowns" },
        { label = "Interrupt Tracker",   path = "modules.interruptTracker.enabled", modName = "InterruptTracker" },
        { label = "Dispel Tracker",      path = "modules.dispelTracker.enabled",    modName = "DispelTracker" },
        { label = "Trinket Tracker",     path = "modules.trinketTracker.enabled",   modName = "TrinketTracker" },
        { label = "Auto Gossip",         path = "modules.autoGossip.enabled",       modName = "AutoGossip" },
        { label = "Battle Res Tracker",  path = "modules.combatRes.enabled",        modName = "CombatRes" },
        { label = "Run Summary Popup",   path = "modules.runSummary.autoShow" },
        { label = "Dungeon History",     path = "modules.dungeonHistory.enabled",   modName = "DungeonHistory" },
        { label = "Auto Keystone Slot",  path = "modules.autoSlot.enabled",         modName = "AutoSlot" },
        { label = "Dungeon Teleports",   path = "modules.dungeonTeleport.enabled",  modName = "DungeonTeleport" },
    }

    -- Two-column layout: half on the left, remainder on the right
    local modStartY    = y
    local splitIndex   = math.ceil(#moduleList / 2)
    local leftEndY     = modStartY

    for i, mod in ipairs(moduleList) do
        local toggle = mod.modName and MakeModuleToggle(mod.modName) or nil
        if i <= splitIndex then
            local cb = CreateCheckbox(content, mod.label, COL1_X, leftEndY, mod.path, toggle)
            table.insert(panel.controls, cb)
            leftEndY = leftEndY - ROW_HEIGHT
        else
            local rowY = modStartY - ((i - splitIndex - 1) * ROW_HEIGHT)
            local cb = CreateCheckbox(content, mod.label, COL2_X, rowY, mod.path, toggle)
            table.insert(panel.controls, cb)
        end
    end

    y = leftEndY - 10

    -- === Reset Button ===
    local resetBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    resetBtn:SetSize(140, 24)
    resetBtn:SetPoint("TOPLEFT", 16 + INDENT, y)
    resetBtn:SetText("Reset All Settings")
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("MYTHICPULSE_RESET_CONFIRM")
    end)

    y = y - 34
    local contentHeight = math.max(1, -y + 12)
    content:SetHeight(contentHeight)

    -- Confirmation dialog
    StaticPopupDialogs["MYTHICPULSE_RESET_CONFIRM"] = {
        text = "Reset all MythicPulse settings to defaults?",
        button1 = "Yes",
        button2 = "No",
        OnAccept = function()
            MP:ResetConfig()
            for _, ctrl in ipairs(panel.controls) do
                if ctrl.Refresh then ctrl:Refresh() end
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
    }

    -- Refresh all controls
    function panel:Refresh()
        for _, ctrl in ipairs(self.controls) do
            if ctrl.Refresh then ctrl:Refresh() end
        end
    end

    panel:SetScript("OnShow", function(self)
        self:Refresh()
    end)

    return panel
end

----------------------------------------------------------------------
-- Register with Settings UI
----------------------------------------------------------------------
function MP.ConfigPanel:Init()
    if self.panel then return end   -- idempotent
    local panel = BuildPanel()
    self.panel = panel

    -- Register with the modern Settings API (Dragonflight+/Midnight)
    if Settings and Settings.RegisterCanvasLayoutCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, panel.name)
        if ok and category then
            local ok2 = pcall(Settings.RegisterAddOnCategory, category)
            if ok2 then
                self.category = category
                MP:Debug("ConfigPanel registered with Settings UI:", category:GetID())
            else
                MP:Debug("ConfigPanel: RegisterAddOnCategory failed")
            end
        else
            MP:Debug("ConfigPanel: RegisterCanvasLayoutCategory failed:", tostring(category))
        end
    else
        MP:Debug("ConfigPanel: Settings.RegisterCanvasLayoutCategory not available")
    end
end

function MP.ConfigPanel:Toggle()
    -- Lazy-init so /mp config works even if PLAYER_ENTERING_WORLD's
    -- delayed Init hasn't fired yet (e.g., right after a /reload).
    if not self.panel then
        self:Init()
    end
    if self.category and Settings and Settings.OpenToCategory then
        Settings.OpenToCategory(self.category:GetID())
        return
    end
    -- Last-resort fallback: try the legacy InterfaceOptions API or open
    -- the Settings panel by name.
    if Settings and Settings.OpenToCategory and self.panel and self.panel.name then
        Settings.OpenToCategory(self.panel.name)
        return
    end
    MP:Print("|cffff8866Could not open Settings panel.|r Try Esc → Options → AddOns → MythicPulse.")
end

----------------------------------------------------------------------
-- Init on load
----------------------------------------------------------------------
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isLogin)
    if isLogin or not MP.ConfigPanel.panel then
        C_Timer.After(0.5, function()
            MP.ConfigPanel:Init()
        end)
    end
end)
