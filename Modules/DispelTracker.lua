--[[
    MythicPulse - Dispel Tracker (data layer)
    Tracks who in the group can dispel which debuff types and whether their
    dispel spell is on cooldown.  No UI of its own — PartyCooldowns reads
    this data to draw per-row dispel indicators (decursive-style).

    MIDNIGHT 12.0.5 COMPLIANCE:
      - UNIT_SPELLCAST_SUCCEEDED only used for unit == "player".
      - Cross-party cooldowns received via Comm "DSP" broadcasts.
      - aura.dispelName access always wrapped in pcall (secret value in M+).
]]

local _, MP = ...

local DispelTracker = {
    registeredEvents = {
        "UNIT_SPELLCAST_SUCCEEDED",
        "GROUP_ROSTER_UPDATE",
        "PLAYER_ENTERING_WORLD",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_RESET",
        "CHALLENGE_MODE_COMPLETED",
    },
    active  = false,
    members = {},
}

----------------------------------------------------------------------
-- Dispel Spell Database
----------------------------------------------------------------------
local DISPELS = {
    { class = "DEMONHUNTER", spellID = 278326, name = "Consume Magic",
      types = { offMagic = true }, cd = 10 },
    { class = "DRUID", spellID = 88423,  name = "Nature's Cure",
      types = { magic = true, curse = true, poison = true }, cd = 8 },
    { class = "DRUID", spellID = 2782,   name = "Remove Corruption",
      types = { curse = true, poison = true }, cd = 8 },
    { class = "DRUID", spellID = 2908,   name = "Soothe",
      types = { enrage = true }, cd = 10 },
    { class = "EVOKER", spellID = 360823, name = "Naturalize",
      types = { magic = true, poison = true }, cd = 8 },
    { class = "EVOKER", spellID = 365585, name = "Expunge",
      types = { poison = true }, cd = 8 },
    { class = "HUNTER", spellID = 19801,  name = "Tranquilizing Shot",
      types = { enrage = true, offMagic = true }, cd = 10 },
    { class = "MAGE", spellID = 475,   name = "Remove Curse",
      types = { curse = true }, cd = 8 },
    { class = "MAGE", spellID = 30449, name = "Spellsteal",
      types = { offMagic = true }, cd = 0 },
    { class = "MONK", spellID = 115450, name = "Detox (Mistweaver)",
      types = { magic = true, disease = true, poison = true }, cd = 8 },
    { class = "MONK", spellID = 218164, name = "Detox",
      types = { disease = true, poison = true }, cd = 8 },
    { class = "PALADIN", spellID = 4987,   name = "Cleanse",
      types = { magic = true, disease = true, poison = true }, cd = 8 },
    { class = "PALADIN", spellID = 213644, name = "Cleanse Toxins",
      types = { disease = true, poison = true }, cd = 8 },
    { class = "PRIEST", spellID = 527,    name = "Purify",
      types = { magic = true, disease = true }, cd = 8 },
    { class = "PRIEST", spellID = 213634, name = "Purify Disease",
      types = { disease = true }, cd = 8 },
    { class = "PRIEST", spellID = 32375,  name = "Mass Dispel",
      types = { magic = true, mass = true }, cd = 45 },
    { class = "PRIEST", spellID = 528,    name = "Dispel Magic",
      types = { offMagic = true }, cd = 0 },
    { class = "ROGUE", spellID = 5938, name = "Shiv",
      types = { enrage = true }, cd = 25 },
    { class = "SHAMAN", spellID = 77130, name = "Purify Spirit",
      types = { magic = true, curse = true }, cd = 8 },
    { class = "SHAMAN", spellID = 51886, name = "Cleanse Spirit",
      types = { curse = true }, cd = 8 },
    { class = "SHAMAN", spellID = 370,   name = "Purge",
      types = { offMagic = true }, cd = 0 },
    { class = "WARLOCK", spellID = 89808, name = "Singe Magic (Imp)",
      types = { magic = true }, cd = 15 },
    { class = "WARRIOR", spellID = 64382, name = "Shattering Throw",
      types = { offMagic = true, immunity = true }, cd = 90 },
}

local SPELL_TO_DISPEL = {}
for _, d in ipairs(DISPELS) do SPELL_TO_DISPEL[d.spellID] = d end

local DISPEL_NAME_MAP = {
    Magic   = "magic",
    Curse   = "curse",
    Disease = "disease",
    Poison  = "poison",
    Enrage  = "enrage",
}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function GetTypesForClass(class)
    local types = {}
    for _, d in ipairs(DISPELS) do
        if d.class == class then
            for k, v in pairs(d.types) do
                if v then types[k] = true end
            end
        end
    end
    return types
end

local function ScanGroup()
    DispelTracker.members = {}
    local numMembers = GetNumGroupMembers()
    if numMembers == 0 then numMembers = 1 end
    for i = 1, numMembers do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        elseif numMembers == 1 then
            unit = "player"
        else
            unit = (i == 1) and "player" or ("party" .. (i - 1))
        end
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            local types = GetTypesForClass(class or "")
            local hasAny = false
            for _ in pairs(types) do hasAny = true; break end
            if hasAny then
                table.insert(DispelTracker.members, {
                    guid  = UnitGUID(unit),
                    name  = UnitName(unit),
                    class = class,
                    types = types,
                    cdEnd = 0,
                })
            end
        end
    end
end

local function FindMember(guid, name)
    for _, m in ipairs(DispelTracker.members) do
        if guid and MP:SafeStringEquals(m.guid, guid) then return m end
        if name and MP:SafeStringEquals(m.name, name) then return m end
    end
    return nil
end

local function OnDispelCast(guid, name, spellID)
    local d = SPELL_TO_DISPEL[spellID]
    if not d or not d.cd or d.cd <= 0 then return end
    local m = FindMember(guid, name)
    if not m then return end
    m.cdEnd = GetTime() + d.cd
end

local function OnRemoteDispel(payload, senderShort)
    if not DispelTracker.active or not payload or not senderShort then return end
    local spellID = tonumber(payload)
    if not spellID then return end
    OnDispelCast(nil, senderShort, spellID)
end

----------------------------------------------------------------------
-- Public API consumed by PartyCooldowns for dispel indicators
----------------------------------------------------------------------

--- Returns which dispel type keys the local player's class can cover.
function DispelTracker:GetLocalPlayerDispelTypes()
    local _, localClass = UnitClass("player")
    if not localClass then return {} end
    return GetTypesForClass(localClass)
end

--- Returns the first dispellable-by-me debuff type on `unit`, or nil.
--- All aura field access is wrapped in pcall (dispelName is a secret
--- value in M+ instances and reading it directly crashes the addon).
function DispelTracker:CanLocalPlayerDispelUnit(unit)
    if not unit or not UnitExists(unit) then return nil end
    if UnitIsUnit(unit, "player") then return nil end

    local playerTypes = self:GetLocalPlayerDispelTypes()
    if not next(playerTypes) then return nil end
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return nil end

    local i = 1
    while i <= 40 do
        local aura
        local ok = pcall(function()
            aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
        end)
        if not ok or not aura then break end

        local dispelType
        pcall(function()
            local dn = aura.dispelName
            if dn and dn ~= "" then
                -- Cannot use dn as a table key (secret value in M+ instances).
                -- Direct == comparison against regular strings is safe and returns
                -- a normal boolean.
                for mapKey, mapVal in pairs(DISPEL_NAME_MAP) do
                    if dn == mapKey then
                        dispelType = mapVal
                        break
                    end
                end
            end
        end)

        if dispelType and playerTypes[dispelType] then
            return dispelType
        end
        i = i + 1
    end
    return nil
end

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function DispelTracker:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if not unit or unit ~= "player" then return end
        if type(spellID) ~= "number" or spellID <= 0 then return end
        if not SPELL_TO_DISPEL[spellID] then return end
        local guid = UnitGUID("player")
        if not guid then return end
        OnDispelCast(guid, nil, spellID)
        if MP.Comm then MP.Comm:Send("DSP", spellID) end

    elseif event == "GROUP_ROSTER_UPDATE" then
        if not MP:IsInMythicPlus() then return end
        C_Timer.After(0.5, ScanGroup)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, ScanGroup)

    elseif event == "CHALLENGE_MODE_START" then
        self.active = true
        C_Timer.After(0.5, ScanGroup)

    elseif event == "CHALLENGE_MODE_RESET" or event == "CHALLENGE_MODE_COMPLETED" then
        self.members = {}
        self.active  = false
    end
end

function DispelTracker:OnFrameReady()
    if MP.Comm then
        MP.Comm:RegisterHandler("DSP", OnRemoteDispel)
    end
    ScanGroup()
    self.active = true
end

function DispelTracker:OnDisable()
    self.active = false
    self.members = {}
end

function DispelTracker:OnPlayerEnteringWorld()
    -- Handled via OnEvent
end

----------------------------------------------------------------------
-- Demo stubs — no UI to drive; just keep member list populated
----------------------------------------------------------------------
function DispelTracker:StartDemo()
    self.active = true
    ScanGroup()
end

function DispelTracker:StopDemo()
    self.members = {}
    self.active  = false
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("DispelTracker", DispelTracker)
