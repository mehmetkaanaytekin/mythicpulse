--[[
    MythicPulse - Timer Bar Widget
    Animated countdown with +2/+3 threshold markers and boss markers.
    Timer text shows "elapsed / total" format.
    +3/+2 labels are rendered inside the progress bar at their marker positions.
]]

local _, MP = ...

MP.TimerBarWidget = {}

function MP.TimerBarWidget:Create(parent, width, height)
    local frame = CreateFrame("Frame", "MythicPulseTimerBar", parent, "BackdropTemplate")
    frame:SetSize(width, height + 46)

    -- Large timer text (top of frame): "elapsed / total"
    frame.timerText = frame:CreateFontString(nil, "OVERLAY")
    frame.timerText:SetFontObject(MP.Fonts.Timer)
    frame.timerText:SetPoint("TOP", 0, 0)
    frame.timerText:SetTextColor(0.95, 0.95, 0.95)
    frame.timerText:SetText("0:00 / 0:00")

    -- Progress bar (bottom of frame) — BOTTOMLEFT+BOTTOMRIGHT so it stretches with the frame
    frame.bar = MP.ProgressBarWidget:Create(frame, width, height, "MythicPulseTimerStatusBar")
    frame.bar:SetPoint("BOTTOMLEFT",  0, 0)
    frame.bar:SetPoint("BOTTOMRIGHT", 0, 0)

    -- +3 threshold marker line (gold)
    frame.plusThreeLine = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.plusThreeLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.plusThreeLine:SetSize(2, height)
    frame.plusThreeLine:SetVertexColor(1.0, 0.85, 0.0, 0.9)
    frame.plusThreeLine:Hide()

    -- +2 threshold marker line (green)
    frame.plusTwoLine = frame.bar:CreateTexture(nil, "OVERLAY")
    frame.plusTwoLine:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.plusTwoLine:SetSize(2, height)
    frame.plusTwoLine:SetVertexColor(0.3, 1.0, 0.4, 0.9)
    frame.plusTwoLine:Hide()

    -- +3 label inside the bar at the marker position
    frame.plusThreeLabel = frame.bar.textOverlay:CreateFontString(nil, "OVERLAY")
    frame.plusThreeLabel:SetFontObject(MP.Fonts.Small)
    frame.plusThreeLabel:SetTextColor(1.0, 0.85, 0.0, 1.0)
    frame.plusThreeLabel:SetText(MP:Loc("TIMER_PLUS_THREE"))
    frame.plusThreeLabel:Hide()

    -- +2 label inside the bar at the marker position
    frame.plusTwoLabel = frame.bar.textOverlay:CreateFontString(nil, "OVERLAY")
    frame.plusTwoLabel:SetFontObject(MP.Fonts.Small)
    frame.plusTwoLabel:SetTextColor(0.3, 1.0, 0.4, 1.0)
    frame.plusTwoLabel:SetText(MP:Loc("TIMER_PLUS_TWO"))
    frame.plusTwoLabel:Hide()

    -- Boss split markers (up to 5) — gold, wider than bar height so they poke out
    frame.bossMarkers = {}
    for i = 1, 5 do
        local marker = frame.bar:CreateTexture(nil, "OVERLAY")
        marker:SetTexture("Interface\\Buttons\\WHITE8x8")
        marker:SetSize(2, height + 10)
        marker:SetBlendMode("ADD")
        marker:SetVertexColor(1.0, 0.85, 0.0, 0.0)
        marker:Hide()
        frame.bossMarkers[i] = marker
    end

    --- Position threshold markers after the time limit is known.
    --- Deferred 0.05s so bar width is finalized after layout.
    function frame:SetTimeLimit(timeLimit)
        self.timeLimit     = timeLimit
        local plusTwo, plusThree = MP.DungeonData:GetTimingThresholds(timeLimit)
        self.plusTwoTime   = plusTwo
        self.plusThreeTime = plusThree

        C_Timer.After(0.05, function()
            local barW = self.bar:GetWidth()
            if not barW or barW <= 4 then barW = 244 end
            if timeLimit > 0 then
                local p3x = math.max(0, (plusThree / timeLimit) * barW)
                self.plusThreeLine:ClearAllPoints()
                self.plusThreeLine:SetPoint("LEFT", self.bar, "LEFT", p3x, 0)
                self.plusThreeLine:Show()
                self.plusThreeLabel:ClearAllPoints()
                self.plusThreeLabel:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT", p3x + 3, 2)
                self.plusThreeLabel:Show()

                local p2x = math.max(0, (plusTwo / timeLimit) * barW)
                self.plusTwoLine:ClearAllPoints()
                self.plusTwoLine:SetPoint("LEFT", self.bar, "LEFT", p2x, 0)
                self.plusTwoLine:Show()
                self.plusTwoLabel:ClearAllPoints()
                self.plusTwoLabel:SetPoint("BOTTOMLEFT", self.bar, "BOTTOMLEFT", p2x + 3, 2)
                self.plusTwoLabel:Show()
            end
        end)
    end

    --- Called every tick to update the countdown and bar fill.
    function frame:UpdateTimer(elapsed, timeLimit)
        if not timeLimit or timeLimit <= 0 then return end
        self.timeLimit   = timeLimit
        local remaining  = timeLimit - elapsed
        local progress   = math.min(math.max(elapsed, 0) / timeLimit, 1.0)

        self.bar:SetProgress(progress)
        self.bar:SetTimerColor(1 - progress)

        local elapsedStr = MP:FormatTime(math.max(0, elapsed))
        local totalStr   = MP:FormatTime(timeLimit)

        if remaining >= 0 then
            self.timerText:SetText(elapsedStr .. " |cff555555/|r " .. totalStr)
            self.timerText:SetTextColor(0.95, 0.95, 0.95)
        else
            local overStr = MP:FormatTime(math.abs(remaining))
            self.timerText:SetText("|cffff4444-" .. overStr .. "|r |cff555555/|r " .. totalStr)
            self.timerText:SetTextColor(1, 1, 1)
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
            marker:SetPoint("CENTER", self.bar, "LEFT", x, 0)
            marker:SetVertexColor(1.0, 0.85, 0.0, 1.0)
            marker:Show()
        end
    end

    function frame:Reset()
        self.timerText:SetText("0:00 / 0:00")
        self.timerText:SetTextColor(0.95, 0.95, 0.95)
        self.bar:SetProgress(0)
        self.plusTwoLine:Hide()
        self.plusThreeLine:Hide()
        self.plusTwoLabel:Hide()
        self.plusThreeLabel:Hide()
        for _, marker in ipairs(self.bossMarkers) do
            marker:Hide()
        end
    end

    return frame
end
