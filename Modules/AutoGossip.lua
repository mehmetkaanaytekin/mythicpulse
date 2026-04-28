--[[
    MythicPulse - Auto Gossip Module
    Automatically advances dialog at known dungeon-gating NPCs so players
    don't waste time clicking through pre-fight scripts in M+.

    SAFETY:
      - Only runs while inside a Mythic+ instance
      - Only fires for known NPC IDs in the AUTO_GOSSIP table
      - Skips when option appears to be a quest turn-in (avoid accidentally
        completing a quest)
      - Can be disabled via config: modules.autoGossip.enabled
]]

local _, MP = ...

local AutoGossip = {
    registeredEvents = {
        "GOSSIP_SHOW",
    },
}

----------------------------------------------------------------------
-- Auto-Gossip Database
-- Keyed by NPC display name (as returned by UnitName("npc")).
--
-- WHY NAMES NOT IDs: In Midnight 12.0.5 M+ instances, UnitGUID("npc")
-- returns a tainted secret value.  Extracting the NPC ID from that GUID
-- via strsplit throws "attempt to perform string conversion on a secret
-- string value".  UnitName is never tainted, so we key this table on the
-- NPC's English display name instead.
--
-- LOCALIZATION NOTE: This matches the client's locale.  Non-enUS clients
-- will not auto-gossip for most entries here until the table is extended
-- with localised names.  This is acceptable — it's a convenience feature.
--
-- Format: ["NPC Name"] = { option = N | "first", note = "..." }
-- option = "first" → select the first gossip option offered (safe default)
----------------------------------------------------------------------
local AUTO_GOSSIP = {
    -- Halls of Valor: Odyn
    ["Odyn"]                 = { option = "first", note = "Halls of Valor" },

    -- Court of Stars: Talixae (skip RP intro)
    ["Talixae Flamewreath"]  = { option = "first", note = "Court of Stars" },

    -- Operation: Mechagon
    ["Pascal-K1N6"]          = { option = "first", note = "Operation: Mechagon" },

    -- Mists of Tirna Scithe: maze guide
    ["Tirnenn Villager"]     = { option = "first", note = "Mists of Tirna Scithe" },

    -- Halls of Atonement
    ["Echelon's Lieutenant"] = { option = "first", note = "Halls of Atonement" },

    -- Theatre of Pain: ring NPCs
    ["Choofa"]               = { option = "first", note = "Theatre of Pain" },
    ["Mistress Dyrax"]       = { option = "first", note = "Theatre of Pain" },

    -- Plaguefall
    ["Globgrog"]             = { option = "first", note = "Plaguefall" },

    -- Tazavesh: Streets
    ["So'leah"]              = { option = "first", note = "Tazavesh" },
}

----------------------------------------------------------------------
-- Check if AutoGossip should run right now.
----------------------------------------------------------------------
local function ShouldRun()
    -- Module-enabled gate
    if MP.IsModuleEnabled and not MP:IsModuleEnabled("autoGossip") then
        return false
    end
    -- Only fire inside M+ to avoid stepping on solo / world content
    if not (MP.IsInMythicPlus and MP:IsInMythicPlus()) then
        return false
    end
    return true
end

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function AutoGossip:OnEvent(event)
    if event ~= "GOSSIP_SHOW" then return end
    if not ShouldRun() then return end
    if not C_GossipInfo or not C_GossipInfo.GetOptions or not C_GossipInfo.SelectOption then
        return
    end

    -- Identify NPC by display name.  UnitName never returns a tainted value,
    -- making this safe in Midnight 12.0.5 M+ instances (unlike UnitGUID).
    local npcName = UnitName("npc")
    if not npcName then return end

    local rule = AUTO_GOSSIP[npcName]
    if not rule then return end

    -- Get available gossip options
    local options = C_GossipInfo.GetOptions()
    if not options or #options == 0 then return end

    -- Decide which option to select
    local target
    if rule.option == "first" then
        target = options[1]
    elseif type(rule.option) == "number" then
        target = options[rule.option]
    end
    if not target then return end

    -- Safety: don't complete quests via auto-gossip
    if target.flags and bit.band(target.flags, 0x10) ~= 0 then
        MP:Debug("AutoGossip: skipping quest turn-in option for", rule.note)
        return
    end

    MP:Debug("AutoGossip:", rule.note, "→ selecting option:",
             target.name or tostring(target.gossipOptionID or "?"))
    C_GossipInfo.SelectOption(target.gossipOptionID)
end

function AutoGossip:OnFrameReady()
    -- Nothing to set up; pure event-driven module
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("AutoGossip", AutoGossip)
