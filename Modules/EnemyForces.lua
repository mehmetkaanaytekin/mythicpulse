--[[
    MythicPulse - Enemy Forces Module
    Tracks trash mob progress via Scenario API with progress bar display.
    
    MIDNIGHT COMPLIANCE:
    - Does NOT use COMBAT_LOG_EVENT_UNFILTERED (restricted in 12.0)
    - Uses PLAYER_REGEN_DISABLED/ENABLED for combat state detection
    - Enemy forces progress from C_Scenario API (whitelisted)
]]

local _, MP = ...

local EnemyForces = {
    registeredEvents = {
        "SCENARIO_CRITERIA_UPDATE",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_COMPLETED",
        "CHALLENGE_MODE_RESET",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
    },
    active    = false,
    current   = 0,
    total     = 0,
    pullCount = 0,
    pullStart = 0,
    inCombat  = false,
}

----------------------------------------------------------------------
-- UI — bar lives inside Timer.forcesContainer (no standalone section)
----------------------------------------------------------------------
local progressBar

--- Called by Timer.lua (or by our own OnFrameReady if Timer ran first).
function EnemyForces:CreateBarInContainer(container)
    if progressBar then return end  -- already created
    progressBar = MP.ProgressBarWidget:Create(container, 244, 24, "MythicPulseEnemyForcesBar")
    progressBar:SetPoint("TOPLEFT",  container, "TOPLEFT",  0, 0)
    progressBar:SetPoint("TOPRIGHT", container, "TOPRIGHT", 0, 0)
end

----------------------------------------------------------------------
-- Shared UI update — called from both the live path and demo path.
-- current/total are plain numbers; all display logic lives here.
----------------------------------------------------------------------
local function ApplyForceDisplay(current, total)
    if not progressBar then return end

    -- Sanitize tainted "secret number" values from Blizzard APIs
    current = tonumber(current) or 0
    total   = tonumber(total) or 0

    if total <= 0 then
        progressBar:SetProgress(0)
        if progressBar.text     then progressBar.text:SetText("") end
        if progressBar.leftText then progressBar.leftText:SetText("") end
        return
    end

    local pct = current / total

    -- Bar fill (animate toward updates so frequent force gains feel continuous)
    if progressBar.SetProgressAnimated then
        progressBar:SetProgressAnimated(pct, 0.16)
    else
        progressBar:SetProgress(pct)
    end
    if progressBar.spark then progressBar.spark:SetShown(pct > 0 and pct < 0.95) end

    if progressBar.leftText then progressBar.leftText:SetText("") end
    if progressBar.rightText then progressBar.rightText:SetText("") end

    if current >= total then
        if progressBar.text then
            progressBar.text:SetText("|cff4dff4dComplete!|r")
        end
        progressBar:SetStatusBarColor(0.3, 1.0, 0.4, 1.0)
        progressBar:SetPaceMarker(nil)
    else
        -- Prominent percentage in bar center (matches Blizzard style)
        if progressBar.text then
            progressBar.text:SetText(string.format("%.1f%%", pct * 100))
            progressBar.text:SetTextColor(1, 1, 1)
        end

        -- Color bar by projected pace (not raw %)
        local timer = MP:GetModule("Timer")
        local el    = timer and timer.GetElapsed   and timer:GetElapsed()   or 0
        local limit = timer and timer.GetTimeLimit and timer:GetTimeLimit() or 0
        el    = tonumber(el) or 0
        limit = tonumber(limit) or 0
        if el > 5 and current > 0 and limit > 0 then
            local projPct = (current / el) * limit / total
            if projPct >= 1.05 then
                progressBar:SetStatusBarColor(0.3, 1.0, 0.4, 1.0)   -- green: ahead
            elseif projPct >= 0.90 then
                progressBar:SetStatusBarColor(0.0, 0.8, 1.0, 1.0)   -- blue: on pace
            elseif projPct >= 0.70 then
                progressBar:SetStatusBarColor(1.0, 0.65, 0.1, 1.0)  -- orange: behind
            else
                progressBar:SetStatusBarColor(1.0, 0.2, 0.2, 1.0)   -- red: well behind
            end
        else
            progressBar:SetStatusBarColor(0.0, 0.8, 1.0, 1.0)
        end
    end

    -- Pace marker (where we'd be if forces scaled linearly with time)
    local timer = MP:GetModule("Timer")
    if timer and timer.GetTimeLimit and timer.GetElapsed then
        local limit = timer:GetTimeLimit() or 0
        local el    = timer:GetElapsed()    or 0
        if limit > 0 and el > 0 and current < total then
            progressBar:SetPaceMarker(math.min(el / limit, 1))
        else
            progressBar:SetPaceMarker(nil)
        end
    end

end

----------------------------------------------------------------------
-- API compatibility: Midnight uses C_ScenarioInfo.GetCriteriaInfo,
-- older builds use C_Scenario.GetCriteriaInfo.  Resolve once.
----------------------------------------------------------------------
local function GetCriteriaInfoCompat(index)
    if C_ScenarioInfo and C_ScenarioInfo.GetCriteriaInfo then
        return C_ScenarioInfo.GetCriteriaInfo(index)
    elseif C_Scenario and C_Scenario.GetCriteriaInfo then
        return C_Scenario.GetCriteriaInfo(index)
    end
    return nil
end

--- GetStepInfo returns (title, desc, numCriteria) as multiple values
--- in the old API, or a table in the new API.  Normalize to numCriteria.
local function GetNumCriteria()
    local a, b, c
    if C_Scenario and C_Scenario.GetStepInfo then
        a, b, c = C_Scenario.GetStepInfo()
    end
    -- Old API: 3rd return is numCriteria (number)
    if type(c) == "number" and c > 0 then return c end
    -- New API or table return
    if type(a) == "table" then
        return a.numCriteria or 0
    end
    return 0
end

----------------------------------------------------------------------
-- Locate the enemy-forces criterion index with a 3-pass strategy.
----------------------------------------------------------------------
local function FindForcesIndex(numCriteria)
    -- Pass 1: explicit isWeightedProgress flag (most reliable when present)
    for i = 1, numCriteria do
        local info = GetCriteriaInfoCompat(i)
        if info and info.isWeightedProgress then return i end
    end

    -- Pass 2: totalQuantity clearly > 1.
    -- Boss criteria always have totalQuantity == 1; forces totals are large (e.g. 100, 250).
    local bestIdx, bestTotal = nil, 1   -- threshold: must beat 1
    for i = 1, numCriteria do
        local info = GetCriteriaInfoCompat(i)
        local tq = info and tonumber(info.totalQuantity) or 0
        if tq > bestTotal then
            bestTotal = tq
            bestIdx   = i
        end
    end
    if bestIdx then return bestIdx end

    -- Pass 3: non-completed criterion with the highest accumulated progress.
    -- Forces count up continuously; un-killed bosses sit at 0 until killed.
    local bestQIdx, bestQ = nil, 0
    for i = 1, numCriteria do
        local info = GetCriteriaInfoCompat(i)
        local q = info and tonumber(info.quantity) or 0
        if info and not info.completed and q > bestQ then
            bestQ    = q
            bestQIdx = i
        end
    end
    return bestQIdx
end

----------------------------------------------------------------------
-- Query Scenario API for enemy forces (live M+ path)
----------------------------------------------------------------------
local _efDiagDone = false
local _forcesRetryPending = false
local _cachedForcesIndex = nil
local UpdateEnemyForces

local function SafeGet(t, k)
    local ok, v = pcall(function() return t[k] end)
    return ok and v
end

local function DiagnoseDump()
    if _efDiagDone then return end
    _efDiagDone = true

    MP:Debug("EnemyForces DiagnoseDump running...")

    -- Dump criteria info using the compat function
    local numCriteria = GetNumCriteria()
    MP:Debug("EnemyForces numCriteria=" .. tostring(numCriteria))

    local CRIT_FIELDS = {
        "quantity","totalQuantity","quantityString",
        "completed","isWeightedProgress","description",
    }
    for i = 1, math.max(numCriteria, 8) do
        local info = GetCriteriaInfoCompat(i)
        if info then
            local cp = {}
            for _, k in ipairs(CRIT_FIELDS) do
                local v = SafeGet(info, k)
                if v ~= nil then cp[#cp+1] = k.."="..tostring(v) end
            end
            if #cp > 0 then
                MP:Debug("EnemyForces crit["..i.."] " .. table.concat(cp, "  "))
            end
        end
    end

    -- Check which API is available
    MP:Debug("EnemyForces C_ScenarioInfo=" .. tostring(C_ScenarioInfo ~= nil)
        .. " C_Scenario=" .. tostring(C_Scenario ~= nil))
end

----------------------------------------------------------------------
-- Read forces from a single criterion index.
-- Follows MythicPlusTimer's approach:
--   1. If quantityString exists, parse it for the raw count
--   2. If isWeightedProgress, quantity is already percentage (0-100)
--   3. Otherwise use quantity / totalQuantity
----------------------------------------------------------------------
local function GetCriteriaForces()
    local numCriteria = GetNumCriteria()
    if numCriteria <= 0 then return nil, nil end

    local function readIndex(idx)
        if not idx then return nil, nil end
        local info = GetCriteriaInfoCompat(idx)
        if not info then return nil, nil end

        local finalValue = tonumber(info.totalQuantity) or 0
        if finalValue <= 0 then return nil, nil end

        local curValue
        local isPercent = info.isWeightedProgress

        -- MythicPlusTimer approach: if quantityString exists, parse the
        -- raw number from it (strip trailing "%").  This gives us the
        -- actual count rather than a percentage.
        if isPercent and info.quantityString then
            local qs = tostring(info.quantityString)
            -- Strip trailing "%" if present
            local raw = qs:match("^(.-)%%?$")
            curValue = tonumber(raw)
            if curValue then
                -- quantityString had the real count — treat as raw, not percent
                isPercent = false
            end
        end

        -- Fallback: use quantity directly
        if not curValue then
            curValue = tonumber(info.quantity) or 0
        end

        -- Normalize to fraction (0..1):
        if isPercent then
            -- quantity IS the percentage (0-100), total doesn't matter
            return curValue, 100
        else
            -- raw count / raw total
            return curValue, finalValue
        end
    end

    local current, total = readIndex(_cachedForcesIndex)
    if current and total then
        return current, total
    end

    _cachedForcesIndex = FindForcesIndex(numCriteria)
    return readIndex(_cachedForcesIndex)
end

local function QueueRetryUpdate()
    if _forcesRetryPending or not EnemyForces.active then return end
    _forcesRetryPending = true
    C_Timer.After(0.05, function()
        _forcesRetryPending = false
        if EnemyForces.active then
            UpdateEnemyForces()
        end
    end)
end

UpdateEnemyForces = function()
    if not EnemyForces.active then return end

    local current, total = GetCriteriaForces()

    -- Dump API state once so we can see what fields are available
    if (not current or (total or 0) <= 0) and MP:IsInMythicPlus() then
        MP:Debug("EnemyForces: no forces data yet, running diagnostics")
        DiagnoseDump()
    end

    if not current or (total or 0) <= 0 then
        QueueRetryUpdate()
        return
    end

    -- One-shot diagnostic: log the raw values so we can verify correctness
    if not EnemyForces._diagValues then
        EnemyForces._diagValues = true
        MP:Debug(string.format("EnemyForces data received: current=%.2f total=%.2f", current, total))
        DiagnoseDump()
    end

    -- Guard against out-of-order scenario updates causing a temporary rewind.
    if total == EnemyForces.total and current < EnemyForces.current then
        QueueRetryUpdate()
        return
    end

    -- Track pull contribution
    if current > EnemyForces.current then
        EnemyForces.pullCount = EnemyForces.pullCount + (current - EnemyForces.current)
    end
    EnemyForces.current = current
    EnemyForces.total   = total

    ApplyForceDisplay(current, total)
end

----------------------------------------------------------------------
-- Pace-marker ticker (updates once per second while the run is active)
----------------------------------------------------------------------
local paceTicker = CreateFrame("Frame")
paceTicker:Hide()
local paceElapsed = 0
paceTicker:SetScript("OnUpdate", function(self, dt)
    paceElapsed = paceElapsed + dt
    if paceElapsed < 1.0 then return end
    paceElapsed = 0

    if not EnemyForces.active or not progressBar then
        self:Hide()
        return
    end

    -- Poll forces every second as a safety net for missed SCENARIO_CRITERIA_UPDATE events
    UpdateEnemyForces()

    if EnemyForces.current >= EnemyForces.total and EnemyForces.total > 0 then
        progressBar:SetPaceMarker(nil)
        return
    end

    local timer = MP:GetModule("Timer")
    if not timer then return end
    local limit = timer:GetTimeLimit() or 0
    local el    = timer:GetElapsed() or 0
    if limit > 0 and el > 0 then
        progressBar:SetPaceMarker(math.min(el / limit, 1))
    end
end)

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function EnemyForces:OnEvent(event, ...)
    if event == "SCENARIO_CRITERIA_UPDATE" or event == "CRITERIA_UPDATE" then
        UpdateEnemyForces()

    elseif event == "CHALLENGE_MODE_START" then
        self.active      = true
        self.current     = 0
        self.total       = 0
        self.pullCount   = 0
        self.pullStart   = 0
        self.inCombat    = false
        self._diagValues = nil
        _cachedForcesIndex = nil
        _forcesRetryPending = false
        _efDiagDone = false
        paceTicker:Show()
        C_Timer.After(1, UpdateEnemyForces)

    elseif event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        self.active = false
        paceTicker:Hide()
        if progressBar then progressBar:SetPaceMarker(nil) end

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entered combat (Midnight-compliant alternative to CLEU)
        if self.active and not self.inCombat then
            self.inCombat  = true
            self.pullStart = self.current
            self.pullCount = 0
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Left combat
        if self.active and self.inCombat then
            self.inCombat = false
            -- Calculate what this pull contributed
            local gained = self.current - self.pullStart
            if gained > 0 then
                MP:Debug(string.format("Pull completed: +%d forces", gained))
            end
            C_Timer.After(3, function()
                if not self.inCombat then self.pullCount = 0 end
            end)
        end
    end
end

----------------------------------------------------------------------
-- Demo API: called by Demo.lua to show synthetic progress
----------------------------------------------------------------------
function EnemyForces:StartDemo(config)
    self.active    = true
    self.current   = config.current or 0
    self.total     = config.total   or 250
    self.pullCount = 0

    ApplyForceDisplay(self.current, self.total)
    paceTicker:Show()
end

function EnemyForces:UpdateDemo(current)
    if not self.active then return end
    self.current = math.min(current, self.total)
    ApplyForceDisplay(self.current, self.total)
end

function EnemyForces:StopDemo()
    self.active  = false
    self.current = 0
    self.total   = 0
    paceTicker:Hide()
    if progressBar then
        progressBar:SetProgress(0)
        if progressBar.text     then progressBar.text:SetText("") end
        if progressBar.leftText then progressBar.leftText:SetText("") end
    end
end

function EnemyForces:OnDisable()
    self.active = false
    paceTicker:Hide()
end

function EnemyForces:OnFrameReady()
    -- Bar creation is handled by Timer.lua calling CreateBarInContainer.
    -- If Timer ran first, the bar was already created.  If we ran first,
    -- Timer.CreateUI will call CreateBarInContainer after it finishes.
    local timerMod = MP:GetModule("Timer")
    if timerMod and timerMod.forcesContainer then
        self:CreateBarInContainer(timerMod.forcesContainer)
    end

    if MP:IsInMythicPlus() then
        self.active = true
        paceTicker:Show()
        UpdateEnemyForces()
    end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("EnemyForces", EnemyForces)
