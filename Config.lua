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
        point    = "LEFT",
        relPoint = "LEFT",
        x        = 320,
        y        = 0,
    },

    -- Module Toggles & Settings
    modules = {
        timer = {
            enabled      = true,
            showPlusTwo   = true,
            showPlusThree = true,
            showBossSplits = true,
            colorCoded   = true,
        },
        deathTracker = {
            enabled      = true,
            showLog      = true,
            showPenalty  = true,
        },
        enemyForces = {
            enabled      = true,
            showCount    = true,
            showPercent  = true,
            showPull     = true,
        },
        affixDisplay = {
            enabled      = true,
            showTooltips = true,
            iconSize     = 24,
        },
        keystoneTracker = {
            enabled      = true,
            showPartyKeys = true,
        },
        interruptTracker = {
            enabled             = true,
            showInCombatOnly    = false,
            failedKickDetection = true,
            clickToAnnounce     = true,
        },
        partyCooldowns = {
            enabled      = true,
            iconSize     = 32,
            showInterrupts = true,
            showDefensives = true,
            showExternals  = true,
        },
        dispelTracker = {
            enabled       = true,
            showOffensive = true,
            showDefensive = true,
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
        runSummary = {
            enabled       = true,
            autoShow      = true,
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

    -- Hide Blizzard's default M+ UI frames to avoid clutter
    MP:RegisterEvent("CHALLENGE_MODE_START", function()
        if ChallengeModeSummaryFrame then
            ChallengeModeSummaryFrame:Hide()
        end
        -- Update visibility of M+-only sections
        MP:UpdateMythicOnlySections()
    end)
    MP:RegisterEvent("CHALLENGE_MODE_COMPLETED", function()
        if ChallengeModeSummaryFrame then
            ChallengeModeSummaryFrame:Hide()
        end
        -- Update visibility of M+-only sections
        MP:UpdateMythicOnlySections()
    end)
    MP:RegisterEvent("CHALLENGE_MODE_RESET", function()
        -- Update visibility of M+-only sections
        MP:UpdateMythicOnlySections()
    end)
end)
