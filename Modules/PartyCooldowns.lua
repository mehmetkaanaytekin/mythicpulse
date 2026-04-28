--[[
    MythicPulse - Party Cooldowns Module
    OmniCD-style: one row per group member (local player listed first),
    each showing ALL of their tracked cooldowns — self-defensives, externals,
    and raid CDs — in a single unified "Cooldowns" section.

    The spell categories in TRACKED_SPELLS clarify the spell's *target*:
      defensive = cast on self only (Barkskin, Ice Block …)
      external  = cast on another player (Ironbark, Pain Suppression …)
      raidcd    = affects the whole group (Rallying Cry, Tranquility …)
      utility   = situational (Shroud, Fade …)
    All categories are shown on every row so the viewer can track both
    "can my healer Pain Supp me?" and "does the Druid have Barkskin?".

    Each row carries a thin coloured left-bar (decursive-style) that
    lights up when the local player can dispel a debuff on that unit.

    MIDNIGHT 12.0.5 COMPLIANCE NOTE:
    - Non-self UNIT_SPELLCAST_SUCCEEDED returns opaque spellIDs; only
      the local player's casts are trusted here.  Remote casts arrive
      via the "CD" Comm broadcast.
    - Cooldown durations are estimated from baseline values.
]]

local _, MP = ...

local PartyCooldowns = {
    registeredEvents = {
        "UNIT_SPELLCAST_SUCCEEDED",
        "GROUP_ROSTER_UPDATE",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_RESET",
        "CHALLENGE_MODE_COMPLETED",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_SPECIALIZATION_CHANGED",
        "INSPECT_READY",
        "UNIT_AURA",
    },
    active  = false,
    players = {},
}

----------------------------------------------------------------------
-- Tracked Spells Database
----------------------------------------------------------------------
local TRACKED_SPELLS = {
    -- ============== Death Knight ==============
    [48707]  = { class = "DEATHKNIGHT", duration = 60,  category = "defensive", name = "Anti-Magic Shell" },
    [48792]  = { class = "DEATHKNIGHT", duration = 180, category = "defensive", name = "Icebound Fortitude" },
    [55233]  = { class = "DEATHKNIGHT", spec = 250, duration = 90,  category = "defensive", name = "Vampiric Blood" },
    [49028]  = { class = "DEATHKNIGHT", spec = 250, duration = 120, category = "defensive", name = "Dancing Rune Weapon" },
    [51052]  = { class = "DEATHKNIGHT", spec = 250, duration = 120, category = "raidcd",   name = "Anti-Magic Zone" },

    -- ============== Demon Hunter ==============
    [198589] = { class = "DEMONHUNTER", duration = 60,  category = "defensive", name = "Blur" },
    [196718] = { class = "DEMONHUNTER", duration = 180, category = "raidcd",   name = "Darkness" },
    [187827] = { class = "DEMONHUNTER", spec = 581, duration = 240, category = "defensive", name = "Metamorphosis (Veng)" },
    [263648] = { class = "DEMONHUNTER", spec = 581, duration = 30,  category = "defensive", name = "Soul Barrier" },

    -- ============== Druid ==============
    [22812]  = { class = "DRUID", duration = 60,  category = "defensive", name = "Barkskin" },
    [61336]  = { class = "DRUID", spec = 103, duration = 180, category = "defensive", name = "Survival Instincts" },
    [29166]  = { class = "DRUID", duration = 180, category = "external",  name = "Innervate" },
    [740]    = { class = "DRUID", spec = 105, duration = 180, category = "raidcd",   name = "Tranquility" },
    [102342] = { class = "DRUID", duration = 60,  category = "external",  name = "Ironbark" },
    [102558] = { class = "DRUID", spec = 104, duration = 180, category = "defensive", name = "Incarnation: Guardian" },
    [50334]  = { class = "DRUID", spec = 104, duration = 180, category = "defensive", name = "Berserk (Guardian)" },

    -- ============== Evoker ==============
    [363916] = { class = "EVOKER", duration = 90,  category = "defensive", name = "Obsidian Scales" },
    [370665] = { class = "EVOKER", duration = 120, category = "external",  name = "Rescue" },
    [363534] = { class = "EVOKER", spec = 1468, duration = 240, category = "raidcd",   name = "Rewind" },
    [357170] = { class = "EVOKER", spec = 1468, duration = 240, category = "raidcd",   name = "Time Dilation" },
    [374348] = { class = "EVOKER", spec = 1468, duration = 240, category = "external",  name = "Renewing Blaze" },

    -- ============== Hunter ==============
    [186265] = { class = "HUNTER", duration = 180, category = "defensive", name = "Aspect of the Turtle" },
    [109304] = { class = "HUNTER", duration = 120, category = "defensive", name = "Exhilaration" },
    [264735] = { class = "HUNTER", duration = 180, category = "utility",   name = "Survival of the Fittest" },
    [34477]  = { class = "HUNTER", duration = 30,  category = "external",  name = "Misdirection" },

    -- ============== Mage ==============
    [45438]  = { class = "MAGE", duration = 240, category = "defensive", name = "Ice Block" },
    [235219] = { class = "MAGE", duration = 300, category = "defensive", name = "Cold Snap" },
    [110959] = { class = "MAGE", spec = 62, duration = 120, category = "defensive", name = "Greater Invisibility" },
    [342246] = { class = "MAGE", duration = 45,  category = "defensive", name = "Alter Time" },

    -- ============== Monk ==============
    [122278] = { class = "MONK", duration = 120, category = "defensive", name = "Dampen Harm" },
    [122783] = { class = "MONK", duration = 90,  category = "defensive", name = "Diffuse Magic" },
    [116849] = { class = "MONK", spec = 270, duration = 120, category = "external",  name = "Life Cocoon" },
    [115310] = { class = "MONK", spec = 270, duration = 180, category = "raidcd",   name = "Revival" },
    [115203] = { class = "MONK", duration = 360, category = "defensive", name = "Fortifying Brew" },

    -- ============== Paladin ==============
    [642]    = { class = "PALADIN", duration = 300, category = "defensive", name = "Divine Shield" },
    [31850]  = { class = "PALADIN", spec = 66, duration = 120, category = "defensive", name = "Ardent Defender" },
    [1022]   = { class = "PALADIN", duration = 300, category = "external",  name = "Blessing of Protection" },
    [6940]   = { class = "PALADIN", duration = 120, category = "external",  name = "Blessing of Sacrifice" },
    [31821]  = { class = "PALADIN", spec = 65, duration = 180, category = "raidcd",   name = "Aura Mastery" },
    [498]    = { class = "PALADIN", duration = 60,  category = "defensive", name = "Divine Protection" },
    [86659]  = { class = "PALADIN", spec = 66, duration = 300, category = "defensive", name = "Guardian of Ancient Kings" },
    [633]    = { class = "PALADIN", duration = 600, category = "external",  name = "Lay on Hands" },
    [1044]   = { class = "PALADIN", duration = 25,  category = "external",  name = "Blessing of Freedom" },
    [204018] = { class = "PALADIN", duration = 180, category = "external",  name = "Blessing of Spellwarding" },

    -- ============== Priest ==============
    [47585]  = { class = "PRIEST", spec = 258, duration = 120, category = "defensive", name = "Dispersion" },
    [33206]  = { class = "PRIEST", spec = 256, duration = 180, category = "external",  name = "Pain Suppression" },
    [47788]  = { class = "PRIEST", spec = 257, duration = 180, category = "external",  name = "Guardian Spirit" },
    [62618]  = { class = "PRIEST", spec = 256, duration = 180, category = "raidcd",   name = "Power Word: Barrier" },
    [64901]  = { class = "PRIEST", spec = 257, duration = 300, category = "raidcd",   name = "Symbol of Hope" },
    [19236]  = { class = "PRIEST", duration = 90,  category = "defensive", name = "Desperate Prayer" },
    [586]    = { class = "PRIEST", duration = 30,  category = "utility",   name = "Fade" },

    -- ============== Rogue ==============
    [1966]   = { class = "ROGUE", duration = 15,  category = "defensive", name = "Feint" },
    [31224]  = { class = "ROGUE", duration = 120, category = "defensive", name = "Cloak of Shadows" },
    [5277]   = { class = "ROGUE", duration = 120, category = "defensive", name = "Evasion" },
    [185311] = { class = "ROGUE", duration = 30,  category = "defensive", name = "Crimson Vial" },
    [114018] = { class = "ROGUE", duration = 360, category = "utility",   name = "Shroud of Concealment" },

    -- ============== Shaman ==============
    [108271] = { class = "SHAMAN", duration = 90,  category = "defensive", name = "Astral Shift" },
    [98008]  = { class = "SHAMAN", spec = 264, duration = 180, category = "raidcd",   name = "Spirit Link Totem" },
    [108280] = { class = "SHAMAN", spec = 264, duration = 180, category = "raidcd",   name = "Healing Tide Totem" },
    [16191]  = { class = "SHAMAN", duration = 180, category = "raidcd",   name = "Mana Tide Totem" },
    [192058] = { class = "SHAMAN", duration = 60,  category = "utility",   name = "Capacitor Totem" },
    [198103] = { class = "SHAMAN", duration = 300, category = "defensive", name = "Earth Elemental" },
    [546]    = { class = "SHAMAN", duration = 30,  category = "utility",   name = "Water Walking" },

    -- ============== Warlock ==============
    [104773] = { class = "WARLOCK", duration = 180, category = "defensive", name = "Unending Resolve" },
    [108416] = { class = "WARLOCK", duration = 60,  category = "defensive", name = "Dark Pact" },
    [212295] = { class = "WARLOCK", duration = 45,  category = "defensive", name = "Nether Ward" },

    -- ============== Warrior ==============
    [184364] = { class = "WARRIOR", duration = 120, category = "defensive", name = "Enraged Regeneration" },
    [871]    = { class = "WARRIOR", spec = 73, duration = 240, category = "defensive", name = "Shield Wall" },
    [12975]  = { class = "WARRIOR", spec = 73, duration = 180, category = "defensive", name = "Last Stand" },
    [97462]  = { class = "WARRIOR", duration = 180, category = "raidcd",   name = "Rallying Cry" },
    [23920]  = { class = "WARRIOR", spec = 73, duration = 25,  category = "utility",   name = "Spell Reflection" },
    [118038] = { class = "WARRIOR", spec = 71, duration = 180, category = "defensive", name = "Die by the Sword" },
}

for k in pairs(TRACKED_SPELLS) do
    if type(k) ~= "number" then TRACKED_SPELLS[k] = nil end
end

----------------------------------------------------------------------
-- Talent-based Cooldown Modifications
----------------------------------------------------------------------
local TALENT_CD_MODS = {
    [114154] = { class = "PALADIN",
        modifies = { [642] = 90, [498] = 18, [633] = 180 }
    },
    [197073] = { class = "DRUID",
        modifies = { [740] = 60 }
    },
    [317133] = { class = "DEATHKNIGHT",
        modifies = { [55233] = 30 }
    },
    [196985] = { class = "PRIEST",
        modifies = { [62618] = 45 }
    },
    [266921] = { class = "HUNTER",
        modifies = { [186265] = 36 }
    },
}

local function GetEffectiveDuration(spellID, isSelf)
    local data = TRACKED_SPELLS[spellID]
    if not data then return 0 end
    local base = data.duration or 0
    if not isSelf then return base end
    local total = base
    for talentID, info in pairs(TALENT_CD_MODS) do
        if info.modifies[spellID] and IsPlayerSpell and IsPlayerSpell(talentID) then
            total = total - info.modifies[spellID]
        end
    end
    return math.max(1, total)
end

----------------------------------------------------------------------
-- UI constants
-- Frame content width = TrackerFrame FRAME_WIDTH(260) - 2×PADDING(8) = 244px
-- Dispel bar: 3px. Name col starts at x=6, width=50.
-- Icon area: 244 - 6 - 50 - 4(gap) = 184px.
-- Icon step = ICON_SIZE(32) + ICON_GAP(4) = 36px → floor(184/36) = 5 max.
----------------------------------------------------------------------
local ICON_SIZE         = 32
local ICON_GAP          = 4
local ROW_HEIGHT        = ICON_SIZE + 6    -- 38px
local NAME_WIDTH        = 50
local SECTION_LABEL_H   = 20
local MAX_ICONS_PER_ROW = 5               -- 5 × 36 = 180px ≤ 184px available

local DISPEL_COLORS = {
    magic   = {0.20, 0.45, 1.00},
    curse   = {0.55, 0.10, 0.85},
    disease = {0.55, 0.85, 0.10},
    poison  = {0.10, 0.90, 0.35},
    enrage  = {1.00, 0.25, 0.25},
}

----------------------------------------------------------------------
-- Single unified section and row list
----------------------------------------------------------------------
local cooldownSection
local rows    = {}
local unitToRow = {}   -- unit token → row (fast UNIT_AURA lookup)

----------------------------------------------------------------------
-- Spec detection
----------------------------------------------------------------------
local function GetUnitSpecID(unit)
    if not UnitExists(unit) then return nil end
    if UnitIsUnit(unit, "player") then
        local idx = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization
                    and C_SpecializationInfo.GetSpecialization()
        if idx then
            local id = C_SpecializationInfo.GetSpecializationInfo(idx)
            if id and id > 0 then return id end
        end
        return nil
    end
    if GetInspectSpecialization then
        local id = GetInspectSpecialization(unit)
        if id and id > 0 then return id end
    end
    return nil
end

----------------------------------------------------------------------
-- Spell collection — all categories for every player
----------------------------------------------------------------------
local function CollectSpellsForUnit(className, specID)
    local spells = {}
    for spellID, data in pairs(TRACKED_SPELLS) do
        if data.class == className then
            local include = true
            if data.spec and specID and data.spec ~= specID then
                include = false
            end
            if include then
                table.insert(spells, spellID)
            end
        end
    end
    return spells
end

-- Sort: defensive → raidcd → external → utility, then by duration desc
local function SortSpells(a, b)
    local catOrder = { defensive = 1, raidcd = 2, external = 3, utility = 4 }
    local catA = TRACKED_SPELLS[a] and catOrder[TRACKED_SPELLS[a].category] or 9
    local catB = TRACKED_SPELLS[b] and catOrder[TRACKED_SPELLS[b].category] or 9
    if catA ~= catB then return catA < catB end
    return (TRACKED_SPELLS[a].duration or 0) > (TRACKED_SPELLS[b].duration or 0)
end

----------------------------------------------------------------------
-- Row creation — all rows have a dispel bar (auto-hides for self)
----------------------------------------------------------------------
local function CreateRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("LEFT",  0, 0)
    row:SetPoint("RIGHT", 0, 0)

    -- 3px coloured bar on the left edge; hidden until a dispellable debuff exists
    row.dispelBar = row:CreateTexture(nil, "OVERLAY")
    row.dispelBar:SetSize(3, ROW_HEIGHT - 4)
    row.dispelBar:SetPoint("LEFT", 0, 0)
    row.dispelBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.dispelBar:Hide()

    row.nameText = row:CreateFontString(nil, "OVERLAY")
    row.nameText:SetFontObject(MP.Fonts.Small)
    row.nameText:SetPoint("LEFT", 6, 0)
    row.nameText:SetWidth(NAME_WIDTH)
    row.nameText:SetJustifyH("LEFT")

    row.icons       = {}
    row.unitToken   = nil
    row.playerGUID  = nil
    row.playerName  = nil
    row.playerClass = nil
    row.playerSpec  = nil

    return row
end

local function GetOrCreateRow(idx)
    if not rows[idx] then
        local row = CreateRow(cooldownSection)
        row:SetPoint("TOPLEFT", 0, -(SECTION_LABEL_H + (idx - 1) * ROW_HEIGHT))
        rows[idx] = row
    end
    return rows[idx]
end

----------------------------------------------------------------------
-- UI creation
----------------------------------------------------------------------
local function CreateUI()
    cooldownSection = MP.TrackerFrame:CreateSection("Cooldowns", SECTION_LABEL_H + 1)
    rows      = {}
    unitToRow = {}
    MP.TrackerFrame:AddSection(cooldownSection)
end

----------------------------------------------------------------------
-- Icon layout for a row
----------------------------------------------------------------------
local function GetIconSize()
    local cfg = MP.db and MP.db.modules and MP.db.modules.partyCooldowns
    return (cfg and cfg.iconSize) or ICON_SIZE
end

local function BuildPlayerIcons(row, spellList)
    for _, icon in ipairs(row.icons) do icon:Hide() end

    local size = GetIconSize()
    local step = size + ICON_GAP

    for i, spellID in ipairs(spellList) do
        if i > MAX_ICONS_PER_ROW then break end

        local icon = row.icons[i]
        if not icon then
            icon = MP.CooldownIconWidget:Create(row, size)
            row.icons[i] = icon
        else
            icon:SetSize(size, size)
            if icon.ApplySize then icon:ApplySize(size) end
        end

        icon:SetPoint("LEFT", row.nameText, "RIGHT", 4 + (i - 1) * step, 0)
        icon:SetSpell(spellID, row.playerClass)
        icon:ClearCooldown()
        icon:Show()
    end
end

----------------------------------------------------------------------
-- Dispel indicator
----------------------------------------------------------------------
local function UpdateDispelIndicator(row)
    if not row or not row.dispelBar then return end
    local dt = MP:GetModule("DispelTracker")
    if not dt then row.dispelBar:Hide(); return end

    local unit = row.unitToken
    if not unit or not UnitExists(unit) then row.dispelBar:Hide(); return end

    local dispelType = dt:CanLocalPlayerDispelUnit(unit)
    if dispelType then
        local c = DISPEL_COLORS[dispelType]
        if c then
            row.dispelBar:SetVertexColor(c[1], c[2], c[3], 1.0)
            row.dispelBar:Show()
            return
        end
    end
    row.dispelBar:Hide()
end

----------------------------------------------------------------------
-- Populate a single row for a unit
----------------------------------------------------------------------
local function PopulateRow(row, unit)
    local name     = UnitName(unit)
    local _, class = UnitClass(unit)
    local guid     = UnitGUID(unit)
    local specID   = GetUnitSpecID(unit)

    row.unitToken   = unit
    row.playerGUID  = guid
    row.playerName  = name
    row.playerClass = class
    row.playerSpec  = specID
    row.nameText:SetText(MP:ClassColoredName(name or "?", class))
    unitToRow[unit] = row

    local spells = CollectSpellsForUnit(class, specID)
    table.sort(spells, SortSpells)
    local limited = {}
    for j = 1, math.min(#spells, MAX_ICONS_PER_ROW) do limited[j] = spells[j] end
    BuildPlayerIcons(row, limited)
    UpdateDispelIndicator(row)
    row:Show()
end

----------------------------------------------------------------------
-- Scan group and rebuild the unified section
----------------------------------------------------------------------
local function ScanGroup()
    if not cooldownSection then return end

    local numMembers = GetNumGroupMembers()
    if numMembers == 0 then
        for _, row in ipairs(rows) do row:Hide() end
        cooldownSection:SetHeight(SECTION_LABEL_H + 1)
        MP.TrackerFrame:Layout()
        return
    end

    local rIdx = 0
    unitToRow = {}

    -- Local player always first
    rIdx = rIdx + 1
    PopulateRow(GetOrCreateRow(rIdx), "player")

    -- Then the rest of the group
    for i = 1, numMembers do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        else
            unit = "party" .. i
        end
        if UnitExists(unit) and not UnitIsUnit(unit, "player") then
            rIdx = rIdx + 1
            PopulateRow(GetOrCreateRow(rIdx), unit)
        end
    end

    -- Hide stale rows from a previously larger group
    for i = rIdx + 1, #rows do
        if rows[i] then rows[i]:Hide() end
    end

    local h = SECTION_LABEL_H + rIdx * ROW_HEIGHT + 2
    cooldownSection:SetHeight(math.max(h, SECTION_LABEL_H + 1))
    if rIdx > 0 then cooldownSection:Show() else cooldownSection:Hide() end
    MP.TrackerFrame:Layout()
end

----------------------------------------------------------------------
-- Start a cooldown on the matching row
----------------------------------------------------------------------
local function StartCooldownOnRow(matchKey, matchType, spellID)
    local data = TRACKED_SPELLS[spellID]
    if not data then return end

    local playerGUID = UnitGUID("player")
    local playerName = UnitName("player")
    local isSelf = (matchType == "guid" and matchKey == playerGUID)
                or (matchType == "name" and matchKey == playerName)
    local dur = GetEffectiveDuration(spellID, isSelf)

    for _, row in ipairs(rows) do
        local matches = (matchType == "guid" and row.playerGUID == matchKey)
                     or (matchType == "name" and row.playerName == matchKey)
        if matches then
            for _, icon in ipairs(row.icons) do
                if icon.spellID == spellID then
                    icon:StartCooldown(dur)
                    break
                end
            end
            return
        end
    end
end

----------------------------------------------------------------------
-- Aura refresh: active-icon highlighting + dispel indicator
----------------------------------------------------------------------
local function GetRowSpellSet(row)
    local set = {}
    for _, icon in ipairs(row.icons) do
        if icon.spellID then set[icon.spellID] = icon end
    end
    return set
end

local function UpdateAurasForUnit(unit)
    if not unit or not UnitExists(unit) then return end

    local row = unitToRow[unit]
    if not row then
        local name = UnitName(unit)
        for _, r in ipairs(rows) do
            if r.playerName == name then row = r; break end
        end
    end
    if not row then return end

    local spellSet = GetRowSpellSet(row)
    for _, icon in pairs(spellSet) do
        if icon.SetActive then icon:SetActive(false) end
    end

    local check = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
    if check then
        for spellID, icon in pairs(spellSet) do
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
            local spellName = info and info.name
            if spellName then
                local ok, helpful = pcall(check, unit, spellName, "HELPFUL")
                local active = (ok and helpful ~= nil)
                if not active then
                    local ok2, harmful = pcall(check, unit, spellName, "HARMFUL")
                    active = (ok2 and harmful ~= nil)
                end
                if active and icon.SetActive then icon:SetActive(true) end
            end
        end
    end

    UpdateDispelIndicator(row)
end

----------------------------------------------------------------------
-- Cast handlers
----------------------------------------------------------------------
local function OnSpellCast(unit, _, spellID)
    if not PartyCooldowns.active then return end
    if unit ~= "player" and unit ~= "pet" and unit ~= "playerpet" then return end
    if type(spellID) ~= "number" or spellID <= 0 then return end
    if not TRACKED_SPELLS[spellID] then return end

    local guid = UnitGUID("player")
    if not guid then return end
    StartCooldownOnRow(guid, "guid", spellID)
    if MP.Comm then MP.Comm:Send("CD", spellID) end
end

local function OnRemoteCast(payload, senderShort)
    if not PartyCooldowns.active or not payload then return end
    local spellID = tonumber(payload)
    if not spellID or not TRACKED_SPELLS[spellID] then return end
    if not senderShort then return end
    StartCooldownOnRow(senderShort, "name", spellID)
end

----------------------------------------------------------------------
-- CD text update ticker
----------------------------------------------------------------------
local updateFrame = CreateFrame("Frame")
updateFrame:Hide()
local updateElapsed = 0

updateFrame:SetScript("OnUpdate", function(self, dt)
    updateElapsed = updateElapsed + dt
    if updateElapsed < 0.5 then return end
    updateElapsed = 0
    if not PartyCooldowns.active then self:Hide(); return end
    for _, row in ipairs(rows) do
        if row:IsShown() then
            for _, icon in ipairs(row.icons) do
                if icon:IsShown() then icon:UpdateCDText() end
            end
        end
    end
end)

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function PartyCooldowns:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        OnSpellCast(...)

    elseif event == "GROUP_ROSTER_UPDATE" then
        if not MP:IsInMythicPlus() then return end
        C_Timer.After(0.5, ScanGroup)

    elseif event == "CHALLENGE_MODE_START" then
        self.active = true
        if cooldownSection then cooldownSection:Show() end
        if updateFrame     then updateFrame:Show() end
        ScanGroup()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(0.3, ScanGroup)

    elseif event == "INSPECT_READY" then
        C_Timer.After(0.2, ScanGroup)

    elseif event == "UNIT_AURA" then
        local unit = ...
        if not unit then return end
        local prefix = unit:match("^(%a+)")
        if prefix ~= "player" and prefix ~= "party" and prefix ~= "raid" then return end

        self._auraPending = self._auraPending or {}
        if self._auraPending[unit] then return end
        self._auraPending[unit] = true
        C_Timer.After(0.2, function()
            self._auraPending[unit] = nil
            UpdateAurasForUnit(unit)
        end)

    elseif event == "CHALLENGE_MODE_RESET" or event == "CHALLENGE_MODE_COMPLETED" then
        self.players = {}
        if cooldownSection then cooldownSection:Hide() end
        if updateFrame     then updateFrame:Hide() end
        self.active = false
    end
end

function PartyCooldowns:OnFrameReady()
    if not MP.TrackerFrame or not MP.TrackerFrame.frame then
        MP:Debug("TrackerFrame not ready, skipping PartyCooldowns UI creation")
        return
    end
    CreateUI()
    self.active = true
    if MP.Comm then MP.Comm:RegisterHandler("CD", OnRemoteCast) end
    ScanGroup()
    updateFrame:Show()
end

function PartyCooldowns:OnPlayerEnteringWorld()
    C_Timer.After(3, ScanGroup)
end

----------------------------------------------------------------------
-- Demo mode
----------------------------------------------------------------------
function PartyCooldowns:StartDemo(demoParty)
    if not cooldownSection then return end
    self.active = true
    unitToRow   = {}

    local rIdx = 0
    for i, p in ipairs(demoParty) do
        rIdx = rIdx + 1
        local row = GetOrCreateRow(rIdx)
        local unitToken = (i == 1) and "player" or ("party" .. (i - 1))

        row.unitToken   = unitToken
        row.playerGUID  = "demo-" .. p.name
        row.playerName  = p.name
        row.playerClass = p.class
        row.playerSpec  = nil
        row.nameText:SetText(MP:ClassColoredName(p.name, p.class))
        unitToRow[unitToken] = row

        local spells = CollectSpellsForUnit(p.class, nil)
        table.sort(spells, SortSpells)
        local limited = {}
        for j = 1, math.min(#spells, MAX_ICONS_PER_ROW) do limited[j] = spells[j] end
        BuildPlayerIcons(row, limited)
        -- No real auras in demo; dispel bar stays hidden
        row:Show()
    end

    for i = rIdx + 1, #rows do if rows[i] then rows[i]:Hide() end end

    local h = SECTION_LABEL_H + rIdx * ROW_HEIGHT + 2
    cooldownSection:SetHeight(math.max(h, SECTION_LABEL_H + 1))
    if rIdx > 0 then cooldownSection:Show() else cooldownSection:Hide() end
    if MP.TrackerFrame and MP.TrackerFrame.Layout then MP.TrackerFrame:Layout() end
    updateFrame:Show()
end

function PartyCooldowns:StopDemo()
    self.active = false
    for _, row in ipairs(rows) do row:Hide() end
    if cooldownSection then cooldownSection:Hide() end
    if updateFrame     then updateFrame:Hide() end
    self.players = {}
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("PartyCooldowns", PartyCooldowns)
