--[[
    MythicPulse - Configuration & SavedVariables
    Handles default settings, SavedVariables merge, and getter/setter API.
]]

local _, MP = ...

----------------------------------------------------------------------
-- Default Configuration
----------------------------------------------------------------------
local DEFAULTS = {
    -- General
    debug        = false,
    locked       = false,
    minimap      = true,
    fontScale    = 1.0,   -- global UI text scale (0.7–2.0)
    showBackdrop = true,  -- show panel backgrounds/borders/glow

    -- Main Frame
    mainFrame = {
        scale    = 1.0,
        alpha    = 1.0,
        point    = "TOP",
        relPoint = "TOP",
        x        = 0,
        y        = -120,
        compact  = false,
    },

    -- Tracker Frame (Party Cooldowns)
    trackerFrame = {
        scale    = 1.0,
        alpha    = 1.0,
        point    = "LEFT",
        relPoint = "LEFT",
        x        = 50,
        y        = 0,
    },

    -- Interrupt Frame
    interruptFrame = {
        scale    = 1.0,
        alpha    = 1.0,
        point    = "TOPLEFT",
        relPoint = "TOPLEFT",
        x        = 320,
        y        = -200,
    },

    -- Combat Utilities Frame (Bloodlust + Battle Res)
    combatResFrame = {
        scale    = 1.0,
        alpha    = 1.0,
        point    = "CENTER",
        relPoint = "CENTER",
        x        = 200,
        y        = -200,
    },

    -- Module Toggles & Settings
    modules = {
        timer = {
            enabled      = true,
        },
        deathTracker = {
            enabled      = true,
        },
        enemyForces = {
            enabled      = true,
        },

        keystoneTracker = {
            enabled      = true,
        },
        interruptTracker = {
            enabled          = true,
            showInCombatOnly = false,
            autoAnnounce     = false,
        },
        partyCooldowns = {
            enabled         = true,
            iconSize        = 32,
            iconGap         = 4,
            maxIcons        = 8,
            iconsPerRow     = 8,
            anchorPoint     = "LEFT",
            relativePoint   = "RIGHT",
            offsetX         = 4,
            offsetY         = 0,
            growthDirection = "RIGHT",
            showDispelBar   = true,
        },
        dispelTracker = {
            enabled = true,
        },
        autoGossip = {
            enabled       = true,
        },
        trinketTracker = {
            enabled       = true,
        },
        dungeonHistory = {
            enabled       = true,
            maxEntries    = 200,
        },
        combatRes = {
            enabled       = true,
            iconSize      = 38,
        },
        autoSlot = {
            enabled       = true,
        },
        dungeonTeleport = {
            enabled       = true,
        },
        dungeonUtility = {
            enabled          = true,
            autoShow         = true,
            showRemove       = true,
            hideNotImportant = false,
            framePoint       = nil,
            frameRelPoint    = nil,
            frameX           = nil,
            frameY           = nil,
        },
    },

    -- Config Panel position
    configPanel = {
        point    = "CENTER",
        relPoint = "CENTER",
        x        = 0,
        y        = 0,
    },

    -- Run History Storage
    history = {},

    -- Per-character keystone cache
    keystoneCache = {},
}

----------------------------------------------------------------------
-- Deep Copy Utility
----------------------------------------------------------------------
local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

----------------------------------------------------------------------
-- Deep Merge: fills in missing keys from defaults without overwriting
----------------------------------------------------------------------
local function DeepMerge(target, defaults)
    for k, v in pairs(defaults) do
        if target[k] == nil then
            target[k] = DeepCopy(v)
        elseif type(v) == "table" and type(target[k]) == "table" then
            DeepMerge(target[k], v)
        end
    end
end

----------------------------------------------------------------------
-- Getter / Setter API
----------------------------------------------------------------------
function MP:GetSetting(path)
    local parts = { strsplit(".", path) }
    local node = self.db
    for _, key in ipairs(parts) do
        if type(node) ~= "table" then return nil end
        node = node[key]
    end
    return node
end

function MP:SetSetting(path, value)
    local parts = { strsplit(".", path) }
    local node = self.db
    for i = 1, #parts - 1 do
        if type(node[parts[i]]) ~= "table" then
            node[parts[i]] = {}
        end
        node = node[parts[i]]
    end
    node[parts[#parts]] = value
end

function MP:IsModuleEnabled(moduleName)
    local modConfig = self.db.modules[moduleName]
    return modConfig and modConfig.enabled
end

----------------------------------------------------------------------
-- Reset to Defaults
----------------------------------------------------------------------
function MP:ResetConfig()
    MythicPulseDB = DeepCopy(DEFAULTS)
    self.db = MythicPulseDB
    self:Print("All settings reset to defaults.")

    -- Reset frame positions
    if MP.MainFrame and MP.MainFrame.ResetPosition then MP.MainFrame:ResetPosition() end
    if MP.TrackerFrame and MP.TrackerFrame.ResetPosition then MP.TrackerFrame:ResetPosition() end
    if MP.InterruptFrame  and MP.InterruptFrame.ResetPosition  then MP.InterruptFrame:ResetPosition()  end
    if MP.CombatResFrame  and MP.CombatResFrame.ResetPosition  then MP.CombatResFrame:ResetPosition()  end
    if MP.UtilityFrame and MP.UtilityFrame.ResetPosition then MP.UtilityFrame:ResetPosition() end

    -- Notify modules
    for name, mod in pairs(self.modules) do
        if mod.OnConfigReset then
            mod:OnConfigReset()
        end
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
MP:RegisterEvent("ADDON_LOADED", function(event, addon)
    if addon ~= MP.name then return end

    -- Create or restore SavedVariables
    if not MythicPulseDB then
        MythicPulseDB = DeepCopy(DEFAULTS)
    else
        -- Merge in any new default keys
        DeepMerge(MythicPulseDB, DEFAULTS)
    end

    -- One-shot migration: bump the old 22px cooldown icon default to 32
    local pc = MythicPulseDB.modules and MythicPulseDB.modules.partyCooldowns
    if pc and pc.iconSize == 22 then
        pc.iconSize = 32
    end

    MP.db = MythicPulseDB
    MP:Debug("Config loaded. Debug:", tostring(MP.db.debug))

    -- Sync module enabled states from config
    for name, mod in pairs(MP.modules) do
        -- Convert PascalCase "EnemyForces" to camelCase "enemyForces" to match DB keys
        local dbKey = name:sub(1,1):lower() .. name:sub(2)
        local isEnabled = MP:IsModuleEnabled(dbKey)
        if isEnabled ~= nil then
            mod.enabled = isEnabled
            if not isEnabled and mod.OnDisable then
                mod:OnDisable()
            end
        end
    end

    -- ============================================================
    -- Hide Blizzard's default M+ UI frames to avoid clutter.
    -- MythicPulse replaces them with its own HUD.
    -- ============================================================
    -- Suppress a frame: alpha=0, no mouse, hook Show to stay suppressed during M+.
    local function SuppressFrame(f)
        if not f then return end
        f:SetAlpha(0)
        f:EnableMouse(false)
        if not f._mpSuppressHooked then
            f._mpSuppressHooked = true
            hooksecurefunc(f, "Show", function(self)
                if MP:IsInMythicPlus() and not InCombatLockdown() then
                    self:SetAlpha(0)
                    self:EnableMouse(false)
                end
            end)
        end
    end

    local function RestoreFrame(f)
        if not f then return end
        f:SetAlpha(1)
        f:EnableMouse(true)
    end

    local function HideBlizzardMythicPlusUI()
        -- Guard combat lockdown for any protected frames
        if InCombatLockdown() then
            C_Timer.After(1, HideBlizzardMythicPlusUI)
            return
        end

        -- ChallengeModeSummaryFrame (post-run summary)
        if ChallengeModeSummaryFrame then
            ChallengeModeSummaryFrame:Hide()
        end

        -- Entire ObjectiveTrackerFrame: quests, bonus objectives, scenario blocks
        SuppressFrame(ObjectiveTrackerFrame)

        -- ScenarioBlocksFrame (standalone M+ block, some builds)
        SuppressFrame(ScenarioBlocksFrame)

        -- The ScenarioObjectiveTracker module (Dragonflight+/Midnight builds)
        if ScenarioObjectiveTracker then
            SuppressFrame(ScenarioObjectiveTracker)
            if ScenarioObjectiveTracker.ContentsFrame then
                SuppressFrame(ScenarioObjectiveTracker.ContentsFrame)
            end
        end

        -- UI widget containers: scenario progress, dungeon-event widgets, affix display
        SuppressFrame(UIWidgetTopCenterContainerFrame)
        SuppressFrame(UIWidgetBelowMinimapContainerFrame)
        SuppressFrame(UIWidgetPowerBarContainerFrame)

        -- Blizzard's built-in M+ death counter (TWW+/Midnight)
        SuppressFrame(ScenarioChallengeDeathTracker)

        -- Remaining sub-blocks in ObjectiveTracker (belt-and-suspenders)
        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.BlocksFrame then
            local bf = ObjectiveTrackerFrame.BlocksFrame
            if bf.ScenarioObjectiveBlock  then bf.ScenarioObjectiveBlock:SetAlpha(0)  end
            if bf.MythicPlusObjectiveBlock then bf.MythicPlusObjectiveBlock:SetAlpha(0) end
        end
    end

    local function RestoreBlizzardMythicPlusUI()
        if InCombatLockdown() then
            C_Timer.After(1, RestoreBlizzardMythicPlusUI)
            return
        end

        RestoreFrame(ObjectiveTrackerFrame)
        RestoreFrame(ScenarioBlocksFrame)

        if ScenarioObjectiveTracker then
            RestoreFrame(ScenarioObjectiveTracker)
            if ScenarioObjectiveTracker.ContentsFrame then
                RestoreFrame(ScenarioObjectiveTracker.ContentsFrame)
            end
        end

        RestoreFrame(UIWidgetTopCenterContainerFrame)
        RestoreFrame(UIWidgetBelowMinimapContainerFrame)
        RestoreFrame(UIWidgetPowerBarContainerFrame)
        RestoreFrame(ScenarioChallengeDeathTracker)

        if ObjectiveTrackerFrame and ObjectiveTrackerFrame.BlocksFrame then
            local bf = ObjectiveTrackerFrame.BlocksFrame
            if bf.ScenarioObjectiveBlock  then bf.ScenarioObjectiveBlock:SetAlpha(1)  end
            if bf.MythicPlusObjectiveBlock then bf.MythicPlusObjectiveBlock:SetAlpha(1) end
        end
    end

    MP:RegisterEvent("CHALLENGE_MODE_START", function()
        HideBlizzardMythicPlusUI()
        -- Update visibility of M+-only sections
        MP:UpdateMythicOnlySections()
    end)
    MP:RegisterEvent("CHALLENGE_MODE_COMPLETED", function()
        RestoreBlizzardMythicPlusUI()
        -- Update visibility of M+-only sections
        MP:UpdateMythicOnlySections()
    end)
    MP:RegisterEvent("CHALLENGE_MODE_RESET", function()
        RestoreBlizzardMythicPlusUI()
        -- Update visibility of M+-only sections
        MP:UpdateMythicOnlySections()
    end)

    -- Also suppress on world entry if already inside an M+ run
    -- (e.g., after a /reload mid-dungeon)
    C_Timer.After(1.5, function()
        if MP:IsInMythicPlus() then
            HideBlizzardMythicPlusUI()
        end
    end)
end)
