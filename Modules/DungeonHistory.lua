--[[
    MythicPulse - Dungeon History Module
    Stores and displays completed run history with personal bests.
]]

local _, MP = ...

local DungeonHistory = {
    registeredEvents = {},
}

----------------------------------------------------------------------
-- Record a completed run
----------------------------------------------------------------------
function DungeonHistory:RecordRun(runData)
    if not MP:IsModuleEnabled("dungeonHistory") then return end
    if not MP.db or not MP.db.history then return end
    if not runData.mapID or runData.mapID <= 0 then return end
    if not runData.keyLevel or runData.keyLevel <= 0 then return end
    if not runData.elapsed or runData.elapsed <= 0 then return end

    table.insert(MP.db.history, 1, runData)  -- newest first

    -- Trim to max entries
    local max = MP.db.modules.dungeonHistory.maxEntries or 200
    while #MP.db.history > max do
        table.remove(MP.db.history)
    end

    MP:Debug("Run recorded:", runData.mapID, "+", runData.keyLevel,
        runData.timed and "(Timed)" or "(Depleted)")
end

----------------------------------------------------------------------
-- Get personal best for a dungeon at a given key level
----------------------------------------------------------------------
function DungeonHistory:GetPersonalBest(mapID, keyLevel)
    if not MP:IsModuleEnabled("dungeonHistory") then return nil end
    if not MP.db or not MP.db.history then return nil end

    local best = nil
    for _, run in ipairs(MP.db.history) do
        if run.mapID == mapID and run.keyLevel == keyLevel and run.timed then
            if not best or run.elapsed < best.elapsed then
                best = run
            end
        end
    end
    return best
end

----------------------------------------------------------------------
-- Get all runs for a specific dungeon
----------------------------------------------------------------------
function DungeonHistory:GetRunsForDungeon(mapID)
    if not MP.db or not MP.db.history then return {} end

    local runs = {}
    for _, run in ipairs(MP.db.history) do
        if run.mapID == mapID then
            table.insert(runs, run)
        end
    end
    return runs
end

----------------------------------------------------------------------
-- Get summary statistics
----------------------------------------------------------------------
function DungeonHistory:GetStats()
    if not MP.db or not MP.db.history then
        return { total = 0, timed = 0, depleted = 0, timedPct = 0 }
    end

    local total   = #MP.db.history
    local timed   = 0
    local depleted = 0

    for _, run in ipairs(MP.db.history) do
        if run.timed then
            timed = timed + 1
        else
            depleted = depleted + 1
        end
    end

    return {
        total    = total,
        timed    = timed,
        depleted = depleted,
        timedPct = total > 0 and (timed / total * 100) or 0,
    }
end

----------------------------------------------------------------------
-- Get highest completed key per dungeon
----------------------------------------------------------------------
function DungeonHistory:GetHighestKeys()
    if not MP.db or not MP.db.history then return {} end

    local highest = {}
    for _, run in ipairs(MP.db.history) do
        if run.timed and (run.elapsed or 0) > 0 then
            local key = run.mapID
            if not highest[key] or run.keyLevel > highest[key].keyLevel then
                highest[key] = run
            end
        end
    end
    return highest
end

----------------------------------------------------------------------
-- Show summary in chat
----------------------------------------------------------------------
function DungeonHistory:ShowSummary()
    local stats = self:GetStats()

    MP:Print("|cff00ccff=== Run History ===|r")

    if stats.total == 0 then
        MP:Print(MP.L["HISTORY_EMPTY"])
        return
    end

    MP:Print(string.format("Total Runs: |cffffffff%d|r", stats.total))
    MP:Print(string.format("Timed: |cff4dff4d%d|r (%.0f%%)", stats.timed, stats.timedPct))
    MP:Print(string.format("Depleted: |cffff4444%d|r", stats.depleted))

    -- Show highest keys per dungeon
    local highest = self:GetHighestKeys()
    if next(highest) then
        MP:Print("|cff00ccff--- Highest Timed Keys ---|r")
        for mapID, run in pairs(highest) do
            local dungeonInfo = MP.DungeonData and MP.DungeonData:GetByMapID(mapID)
            local dName = dungeonInfo and dungeonInfo.shortName
            if not dName then
                local apiName = C_ChallengeMode.GetMapUIInfo(mapID)
                dName = apiName or ("Map " .. tostring(mapID))
            end
            MP:Print(string.format("  %s: |cffffffff+%d|r (%s)",
                dName, run.keyLevel, MP:FormatTime(run.elapsed)))
        end
    end

    -- Show last 5 runs
    MP:Print("|cff00ccff--- Recent Runs ---|r")
    local shown = 0
    for i = 1, #MP.db.history do
        if shown >= 5 then break end
        local run = MP.db.history[i]
        if run.mapID and run.mapID > 0 and (run.keyLevel or 0) > 0 and (run.elapsed or 0) > 0 then
            local dungeonInfo = MP.DungeonData:GetByMapID(run.mapID)
            local dName = dungeonInfo and dungeonInfo.shortName
            if not dName then
                local apiName = C_ChallengeMode.GetMapUIInfo(run.mapID)
                dName = apiName or ("Map " .. run.mapID)
            end
            local status = run.timed and "|cff4dff4dTimed|r" or "|cffff4444Depleted|r"
            MP:Print(string.format("  %s +%d — %s — %s (%s)",
                dName, run.keyLevel, MP:FormatTime(run.elapsed),
                status, run.date or "?"))
            shown = shown + 1
        end
    end
    if shown == 0 then
        MP:Print("|cff666666No valid runs recorded yet.|r")
    end
end

----------------------------------------------------------------------
-- Prune invalid entries that slipped in before validation guards existed.
-- Called once on load so stale SavedVariables data doesn't pollute displays.
----------------------------------------------------------------------
local function PruneHistory()
    if not MP.db or not MP.db.history then return end
    local pruned = {}
    for _, run in ipairs(MP.db.history) do
        if (run.mapID  and run.mapID  > 0)
        and (run.keyLevel and run.keyLevel > 0)
        and (run.elapsed  and run.elapsed  > 0) then
            table.insert(pruned, run)
        end
    end
    local removed = #MP.db.history - #pruned
    MP.db.history = pruned
    if removed > 0 then
        MP:Debug("DungeonHistory: pruned", removed, "invalid entries from SavedVariables")
    end
end

----------------------------------------------------------------------
-- Module Callbacks
----------------------------------------------------------------------
function DungeonHistory:OnFrameReady()
    -- History doesn't need a persistent UI section on the HUD
    -- It's accessed via /mp history and the config panel.
    -- Prune any junk entries that existed before validation guards were added.
    PruneHistory()
end

function DungeonHistory:OnSave()
    -- Data is already in SavedVariables via MP.db.history
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("DungeonHistory", DungeonHistory)
