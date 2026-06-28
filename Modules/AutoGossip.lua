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
-- returns a tainted secret value.  UnitName("npc") is also tainted and
-- cannot be used as a table key — instead we iterate this table and
-- compare with ==, which returns a regular boolean even for secret strings.
--
-- Format: ["NPC Name"] = { option = N | "first", note = "..." }
-- option = "first" → select the first gossip option offered (safe default)
--
-- HOW TO DISCOVER NEW NPCs: Run the dungeon in NORMAL (non-M+) mode with
-- DEBUG_GOSSIP_NAMES = true below.  The addon will print each gossip NPC
-- name to chat so you can add it here.  Names found in normal mode are
-- identical in M+ — they just become tainted secret strings there.
----------------------------------------------------------------------

-- Set true to print gossip NPC names to chat (only works outside M+).
local DEBUG_GOSSIP_NAMES = false

local AUTO_GOSSIP = {
    -- -----------------------------------------------------------------------
    -- Pit of Saron (556) — WotLK remixed
    -- Escort leader at dungeon entrance; gossip to begin the assault.
    -- One NPC appears depending on server/phase: add both to be safe.
    -- -----------------------------------------------------------------------
    ["Lady Sylvanas Windrunner"] = { option = "first", note = "PoS: begin assault (Horde)" },
    ["Jaina Proudmoore"]         = { option = "first", note = "PoS: begin assault (Alliance)" },

    -- -----------------------------------------------------------------------
    -- Seat of the Triumvirate (239) — Legion
    -- Alleria Windrunner accompanies the party and has a dialog prompt
    -- before the void-corruption sequence near the third boss.
    -- -----------------------------------------------------------------------
    ["Alleria Windrunner"] = { option = "first", note = "SotT: void introduction" },

    -- -----------------------------------------------------------------------
    -- Algeth'ar Academy (402) — Dragonflight
    -- Verify the exact NPC name in normal mode with DEBUG_GOSSIP_NAMES = true.
    -- -----------------------------------------------------------------------
    -- ["<NPC Name>"] = { option = "first", note = "AA: <description>" },

    -- -----------------------------------------------------------------------
    -- Skyreach (161) — WoD
    -- Verify the exact NPC name in normal mode with DEBUG_GOSSIP_NAMES = true.
    -- -----------------------------------------------------------------------
    -- ["<NPC Name>"] = { option = "first", note = "SR: <description>" },

    -- -----------------------------------------------------------------------
    -- Windrunner Spire (557) — Midnight
    -- Verify the exact NPC name in normal mode with DEBUG_GOSSIP_NAMES = true.
    -- -----------------------------------------------------------------------
    -- ["<NPC Name>"] = { option = "first", note = "WS: <description>" },

    -- -----------------------------------------------------------------------
    -- Magisters' Terrace (558) — Midnight
    -- Verify the exact NPC name in normal mode with DEBUG_GOSSIP_NAMES = true.
    -- -----------------------------------------------------------------------
    -- ["<NPC Name>"] = { option = "first", note = "MT: <description>" },

    -- -----------------------------------------------------------------------
    -- Nexus-Point Xenas (559) — Midnight
    -- Verify the exact NPC name in normal mode with DEBUG_GOSSIP_NAMES = true.
    -- -----------------------------------------------------------------------
    -- ["<NPC Name>"] = { option = "first", note = "NPX: <description>" },

    -- -----------------------------------------------------------------------
    -- Maisara Caverns (560) — Midnight
    -- Verify the exact NPC name in normal mode with DEBUG_GOSSIP_NAMES = true.
    -- -----------------------------------------------------------------------
    -- ["<NPC Name>"] = { option = "first", note = "MC: <description>" },

    -- =======================================================================
    -- SEASON 2 — add gating-NPC entries here once the dungeon pool is known.
    -- Capture exact names in-game with DEBUG_GOSSIP_NAMES = true. See
    -- Docs/SEASON_UPDATE.md. Entries are keyed by NPC display name, e.g.:
    --   ["<NPC Name>"] = { option = "first", note = "<dungeon>: <description>" },
    -- =======================================================================
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

    -- UnitName("npc") returns a tainted string in Midnight 12.x. Direct == throws
    -- "secret string value" even against a literal. Use SafeStringEquals (pcall).
    local npcName = UnitName("npc")
    if not npcName then return end

    -- Debug helper: outside M+ the name is a normal string, safe to print.
    if DEBUG_GOSSIP_NAMES and not MP:IsInMythicPlus() then
        local ok, safeName = pcall(tostring, npcName)
        if ok and safeName then
            MP:Print("|cffff9f00AutoGossip debug:|r GOSSIP_SHOW from NPC: '" .. safeName .. "'")
        end
    end

    local rule
    for knownName, entry in pairs(AUTO_GOSSIP) do
        if MP:SafeStringEquals(npcName, knownName) then
            rule = entry
            break
        end
    end
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

    -- Safety: don't complete quests via auto-gossip.
    -- QuestLabelPrepend flag (0x10) marks quest turn-in options; use the named enum
    -- if available so the code stays correct if Blizzard renumbers the flag.
    local QUEST_FLAG = (Enum.GossipOptionRecFlags and Enum.GossipOptionRecFlags.QuestLabelPrepend) or 0x10
    if target.flags and bit.band(target.flags, QUEST_FLAG) ~= 0 then
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
