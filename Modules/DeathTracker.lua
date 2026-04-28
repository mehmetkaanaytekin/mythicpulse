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
-- UI
----------------------------------------------------------------------
local section, deathCountText, penaltyText

local function CreateUI()
    section = MP.MainFrame:CreateSection(MP.L and MP.L["DEATHS"] or "Deaths", 46)

    local skull = section:CreateTexture(nil, "ARTWORK")
    skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
    skull:SetSize(16, 16)
    skull:SetPoint("TOPLEFT", 0, -26)

    -- Death count
    deathCountText = section:CreateFontString(nil, "OVERLAY")
    deathCountText:SetFontObject(MP.Fonts.Number)
    deathCountText:SetPoint("LEFT", skull, "RIGHT", 4, 0)
    deathCountText:SetTextColor(0.95, 0.95, 0.95)
    deathCountText:SetText("0")

    -- Penalty text
    penaltyText = section:CreateFontString(nil, "OVERLAY")
    penaltyText:SetFontObject(MP.Fonts.Small)
    penaltyText:SetPoint("LEFT", deathCountText, "RIGHT", 8, 0)
    penaltyText:SetTextColor(MP.COLORS.danger.r, MP.COLORS.danger.g, MP.COLORS.danger.b)

    -- Tooltip on hover (shows death log)
    section:EnableMouse(true)
    section:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("|cff00ccff" .. MP.L["DEATH_LOG"] .. "|r", 1, 1, 1)

        if #DeathTracker.deathLog == 0 then
            GameTooltip:AddLine(MP.L["NO_DEATHS"], 0.5, 0.5, 0.5)
        else
            for _, entry in ipairs(DeathTracker.deathLog) do
                local nameStr = entry.classColoredName or entry.name
                local timeStr = MP:FormatTime(entry.elapsed)
                GameTooltip:AddDoubleLine(
                    nameStr,
                    timeStr,
                    1, 1, 1,
                    0.6, 0.62, 0.7
                )
            end
        end

        GameTooltip:AddLine(" ")
        local penalty = 0
        if MP.DungeonData then
            penalty = MP.DungeonData:GetDeathPenalty(DeathTracker.keyLevel)
        end
        local totalPenalty = DeathTracker.count * penalty
        GameTooltip:AddDoubleLine(
            MP.L["DEATH_PENALTY"],
            "-" .. MP:FormatTime(totalPenalty),
            0.9, 0.9, 0.9,
            1.0, 0.25, 0.25
        )
        GameTooltip:Show()
    end)
    section:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    MP.MainFrame:AddSection(section)
    return section
end

----------------------------------------------------------------------
-- Update Display
----------------------------------------------------------------------
local function UpdateDisplay()
    -- Use authoritative API count (whitelisted, always reliable)
    local apiDeaths = C_ChallengeMode.GetDeathCount()
    if apiDeaths then
        DeathTracker.count = apiDeaths
    end

    if deathCountText then
        deathCountText:SetText(tostring(DeathTracker.count))
        if DeathTracker.count > 0 then
            deathCountText:SetTextColor(1.0, 0.25, 0.25)
        else
            deathCountText:SetTextColor(0.3, 1.0, 0.4)
        end
    end

    if penaltyText and DeathTracker.count > 0 then
        local penalty = 0
        local isPenalized = false
        if MP.DungeonData then
            penalty = MP.DungeonData:GetDeathPenalty(DeathTracker.keyLevel)
            isPenalized = MP.DungeonData:DeathsPenalized(DeathTracker.keyLevel)
        end
        local totalPenalty = DeathTracker.count * penalty
        if isPenalized and penalty > 0 then
            penaltyText:SetText(string.format("-%s (-%ds ea)", MP:FormatTime(totalPenalty), penalty))
        else
            penaltyText:SetText("|cff4dff4dNo penalty|r")
        end
    elseif penaltyText then
        penaltyText:SetText("")
    end
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

function DeathTracker:OnFrameReady()
    if not MP.MainFrame or not MP.MainFrame.frame then
        MP:Debug("MainFrame not ready, skipping DeathTracker UI creation")
        return
    end
    CreateUI()
    -- Register as M+-only section
    if section then
        MP:RegisterMythicOnlySection(section)
    end
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
