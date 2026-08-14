--[[
    MythicPulse - Dungeon Data
    Contains dungeon metadata, affix data, and helper functions.

    SEASON ROTATION:
      The hardcoded pool below is only an ENRICHMENT layer (short codes, etc.).
      Core features (timer, name, time limit, affixes) resolve from live
      C_ChallengeMode / C_MythicPlus APIs and work on ANY dungeon rotation with
      no code change — see MP.DungeonData:GetInfo(). Every season's table below
      gets merged into one lookup (ChallengeMapIDs are permanent, seasons never
      reuse or conflict), so there is no "current season" switch to flip when a
      new season goes live — just add that season's table here (and the
      value-add data in DungeonTeleport / UtilityDungeons / AutoGossip).
      See Docs/SEASON_UPDATE.md.

      NOTE: dungeon ids here are ChallengeMapIDs
      (C_ChallengeMode.GetActiveChallengeMapID / MapChallengeModeID from
      Map_ChallengeMode.db2). UtilityDungeons.lua keys on instanceID — a
      different ID space.
]]

local _, MP = ...

MP.DungeonData = {}
MP.AffixData   = {}

----------------------------------------------------------------------
-- Season Dungeon Pools (keyed by ChallengeMapID)
-- Season 1 sourced from MDT mapInfo tables (build 12.0.5.67602).
-- Season 2 sourced from the live MapChallengeMode DB2 (wago.tools, 2026-08-14).
-- All seasons below are merged into one lookup — see MP.DungeonData.ByMapID.
----------------------------------------------------------------------
MP.DungeonData.Seasons = {
    -- Midnight Season 1
    [1] = {
        -- Midnight Dungeons
        { id = 558, name = "Magisters' Terrace",      shortName = "MT",   timeLimit = 1980, numBosses = 4, expansion = "Midnight" },
        { id = 560, name = "Maisara Caverns",         shortName = "MC",   timeLimit = 2100, numBosses = 3, expansion = "Midnight" },
        { id = 559, name = "Nexus-Point Xenas",       shortName = "NPX",  timeLimit = 1920, numBosses = 3, expansion = "Midnight" },
        { id = 557, name = "Windrunner Spire",        shortName = "WS",   timeLimit = 2040, numBosses = 4, expansion = "Midnight" },
        -- Legacy Dungeons
        { id = 402, name = "Algeth'ar Academy",       shortName = "AA",   timeLimit = 1800, numBosses = 4, expansion = "Dragonflight" },
        { id = 556, name = "Pit of Saron",            shortName = "PoS",  timeLimit = 1860, numBosses = 3, expansion = "WotLK" },
        { id = 239, name = "Seat of the Triumvirate", shortName = "SotT", timeLimit = 1740, numBosses = 4, expansion = "Legion" },
        { id = 161, name = "Skyreach",                shortName = "SR",   timeLimit = 1680, numBosses = 4, expansion = "WoD" },
    },

    -- Midnight Season 2, live Aug 18 2026 (Blizzard news post "The Shadows
    -- Deepen: Midnight Season 2 Begins August 18"). IDs pulled from the live
    -- MapChallengeMode DB2 (wago.tools) and cross-checked against Season 1's
    -- known-good rows (Skyreach/Windrunner Spire matched exactly) — high
    -- confidence. timeLimit is the DB2's own value (not a secondary-source
    -- guess), but GetInfo() still prefers the live API when available.
    [2] = {
        { id = 588, name = "Altar of Fangs",      shortName = "AoF", timeLimit = 1800, numBosses = 3, expansion = "Midnight" },
        { id = 587, name = "Murder Row",          shortName = "MR",  timeLimit = 2040, numBosses = 4, expansion = "Midnight" },
        { id = 586, name = "Den of Nalorakk",     shortName = "DoN", timeLimit = 1920, numBosses = 3, expansion = "Midnight" },
        { id = 584, name = "The Blinding Vale",   shortName = "BV",  timeLimit = 1800, numBosses = 4, expansion = "Midnight" },
        { id = 585, name = "Voidscar Arena",      shortName = "VA",  timeLimit = 1800, numBosses = 3, expansion = "Midnight" },
        { id = 249, name = "Kings' Rest",         shortName = "KR",  timeLimit = 1980, numBosses = 5, expansion = "Battle for Azeroth" },
        { id = 250, name = "Temple of Sethraliss",shortName = "ToS", timeLimit = 1920, numBosses = 3, expansion = "Battle for Azeroth" },
        { id = 399, name = "Ruby Life Pools",     shortName = "RLP", timeLimit = 1680, numBosses = 3, expansion = "Dragonflight" },
    },
}

--- Flattened pool across every season filled in above. A dungeon's
--- ChallengeMapID never changes, so merging seasons (instead of gating on
--- CURRENT_SEASON) means a new season's data just adds to the lookup —
--- no runtime switch to flip when a season goes live.
MP.DungeonData.Dungeons = {}
MP.DungeonData.ByMapID = {}
for _, season in pairs(MP.DungeonData.Seasons) do
    for _, dungeon in ipairs(season) do
        table.insert(MP.DungeonData.Dungeons, dungeon)
        MP.DungeonData.ByMapID[dungeon.id] = dungeon
    end
end

----------------------------------------------------------------------
-- Affix Definitions
----------------------------------------------------------------------
MP.AffixData.Affixes = {
    -- Seasonal affixes
    { id = 160, name = "Lindormi's Guidance",  icon = "Interface\\Icons\\ability_monk_renewingmists",  minLevel = 2,  maxLevel = 5  },
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

--- Read name + time limit from the live Blizzard API (works on any season's
--- dungeons). Returns name, timeLimit (either may be nil/0 when unavailable).
local function ApiMapInfo(mapID)
    if mapID and C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
        return name, timeLimit
    end
    return nil, nil
end

--- Merged, always-populated dungeon info for ANY mapID — including dungeons not
--- in the hardcoded pool (e.g. a new season). Prefers the live API for
--- name/time limit, using the hardcoded table only to enrich (short codes,
--- expansion). This is the single resolver all consumers should use.
function MP.DungeonData:GetInfo(mapID)
    local d = self.ByMapID[mapID]
    local apiName, apiTimeLimit = ApiMapInfo(mapID)
    return {
        id        = mapID,
        name      = apiName or (d and d.name),
        shortName = (d and d.shortName) or apiName,   -- full name if no short code
        timeLimit = apiTimeLimit or (d and d.timeLimit) or 0,
        numBosses = (d and d.numBosses) or 0,
        expansion = d and d.expansion,
    }
end

function MP.DungeonData:GetShortName(mapID)
    local d = self.ByMapID[mapID]
    if d and d.shortName then return d.shortName end
    return (ApiMapInfo(mapID))   -- live name, or nil
end

function MP.DungeonData:GetTimeLimit(mapID)
    local _, apiTimeLimit = ApiMapInfo(mapID)
    if apiTimeLimit then return apiTimeLimit end
    local d = self.ByMapID[mapID]
    return (d and d.timeLimit) or 0
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
