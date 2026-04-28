--[[
    MythicPulse - Timer Bar Widget
    Animated countdown with +2/+3 threshold markers and boss markers.
    Threshold countdown rows and pace text are rendered in Timer.lua's
    section, directly below this widget.
]]

local _, MP = ...

MP.TimerBarWidget = {}

function MP.TimerBarWidget:Create(parent, width, height)
    local frame = CreateFrame("Frame", "MythicPulseTimerBar", parent, "BackdropTemplate")
    frame:SetSize(width, height + 46)

    -- Large countdown text (top of frame)
    frame.timerText = frame:CreateFontString(nil, "OVERLAY")
    frame.timerText:SetFontObject(MP.Fonts.Timer)
    frame.timerText:SetPoint("TOP", 0, 0)
    frame.timerText:SetTextColor(0.95, 0.95, 0.95)
    frame.timerText:SetText("00:00")

    -- Progress bar (bottom of frame)
    frame.bar = MP.ProgressBarWidget:Create(frame, width, height, "MythicPulseTimerStatusBar")
    frame.bar:SetPoint("BOTTOM", 0, 0)

    -- +2 threshold marker line (label is shown in the countdown row below the bar)
    frame.plusTwoLine = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.plusTwoLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.plusTwoLine:SetSize(2, height)
    frame.plusTwoLine:SetVertexColor(0.3, 1.0, 0.4, 0.8)

    -- +3 threshold marker line
    frame.plusThreeLine = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.plusThreeLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.plusThreeLine:SetSize(2, height)
    frame.plusThreeLine:SetVertexColor(1.0, 0.85, 0.0, 0.8)

    -- Boss split markers (up to 5)
    frame.bossMarkers = {}
    for i = 1, 5 do
        local marker = frame.bar:CreateTexture(nil, "OVERLAY")
        marker:SetTexture("Interface\\Buttons\\WHITE8x8")
        marker:SetSize(1, height)
        marker:SetVertexColor(0.5, 0.5, 0.7, 0.4)
        marker:Hide()
        frame.bossMarkers[i] = marker
    end

    --- Position threshold markers after the time limit is known.
    function frame:SetTimeLimit(timeLimit)
        self.timeLimit = timeLimit
        local plusTwo, plusThree = MP.DungeonData:GetTimingThresholds(timeLimit)
        self.plusTwoTime   = plusTwo
        self.plusThreeTime = plusThree

        local barW = self.bar:GetWidth()
        if timeLimit > 0 then
            local p2x = (plusTwo / timeLimit) * barW
            self.plusTwoLine:SetPoint("LEFT", self.bar, "LEFT", p2x, 0)
            self.plusTwoLine:Show()

            local p3x = (plusThree / timeLimit) * barW
            self.plusThreeLine:SetPoint("LEFT", self.bar, "LEFT", p3x, 0)
            self.plusThreeLine:Show()
        end
    end

    --- Called every tick to update the countdown and bar fill.
    function frame:UpdateTimer(elapsed, timeLimit)
        if not timeLimit or timeLimit <= 0 then return end
        self.timeLimit = timeLimit
        local remaining = timeLimit - elapsed
        local progress  = math.min(elapsed / timeLimit, 1.0)

        self.bar:SetProgress(progress)
        self.bar:SetTimerColor(1 - progress)

        if remaining >= 0 then
            self.timerText:SetText(MP:FormatTime(remaining))
            self.timerText:SetTextColor(0.95, 0.95, 0.95)
        else
            self.timerText:SetText("-" .. MP:FormatTime(math.abs(remaining)))
            self.timerText:SetTextColor(1.0, 0.25, 0.25)
        end
    end

    --- Mark a boss kill position on the bar.
    function frame:MarkBoss(bossIndex, elapsed)
        if not self.timeLimit or self.timeLimit <= 0 then return end
        local marker = self.bossMarkers[bossIndex]
        if marker then
            local barW = self.bar:GetWidth()
            local x = (elapsed / self.timeLimit) * barW
            marker:ClearAllPoints()
            marker:SetPoint("LEFT", self.bar, "LEFT", x, 0)
            marker:SetVertexColor(0.0, 0.8, 1.0, 0.7)
            marker:Show()
        end
    end

    function frame:Reset()
        self.timerText:SetText("00:00")
        self.timerText:SetTextColor(0.95, 0.95, 0.95)
        self.bar:SetProgress(0)
        self.plusTwoLine:Hide()
        self.plusThreeLine:Hide()
        for _, marker in ipairs(self.bossMarkers) do
            marker:Hide()
        end
    end

    return frame
end
