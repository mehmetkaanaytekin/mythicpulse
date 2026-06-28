--[[
    MythicPulse - Dungeon Timer Module

    Layout (top → bottom inside the MainFrame section):
      [deathRow]        "2 Deaths (+0:30)"  (red, hidden when no deaths)
      [affixRow]        "[12] Fortified · Spiteful · Grievous"
      [timerBar]        large "elapsed / total" text + progress bar + +3/+2 labels
      [forcesContainer] Enemy Forces progress bar (EnemyForces module populates this)
      [pbText]          personal best for this dungeon/level
      [splitFrame]      per-boss rows: name · kill-time · +prev · +-PB
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
-- Vertical offsets from section TOPLEFT (all negative Y):
local Y_DEATH   =   0    -- death count row (Body font ~18px effective)
local Y_AFFIX   = -22    -- affix names row (death 18 + gap 4)
local Y_TIMER   = -54    -- timerBar frame top (affix 18 + gap 14)
-- timerBar height = 24 + 46 = 70
local Y_FORCES  = -128   -- forces bar (timer 70 + gap 4)
-- forces height = 24
local Y_PB      = -156   -- personal best (forces 24 + gap 4)
-- pb height = 16
local Y_SCORE   = -176   -- live score estimate (pb 16 + gap 4)
-- score height = 16
local Y_SPLITS  = -196   -- boss splits (score 16 + gap 4)

local SECTION_BASE_H = 196
local SPLIT_ROW_H    = 18

----------------------------------------------------------------------
-- UI elements (module-scoped locals for easy access)
----------------------------------------------------------------------
local timerBar, splitFrame, splitTexts
local deathRow, affixRow, pbText, scoreText

----------------------------------------------------------------------
-- Section creation
----------------------------------------------------------------------
local function CreateUI()
    local section = MP.MainFrame:CreateSection(nil, SECTION_BASE_H)

    -- Death count row (top of section)
    deathRow = section:CreateFontString(nil, "OVERLAY")
    deathRow:SetFontObject(MP.Fonts.Body)
    deathRow:SetPoint("TOPLEFT",  section, "TOPLEFT",  0, Y_DEATH)
    deathRow:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, Y_DEATH)
    deathRow:SetJustifyH("LEFT")
    deathRow:SetText("")
    Timer.deathRow = deathRow

    -- Affix names row
    affixRow = section:CreateFontString(nil, "OVERLAY")
    affixRow:SetFontObject(MP.Fonts.Body)
    affixRow:SetPoint("TOPLEFT",  section, "TOPLEFT",  0, Y_AFFIX)
    affixRow:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, Y_AFFIX)
    affixRow:SetJustifyH("LEFT")
    affixRow:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
    affixRow:SetText("")
    Timer.affixRow = affixRow

    -- Timer bar: large "elapsed / total" text + progress bar with +3/+2 labels
    timerBar = MP.TimerBarWidget:Create(section, 244, 24)
    timerBar:SetPoint("TOPLEFT",  section, "TOPLEFT",  0, Y_TIMER)
    timerBar:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, Y_TIMER)

    -- Enemy forces container — EnemyForces module creates its bar here
    Timer.forcesContainer = CreateFrame("Frame", nil, section)
    Timer.forcesContainer:SetHeight(24)
    Timer.forcesContainer:SetPoint("TOPLEFT",  section, "TOPLEFT",  0, Y_FORCES)
    Timer.forcesContainer:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, Y_FORCES)

    -- Personal best reference line
    pbText = section:CreateFontString(nil, "OVERLAY")
    pbText:SetFontObject(MP.Fonts.Small)
    pbText:SetPoint("TOPLEFT",  section, "TOPLEFT",  0, Y_PB)
    pbText:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, Y_PB)
    pbText:SetJustifyH("LEFT")
    pbText:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)

    -- Live score estimate line
    scoreText = section:CreateFontString(nil, "OVERLAY")
    scoreText:SetFontObject(MP.Fonts.Small)
    scoreText:SetPoint("TOPLEFT",  section, "TOPLEFT",  0, Y_SCORE)
    scoreText:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, Y_SCORE)
    scoreText:SetJustifyH("LEFT")
    scoreText:SetText("")
    Timer.scoreText = scoreText

    -- Boss splits container
    splitFrame = CreateFrame("Frame", nil, section)
    splitFrame:SetHeight(1)
    splitFrame:SetPoint("TOPLEFT", section, "TOPLEFT",  0, Y_SPLITS)
    splitFrame:SetPoint("RIGHT",   section, "RIGHT",    0, 0)
    splitTexts = {}

    MP.MainFrame:AddSection(section)
    Timer.section = section

    -- Invite EnemyForces to create its bar in our container now (if it loaded first).
    local ef = MP:GetModule("EnemyForces")
    if ef and ef.CreateBarInContainer then
        ef:CreateBarInContainer(Timer.forcesContainer)
    end

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
    local best   = history:GetPersonalBest(Timer.mapID, Timer.keyLevel)
    local weekly = history.GetWeeklyBest and history:GetWeeklyBest(Timer.mapID, Timer.keyLevel)

    if best and best.elapsed and best.elapsed > 0 then
        local pbLine = MP:Loc("TIMER_PB_FORMAT", MP:FormatTime(best.elapsed), Timer.keyLevel)
        -- Append weekly best when it differs from all-time PB (or when only weekly exists)
        if weekly and weekly.elapsed and weekly.elapsed > 0
        and (not best or weekly.elapsed ~= best.elapsed) then
            pbLine = pbLine .. "  |cffaaaaaa" .. MP:Loc("TIMER_WK_PB_FORMAT", MP:FormatTime(weekly.elapsed)) .. "|r"
        end
        pbText:SetText(pbLine)
    elseif weekly and weekly.elapsed and weekly.elapsed > 0 then
        pbText:SetText("|cffaaaaaa" .. MP:Loc("TIMER_WK_PB_FORMAT", MP:FormatTime(weekly.elapsed)) .. "|r")
    else
        pbText:SetText(MP:Loc("TIMER_NO_PB"))
    end
end

----------------------------------------------------------------------
-- Affix display: "[12] Fortified · Spiteful · Grievous"
----------------------------------------------------------------------
local function UpdateAffixText()
    if not affixRow then return end
    local level, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    if not affixIDs or #affixIDs == 0 then
        affixRow:SetText("")
        return
    end
    local parts = {}
    for _, id in ipairs(affixIDs) do
        local info = C_ChallengeMode.GetAffixInfo(id)
        if type(info) == "table" and info.name then
            table.insert(parts, info.name)
        elseif type(info) == "string" then
            table.insert(parts, info)
        end
    end
    local levelStr = level and ("|cffffff00[" .. level .. "]|r ") or ""
    affixRow:SetText(levelStr .. table.concat(parts, " · "))
end

----------------------------------------------------------------------
-- Death row — pulled from DeathTracker each tick (throttled)
----------------------------------------------------------------------
local _lastDeathCount = -1

-- Skull raid-target marker (icon 8) — 64x64 standalone texture, ASCII-safe inline icon.
local SKULL_ICON = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:14:14:0:-1|t "

local function UpdateDeathRow()
    if not deathRow then return end
    local dt = MP:GetModule("DeathTracker")
    if not dt or not dt.enabled then
        deathRow:SetText("")
        _lastDeathCount = -1
        return
    end
    local deaths = dt.count or 0
    if deaths == _lastDeathCount then return end
    _lastDeathCount = deaths

    if deaths <= 0 then
        if Timer.active then
            deathRow:SetText(SKULL_ICON .. "|cff4daa55" .. MP:Loc("TIMER_ZERO_DEATHS") .. "|r")
        else
            deathRow:SetText("")
        end
        return
    end

    local penalty, isPenalized = 0, false
    if MP.DungeonData and Timer.keyLevel and Timer.keyLevel > 0 then
        isPenalized = MP.DungeonData:DeathsPenalized(Timer.keyLevel)
        if isPenalized then
            penalty = MP.DungeonData:GetDeathPenalty(Timer.keyLevel) or 0
        end
    end
    local totalPenalty = deaths * penalty
    local label = deaths == 1 and MP:Loc("TIMER_DEATH_SINGULAR") or MP:Loc("TIMER_DEATH_PLURAL")
    if totalPenalty > 0 then
        deathRow:SetText(string.format(
            "%s|cffff5555%d %s|r |cff888888(+%s)|r",
            SKULL_ICON, deaths, label, MP:FormatTime(totalPenalty)
        ))
    else
        deathRow:SetText(string.format("%s|cffff5555%d %s|r", SKULL_ICON, deaths, label))
    end
end

----------------------------------------------------------------------
-- Live score estimate
----------------------------------------------------------------------
local _lastScoreElapsed = -1

local function UpdateScoreText()
    if not scoreText or not Timer.active then return end
    local elapsed = Timer.elapsed
    -- Update at most once per second
    if math.floor(elapsed) == math.floor(_lastScoreElapsed) then return end
    _lastScoreElapsed = elapsed

    local sp = MP.ScorePredictor
    if not sp or not Timer.keyLevel or Timer.keyLevel <= 0 then
        scoreText:SetText("")
        return
    end

    local timed    = elapsed <= (Timer.timeLimit or 0) and Timer.timeLimit > 0
    local tier     = sp:GetChestTier(elapsed, Timer.timeLimit)
    local score    = sp:EstimateRunScore(Timer.keyLevel, timed, tier)
    local existing = sp:GetExistingBestForMap(Timer.mapID)

    local paceStr
    if timed then
        -- Show tier label and score
        local tierLabel = (tier == 3 and "|cffffd700+3|r") or (tier == 2 and "|cffaaaaaa+2|r") or "|cffff9f00+1|r"
        paceStr = string.format("%s  ~|cffffff80%d pts|r", tierLabel, score)
    else
        -- Over-time: show as depleted
        paceStr = string.format("|cffff4040%s|r  ~|cffffff80%d pts|r",
            MP:Loc("RS_DEPLETED"), score)
    end

    if existing and existing > 0 then
        local delta = score - existing
        if delta > 0 then
            paceStr = paceStr .. string.format("  |cff4dff4d(+%d)|r", delta)
        elseif delta < 0 then
            paceStr = paceStr .. string.format("  |cffff5555(%d)|r", delta)
        end
    end

    scoreText:SetText(paceStr)
end

local function ClearLiveText()
    _lastDeathCount   = -1
    _lastScoreElapsed = -1
    if deathRow   then deathRow:SetText("") end
    if affixRow   then affixRow:SetText("") end
    if scoreText  then scoreText:SetText("") end
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
    UpdateDeathRow()
    UpdateScoreText()
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

    local _, affixIDs = C_ChallengeMode.GetActiveKeystoneInfo()
    Timer.affixes = {}
    if affixIDs then
        for _, id in ipairs(affixIDs) do table.insert(Timer.affixes, id) end
    end

    local info = MP.DungeonData:GetInfo(mapID)
    -- Informational only; boss-split rows are created dynamically on ENCOUNTER_END,
    -- so an unknown (e.g. new-season) dungeon still tracks splits correctly.
    Timer.bossCount = info.numBosses or 0

    if timerBar then
        timerBar:Reset()
        timerBar:SetTimeLimit(Timer.timeLimit)
    end

    -- Reset section to base height (clears visual remnants from previous run)
    if Timer.section then
        Timer.section:SetHeight(SECTION_BASE_H)
    end

    -- Clear live text rows, then populate static ones
    ClearLiveText()
    UpdateAffixText()

    local shortName = info.shortName or name
    MP.MainFrame:SetDungeonInfo(shortName, level)
    MP.MainFrame.frame:Show()

    if Timer.section then
        Timer.section:Show()
        MP.MainFrame:Layout()
    end

    RefreshPBDisplay()
    HideBlizzardTracker()
    tickFrame:Show()

    -- Clear and hide split rows from the previous run
    if splitTexts then
        for _, row in ipairs(splitTexts) do
            if row.text then row.text:SetText("") end
            row.splitData = nil
            row:Hide()
        end
    end
    if splitFrame then splitFrame:SetHeight(1) end

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
        MP:Print("|cff4dff4d" .. MP:Loc("TIMER_COMPLETED") .. "|r " .. MP:FormatTime(Timer.elapsed))
    end

    if not Timer.mapID or Timer.mapID <= 0 or (Timer.keyLevel or 0) <= 0 then
        RefreshPBDisplay()
        RestoreBlizzardTracker()
        return
    end

    local deathMod = MP:GetModule("DeathTracker")
    local deaths   = deathMod and deathMod.count or 0
    local deathPenalty = MP.DungeonData and MP.DungeonData:GetDeathPenalty(Timer.keyLevel) or 5

    -- Snapshot interrupt stats before InterruptTracker may clear its members table
    -- (both Timer and InterruptTracker listen to CHALLENGE_MODE_COMPLETED; order varies).
    local it = MP:GetModule("InterruptTracker")
    local interruptStats = it and it:GetRunStats() or {}

    local runData  = {
        mapID          = Timer.mapID,
        keyLevel       = Timer.keyLevel,
        elapsed        = Timer.elapsed,
        timeLimit      = Timer.timeLimit,
        deaths         = deaths,
        timed          = completed and (Timer.elapsed <= Timer.timeLimit),
        completed      = completed or false,
        date           = date("%Y-%m-%d %H:%M"),
        bossSplits     = Timer.bossSplits,
        affixes        = Timer.affixes,
        dungeonName    = MP.DungeonData and MP.DungeonData:GetInfo(Timer.mapID).shortName,
        deathPenalty   = deathPenalty,
        totalPenalty   = deaths * deathPenalty,
        interruptStats = interruptStats,
    }
    Timer.affixes = nil

    local history = MP:GetModule("DungeonHistory")
    if history and history.RecordRun then
        history:RecordRun(runData)
    end

    RefreshPBDisplay()
    RestoreBlizzardTracker()

    -- Show the run summary panel when a key completes (not on reset/abandon).
    if completed and MP.RunSummary then
        C_Timer.After(1.5, function()
            if MP.IsModuleEnabled and not MP:IsModuleEnabled("runSummary") then return end
            MP.RunSummary:Show(runData)
        end)
    end
end

----------------------------------------------------------------------
-- Boss split tooltip
----------------------------------------------------------------------
local function ShowSplitTooltip(self)
    if not self.splitData then return end
    local s = self.splitData
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(s.name or MP:Loc("TIMER_BOSS_FALLBACK", s.index), 0, 0.8, 1)

    GameTooltip:AddDoubleLine(MP:Loc("TIMER_TOOLTIP_KILLED"), MP:FormatTime(s.elapsed), 0.85, 0.85, 0.85, 1, 1, 1)

    local prev = Timer.bossSplits[s.index - 1]
    if prev then
        local delta = s.elapsed - prev.elapsed
        GameTooltip:AddDoubleLine(MP:Loc("TIMER_TOOLTIP_PREV"), MP:FormatTime(delta), 0.85, 0.85, 0.85, 0.7, 0.95, 0.7)
    else
        GameTooltip:AddDoubleLine(MP:Loc("TIMER_TOOLTIP_START"), MP:FormatTime(s.elapsed), 0.85, 0.85, 0.85, 0.7, 0.95, 0.7)
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
            GameTooltip:AddDoubleLine(MP:Loc("TIMER_TOOLTIP_VS_PB"), diffStr, 0.7, 0.7, 0.7, r, g, b)
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
    local displayName = (bossName and bossName ~= "") and bossName or MP:Loc("TIMER_BOSS_FALLBACK", idx)

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
        splitRow:SetPoint("TOPLEFT", splitFrame, "TOPLEFT",  0, -((idx - 1) * SPLIT_ROW_H))
        splitRow:SetPoint("RIGHT",   splitFrame, "RIGHT",    0, 0)

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
        "|cff6ad4ff%s|r  |cffffd866%s|r  |cff888888+%s|r%s",
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
        local encounterID, encounterName, _, _, success = ...
        -- success can be 1 (number) or true (boolean) depending on the build
        if self.active and (success == 1 or success == true) then
            local name = encounterName
            -- Fall back to encounter journal when the event arg is nil/empty
            if (not name or name == "") and encounterID and encounterID > 0 then
                if C_EncounterJournal and C_EncounterJournal.GetEncounterInfo then
                    name = C_EncounterJournal.GetEncounterInfo(encounterID)
                end
            end
            OnBossKill(name or MP:Loc("TIMER_BOSS_FALLBACK", self.bossesKilled + 1))
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
    -- If EnemyForces loaded before us and has a deferred CreateBarInContainer,
    -- it will have been called already in CreateUI above.  If Timer loaded first,
    -- EnemyForces.OnFrameReady will call CreateBarInContainer when it runs.
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

function Timer:OnDisable()
    self.active = false
    tickFrame:Hide()
    if Timer.section then Timer.section:Hide() end
    ClearLiveText()
    if timerBar then timerBar:Reset() end
    if MP.MainFrame then MP.MainFrame:Layout() end
end

function Timer:OnEnable()
    if Timer.section then Timer.section:Show() end
    if MP:IsInMythicPlus() then
        StartRun()
        tickFrame:Show()
    end
    if MP.MainFrame then MP.MainFrame:Layout() end
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

--- Hides split rows and resets section height.
--- Called at the start of each new run and by external callers on demand.
function Timer:ClearBossSplits()
    if splitTexts then
        for _, row in ipairs(splitTexts) do
            row:Hide()
            if row.splitData then row.splitData = nil end
        end
    end
    if splitFrame then splitFrame:SetHeight(1) end
    if self.section then
        self.section:SetHeight(SECTION_BASE_H)
        MP.MainFrame:Layout()
    end
end

--- Called by Demo.lua to trigger a boss-kill with full UI output.
--- OnBossKill is local so this thin wrapper is the only public path.
function Timer:SimulateBossKill(bossName)
    if self.active then
        OnBossKill(bossName or MP:Loc("TIMER_BOSS_FALLBACK", self.bossesKilled + 1))
    end
end

--- Clean up after demo stops: resets section height and split rows.
function Timer:StopDemo()
    self.active       = false
    self.elapsed      = 0
    self.bossSplits   = {}
    self.bossesKilled = 0
    ClearLiveText()
    if pbText then pbText:SetText("") end
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
    if affixRow then
        affixRow:SetText(string.format(
            "|cffffff00[%d]|r Fortified · Spiteful · Grievous",
            self.keyLevel or 0
        ))
    end

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
    UpdateDeathRow()
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("Timer", Timer)
