--[[
    MythicPulse - Death Tracker Module
    Tracks deaths, maintains a death log, and displays time penalties.
    
    MIDNIGHT COMPLIANCE:
    - Does NOT use COMBAT_LOG_EVENT_UNFILTERED (restricted in 12.0)
    - Death count sourced from C_ChallengeMode.GetDeathCount() (whitelisted API)
    - Death log uses UNIT_FLAGS polling to detect party member deaths
    - Fallback: PLAYER_DEAD event for self-death detection
]]

local _, MP = ...

local DeathTracker = {
    registeredEvents = {
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_COMPLETED",
        "CHALLENGE_MODE_RESET",
        "PLAYER_DEAD",
        "UNIT_FLAGS",
        "UNIT_HEALTH",
    },
    count    = 0,
    deathLog = {},
    active   = false,
    lastKnownCount = 0,
    unitAliveState = {},
}

----------------------------------------------------------------------
-- UI — deaths shown in the MainFrame header, no standalone section
----------------------------------------------------------------------
local function UpdateDeathHeader()
    if not (MP.MainFrame and MP.MainFrame.SetDeathInfo) then return end
    local count = DeathTracker.count
    if count > 0 then
        local penalty, isPenalized = 0, false
        if MP.DungeonData then
            penalty     = MP.DungeonData:GetDeathPenalty(DeathTracker.keyLevel)
            isPenalized = MP.DungeonData:DeathsPenalized(DeathTracker.keyLevel)
        end
        local totalPenalty = (isPenalized and penalty > 0) and count * penalty or 0
        MP.MainFrame:SetDeathInfo(count, totalPenalty)
    else
        MP.MainFrame:SetDeathInfo(0, 0)
    end
end

----------------------------------------------------------------------
-- Update Display
----------------------------------------------------------------------
local function UpdateDisplay()
    local apiDeaths = C_ChallengeMode.GetDeathCount()
    if apiDeaths then DeathTracker.count = apiDeaths end
    UpdateDeathHeader()
end

----------------------------------------------------------------------
-- Death Detection via Unit Flags & Health Polling
-- (Midnight-compliant: no COMBAT_LOG_EVENT_UNFILTERED)
----------------------------------------------------------------------

--- Initialize alive state for all party members
local function InitAliveStates()
    DeathTracker.unitAliveState = {}
    local units = { "player", "party1", "party2", "party3", "party4" }
    for _, unit in ipairs(units) do
        if UnitExists(unit) then
            DeathTracker.unitAliveState[unit] = not UnitIsDeadOrGhost(unit)
        end
    end
end

--- Check if a party member transitioned from alive to dead
local function CheckUnitDeath(unit)
    if not DeathTracker.active then return end
    if not UnitExists(unit) then return end

    local wasAlive = DeathTracker.unitAliveState[unit]
    local isAlive  = not UnitIsDeadOrGhost(unit)

    DeathTracker.unitAliveState[unit] = isAlive

    -- Transition: alive -> dead
    if wasAlive and not isAlive then
        local name = UnitName(unit)
        local _, className = UnitClass(unit)

        local timer = MP:GetModule("Timer")
        local elapsed = timer and timer:GetElapsed() or 0

        table.insert(DeathTracker.deathLog, {
            name = name or "Unknown",
            classColoredName = MP:ClassColoredName(name or "Unknown", className),
            class   = className,
            elapsed = elapsed,
            time    = date("%H:%M:%S"),
        })

        MP:Debug(name, "died at", MP:FormatTime(elapsed))

        -- Sync with authoritative API after a short delay
        C_Timer.After(0.5, UpdateDisplay)
    end
end

----------------------------------------------------------------------
-- Periodic polling for death count sync
----------------------------------------------------------------------
local pollFrame = CreateFrame("Frame")
pollFrame:Hide()
local pollElapsed = 0

pollFrame:SetScript("OnUpdate", function(self, dt)
    pollElapsed = pollElapsed + dt
    if pollElapsed < 1.0 then return end  -- poll every 1 second
    pollElapsed = 0

    if not DeathTracker.active then
        self:Hide()
        return
    end

    -- Sync death count from API
    local apiDeaths = C_ChallengeMode.GetDeathCount()
    if apiDeaths and apiDeaths ~= DeathTracker.lastKnownCount then
        -- A new death occurred that we may have missed
        if apiDeaths > DeathTracker.lastKnownCount then
            -- If our log doesn't have enough entries, add an "Unknown" entry
            local loggedDeaths = #DeathTracker.deathLog
            local diff = apiDeaths - DeathTracker.lastKnownCount
            if diff > (loggedDeaths - (DeathTracker.lastKnownCount - (DeathTracker.count - loggedDeaths))) then
                -- We missed some deaths — the API is authoritative
                MP:Debug("Death count synced from API:", apiDeaths)
            end
        end
        DeathTracker.lastKnownCount = apiDeaths
        UpdateDisplay()
    end
end)

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function DeathTracker:OnEvent(event, ...)
    if event == "PLAYER_DEAD" then
        -- Self-death: always reliable
        if self.active then
            CheckUnitDeath("player")
        end

    elseif event == "UNIT_FLAGS" then
        -- Fires when a unit's flags change (including alive/dead state)
        local unit = ...
        if self.active and unit then
            -- Only process party units
            if unit == "player" or unit:match("^party%d$") then
                CheckUnitDeath(unit)
            end
        end

    elseif event == "UNIT_HEALTH" then
        -- Backup: detect death via health reaching 0 (use safe API)
        local unit = ...
        if self.active and unit then
            if unit == "player" or unit:match("^party%d$") then
                if UnitExists(unit) and UnitIsDeadOrGhost(unit) then
                    CheckUnitDeath(unit)
                end
            end
        end

    elseif event == "CHALLENGE_MODE_START" then
        self.active         = true
        self.count          = 0
        self.deathLog       = {}
        self.lastKnownCount = 0
        self.keyLevel       = MP:GetActiveKeyLevel()
        InitAliveStates()
        UpdateDisplay()
        pollFrame:Show()

    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        self.active = false
        pollFrame:Hide()
        -- Final sync with API
        UpdateDisplay()
    end
end

function DeathTracker:OnDisable()
    self.active = false
    pollFrame:Hide()
    if MP.MainFrame and MP.MainFrame.SetDeathInfo then
        MP.MainFrame:SetDeathInfo(0, 0)
    end
end

function DeathTracker:OnFrameReady()
    if MP:IsInMythicPlus() then
        self.active   = true
        self.keyLevel = MP:GetActiveKeyLevel()
        InitAliveStates()
        UpdateDisplay()
        pollFrame:Show()
    end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("DeathTracker", DeathTracker)
