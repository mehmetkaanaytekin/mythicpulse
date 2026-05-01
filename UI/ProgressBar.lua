--[[
    MythicPulse - Reusable Progress Bar Widget
    Used for enemy forces, timer bar, and any percentage-based display.
]]

local _, MP = ...

MP.ProgressBarWidget = {}

function MP.ProgressBarWidget:Create(parent, width, height, name)
    local bar = CreateFrame("StatusBar", name, parent)
    bar:SetSize(width, height)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(0)
    bar:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    bar:SetStatusBarColor(0.0, 0.8, 1.0, 1.0)

    -- Background
    bar.bg = bar:CreateTexture(nil, "BACKGROUND")
    bar.bg:SetAllPoints()
    bar.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bar.bg:SetVertexColor(0.1, 0.1, 0.15, 0.9)

    -- Border
    bar.border = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    bar.border:SetPoint("TOPLEFT", -1, 1)
    bar.border:SetPoint("BOTTOMRIGHT", 1, -1)
    bar.border:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    bar.border:SetBackdropBorderColor(0.2, 0.2, 0.3, 0.6)

    -- Spark (glow at the end of the bar)
    bar.spark = bar:CreateTexture(nil, "OVERLAY")
    bar.spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    bar.spark:SetSize(12, height * 2.5)
    bar.spark:SetBlendMode("ADD")
    bar.spark:SetAlpha(0.8)

    -- Text overlay — a dedicated plain Frame at a high frame level so the
    -- center text is NEVER occluded by the StatusBar fill texture or border.
    bar.textOverlay = CreateFrame("Frame", nil, bar)
    bar.textOverlay:SetAllPoints(bar)
    bar.textOverlay:SetFrameLevel(bar:GetFrameLevel() + 10)

    -- Center text (percentage / status) — uses MP.Fonts.Label (16px OUTLINE)
    bar.text = bar.textOverlay:CreateFontString(nil, "OVERLAY")
    bar.text:SetFontObject(MP.Fonts.Label)
    bar.text:SetPoint("CENTER", bar, "CENTER", 0, 0)
    bar.text:SetTextColor(1, 1, 1)
    bar.text:SetJustifyH("CENTER")
    bar.text:SetJustifyV("MIDDLE")

    -- Left text
    bar.leftText = bar.textOverlay:CreateFontString(nil, "OVERLAY")
    bar.leftText:SetFontObject(MP.Fonts.Small)
    bar.leftText:SetPoint("LEFT", bar, "LEFT", 4, 0)
    bar.leftText:SetTextColor(0.7, 0.7, 0.7)

    -- Right text
    bar.rightText = bar.textOverlay:CreateFontString(nil, "OVERLAY")
    bar.rightText:SetFontObject(MP.Fonts.Small)
    bar.rightText:SetPoint("RIGHT", bar, "RIGHT", -4, 0)
    bar.rightText:SetTextColor(0.7, 0.7, 0.7)

    local function ApplyVisual(value)
        value = math.max(0, math.min(1, value))
        bar:SetValue(value)
        bar._displayValue = value
        -- Position spark
        local barWidth = bar:GetWidth()
        bar.spark:SetPoint("CENTER", bar, "LEFT", barWidth * value, 0)
        bar.spark:SetAlpha(value > 0 and value < 1 and 0.8 or 0)
    end

    bar._displayValue = 0
    bar._targetValue = 0
    bar._animStartValue = 0
    bar._animElapsed = 0
    bar._animDuration = 0
    bar._animDriver = CreateFrame("Frame", nil, bar)
    bar._animDriver:Hide()
    bar._animDriver:SetScript("OnUpdate", function(_, dt)
        if bar._animDuration <= 0 then
            ApplyVisual(bar._targetValue)
            bar._animDriver:Hide()
            return
        end
        bar._animElapsed = bar._animElapsed + dt
        local t = math.min(bar._animElapsed / bar._animDuration, 1)
        local value = bar._animStartValue + (bar._targetValue - bar._animStartValue) * t
        ApplyVisual(value)
        if t >= 1 then
            bar._animDriver:Hide()
        end
    end)

    --- Set progress immediately (0.0 to 1.0)
    function bar:SetProgress(value)
        value = math.max(0, math.min(1, value))
        self._targetValue = value
        self._animDriver:Hide()
        ApplyVisual(value)
    end

    --- Set progress with short interpolation (0.0 to 1.0)
    function bar:SetProgressAnimated(value, duration)
        value = math.max(0, math.min(1, value))
        duration = duration or 0.2
        if duration <= 0 then
            self:SetProgress(value)
            return
        end
        self._animStartValue = self._displayValue or 0
        self._targetValue = value
        self._animElapsed = 0
        self._animDuration = duration
        self._animDriver:Show()
    end

    -- 5-stop color gradient helper (progress bar: red -> orange -> yellow -> lime -> green)
    local PROGRESS_STOPS = {
        { 0.00, 1.00, 0.20, 0.20 }, -- red
        { 0.25, 1.00, 0.55, 0.10 }, -- orange
        { 0.50, 1.00, 0.92, 0.10 }, -- yellow
        { 0.75, 0.60, 0.95, 0.25 }, -- lime
        { 1.00, 0.20, 1.00, 0.35 }, -- green
    }

    local function LerpStops(t, stops)
        if t <= stops[1][1] then
            return stops[1][2], stops[1][3], stops[1][4]
        end
        if t >= stops[#stops][1] then
            return stops[#stops][2], stops[#stops][3], stops[#stops][4]
        end
        for i = 1, #stops - 1 do
            local a, b = stops[i], stops[i + 1]
            if t >= a[1] and t <= b[1] then
                local u = (t - a[1]) / (b[1] - a[1])
                return a[2] + (b[2] - a[2]) * u,
                       a[3] + (b[3] - a[3]) * u,
                       a[4] + (b[4] - a[4]) * u
            end
        end
    end

    --- Set color based on percentage (red -> orange -> yellow -> lime -> green)
    function bar:SetProgressColor(value)
        local r, g, b = LerpStops(value, PROGRESS_STOPS)
        self:SetStatusBarColor(r, g, b, 1.0)
    end

    --- Set a vertical pace marker at the given fraction (0..1).
    --- Pass nil to hide the marker.
    function bar:SetPaceMarker(frac)
        if not self.paceMarker then
            self.paceMarker = self:CreateTexture(nil, "OVERLAY")
            self.paceMarker:SetTexture("Interface\\Buttons\\WHITE8x8")
            self.paceMarker:SetVertexColor(1, 1, 1, 0.85)
            self.paceMarker:SetSize(2, self:GetHeight() + 4)
        end
        if not frac then
            self.paceMarker:Hide()
            return
        end
        frac = math.max(0, math.min(1, frac))
        local w = self:GetWidth()
        self.paceMarker:ClearAllPoints()
        self.paceMarker:SetPoint("CENTER", self, "LEFT", w * frac, 0)
        self.paceMarker:Show()
    end

    --- Set inverted color based on REMAINING value (1 = just started/green, 0 = time up/red).
    --- Uses the same 5-stop gradient as SetProgressColor so both bars share the palette.
    function bar:SetTimerColor(value)
        local r, g, b = LerpStops(value, PROGRESS_STOPS)
        self:SetStatusBarColor(r, g, b, 1.0)
    end

    return bar
end
