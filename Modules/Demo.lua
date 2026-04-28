--[[
    MythicPulse - Demo Mode Module
    Injects mock data into all visible modules so users can configure layouts
    outside of an actual M+ run.  Toggled via /mp demo.

    Strategy:
    - Call Timer:StartDemo() to wire up the timerBar and reset section state.
    - Drive a synthetic ticker that advances elapsed time and calls Timer:RefreshUI()
      each frame for smooth animation.
    - Simulate boss kills via Timer:SimulateBossKill() so split rows render with
      full formatting (name · kill-time · Δprev · ±PB).
    - On loop-reset, call Timer:StartDemo() again so section height and split rows
      are properly cleared.
    - On stop, call Timer:StopDemo() for a clean idle state.
]]

local _, MP = ...

local Demo = {
    active = false,
}

----------------------------------------------------------------------
-- Demo data
----------------------------------------------------------------------
local DEMO_DUNGEON = {
    mapID     = 503,
    name      = "Demo Dungeon",
    timeLimit = 1800,           -- 30:00
    keyLevel  = 15,
    bossCount = 3,
    bossNames = { "Voidkeeper", "Sorcerer Umbric", "High Sage Viryx" },
}

local DEMO_PARTY = {
    { name = "Aydalor",   class = "PALADIN" },
    { name = "Veyrith",   class = "MAGE"    },
    { name = "Thessabel", class = "PRIEST"  },
    { name = "Korr",      class = "WARRIOR" },
    { name = "Lythera",   class = "DRUID"   },
}

local DEMO_FORCES_TOTAL = 250
local DEMO_BOSS_SPLITS  = { 240, 600, 1020 }   -- 4:00, 10:00, 17:00

----------------------------------------------------------------------
-- Synthetic ticker
----------------------------------------------------------------------
local ticker = CreateFrame("Frame")
ticker:Hide()
local tickerElapsed = 0
local nextBossIdx   = 1

local function ResetDemoTimer()
    local timer = MP:GetModule("Timer")
    if not timer then return end
    if timer.StartDemo then timer:StartDemo(DEMO_DUNGEON) end
    -- Restore the dungeon header (StartDemo doesn't set it)
    if MP.MainFrame and MP.MainFrame.SetDungeonInfo then
        MP.MainFrame:SetDungeonInfo(DEMO_DUNGEON.name, DEMO_DUNGEON.keyLevel)
    end
end

ticker:SetScript("OnUpdate", function(self, dt)
    if not Demo.active then self:Hide(); return end

    local timer = MP:GetModule("Timer")
    if timer then
        timer.elapsed = (timer.elapsed or 0) + dt

        -- Loop: restart when we hit the time limit
        if timer.elapsed > DEMO_DUNGEON.timeLimit then
            ResetDemoTimer()
            nextBossIdx = 1
        end

        -- Simulate boss kills at staged elapsed times
        local nextSplit = DEMO_BOSS_SPLITS[nextBossIdx]
        if nextSplit and timer.elapsed >= nextSplit then
            local bossName = DEMO_DUNGEON.bossNames[nextBossIdx]
                          or ("Boss " .. nextBossIdx)
            if timer.SimulateBossKill then
                timer:SimulateBossKill(bossName)
            end
            nextBossIdx = nextBossIdx + 1
        end

        -- Drive timer bar, threshold countdown, and pace text every frame
        if timer.RefreshUI then timer:RefreshUI() end
    end

    -- Enemy forces (throttled to 10 Hz — sub-second precision not needed)
    tickerElapsed = tickerElapsed + dt
    if tickerElapsed >= 0.1 then
        tickerElapsed = 0
        local ef = MP:GetModule("EnemyForces")
        if ef and ef.UpdateDemo then
            local t = MP:GetModule("Timer")
            if t then
                local efCurrent = (t.elapsed / DEMO_DUNGEON.timeLimit) * DEMO_FORCES_TOTAL
                ef:UpdateDemo(efCurrent)
            end
        end
    end
end)

----------------------------------------------------------------------
-- Start helpers
----------------------------------------------------------------------
local function StartTimer()
    local timer = MP:GetModule("Timer")
    if not timer then return end
    if timer.StartDemo then timer:StartDemo(DEMO_DUNGEON) end
    if MP.MainFrame and MP.MainFrame.SetDungeonInfo then
        MP.MainFrame:SetDungeonInfo(DEMO_DUNGEON.name, DEMO_DUNGEON.keyLevel)
        if MP.MainFrame.frame then MP.MainFrame.frame:Show() end
    end
end

local function StartPartyTrackers()
    local it = MP:GetModule("InterruptTracker")
    if it then
        it.members = {}
        for _, p in ipairs(DEMO_PARTY) do
            table.insert(it.members, {
                guid      = "demo-" .. p.name,
                name      = p.name,
                class     = p.class,
                spellID   = 1766,
                duration  = 15,
                spellName = "Interrupt",
                cdEnd     = 0,
                kickResult = nil,
            })
        end
        it.active = true
    end

    local pc = MP:GetModule("PartyCooldowns")
    if pc and pc.StartDemo then
        pc:StartDemo(DEMO_PARTY)
    end
end

----------------------------------------------------------------------
-- Public: Start
----------------------------------------------------------------------
function Demo:Start()
    if self.active then
        MP:Print("Demo mode already active. /mp demo to stop.")
        return
    end
    if not (MP.MainFrame and MP.MainFrame.frame) then
        MP:Print("Demo: HUD still loading, retrying in 2s...")
        C_Timer.After(2, function() self:Start() end)
        return
    end

    self.active = true
    nextBossIdx = 1

    StartTimer()
    StartPartyTrackers()

    local ef = MP:GetModule("EnemyForces")
    if ef and ef.StartDemo then
        ef:StartDemo({ current = 0, total = DEMO_FORCES_TOTAL })
    end

    local dt = MP:GetModule("DispelTracker")
    if dt and dt.StartDemo then dt:StartDemo() end

    if MP.TrackerFrame and MP.TrackerFrame.frame then
        MP.TrackerFrame.frame:Show()
    end
    if MP.InterruptFrame and MP.InterruptFrame.frame then
        MP.InterruptFrame.frame:Show()
    end

    if MP.UpdateMythicOnlySections then
        Demo._origInMythic = MP.IsInMythicPlus
        MP.IsInMythicPlus  = function() return true end
        MP:UpdateMythicOnlySections()
    end

    if MP.MainFrame and MP.MainFrame.Layout then MP.MainFrame:Layout() end

    if ObjectiveTrackerFrame then
        Demo._trackerWasShown = ObjectiveTrackerFrame:IsShown()
        ObjectiveTrackerFrame:Hide()
    end

    ticker:Show()
    MP:Print("|cff4dff4dDemo mode ON|r — drag frames to reposition. /mp demo again to stop.")
end

----------------------------------------------------------------------
-- Public: Stop
----------------------------------------------------------------------
function Demo:Stop()
    if not self.active then return end
    self.active = false
    ticker:Hide()

    if Demo._origInMythic then
        MP.IsInMythicPlus  = Demo._origInMythic
        Demo._origInMythic = nil
    end

    -- Timer: use StopDemo to reset section height and split rows cleanly
    local timer = MP:GetModule("Timer")
    if timer and timer.StopDemo then
        timer:StopDemo()
    end
    if MP.MainFrame and MP.MainFrame.SetDungeonInfo then
        MP.MainFrame:SetDungeonInfo(nil, nil)
    end

    local it = MP:GetModule("InterruptTracker")
    if it then it.members = {} end

    local pc = MP:GetModule("PartyCooldowns")
    if pc and pc.StopDemo then pc:StopDemo() end

    local dt = MP:GetModule("DispelTracker")
    if dt and dt.StopDemo then dt:StopDemo() end

    local ef = MP:GetModule("EnemyForces")
    if ef and ef.StopDemo then ef:StopDemo() end

    if MP.UpdateMythicOnlySections then MP:UpdateMythicOnlySections() end
    if MP.TrackerFrame   and MP.TrackerFrame.UpdateVisibility   then MP.TrackerFrame:UpdateVisibility()   end
    if MP.InterruptFrame and MP.InterruptFrame.UpdateVisibility then MP.InterruptFrame:UpdateVisibility() end
    if MP.MainFrame      and MP.MainFrame.Layout                then MP.MainFrame:Layout()                end

    if ObjectiveTrackerFrame and Demo._trackerWasShown then
        ObjectiveTrackerFrame:Show()
    end
    Demo._trackerWasShown = nil

    MP:Print("|cffaaaaaaDemo mode OFF|r")
end

----------------------------------------------------------------------
-- Public: Toggle
----------------------------------------------------------------------
function Demo:Toggle()
    if self.active then self:Stop() else self:Start() end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP.Demo = Demo
