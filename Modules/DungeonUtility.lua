--[[
    MythicPulse - Dungeon Utility Module
    Core logic for the dungeon utility ability recommendations.
    
    Handles:
    - Tag parsing from bracket notation
    - Spell knowledge detection via C_SpellBook/C_Spell
    - Ability list building (cross-referencing player abilities with dungeon entries)
    - Categorization (Known/Add/Remove with importance levels)
    - Text formatting ({spell:ID} and {npc:ID} placeholder resolution)
    
    MIDNIGHT COMPLIANCE:
    - No secure frame interactions
    - No combat lockdown violations
    - All API calls are read-only queries
]]

local _, MP = ...

local DungeonUtility = {}
DungeonUtility.registeredEvents = {
    "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
    "TRAIT_CONFIG_UPDATED",
    "PLAYER_ENTERING_WORLD",
    "CHALLENGE_MODE_START",
}

-- State
DungeonUtility.currentAbilities = {}    -- built ability list
DungeonUtility.currentDungeonID = nil   -- selected dungeon
DungeonUtility.playerClass = nil
DungeonUtility.playerSpec = nil
DungeonUtility.isDirty = true           -- needs rebuild

-- Caches
DungeonUtility.spellNameCache = {}
DungeonUtility.spellIconCache = {}
DungeonUtility.npcNameCache = {}

----------------------------------------------------------------------
-- Tag Parsing
----------------------------------------------------------------------

--- Parse "[tag1][tag2][tag3]" into { tag1 = true, tag2 = true, tag3 = true }
local function ParseTags(tagString)
    local result = {}
    if not tagString then return result end
    for tag in tagString:gmatch("%[([^%]]+)%]") do
        result[tag] = true
        -- super_important implies important
        if tag == "super_important" then
            result["important"] = true
        end
    end
    return result
end

----------------------------------------------------------------------
-- Spell / NPC Info Helpers
----------------------------------------------------------------------

--- Get spell name by ID (cached)
function DungeonUtility:GetSpellName(spellID)
    if self.spellNameCache[spellID] then
        return self.spellNameCache[spellID]
    end
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if info and info.name then
        self.spellNameCache[spellID] = info.name
        return info.name
    end
    return ""
end

--- Get spell icon texture by ID (cached)
function DungeonUtility:GetSpellIcon(spellID)
    if self.spellIconCache[spellID] then
        return self.spellIconCache[spellID]
    end
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if info and info.originalIconID then
        self.spellIconCache[spellID] = info.originalIconID
        return info.originalIconID
    end
    return nil
end

--- Get spell hyperlink for chat/tooltip
function DungeonUtility:GetSpellLink(spellID)
    local name = self:GetSpellName(spellID)
    if name and name ~= "" then
        return string.format("|cff71d5ff|Hspell:%s:0|h[%s]|h|r", spellID, name)
    end
    return ""
end

--- Get NPC name by ID (Fallback, as C_TooltipInfo returns secret strings in Midnight)
function DungeonUtility:GetNpcName(npcID)
    if self.npcNameCache[npcID] then
        return self.npcNameCache[npcID]
    end
    -- In Midnight 12.0, tooltip scanning for unit names returns secret string values.
    -- To prevent Lua concatenation crashes, we simply return nil here, and the
    -- calling functions will use a fallback name.
    return nil
end

--- Get NPC hyperlink
function DungeonUtility:GetNpcLink(npcID)
    local name = self:GetNpcName(npcID)
    
    -- Safe check in case the string is tainted by other addons
    local isSafe = false
    if name then
        local ok = pcall(function() return name == "" end)
        if ok then isSafe = true end
    end

    if isSafe and name ~= "" then
        return string.format("|cffffd100|Hunit:Creature-0-0-0-0-%s-0:%s|h[%s]|h|r", npcID, name, name)
    end
    return string.format("|cffffd100|Hunit:Creature-0-0-0-0-%s-0|h[NPC:%d]|h|r", npcID, npcID)
end

--- Convert icon ID to inline chat icon markup
function DungeonUtility:IconMarkup(iconID)
    if iconID then
        return string.format("|T%s:0:0:0:0|t", iconID)
    end
    return ""
end

----------------------------------------------------------------------
-- Spell Knowledge Detection
----------------------------------------------------------------------

--- Check if a spell is known (handles pet spells)
function DungeonUtility:IsSpellKnown(spellID, isPet)
    if isPet then
        return C_SpellBook and C_SpellBook.IsSpellInSpellBook and
               C_SpellBook.IsSpellInSpellBook(spellID, 1)
    end
    -- Primary: C_SpellBook covers baseline spells and most talents
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        if C_SpellBook.IsSpellKnown(spellID) then return true end
    end
    -- Fallback: IsPlayerSpell covers talent-granted spells that IsSpellKnown may miss
    if IsPlayerSpell then
        return IsPlayerSpell(spellID) or false
    end
    return false
end

----------------------------------------------------------------------
-- Format Dungeon Entry Text
----------------------------------------------------------------------

--- Replace {spell:ID} and {npc:ID} placeholders with hyperlinks + icons
function DungeonUtility:FormatEntryText(text)
    local formatted = text

    -- Replace {spell:ID} with icon + hyperlink
    formatted = formatted:gsub("{spell:(%d+)}", function(id)
        local spellID = tonumber(id)
        local icon = self:GetSpellIcon(spellID)
        local link = self:GetSpellLink(spellID)
        return self:IconMarkup(icon) .. link
    end)

    -- Replace {npc:ID} with hyperlink
    formatted = formatted:gsub("{npc:(%d+)}", function(id)
        local npcID = tonumber(id)
        return self:GetNpcLink(npcID)
    end)

    return formatted
end

----------------------------------------------------------------------
-- Build Ability List for Current Player
----------------------------------------------------------------------

--- Deep copy a table
local function DeepCopy(src)
    if type(src) ~= "table" then return src end
    local copy = {}
    for k, v in pairs(src) do
        copy[k] = DeepCopy(v)
    end
    return copy
end

--- Build the full list of relevant abilities for the current player
function DungeonUtility:BuildAbilityList()
    local UD = MP.UtilityData
    if not UD or not UD.classAbilities then return end

    self.playerClass = UnitClassBase("player")
    if not self.playerClass then return end

    -- Get current spec
    if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
        local specIndex = C_SpecializationInfo.GetSpecialization()
        if specIndex then
            self.playerSpec = C_SpecializationInfo.GetSpecializationInfo(specIndex)
        end
    end

    -- Start with class-wide abilities
    local combined = {}
    local classAbilities = UD.classAbilities[self.playerClass]
    if classAbilities then
        for spellID, entry in pairs(classAbilities) do
            combined[spellID] = DeepCopy(entry)
        end
    end

    -- Merge spec-specific abilities (override class entries)
    if self.playerSpec and UD.classAbilities[self.playerSpec] then
        for spellID, entry in pairs(UD.classAbilities[self.playerSpec]) do
            combined[spellID] = DeepCopy(entry)
        end
    end

    -- Resolve knowledge state
    for spellID, entry in pairs(combined) do
        entry.spellID = spellID
        entry.tagsTable = ParseTags(entry.tags)

        if entry.alternatives and #entry.alternatives > 0 then
            local known = false
            for _, altID in ipairs(entry.alternatives) do
                if self:IsSpellKnown(altID, entry.pet) then
                    entry.isKnown = true
                    entry.altSpellID = altID
                    entry.spellName = self:GetSpellName(altID)
                    known = true
                    break
                end
            end
            if not known then
                entry.isKnown = self:IsSpellKnown(spellID, entry.pet)
            end
        else
            entry.isKnown = self:IsSpellKnown(spellID, entry.pet)
        end

        if not entry.spellName or entry.spellName == "" then
            entry.spellName = self:GetSpellName(entry.altSpellID or spellID)
        end
    end

    -- Handle overrides (e.g., Ice Prison overrides Chains of Ice)
    for spellID, entry in pairs(combined) do
        if entry.override and entry.isKnown and combined[entry.override] then
            combined[entry.override].isOverridden = true
        end
    end

    -- Add known racial abilities
    if UD.racialAbilities then
        for spellID, entry in pairs(UD.racialAbilities) do
            local racialEntry = DeepCopy(entry)
            racialEntry.spellID = spellID
            racialEntry.tagsTable = ParseTags(racialEntry.tags)

            if racialEntry.alternatives and #racialEntry.alternatives > 0 then
                local known = false
                for _, altID in ipairs(racialEntry.alternatives) do
                    if self:IsSpellKnown(altID) then
                        racialEntry.isKnown = true
                        racialEntry.altSpellID = altID
                        racialEntry.spellName = self:GetSpellName(altID)
                        known = true
                        break
                    end
                end
                if not known then
                    racialEntry.isKnown = self:IsSpellKnown(spellID)
                end
            else
                racialEntry.isKnown = self:IsSpellKnown(spellID)
            end

            if not racialEntry.spellName or racialEntry.spellName == "" then
                racialEntry.spellName = self:GetSpellName(racialEntry.altSpellID or spellID)
            end

            if racialEntry.isKnown then
                local key = racialEntry.altSpellID or spellID
                combined[key] = racialEntry
            end
        end
    end

    -- Flatten to indexed array
    self.currentAbilities = {}
    for _, entry in pairs(combined) do
        if not entry.isOverridden then
            table.insert(self.currentAbilities, DeepCopy(entry))
        end
    end

    self.isDirty = false
    MP:Debug("DungeonUtility: Built ability list with", #self.currentAbilities, "abilities for", self.playerClass)
end

----------------------------------------------------------------------
-- Populate Abilities with Dungeon Data (tag matching)
----------------------------------------------------------------------

--- Cross-reference abilities with dungeon entries for a given dungeon
function DungeonUtility:PopulateForDungeon(dungeonID)
    local UD = MP.UtilityData
    if not UD or not UD.dungeonEntries then return end

    self.currentDungeonID = dungeonID
    local dungeonData = UD.dungeonEntries[dungeonID]

    -- Parse dungeon entry tags and format text (do this once)
    if dungeonData then
        for _, dEntry in ipairs(dungeonData) do
            if not dEntry.tagsTable then
                dEntry.tagsTable = ParseTags(dEntry.tags)
            end
            if not dEntry.formattedText then
                dEntry.formattedText = self:FormatEntryText(dEntry.text)
            end
        end
    end

    local hideNotImportant = MP.db and MP.db.modules and
                             MP.db.modules.dungeonUtility and
                             MP.db.modules.dungeonUtility.hideNotImportant

    -- For each ability, find matching dungeon entries
    for _, ability in ipairs(self.currentAbilities) do
        ability.matchedEntries = {}
        ability.hasImportant = false

        if not ability.isOverridden and dungeonData then
            for _, dEntry in ipairs(dungeonData) do
                -- Skip non-important entries if option is set
                if not (hideNotImportant and not dEntry.tagsTable.important) then
                    -- Check tag overlap
                    local matched = false
                    for tag, _ in pairs(dEntry.tagsTable) do
                        if ability.tagsTable[tag] then
                            matched = true
                            break
                        end
                    end

                    if matched then
                        if dEntry.tagsTable.important then
                            ability.hasImportant = true
                        end

                        -- Build display text with importance prefix
                        local displayText = dEntry.formattedText or dEntry.text
                        if not dEntry.tagsTable.important then
                            -- Low importance: prepend ? icon
                            displayText = CreateAtlasMarkup("map-icon-ignored-bluequestion") .. displayText
                        end
                        if dEntry.tagsTable.super_important then
                            -- Super important: prepend ! icon
                            displayText = CreateAtlasMarkup("QuestNormal") .. displayText
                        end

                        table.insert(ability.matchedEntries, displayText)
                    end
                end
            end
        end

        -- Determine button type (category)
        local showRemove = MP.db and MP.db.modules and
                           MP.db.modules.dungeonUtility and
                           MP.db.modules.dungeonUtility.showRemove

        if #ability.matchedEntries > 0 then
            if ability.isKnown then
                ability.buttonType = ability.hasImportant and "known" or "knownOptional"
            else
                ability.buttonType = ability.hasImportant and "add" or "addOptional"
            end
        else
            ability.buttonType = "remove"
        end
    end

    -- Sort: Known > Known(?) > Add > Add(?) > Remove
    local typeOrder = { known = 1, knownOptional = 2, add = 3, addOptional = 4, remove = 5 }
    table.sort(self.currentAbilities, function(a, b)
        local orderA = typeOrder[a.buttonType] or 99
        local orderB = typeOrder[b.buttonType] or 99
        if orderA ~= orderB then
            return orderA < orderB
        end
        return (a.spellName or "") < (b.spellName or "")
    end)

    MP:Debug("DungeonUtility: Populated dungeon", dungeonID, "with", #self.currentAbilities, "abilities")
end

----------------------------------------------------------------------
-- Get Filtered Ability List (for UI)
----------------------------------------------------------------------

--- Returns the current abilities filtered by visibility settings
function DungeonUtility:GetDisplayList()
    local showRemove = MP.db and MP.db.modules and
                       MP.db.modules.dungeonUtility and
                       MP.db.modules.dungeonUtility.showRemove

    local list = {}
    for _, ability in ipairs(self.currentAbilities) do
        if ability.buttonType ~= "remove" or showRemove then
            -- Only show "remove" abilities that are known and not baseline/racial
            if ability.buttonType == "remove" then
                if ability.isKnown and not ability.baseline and not ability.racial then
                    table.insert(list, ability)
                end
            else
                table.insert(list, ability)
            end
        end
    end
    return list
end

----------------------------------------------------------------------
-- Get Available Dungeons
----------------------------------------------------------------------

--- Returns a sorted list of available dungeons for the dropdown
function DungeonUtility:GetDungeonList()
    local UD = MP.UtilityData
    if not UD or not UD.dungeonNames then return {} end

    local list = {}
    for id, name in pairs(UD.dungeonNames) do
        table.insert(list, { id = id, name = name })
    end
    table.sort(list, function(a, b) return a.name < b.name end)
    return list
end

----------------------------------------------------------------------
-- Refresh (full rebuild)
----------------------------------------------------------------------

function DungeonUtility:Refresh()
    self.spellNameCache = {}
    self.spellIconCache = {}
    self.npcNameCache = {}
    self.isDirty = true
end

----------------------------------------------------------------------
-- Event Handling
----------------------------------------------------------------------

function DungeonUtility:OnEvent(event, ...)
    if event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED" then
        self:Refresh()
        -- Delayed rebuild to let talent data settle
        C_Timer.After(0.5, function()
            DungeonUtility:BuildAbilityList()
            if DungeonUtility.currentDungeonID then
                DungeonUtility:PopulateForDungeon(DungeonUtility.currentDungeonID)
            end
            if MP.UtilityFrame and MP.UtilityFrame.frame and MP.UtilityFrame.frame:IsShown() then
                MP.UtilityFrame:RefreshContent()
            end
        end)

    elseif event == "TRAIT_CONFIG_UPDATED" then
        -- Talent change: rebuild knowledge state
        C_Timer.After(0.3, function()
            DungeonUtility:BuildAbilityList()
            if DungeonUtility.currentDungeonID then
                DungeonUtility:PopulateForDungeon(DungeonUtility.currentDungeonID)
            end
            if MP.UtilityFrame and MP.UtilityFrame.frame and MP.UtilityFrame.frame:IsShown() then
                MP.UtilityFrame:RefreshContent()
            end
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        local isInitialLogin, isReloadingUI = ...
        C_Timer.After(1.0, function()
            -- Initial setup
            if DungeonUtility.isDirty then
                DungeonUtility:BuildAbilityList()
            end

            -- Auto-detect dungeon
            if not (isInitialLogin or isReloadingUI) then
                local _, _, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()
                local UD = MP.UtilityData
                -- Check if we're in a M+ dungeon that we have data for
                if UD and UD.dungeonEntries and UD.dungeonEntries[instanceID] then
                    DungeonUtility.currentDungeonID = instanceID
                    DungeonUtility:PopulateForDungeon(instanceID)

                    -- Auto-show if enabled
                    local autoShow = MP.db and MP.db.modules and
                                     MP.db.modules.dungeonUtility and
                                     MP.db.modules.dungeonUtility.autoShow
                    if autoShow and MP.UtilityFrame then
                        MP.UtilityFrame:Show()
                    end
                end
            else
                -- On login/reload, use default dungeon
                local UD = MP.UtilityData
                local defaultID = UD and UD.defaultDungeonID or 2526
                DungeonUtility.currentDungeonID = defaultID
                DungeonUtility:PopulateForDungeon(defaultID)
            end
        end)

    elseif event == "CHALLENGE_MODE_START" then
        -- Optionally hide utility window when key starts
        if MP.UtilityFrame and MP.UtilityFrame.frame and MP.UtilityFrame.frame:IsShown() then
            MP.UtilityFrame:Hide()
        end
    end
end

----------------------------------------------------------------------
-- Module Callbacks
----------------------------------------------------------------------

function DungeonUtility:OnPlayerEnteringWorld(isInitialLogin, isReloadingUI)
    -- Handled by OnEvent
end

function DungeonUtility:OnFrameReady()
    -- Main frame is ready; we can create our own frame if needed
end

function DungeonUtility:OnConfigReset()
    self:Refresh()
end

----------------------------------------------------------------------
-- Toggle the Utility Window
----------------------------------------------------------------------

function DungeonUtility:Toggle()
    if not MP.UtilityFrame then return end

    -- Ensure we have ability data
    if self.isDirty then
        self:BuildAbilityList()
    end
    if self.currentDungeonID then
        self:PopulateForDungeon(self.currentDungeonID)
    else
        local UD = MP.UtilityData
        local defaultID = UD and UD.defaultDungeonID or 2526
        self.currentDungeonID = defaultID
        self:PopulateForDungeon(defaultID)
    end

    MP.UtilityFrame:Toggle()
end

----------------------------------------------------------------------
-- Register Module
----------------------------------------------------------------------
MP:RegisterModule("DungeonUtility", DungeonUtility)
