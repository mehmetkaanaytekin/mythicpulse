--[[
    MythicPulse - Party Cooldowns Module
    OmniCD-style: cooldown icons anchor directly to party/raid unit frames
    (Blizzard default or ElvUI) via MP.UnitFrameProvider.

    One icon row per group member. The local player is always listed first.
    Icons show ALL tracked cooldowns for that class/spec.

    MIDNIGHT 12.0.5 COMPLIANCE NOTE:
    - Non-self UNIT_SPELLCAST_SUCCEEDED returns opaque spellIDs; only
      the local player's casts are trusted here.  Remote casts arrive
      via the "CD" Comm broadcast.
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

    -- ============== Bloodlust / Heroism ==============
    -- Also tracked by CombatRes for its dedicated HUD frame; these entries
    -- make the cast visible in the per-player icon row as well.
    [2825]   = { class = "SHAMAN", duration = 600, category = "raidcd", name = "Bloodlust" },
    [32182]  = { class = "SHAMAN", duration = 600, category = "raidcd", name = "Heroism" },
    [80353]  = { class = "MAGE",   duration = 600, category = "raidcd", name = "Time Warp" },
    [390386] = { class = "EVOKER", duration = 600, category = "raidcd", name = "Fury of the Aspects" },
    [264667] = { class = "HUNTER", spec = 253, duration = 600, category = "raidcd", name = "Primal Rage" },
    [90355]  = { class = "HUNTER", spec = 253, duration = 600, category = "raidcd", name = "Ancient Hysteria" },
}

for k in pairs(TRACKED_SPELLS) do
    if type(k) ~= "number" then TRACKED_SPELLS[k] = nil end
end

-- Debuffs that indicate Bloodlust-equivalent was recently used, and the set of
-- lust spell IDs. Shared with CombatRes via Data/LustData.lua (single source of
-- truth). Any Sated debuff on any party member means lust icons go on cooldown.
local SATED_IDS      = MP.LustData.SATED_IDS
local LUST_SPELL_IDS = MP.LustData.LUST_SPELL_IDS

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
-- Config helpers
----------------------------------------------------------------------
local ICON_SIZE_DEFAULT = 32
local ICON_GAP_DEFAULT  = 4

local function GetCfg()
    return (MP.db and MP.db.modules and MP.db.modules.partyCooldowns) or {}
end

local DISPEL_COLORS = {
    magic    = {0.20, 0.45, 1.00},
    curse    = {0.55, 0.10, 0.85},
    disease  = {0.55, 0.85, 0.10},
    poison   = {0.10, 0.90, 0.35},
    enrage   = {1.00, 0.25, 0.25},
    offMagic = {0.60, 0.60, 0.60},
    mass     = {0.60, 0.60, 0.60},
    immunity = {0.80, 0.70, 0.20},
}

----------------------------------------------------------------------
-- Row state
----------------------------------------------------------------------
local rows      = {}
local unitToRow = {}  -- unitToken -> row (fast UNIT_AURA lookup)

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
-- Spell collection
----------------------------------------------------------------------
local function CollectSpellsForUnit(unitToken, className, specID)
    local spells = {}
    local isLocalPlayer = unitToken == "player"

    if isLocalPlayer then
        local tt = MP:GetModule("TrinketTracker")
        if tt and tt.active and tt.trinkets then
            for spellID, tData in pairs(tt.trinkets) do
                if not TRACKED_SPELLS[spellID] then
                    TRACKED_SPELLS[spellID] = {
                        class    = className,
                        duration = tData.duration,
                        category = "utility",
                        name     = "Trinket",
                        isTrinket = true,
                    }
                end
            end
        end
    end

    for spellID, data in pairs(TRACKED_SPELLS) do
        if data.class == className then
            local include = true
            if data.spec and specID and data.spec ~= specID then
                include = false
            end
            if include and isLocalPlayer and IsPlayerSpell and not data.isTrinket then
                if not IsPlayerSpell(spellID) then include = false end
            end
            if include and data.isTrinket and isLocalPlayer then
                local tt = MP:GetModule("TrinketTracker")
                if not tt or not tt.active or not tt.trinkets or not tt.trinkets[spellID] then
                    include = false
                end
            end
            if include then table.insert(spells, spellID) end
        end
    end
    return spells
end

local function SortSpells(a, b)
    local catOrder = { defensive = 1, raidcd = 2, external = 3, utility = 4 }
    local catA = TRACKED_SPELLS[a] and catOrder[TRACKED_SPELLS[a].category] or 9
    local catB = TRACKED_SPELLS[b] and catOrder[TRACKED_SPELLS[b].category] or 9
    if catA ~= catB then return catA < catB end
    return (TRACKED_SPELLS[a].duration or 0) > (TRACKED_SPELLS[b].duration or 0)
end

----------------------------------------------------------------------
-- Row creation — unparented, sized by BuildPlayerIcons
----------------------------------------------------------------------
local function CreateRow()
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetSize(1, 1)
    row:SetFrameStrata("MEDIUM")
    row:Hide()

    row.dispelBar = row:CreateTexture(nil, "OVERLAY")
    row.dispelBar:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.dispelBar:Hide()

    row.icons       = {}
    row.unitToken   = nil
    row.playerGUID  = nil
    row.playerName  = nil
    row.playerClass = nil
    row.playerSpec  = nil
    row.anchoredTo  = nil

    return row
end

local function GetOrCreateRow(idx)
    if not rows[idx] then
        rows[idx] = CreateRow()
    end
    return rows[idx]
end

----------------------------------------------------------------------
-- Anchor a row's icon strip to the unit's frame
----------------------------------------------------------------------
local function AnchorRowToUnitFrame(row, unitToken)
    if not MP.UnitFrameProvider then row:Hide(); return false end
    local target = MP.UnitFrameProvider:GetFrame(unitToken)
    if not target then row:Hide(); row.anchoredTo = nil; return false end

    local cfg = GetCfg()
    row:ClearAllPoints()
    row:SetPoint(
        cfg.anchorPoint   or "LEFT",
        target,
        cfg.relativePoint or "RIGHT",
        cfg.offsetX       or 4,
        cfg.offsetY       or 0
    )
    row:SetFrameLevel((target:GetFrameLevel() or 1) + 5)
    row.anchoredTo = target
    row:Show()
    return true
end

----------------------------------------------------------------------
-- Icon layout
----------------------------------------------------------------------
local function BuildPlayerIcons(row, spellList)
    for _, icon in ipairs(row.icons) do icon:Hide() end

    local cfg      = GetCfg()
    local size     = cfg.iconSize        or ICON_SIZE_DEFAULT
    local gap      = cfg.iconGap         or ICON_GAP_DEFAULT
    local maxIcons = cfg.maxIcons        or 8
    local perRow   = cfg.iconsPerRow     or maxIcons
    local growth   = cfg.growthDirection or "RIGHT"
    local step     = size + gap
    local count    = math.min(#spellList, maxIcons)

    local function PlaceIcon(icon, idx)
        local col  = (idx - 1) % perRow
        local rowN = math.floor((idx - 1) / perRow)
        icon:ClearAllPoints()
        if growth == "RIGHT" then
            icon:SetPoint("TOPLEFT", row, "TOPLEFT",  col * step,  -rowN * step)
        elseif growth == "LEFT" then
            icon:SetPoint("TOPRIGHT", row, "TOPRIGHT", -col * step, -rowN * step)
        elseif growth == "UP" then
            icon:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", col * step,  rowN * step)
        else -- DOWN
            icon:SetPoint("TOPLEFT", row, "TOPLEFT",  col * step, -rowN * step)
        end
    end

    for i = 1, count do
        local spellID = spellList[i]
        local icon = row.icons[i]
        if not icon then
            icon = MP.CooldownIconWidget:Create(row, size)
            row.icons[i] = icon
        else
            icon:SetSize(size, size)
            if icon.ApplySize then icon:ApplySize(size) end
        end
        PlaceIcon(icon, i)
        icon:SetSpell(spellID, row.playerClass)
        icon:ClearCooldown()
        icon:Show()
    end

    -- Size the row frame to contain the icon strip
    local cols  = math.min(count, perRow)
    local rowCt = math.max(1, math.ceil(count / perRow))
    if count == 0 then
        row:SetSize(1, 1)
    elseif growth == "RIGHT" or growth == "LEFT" or growth == "DOWN" then
        row:SetSize(cols * step - gap, rowCt * step - gap)
    else -- UP
        row:SetSize(cols * step - gap, rowCt * step - gap)
    end

    -- Dispel bar: 3px strip on the leading edge
    local showBar = cfg.showDispelBar ~= false
    if showBar then
        row.dispelBar:ClearAllPoints()
        if growth == "RIGHT" then
            row.dispelBar:SetSize(3, math.max(1, row:GetHeight()))
            row.dispelBar:SetPoint("RIGHT", row, "LEFT", -2, 0)
        elseif growth == "LEFT" then
            row.dispelBar:SetSize(3, math.max(1, row:GetHeight()))
            row.dispelBar:SetPoint("LEFT", row, "RIGHT", 2, 0)
        elseif growth == "UP" then
            row.dispelBar:SetSize(math.max(1, row:GetWidth()), 3)
            row.dispelBar:SetPoint("TOP", row, "BOTTOM", 0, -2)
        else -- DOWN
            row.dispelBar:SetSize(math.max(1, row:GetWidth()), 3)
            row.dispelBar:SetPoint("BOTTOM", row, "TOP", 0, 2)
        end
    end
end

----------------------------------------------------------------------
-- Dispel indicator
----------------------------------------------------------------------
local function UpdateDispelIndicator(row)
    if not row or not row.dispelBar then return end
    local cfg = GetCfg()
    if cfg.showDispelBar == false then row.dispelBar:Hide(); return end

    local dt = MP:GetModule("DispelTracker")
    if not dt then row.dispelBar:Hide(); return end
    if not MP:IsModuleEnabled("dispelTracker") then row.dispelBar:Hide(); return end
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
-- Populate a row for a unit
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
    unitToRow[unit] = row

    local cfg    = GetCfg()
    local spells = CollectSpellsForUnit(unit, class, specID)
    table.sort(spells, SortSpells)
    local limited = {}
    for j = 1, math.min(#spells, cfg.maxIcons or 8) do limited[j] = spells[j] end
    BuildPlayerIcons(row, limited)

    -- Restore in-flight trinket cooldowns after a row rebuild
    if unit == "player" then
        local tt = MP:GetModule("TrinketTracker")
        if tt and tt.active and tt.trinkets then
            local now = GetTime()
            for sID, tData in pairs(tt.trinkets) do
                if (tData.cdEnd or 0) > now then
                    for _, icon in ipairs(row.icons) do
                        if icon.spellID == sID then
                            icon:StartCooldown(tData.cdEnd - now)
                            break
                        end
                    end
                end
            end
        end
    end

    UpdateDispelIndicator(row)

    if not AnchorRowToUnitFrame(row, unit) then
        row:Hide()
    end
end

----------------------------------------------------------------------
-- Scan group and anchor all rows to unit frames
----------------------------------------------------------------------
local function ScanGroup()
    if not PartyCooldowns.active then
        for _, row in ipairs(rows) do row:Hide() end
        return
    end

    local rIdx    = 0
    unitToRow = {}

    -- Local player always first (even solo)
    rIdx = rIdx + 1
    PopulateRow(GetOrCreateRow(rIdx), "player")

    local numMembers = GetNumGroupMembers()
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

    -- Hide rows from a previously larger group
    for i = rIdx + 1, #rows do
        if rows[i] then rows[i]:Hide() end
    end
end

----------------------------------------------------------------------
-- Start a cooldown on the matching row
----------------------------------------------------------------------
local function StartCooldownOnRow(matchKey, matchType, spellID)
    local data = TRACKED_SPELLS[spellID]
    if not data then return end

    local playerGUID = UnitGUID("player")
    local playerName = UnitName("player")
    local isSelf = (matchType == "guid" and MP:SafeStringEquals(matchKey, playerGUID))
                or (matchType == "name" and MP:SafeStringEquals(matchKey, playerName))
    local dur = GetEffectiveDuration(spellID, isSelf)

    for _, row in ipairs(rows) do
        local matches = (matchType == "guid" and MP:SafeStringEquals(row.playerGUID, matchKey))
                     or (matchType == "name" and MP:SafeStringEquals(row.playerName, matchKey))
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
-- Aura refresh
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
            if MP:SafeStringEquals(r.playerName, name) then row = r; break end
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

    -- If this unit has a Sated-type debuff, force all lust icons in every row
    -- into cooldown for the debuff's remaining duration.  This catches cases
    -- where the caster isn't running MythicPulse (no Comm message) so the
    -- UNIT_SPELLCAST_SUCCEEDED path never fired for us.
    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID then
        local now         = GetTime()
        local satedExpiry = 0
        for satedID in pairs(SATED_IDS) do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellID, unit, satedID, "HARMFUL")
            if ok and aura then
                local expOk, exp = pcall(function() return aura.expirationTime end)
                exp = (expOk and type(exp) == "number" and exp > 0) and exp or (now + 600)
                if exp > satedExpiry then satedExpiry = exp end
            end
        end
        if satedExpiry > now then
            local remaining = satedExpiry - now
            for _, r in ipairs(rows) do
                for _, icon in ipairs(r.icons) do
                    if icon.spellID and LUST_SPELL_IDS[icon.spellID] then
                        -- Only update if the icon has no cooldown or less time than debuff has left
                        if not icon:IsOnCooldown() or (icon.endTime and icon.endTime < satedExpiry) then
                            icon:StartCooldown(remaining)
                        end
                    end
                end
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
        if self.active then C_Timer.After(0.5, ScanGroup) end

    elseif event == "CHALLENGE_MODE_START" then
        self.active = true
        updateFrame:Show()
        ScanGroup()

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        if self.active then C_Timer.After(0.3, ScanGroup) end

    elseif event == "INSPECT_READY" then
        if self.active then C_Timer.After(0.2, ScanGroup) end

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
        for _, row in ipairs(rows) do
            row:Hide()
            row:ClearAllPoints()
            row.anchoredTo = nil
        end
        updateFrame:Hide()
        self.active = false
    end
end

function PartyCooldowns:OnFrameReady()
    if MP.UnitFrameProvider then
        MP.UnitFrameProvider:RegisterCallback("PartyCooldowns", function(unitToken)
            if not self.active then return end
            if unitToken then
                local row = unitToRow[unitToken]
                if row then AnchorRowToUnitFrame(row, unitToken) end
            else
                for _, row in ipairs(rows) do
                    if row.unitToken then AnchorRowToUnitFrame(row, row.unitToken) end
                end
            end
        end)
    end
    if MP.Comm then MP.Comm:RegisterHandler("CD", OnRemoteCast) end
end

function PartyCooldowns:OnDisable()
    self.active = false
    updateFrame:Hide()
    for _, row in ipairs(rows) do
        row:Hide()
        row:ClearAllPoints()
        row.anchoredTo = nil
    end
    if MP.UnitFrameProvider then
        MP.UnitFrameProvider:UnregisterCallback("PartyCooldowns")
    end
end

function PartyCooldowns:OnEnable()
    -- Re-run frame-ready setup to restore the UnitFrameProvider callback (OnDisable unregisters it).
    -- Comm handler re-registration is safe here because Comm:RegisterHandler now deduplicates.
    self:OnFrameReady()
    if MP:IsInMythicPlus() then
        self.active = true
        ScanGroup()
    end
end

function PartyCooldowns:OnPlayerEnteringWorld()
    C_Timer.After(3, function()
        -- Reactivate if we reloaded while already inside an active key.
        if not self.active
        and C_ChallengeMode
        and C_ChallengeMode.IsChallengeModeActive
        and C_ChallengeMode.IsChallengeModeActive() then
            self.active = true
            updateFrame:Show()
        end
        if self.active then ScanGroup() end
    end)
end

function PartyCooldowns:RebuildAll()
    if not self.active then return end
    ScanGroup()
end

--- Refresh dispel bar color/visibility on all visible rows (called on dispelTracker enable/disable)
function PartyCooldowns:RefreshDispelBars()
    for _, row in ipairs(rows) do
        if row:IsShown() then
            UpdateDispelIndicator(row)
        end
    end
end

--- Start a cooldown sweep on the local player's trinket icon (called by TrinketTracker)
function PartyCooldowns:StartTrinketCooldown(spellID, duration)
    local row = unitToRow["player"]
    if not row then return end
    for _, icon in ipairs(row.icons) do
        if icon.spellID == spellID then
            icon:StartCooldown(duration)
            return
        end
    end
end

----------------------------------------------------------------------
-- Demo mode
----------------------------------------------------------------------
local _demoPrinted = false

function PartyCooldowns:StartDemo(demoParty)
    self.active = true
    unitToRow   = {}

    local rIdx = 0
    for i, p in ipairs(demoParty) do
        local unitToken = (i == 1) and "player" or ("party" .. (i - 1))
        if MP.UnitFrameProvider and MP.UnitFrameProvider:GetFrame(unitToken) then
            rIdx = rIdx + 1
            local row = GetOrCreateRow(rIdx)
            row.unitToken   = unitToken
            row.playerGUID  = "demo-" .. p.name
            row.playerName  = p.name
            row.playerClass = p.class
            row.playerSpec  = nil
            unitToRow[unitToken] = row

            local cfg    = GetCfg()
            -- Use a neutral token so IsPlayerSpell doesn't filter demo spells for the wrong class.
            local spells = CollectSpellsForUnit("party0", p.class, nil)
            table.sort(spells, SortSpells)
            local limited = {}
            for j = 1, math.min(#spells, cfg.maxIcons or 8) do limited[j] = spells[j] end
            BuildPlayerIcons(row, limited)
            AnchorRowToUnitFrame(row, unitToken)
        end
    end

    for i = rIdx + 1, #rows do if rows[i] then rows[i]:Hide() end end

    if rIdx < #demoParty and not _demoPrinted then
        _demoPrinted = true
        MP:Print(MP:Loc("PC_DEMO_NEEDS_PARTY"))
    end

    updateFrame:Show()
end

function PartyCooldowns:StopDemo()
    self.active = false
    _demoPrinted = false
    for _, row in ipairs(rows) do
        row:Hide()
        row:ClearAllPoints()
        row.anchoredTo = nil
    end
    updateFrame:Hide()
    self.players = {}
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("PartyCooldowns", PartyCooldowns)
