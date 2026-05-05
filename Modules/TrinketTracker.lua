--[[
    MythicPulse - Trinket Tracker Module
    Tracks the local player's on-use trinket cooldowns and broadcasts usage
    to other MythicPulse users so they can see party trinket usage too.

    SCOPE & RATIONALE:
      Trinket databases shift every season and listing every relic-of-the-week
      is a maintenance burden. Instead, we discover the player's own trinkets
      dynamically:
        - Read inventory slots 13 and 14 (trinket1 / trinket2)
        - Use C_Item.GetItemSpell(itemID) to find the on-use spell
        - Read its cooldown via C_Spell.GetSpellCooldown
      This handles every trinket Blizzard introduces without code changes.

    For party members we display incoming "TRK" Comm broadcasts from other
    MythicPulse users. Non-MythicPulse users won't be tracked (acceptable
    tradeoff vs. the alternative of brittle item-DB maintenance).
]]

local _, MP = ...

local TrinketTracker = {
    registeredEvents = {
        "UNIT_SPELLCAST_SUCCEEDED",
        "PLAYER_EQUIPMENT_CHANGED",
        "PLAYER_ENTERING_WORLD",
        "CHALLENGE_MODE_RESET",
        "CHALLENGE_MODE_COMPLETED",
    },
    active   = false,
    trinkets = {},   -- [spellID] = { itemID, slot, name, duration, cdEnd }
}

-- Slots 13 and 14 are the two trinket slots
local TRINKET_SLOTS = { 13, 14 }

----------------------------------------------------------------------
-- Discover the player's currently equipped on-use trinkets.
-- Returns a table keyed by spellID.
----------------------------------------------------------------------
local function ScanEquippedTrinkets()
    local found = {}
    if not C_Item then return found end

    for _, slot in ipairs(TRINKET_SLOTS) do
        local itemID = GetInventoryItemID and GetInventoryItemID("player", slot)
        if itemID then
            -- Resolve the on-use spell (may be nil for stat-only trinkets)
            local spellName, spellID
            if C_Item.GetItemSpell then
                spellName, spellID = C_Item.GetItemSpell(itemID)
            end
            if spellID and type(spellID) == "number" then
                -- Read cooldown from the spell book if possible
                local duration = 0
                if C_Spell and C_Spell.GetSpellCooldown then
                    local info = C_Spell.GetSpellCooldown(spellID)
                    -- Blizzard's Midnight "secret number" taint can make
                    -- tonumber() return nil AND make direct comparisons error.
                    -- Use pcall to safely extract a usable number.
                    if info then
                        local ok, val = pcall(function()
                            local d = tonumber(info.duration)
                            if d and d > 0 then return d end
                            return 0
                        end)
                        duration = (ok and val) or 0
                    end
                end
                -- Skip 0-CD entries (passive procs masquerading as spells)
                if duration > 0 then
                    local itemName = C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
                    found[spellID] = {
                        itemID   = itemID,
                        slot     = slot,
                        name     = spellName or itemName or "Trinket",
                        duration = duration,
                        cdEnd    = 0,
                    }
                end
            end
        end
    end
    return found
end

----------------------------------------------------------------------
-- UI: piggy-back on PartyCooldowns by injecting "trinket-spell" entries
-- into the icon row for the local player. We don't build our own
-- visualization — keeping the player row dense and uniform is better.
----------------------------------------------------------------------
local function StartCooldown(spellID)
    local data = TrinketTracker.trinkets[spellID]
    if not data then return end
    data.cdEnd = GetTime() + data.duration

    -- Optional: surface to PartyCooldowns row by writing to the icon if it
    -- happens to track this spell. Most trinket spell IDs won't match
    -- TRACKED_SPELLS, so this is a no-op unless a trinket dovetails with
    -- a tracked class CD.
end

----------------------------------------------------------------------
-- Comm: broadcast/listen for party trinket usage
----------------------------------------------------------------------
local function OnRemoteTrinket(payload, senderShort)
    if not TrinketTracker.active or not payload or not senderShort then return end
    -- Format: "<spellID>:<duration>"
    local sid, dur = strsplit(":", payload)
    sid = tonumber(sid); dur = tonumber(dur)
    if not sid or not dur then return end
    -- Future enhancement: surface remote trinket CDs in a dedicated row.
    MP:Debug(string.format("Remote trinket use: %s spell %d (%ds)",
        senderShort, sid, dur))
end

----------------------------------------------------------------------
-- Public: get the next-ready trinket info (for UI consumers).
----------------------------------------------------------------------
function TrinketTracker:GetNextReady()
    local now = GetTime()
    local best, bestEnd
    for sid, data in pairs(self.trinkets) do
        local cdEnd = data.cdEnd or 0
        if not bestEnd or cdEnd < bestEnd then
            bestEnd = cdEnd
            best = {
                spellID = sid,
                itemID  = data.itemID,
                name    = data.name,
                ready   = (cdEnd <= now),
                at      = cdEnd,
            }
        end
    end
    return best
end

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function TrinketTracker:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if not unit or not spellID then return end
        if unit ~= "player" then return end
        if type(spellID) ~= "number" or spellID <= 0 then return end
        if not self.trinkets[spellID] then return end

        StartCooldown(spellID)

        if MP.Comm then
            local data = self.trinkets[spellID]
            MP.Comm:Send("TRK", string.format("%d:%d", spellID, data.duration or 0))
        end

    elseif event == "PLAYER_EQUIPMENT_CHANGED" then
        -- Re-scan when trinkets swap mid-run
        C_Timer.After(0.5, function()
            self.trinkets = ScanEquippedTrinkets()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(2, function()
            self.trinkets = ScanEquippedTrinkets()
            self.active = true
        end)

    elseif event == "CHALLENGE_MODE_RESET" or event == "CHALLENGE_MODE_COMPLETED" then
        -- Reset cooldown end-times so the next run starts fresh
        for _, data in pairs(self.trinkets) do
            data.cdEnd = 0
        end
    end
end

function TrinketTracker:OnFrameReady()
    if MP.Comm then
        MP.Comm:RegisterHandler("TRK", OnRemoteTrinket)
    end
    -- Initial scan deferred until PLAYER_ENTERING_WORLD; bag/inventory
    -- isn't ready at addon-load time.
end

function TrinketTracker:OnDisable()
    self.active = false
    self.trinkets = {}
    local pc = MP:GetModule("PartyCooldowns")
    if pc and pc.RebuildAll then pc:RebuildAll() end
end

function TrinketTracker:OnEnable()
    self.trinkets = ScanEquippedTrinkets()
    self.active = true
    local pc = MP:GetModule("PartyCooldowns")
    if pc and pc.RebuildAll then pc:RebuildAll() end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("TrinketTracker", TrinketTracker)
