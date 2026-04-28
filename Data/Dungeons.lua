--[[
    MythicPulse - Dungeon Data (Midnight Season 1)
    Contains dungeon metadata, affix data, and helper functions.
]]

local _, MP = ...

MP.DungeonData = {}
MP.AffixData   = {}

----------------------------------------------------------------------
-- Season 1 Dungeon Pool
-- mapChallengeModeID values are placeholders; update with live IDs
----------------------------------------------------------------------
MP.DungeonData.Dungeons = {
    -- Midnight Dungeons
    { id = 501, name = "Magisters' Terrace",      shortName = "MT",   timeLimit = 1980, numBosses = 3, expansion = "Midnight" },
    { id = 502, name = "Maisara Caverns",         shortName = "MC",   timeLimit = 2100, numBosses = 4, expansion = "Midnight" },
    { id = 503, name = "Nexus-Point Xenas",       shortName = "NPX",  timeLimit = 1920, numBosses = 3, expansion = "Midnight" },
    { id = 504, name = "Windrunner Spire",        shortName = "WS",   timeLimit = 2040, numBosses = 4, expansion = "Midnight" },
    -- Legacy Dungeons
    { id = 505, name = "Algeth'ar Academy",       shortName = "AA",   timeLimit = 1800, numBosses = 4, expansion = "Dragonflight" },
    { id = 506, name = "Pit of Saron",            shortName = "PoS",  timeLimit = 1860, numBosses = 3, expansion = "WotLK" },
    { id = 507, name = "Seat of the Triumvirate", shortName = "SotT", timeLimit = 1740, numBosses = 4, expansion = "Legion" },
    { id = 508, name = "Skyreach",                shortName = "SR",   timeLimit = 1680, numBosses = 4, expansion = "WoD" },
}

--- Lookup table by mapID
MP.DungeonData.ByMapID = {}
for _, dungeon in ipairs(MP.DungeonData.Dungeons) do
    MP.DungeonData.ByMapID[dungeon.id] = dungeon
end

----------------------------------------------------------------------
-- Affix Definitions
----------------------------------------------------------------------
MP.AffixData.Affixes = {
    -- Seasonal affixes
    { id = 160, name = "Lindormi's Guidance",  icon = "Interface\\Icons\\ability_monk_renewingmists",  minLevel = 2,  maxLevel = 4  },
    { id = 161, name = "Xal'atath's Bargain: Ascendant", icon = "Interface\\Icons\\spell_shadow_shadowwordpain", minLevel = 5, maxLevel = 11 },
    { id = 162, name = "Xal'atath's Bargain: Voidbound", icon = "Interface\\Icons\\spell_shadow_shadowfury",     minLevel = 5, maxLevel = 11 },
    { id = 163, name = "Xal'atath's Bargain: Pulsar",    icon = "Interface\\Icons\\spell_arcane_arcane04",       minLevel = 5, maxLevel = 11 },
    { id = 164, name = "Xal'atath's Bargain: Devour",    icon = "Interface\\Icons\\spell_shadow_devourmagic",    minLevel = 5, maxLevel = 11 },
    { id = 165, name = "Xal'atath's Guile",   icon = "Interface\\Icons\\spell_shadow_requiem",     minLevel = 12, maxLevel = 99 },
    -- Standard affixes
    { id = 10,  name = "Fortified",            icon = "Interface\\Icons\\ability_toughness",         minLevel = 7,  maxLevel = 99 },
    { id = 9,   name = "Tyrannical",           icon = "Interface\\Icons\\achievement_boss_archaedas", minLevel = 7,  maxLevel = 99 },
}

MP.AffixData.ByID = {}
for _, affix in ipairs(MP.AffixData.Affixes) do
    MP.AffixData.ByID[affix.id] = affix
end

----------------------------------------------------------------------
-- Helper Functions
----------------------------------------------------------------------

function MP.DungeonData:GetByMapID(mapID)
    return self.ByMapID[mapID]
end

function MP.DungeonData:GetShortName(mapID)
    local d = self.ByMapID[mapID]
    return d and d.shortName
end

function MP.DungeonData:GetTimeLimit(mapID)
    local d = self.ByMapID[mapID]
    return d and d.timeLimit or 0
end

function MP.DungeonData:GetAll()
    return self.Dungeons
end

--- Calculate +2 and +3 time thresholds
--- +3 = completion within 60% of total time
--- +2 = completion within 80% of total time
function MP.DungeonData:GetTimingThresholds(timeLimit)
    if not timeLimit or timeLimit <= 0 then return 0, 0 end
    return math.floor(timeLimit * 0.8), math.floor(timeLimit * 0.6)
end

--- Get death penalty based on key level
function MP.DungeonData:GetDeathPenalty(keyLevel)
    if keyLevel and keyLevel >= 12 then
        return MP.DEATH_PENALTY.guile
    end
    return MP.DEATH_PENALTY.default
end

--- Check if deaths are penalized (Lindormi's Guidance = no penalty)
function MP.DungeonData:DeathsPenalized(keyLevel)
    return keyLevel and keyLevel >= 5
end
