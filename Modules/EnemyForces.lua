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
        "CRITERIA_UPDATE",
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
-- UI
----------------------------------------------------------------------
local section, progressBar, pullText

local function CreateUI()
    section = MP.MainFrame:CreateSection(MP.L["ENEMY_FORCES"], 68)

    -- Progress bar (height 20 for readable percentage text)
    progressBar = MP.ProgressBarWidget:Create(section, 244, 20, "MythicPulseEnemyForcesBar")
    progressBar:SetPoint("TOPLEFT", 0, -26)
    progressBar:SetPoint("RIGHT", section, "RIGHT", 0, 0)

    -- Pull count text (below bar)
    pullText = section:CreateFontString(nil, "OVERLAY")
    pullText:SetFontObject(MP.Fonts.Small)
    pullText:SetPoint("TOPLEFT", progressBar, "BOTTOMLEFT", 0, -4)
    pullText:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)

    MP.MainFrame:AddSection(section)
    return section
end

----------------------------------------------------------------------
-- Shared UI update — called from both the live path and demo path.
-- current/total are plain numbers; all display logic lives here.
----------------------------------------------------------------------
local function ApplyForceDisplay(current, total)
    if not progressBar then return end

    if total <= 0 then
        progressBar:SetProgress(0)
        progressBar.text:SetText("")
        if progressBar.leftText then progressBar.leftText:SetText("") end
        if pullText then pullText:SetText("") end
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

    -- Clear left/right text — percentage lives in the center only
    if progressBar.leftText  then progressBar.leftText:SetText("") end
    if progressBar.rightText then progressBar.rightText:SetText("") end

    if current >= total then
        progressBar.text:SetText("|cff4dff4dComplete!|r")
        progressBar:SetStatusBarColor(0.3, 1.0, 0.4, 1.0)
        progressBar:SetPaceMarker(nil)
    else
        -- Prominent percentage in bar center (matches Blizzard style)
        progressBar.text:SetText(string.format("%.1f%%", pct * 100))
        progressBar.text:SetTextColor(1, 1, 1)

        -- Color bar by projected pace (not raw %)
        local timer = MP:GetModule("Timer")
        local el    = timer and timer.GetElapsed   and timer:GetElapsed()   or 0
        local limit = timer and timer.GetTimeLimit and timer:GetTimeLimit() or 0
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

    -- Pull-info line below the bar (count + need + pace projection)
    if pullText then
        local parts = {}
        -- Always show current/total count (moved here from bar.leftText)
        table.insert(parts, string.format("|cffcccccc%d / %d|r", current, total))
        if EnemyForces.pullCount > 0 then
            table.insert(parts, string.format("|cffaaccff+%d pull|r", EnemyForces.pullCount))
        end
        local remaining = math.max(0, total - current)
        if remaining > 0 then
            table.insert(parts, string.format("|cff888888need %d|r", remaining))
        end
        -- ETA: linear extrapolation (only meaningful after 30s of data)
        if timer and timer.GetElapsed and timer.GetTimeLimit then
            local el    = timer:GetElapsed()    or 0
            local limit = timer:GetTimeLimit()  or 0
            if el > 30 and current > 0 and limit > 0 then
                local projected = (current / el) * limit
                local projPct   = projected / total
                local color = projPct >= 1.05 and "|cff4dff4d"    -- green (ahead)
                           or projPct >= 1.00 and "|cffffd866"    -- yellow (tight)
                           or "|cffff6666"                        -- red (behind)
                table.insert(parts, string.format("%sPace: %d%%|r",
                    color, math.floor(projPct * 100 + 0.5)))
            end
        end
        pullText:SetText(table.concat(parts, "  "))
    end
end

----------------------------------------------------------------------
-- Locate the enemy-forces criterion index with a 3-pass strategy.
----------------------------------------------------------------------
local function FindForcesIndex(numCriteria)
    -- Pass 1: explicit isWeightedProgress flag (most reliable when present)
    for i = 1, numCriteria do
        local info = C_Scenario.GetCriteriaInfo(i)
        if info and info.isWeightedProgress then return i end
    end

    -- Pass 2: totalQuantity clearly > 1.
    -- Boss criteria always have totalQuantity == 1; forces totals are large (e.g. 100, 250).
    local bestIdx, bestTotal = nil, 1   -- threshold: must beat 1
    for i = 1, numCriteria do
        local info = C_Scenario.GetCriteriaInfo(i)
        if info and (info.totalQuantity or 0) > bestTotal then
            bestTotal = info.totalQuantity
            bestIdx   = i
        end
    end
    if bestIdx then return bestIdx end

    -- Pass 3: non-completed criterion with the highest accumulated progress.
    -- Forces count up continuously; un-killed bosses sit at 0 until killed.
    local bestQIdx, bestQ = nil, 0
    for i = 1, numCriteria do
        local info = C_Scenario.GetCriteriaInfo(i)
        if info and not info.completed and (info.quantity or 0) > bestQ then
            bestQ    = info.quantity
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

    local stepInfo = C_Scenario.GetStepInfo and C_Scenario.GetStepInfo()
    if not stepInfo then
        print("|cff00ccffMP EF|r GetStepInfo() = nil")
        return
    end

    -- Probe every field name we might care about, one by one
    local STEP_FIELDS = {
        "numCriteria","numObjectives","scenarioType","title","xp","money",
        "weightedProgress","weightedProgressTotal",
        "enemyForcesCurrent","enemyForcesTotal",
        "currentForces","totalForces","forcesPercent",
        "numCompleted","flags","stepFailed","spells","shouldShowBonuses",
    }
    local parts = {}
    for _, k in ipairs(STEP_FIELDS) do
        local v = SafeGet(stepInfo, k)
        if v ~= nil then parts[#parts+1] = k.."="..tostring(v) end
    end
    print("|cff00ccffMP EF stepInfo|r " .. (#parts > 0 and table.concat(parts, "  ") or "(all nil)"))

    -- Try GetCriteriaInfo for indices 1–8 regardless of numCriteria
    local CRIT_FIELDS = {
        "quantity","totalQuantity","currentQuantity","maxQuantity",
        "completed","isWeightedProgress","isPassed","criteriaString",
        "duration","elapsed","flags","conditionType","uiOrder",
    }
    for i = 1, 8 do
        local info = C_Scenario.GetCriteriaInfo and C_Scenario.GetCriteriaInfo(i)
        if info then
            local cp = {}
            for _, k in ipairs(CRIT_FIELDS) do
                local v = SafeGet(info, k)
                if v ~= nil then cp[#cp+1] = k.."="..tostring(v) end
            end
            if #cp > 0 then
                print("|cff00ccffMP EF crit["..i.."]|r " .. table.concat(cp, "  "))
            end
        end
    end
end

local function GetCriteriaForces(stepInfo)
    local numCriteria = stepInfo.numCriteria or 0
    if numCriteria <= 0 then return nil, nil end

    local function readIndex(idx)
        if not idx then return nil, nil end
        local info = C_Scenario.GetCriteriaInfo(idx)
        if not info then return nil, nil end
        local c = info.quantity or info.currentQuantity or 0
        local t = info.totalQuantity or info.maxQuantity or 0
        if t <= 0 then return nil, nil end
        return c, t
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

    local stepInfo = C_Scenario.GetStepInfo and C_Scenario.GetStepInfo()
    if not stepInfo then return end

    local current, total

    -- Approach 1: direct weighted-progress fields (retail / some Midnight builds)
    local wp  = stepInfo.weightedProgress
    local wpt = stepInfo.weightedProgressTotal
    if wp ~= nil and wpt ~= nil and wpt > 0 then
        current, total = wp, wpt
    end

    -- Approach 2: criteria scanning with every known field-name variant
    if not current or (total or 0) <= 0 then
        current, total = GetCriteriaForces(stepInfo)
    end

    -- Dump API state once so we can see what fields are available
    if (not current or (total or 0) <= 0) and MP:IsInMythicPlus() then
        DiagnoseDump()
    end

    if not current or (total or 0) <= 0 then
        QueueRetryUpdate()
        return
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
        self.active    = true
        self.current   = 0
        self.total     = 0
        self.pullCount = 0
        self.pullStart = 0
        self.inCombat  = false
        _cachedForcesIndex = nil
        _forcesRetryPending = false
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
            -- Reset pull display after a delay
            C_Timer.After(3, function()
                if not self.inCombat then
                    self.pullCount = 0
                    if pullText then
                        pullText:SetText("")
                    end
                end
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

    if section then section:Show() end
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
        progressBar.text:SetText("")
        if progressBar.leftText then progressBar.leftText:SetText("") end
    end
    if pullText then pullText:SetText("") end
    if section then section:Hide() end
end

function EnemyForces:OnFrameReady()
    if not MP.MainFrame or not MP.MainFrame.frame then
        MP:Debug("MainFrame not ready, skipping EnemyForces UI creation")
        return
    end
    CreateUI()
    -- Register as M+-only section
    if section then
        MP:RegisterMythicOnlySection(section)
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
