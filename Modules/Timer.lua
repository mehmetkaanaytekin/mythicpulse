--[[
    MythicPulse - Dungeon Timer Module

    Layout (top → bottom inside the MainFrame section):
      [timerBar]        large countdown + progress bar + +2/+3 markers
      [thresholdText]   live "+3  X:XX     +2  X:XX" countdown row
      [paceText]        "On pace for +3 · ahead 0:23"  (color-coded)
      [pbText]          personal best for this dungeon/level
      [splitFrame]      per-boss rows: name · kill-time · Δprev · ±PB
]]

local _, MP = ...

local trackerWasShown = true

local function HideBlizzardTracker()
    if ObjectiveTrackerFrame then
        trackerWasShown = ObjectiveTrackerFrame:IsShown()
        ObjectiveTrackerFrame:Hide()
    end
end

local function RestoreBlizzardTracker()
    if ObjectiveTrackerFrame and trackerWasShown then
        ObjectiveTrackerFrame:Show()
    end
end

local Timer = {
    registeredEvents = {
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_COMPLETED",
        "CHALLENGE_MODE_RESET",
        "WORLD_STATE_TIMER_START",
        "WORLD_STATE_TIMER_STOP",
        "ENCOUNTER_END",
    },
    active        = false,
    elapsed       = 0,
    timeLimit     = 0,
    mapID         = 0,
    keyLevel      = 0,
    bossSplits    = {},
    bossCount     = 0,
    bossesKilled  = 0,
    worldTimerID  = nil,
    runStartTime  = nil,
}

----------------------------------------------------------------------
-- Section layout constants
----------------------------------------------------------------------
local SECTION_BASE_H = 155   -- timerBar(62) + top-gap(14) + threshold(20) + pace(22) + pb(22) + splits-gap(15)
local SPLIT_ROW_H    = 18

----------------------------------------------------------------------
-- UI elements (module-scoped locals for easy access)
----------------------------------------------------------------------
local timerBar, splitFrame, splitTexts
local thresholdText, paceText, pbText

----------------------------------------------------------------------
-- Section creation
----------------------------------------------------------------------
local function CreateUI()
    local section = MP.MainFrame:CreateSection(nil, SECTION_BASE_H)

    -- Timer bar: large countdown + progress bar + markers
    timerBar = MP.TimerBarWidget:Create(section, 244, 16)
    timerBar:SetPoint("TOPLEFT",  0, -14)
    timerBar:SetPoint("TOPRIGHT", 0, -14)
    -- timerBar frame is 62px tall → bottom at section y = -76

    -- Threshold countdown row: "+3  X:XX          +2  X:XX"
    thresholdText = section:CreateFontString(nil, "OVERLAY")
    thresholdText:SetFontObject(MP.Fonts.Small)
    thresholdText:SetPoint("LEFT",  timerBar, "BOTTOMLEFT",  0, -8)
    thresholdText:SetPoint("RIGHT", timerBar, "BOTTOMRIGHT", 0, -8)
    thresholdText:SetJustifyH("CENTER")
    thresholdText:SetText("")

    -- Pace indicator: "On pace for +3 · 0:23 ahead"
    paceText = section:CreateFontString(nil, "OVERLAY")
    paceText:SetFontObject(MP.Fonts.Small)
    paceText:SetPoint("LEFT",  timerBar, "BOTTOMLEFT",  0, -28)
    paceText:SetPoint("RIGHT", timerBar, "BOTTOMRIGHT", 0, -28)
    paceText:SetJustifyH("LEFT")
    paceText:SetText("")

    -- Personal best reference line
    pbText = section:CreateFontString(nil, "OVERLAY")
    pbText:SetFontObject(MP.Fonts.Small)
    pbText:SetPoint("TOPLEFT", timerBar, "BOTTOMLEFT", 0, -50)
    pbText:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)

    -- Boss splits container
    splitFrame = CreateFrame("Frame", nil, section)
    splitFrame:SetHeight(1)
    splitFrame:SetPoint("TOPLEFT", timerBar, "BOTTOMLEFT",  0, -72)
    splitFrame:SetPoint("RIGHT",   section,  "RIGHT",       0,   0)
    splitTexts = {}

    MP.MainFrame:AddSection(section)
    Timer.section = section
    return section
end

----------------------------------------------------------------------
-- Personal best display
----------------------------------------------------------------------
local function RefreshPBDisplay()
    if not pbText then return end
    local history = MP:GetModule("DungeonHistory")
    if not history or not history.GetPersonalBest then
        pbText:SetText("")
        return
    end
    local best = history:GetPersonalBest(Timer.mapID, Timer.keyLevel)
    if best and best.elapsed and best.elapsed > 0 then
        pbText:SetText(string.format(
            "PB |cffffffff%s|r  (+%d)",
            MP:FormatTime(best.elapsed),
            Timer.keyLevel
        ))
    else
        pbText:SetText("|cff666666No PB yet|r")
    end
end

----------------------------------------------------------------------
-- Live threshold countdown: "+3  X:XX          +2  X:XX"
----------------------------------------------------------------------
local function UpdateThresholdText(elapsed)
    if not thresholdText or not timerBar then return end
    local p2t = timerBar.plusTwoTime   or 0
    local p3t = timerBar.plusThreeTime or 0
    if p2t <= 0 and p3t <= 0 then thresholdText:SetText(""); return end

    local r3 = p3t - elapsed
    local r2 = p2t - elapsed

    local p3str = r3 > 0
        and string.format("|cff4dff4d+3  %s|r", MP:FormatTime(r3))
        or  "|cff555555+3  --|r"
    local p2str = r2 > 0
        and string.format("|cffffff00+2  %s|r", MP:FormatTime(r2))
        or  "|cff555555+2  --|r"

    thresholdText:SetText(p3str .. "          " .. p2str)
end

----------------------------------------------------------------------
-- Live pace indicator
----------------------------------------------------------------------
local function UpdatePaceText(elapsed)
    if not paceText or not timerBar then return end
    local timeLimit = timerBar.timeLimit    or 0
    local p2t       = timerBar.plusTwoTime  or 0
    local p3t       = timerBar.plusThreeTime or 0
    if timeLimit <= 0 then paceText:SetText(""); return end

    local r3 = p3t - elapsed
    local r2 = p2t - elapsed
    local r0 = timeLimit - elapsed

    local text, r, g, b
    if r3 > 0 then
        text = string.format("On pace for +3  ·  ahead by %s", MP:FormatTime(r3))
        r, g, b = 0.30, 1.00, 0.44
    elseif r2 > 0 then
        text = string.format("On pace for +2  ·  need %s faster for +3", MP:FormatTime(-r3))
        r, g, b = 1.00, 0.85, 0.20
    elseif r0 > 0 then
        text = string.format("Timer only  ·  need %s faster for +2", MP:FormatTime(-r2))
        r, g, b = 1.00, 0.50, 0.15
    else
        text = string.format("Overtime  ·  %s over", MP:FormatTime(-r0))
        r, g, b = 1.00, 0.25, 0.25
    end

    paceText:SetText(text)
    paceText:SetTextColor(r, g, b)
end

local function ClearLiveText()
    if thresholdText then thresholdText:SetText("") end
    if paceText      then paceText:SetText("") end
end

----------------------------------------------------------------------
-- Timer tick
----------------------------------------------------------------------
local tickFrame = CreateFrame("Frame")
tickFrame:Hide()
local tickElapsed = 0

tickFrame:SetScript("OnUpdate", function(self, dt)
    if not Timer.active then
        self:Hide()
        tickElapsed = 0
        return
    end

    tickElapsed = tickElapsed + dt
    if tickElapsed < 0.05 then return end
    tickElapsed = 0

    local _, elapsedTime = GetWorldElapsedTime(Timer.worldTimerID or 1)
    if elapsedTime then
        Timer.elapsed = elapsedTime
    elseif Timer.runStartTime then
        Timer.elapsed = GetTime() - Timer.runStartTime
    end

    if timerBar then
        timerBar:UpdateTimer(Timer.elapsed, Timer.timeLimit)
    end
    UpdateThresholdText(Timer.elapsed)
    UpdatePaceText(Timer.elapsed)
end)

----------------------------------------------------------------------
-- Start a run
----------------------------------------------------------------------
local function StartRun()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    if not mapID then return end

    local name, _, timeLimit = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then
        MP:Debug("Failed to get map info for mapID:", mapID)
        return
    end
    local level = C_ChallengeMode.GetActiveKeystoneInfo()

    Timer.active            = true
    Timer.elapsed           = 0
    Timer.timeLimit         = timeLimit or 0
    Timer.mapID             = mapID
    Timer.keyLevel          = level or 0
    Timer.bossSplits        = {}
    Timer.bossesKilled      = 0
    Timer.runStartTime      = GetTime()
    Timer.worldTimerID      = nil

    local dungeon = MP.DungeonData:GetByMapID(mapID)
    Timer.bossCount = dungeon and dungeon.numBosses or 0

    if timerBar then
        timerBar:Reset()
        timerBar:SetTimeLimit(Timer.timeLimit)
    end

    -- Reset section to base height (clears visual remnants from previous run)
    if Timer.section then
        Timer.section:SetHeight(SECTION_BASE_H)
    end

    -- Clear live text rows
    ClearLiveText()

    local shortName = MP.DungeonData:GetShortName(mapID) or name
    MP.MainFrame:SetDungeonInfo(shortName, level)
    MP.MainFrame.frame:Show()

    if Timer.section then
        Timer.section:Show()
        MP.MainFrame:Layout()
    end

    RefreshPBDisplay()
    HideBlizzardTracker()
    tickFrame:Show()

    -- Clear split text rows (reused across runs)
    if splitTexts then
        for _, row in ipairs(splitTexts) do
            if row.text then row.text:SetText("") end
            row.splitData = nil
        end
    end

    MP:Debug("Timer started:", name, "+", level, "| Limit:", MP:FormatTime(timeLimit))
end

----------------------------------------------------------------------
-- End a run
----------------------------------------------------------------------
local function EndRun(completed)
    Timer.active = false
    tickFrame:Hide()
    ClearLiveText()

    if completed then
        if timerBar then
            local remaining = Timer.timeLimit - Timer.elapsed
            if remaining > 0 then
                timerBar.timerText:SetTextColor(0.3, 1.0, 0.4)
            end
        end
        MP:Print("|cff4dff4d" .. MP.L["TIMER_COMPLETED"] .. "|r " .. MP:FormatTime(Timer.elapsed))
    end

    if not Timer.mapID or Timer.mapID <= 0 or (Timer.keyLevel or 0) <= 0 then
        RefreshPBDisplay()
        RestoreBlizzardTracker()
        return
    end

    local deathMod = MP:GetModule("DeathTracker")
    local deaths   = deathMod and deathMod.count or 0
    local runData  = {
        mapID      = Timer.mapID,
        keyLevel   = Timer.keyLevel,
        elapsed    = Timer.elapsed,
        timeLimit  = Timer.timeLimit,
        deaths     = deaths,
        timed      = completed and (Timer.elapsed <= Timer.timeLimit),
        completed  = completed or false,
        date       = date("%Y-%m-%d %H:%M"),
        bossSplits = Timer.bossSplits,
    }

    local history = MP:GetModule("DungeonHistory")
    if history and history.RecordRun then
        history:RecordRun(runData)
    end

    if completed and MP.RunSummary and MP.RunSummary.Show then
        MP.RunSummary.lastRun = runData
        local cfg = MP.db and MP.db.modules and MP.db.modules.runSummary
        if not cfg or cfg.autoShow ~= false then
            C_Timer.After(2, function()
                if MP.RunSummary and MP.RunSummary.Show then
                    MP.RunSummary:Show(runData)
                end
            end)
        end
    end

    RefreshPBDisplay()
    RestoreBlizzardTracker()
end

----------------------------------------------------------------------
-- Boss split tooltip
----------------------------------------------------------------------
local function ShowSplitTooltip(self)
    if not self.splitData then return end
    local s = self.splitData
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(s.name or ("Boss " .. s.index), 0, 0.8, 1)

    GameTooltip:AddDoubleLine("Killed at:", MP:FormatTime(s.elapsed), 0.85, 0.85, 0.85, 1, 1, 1)

    local prev = Timer.bossSplits[s.index - 1]
    if prev then
        local delta = s.elapsed - prev.elapsed
        GameTooltip:AddDoubleLine("Since prev boss:", MP:FormatTime(delta), 0.85, 0.85, 0.85, 0.7, 0.95, 0.7)
    else
        GameTooltip:AddDoubleLine("From start:", MP:FormatTime(s.elapsed), 0.85, 0.85, 0.85, 0.7, 0.95, 0.7)
    end

    local history = MP:GetModule("DungeonHistory")
    if history and history.GetPersonalBest then
        local best = history:GetPersonalBest(Timer.mapID, Timer.keyLevel)
        if best and best.bossSplits and best.bossSplits[s.index] then
            local pbTime = best.bossSplits[s.index].elapsed
            local diff   = s.elapsed - pbTime
            local diffStr, r, g, b
            if diff <= 0 then
                diffStr = "-" .. MP:FormatTime(-diff)
                r, g, b = 0.3, 1.0, 0.4
            else
                diffStr = "+" .. MP:FormatTime(diff)
                r, g, b = 1.0, 0.4, 0.4
            end
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("vs Personal Best:", diffStr, 0.7, 0.7, 0.7, r, g, b)
        end
    end

    GameTooltip:Show()
end

local function HideSplitTooltip()
    GameTooltip:Hide()
end

----------------------------------------------------------------------
-- Boss kill
----------------------------------------------------------------------
local function OnBossKill(bossName)
    Timer.bossesKilled = Timer.bossesKilled + 1
    local idx       = Timer.bossesKilled
    local splitTime = Timer.elapsed
    local displayName = (bossName and bossName ~= "") and bossName or ("Boss " .. idx)

    local splitData = { index = idx, elapsed = splitTime, name = displayName }
    table.insert(Timer.bossSplits, splitData)

    if timerBar then timerBar:MarkBoss(idx, splitTime) end

    -- Delta since previous boss (or from run start for the first boss)
    local prev      = Timer.bossSplits[idx - 1]
    local deltaTime = prev and (splitTime - prev.elapsed) or splitTime

    -- Inline ±PB comparison
    local pbDiffStr = ""
    do
        local history = MP:GetModule("DungeonHistory")
        if history and history.GetPersonalBest then
            local best = history:GetPersonalBest(Timer.mapID, Timer.keyLevel)
            if best and best.bossSplits and best.bossSplits[idx] then
                local diff = splitTime - best.bossSplits[idx].elapsed
                if diff <= 0 then
                    pbDiffStr = string.format("  |cff4dff4d%s|r", MP:FormatTime(-diff))
                else
                    pbDiffStr = string.format("  |cffff6644+%s|r", MP:FormatTime(diff))
                end
            end
        end
    end

    -- Create or reuse the split row
    local splitRow = splitTexts[idx]
    if not splitRow then
        splitRow = CreateFrame("Button", nil, splitFrame)
        splitRow:SetHeight(SPLIT_ROW_H)
        splitRow:SetPoint("TOPLEFT", splitFrame, "TOPLEFT", 0, -((idx - 1) * SPLIT_ROW_H))
        splitRow:SetPoint("RIGHT",   splitFrame, "RIGHT",   0, 0)

        splitRow.text = splitRow:CreateFontString(nil, "OVERLAY")
        splitRow.text:SetFontObject(MP.Fonts.Body)
        splitRow.text:SetPoint("LEFT", 4, 0)

        splitRow:EnableMouse(true)
        splitRow:SetScript("OnEnter", ShowSplitTooltip)
        splitRow:SetScript("OnLeave", HideSplitTooltip)
        splitTexts[idx] = splitRow
    end

    splitRow.splitData = splitData
    splitRow.text:SetText(string.format(
        "|cff6ad4ff%s|r  |cffffd866%s|r  |cff888888Δ%s|r%s",
        displayName,
        MP:FormatTime(splitTime),
        MP:FormatTime(deltaTime),
        pbDiffStr
    ))

    if Timer.section then
        Timer.section:SetHeight(SECTION_BASE_H + idx * SPLIT_ROW_H)
        MP.MainFrame:Layout()
    end

    MP:Debug("Boss", idx, displayName, "at", MP:FormatTime(splitTime))
end

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function Timer:OnEvent(event, ...)
    if event == "CHALLENGE_MODE_START" then
        C_Timer.After(0.5, StartRun)

    elseif event == "CHALLENGE_MODE_COMPLETED" then
        EndRun(true)

    elseif event == "CHALLENGE_MODE_RESET" then
        EndRun(false)
        if timerBar then timerBar:Reset() end
        MP.MainFrame:SetDungeonInfo(nil, nil)

    elseif event == "ENCOUNTER_END" then
        -- ENCOUNTER_END is the most reliable boss-kill signal in M+.
        -- It fires once per encounter with the boss name and a success flag.
        local _, encounterName, _, _, success = ...
        if self.active and success == 1 then
            OnBossKill(encounterName or ("Boss " .. (self.bossesKilled + 1)))
        end

    elseif event == "WORLD_STATE_TIMER_START" then
        local id = ...
        if id then Timer.worldTimerID = id end
        if not self.active then
            C_Timer.After(0.5, StartRun)
        end
    end
end

function Timer:OnFrameReady()
    if not MP.MainFrame or not MP.MainFrame.frame then
        MP:Debug("MainFrame not ready, skipping Timer UI creation")
        return
    end
    CreateUI()
    if Timer.section then
        MP:RegisterMythicOnlySection(Timer.section)
    end
    if MP:IsInMythicPlus() then
        StartRun()
    end
end

function Timer:OnPlayerEnteringWorld()
    if not MP:IsInMythicPlus() then
        self.active = false
        tickFrame:Hide()
        ClearLiveText()
        if timerBar then timerBar:Reset() end
        if Timer.section then Timer.section:Hide() end
        if MP.MainFrame and MP.MainFrame.SetDungeonInfo then
            MP.MainFrame:SetDungeonInfo(nil, nil)
        end
        RestoreBlizzardTracker()
    else
        HideBlizzardTracker()
    end
end

function Timer:OnConfigReset()
    if timerBar then timerBar:Reset() end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function Timer:GetElapsed()    return self.elapsed    end
function Timer:GetTimeLimit()  return self.timeLimit  end
function Timer:GetBossSplits() return self.bossSplits end

--- Called by Demo.lua to trigger a boss-kill with full UI output.
--- OnBossKill is local so this thin wrapper is the only public path.
function Timer:SimulateBossKill(bossName)
    if self.active then
        OnBossKill(bossName or ("Boss " .. (self.bossesKilled + 1)))
    end
end

--- Clean up after demo stops: resets section height and split rows.
function Timer:StopDemo()
    self.active       = false
    self.elapsed      = 0
    self.bossSplits   = {}
    self.bossesKilled = 0
    ClearLiveText()
    if timerBar then timerBar:Reset() end
    if splitTexts then
        for _, row in ipairs(splitTexts) do
            if row.text then row.text:SetText("") end
            row.splitData = nil
        end
    end
    if Timer.section then
        Timer.section:SetHeight(SECTION_BASE_H)
        MP.MainFrame:Layout()
    end
end

----------------------------------------------------------------------
-- Demo mode
----------------------------------------------------------------------
function Timer:StartDemo(config)
    if not config then return end
    self.active       = true
    self.elapsed      = 0
    self.timeLimit    = config.timeLimit or 0
    self.mapID        = config.mapID    or 0
    self.keyLevel     = config.keyLevel or 0
    self.bossSplits   = {}
    self.bossesKilled = 0
    self.bossCount    = config.bossCount or 0
    self.runStartTime = nil

    if timerBar then
        timerBar:Reset()
        timerBar:SetTimeLimit(self.timeLimit)
    end

    -- Demo uses its own ticker; tickFrame must stay hidden to prevent
    -- GetWorldElapsedTime from overwriting the synthetic elapsed value.
    tickFrame:Hide()

    if splitTexts then
        for _, row in ipairs(splitTexts) do
            if row.text then row.text:SetText("") end
            row.splitData = nil
        end
    end

    ClearLiveText()

    if Timer.section then
        Timer.section:SetHeight(SECTION_BASE_H)
        Timer.section:Show()
        MP.MainFrame:Layout()
    end
end

function Timer:RefreshUI()
    if timerBar then
        timerBar:UpdateTimer(self.elapsed, self.timeLimit)
    end
    UpdateThresholdText(self.elapsed)
    UpdatePaceText(self.elapsed)
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("Timer", Timer)
