--[[
    MythicPulse - Post-Run Summary Panel
    A standalone window that pops up on CHALLENGE_MODE_COMPLETED with a
    breakdown of the run: time, deaths, boss splits, PB delta.
]]

local _, MP = ...

MP.RunSummary = {}

local PANEL_WIDTH  = 340
local PANEL_HEIGHT = 420   -- generous height: handles 5 bosses + score section
local PADDING      = 12

----------------------------------------------------------------------
-- Panel construction
----------------------------------------------------------------------
local function BuildPanel()
    local f = CreateFrame("Frame", "MythicPulseRunSummary", UIParent, "BackdropTemplate")
    f:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:Hide()

    MP:CreateBackdrop(f, MP.COLORS.bgDark)
    MP:CreateGlow(f, MP.COLORS.borderGlow, 4)

    -- Title
    f.title = f:CreateFontString(nil, "OVERLAY")
    f.title:SetFontObject(MP.Fonts.Title)
    f.title:SetPoint("TOPLEFT", PADDING, -PADDING)
    f.title:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
    f.title:SetText("Run Summary")

    f.subtitle = f:CreateFontString(nil, "OVERLAY")
    f.subtitle:SetFontObject(MP.Fonts.Small)
    f.subtitle:SetPoint("TOPLEFT", f.title, "BOTTOMLEFT", 0, -2)
    f.subtitle:SetTextColor(0.7, 0.7, 0.75)

    -- Close button
    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)

    -- Separator
    local sep = f:CreateTexture(nil, "ARTWORK")
    sep:SetTexture("Interface\\Buttons\\WHITE8x8")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", PADDING, -48)
    sep:SetPoint("TOPRIGHT", -PADDING, -48)
    sep:SetVertexColor(MP.COLORS.border.r, MP.COLORS.border.g, MP.COLORS.border.b, 0.5)

    -- Body (filled in dynamically)
    f.body = CreateFrame("Frame", nil, f)
    f.body:SetPoint("TOPLEFT", PADDING, -54)
    f.body:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
    f.body.lines = {}

    -- Final sync after all visual layers exist (glow and separators).
    MP:ApplyBackdrop(f)

    return f
end

----------------------------------------------------------------------
-- Fill the body with key/value lines
----------------------------------------------------------------------
local function ResetBody(body)
    for _, line in ipairs(body.lines) do
        if line.key then line.key:SetText("") end
        if line.val and line.val.GetFont and line.val:GetFont() then
            line.val:SetText("")
        end
        line:Hide()
    end
end

local function AddLine(body, key, value, valueColor)
    local idx = (body.usedLines or 0) + 1
    body.usedLines = idx

    local line = body.lines[idx]
    if not line then
        line = CreateFrame("Frame", nil, body)
        line:SetHeight(18)
        line:SetPoint("LEFT", 0, 0)
        line:SetPoint("RIGHT", 0, 0)

        line.key = line:CreateFontString(nil, "OVERLAY")
        line.key:SetFontObject(MP.Fonts.Body)
        line.key:SetPoint("LEFT", 0, 0)
        line.key:SetTextColor(0.7, 0.72, 0.8)

        line.val = line:CreateFontString(nil, "OVERLAY")
        line.val:SetFontObject(MP.Fonts.Body)
        line.val:SetPoint("RIGHT", 0, 0)

        body.lines[idx] = line
    end

    line:ClearAllPoints()
    line:SetPoint("LEFT", 0, 0)
    line:SetPoint("RIGHT", 0, 0)
    line:SetPoint("TOP", 0, -(idx - 1) * 18)
    line:Show()

    line.key:SetText(key or "")
    line.val:SetText(value or "")
    if valueColor then
        line.val:SetTextColor(valueColor[1], valueColor[2], valueColor[3])
    else
        line.val:SetTextColor(0.95, 0.95, 0.95)
    end
end

local function AddHeader(body, text)
    local idx = (body.usedLines or 0) + 1
    body.usedLines = idx

    local line = body.lines[idx]
    if not line or not line.headerMode then
        line = CreateFrame("Frame", nil, body)
        line:SetHeight(18)
        line:SetPoint("LEFT", 0, 0)
        line:SetPoint("RIGHT", 0, 0)
        line.headerMode = true

        line.key = line:CreateFontString(nil, "OVERLAY")
        line.key:SetFontObject(MP.Fonts.Header)
        line.key:SetPoint("LEFT", 0, 0)
        line.key:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)

        -- val is unused in headers but ResetBody iterates all lines,
        -- so give it a valid font to prevent "Font not set" errors.
        line.val = line:CreateFontString(nil, "OVERLAY")
        line.val:SetFontObject(MP.Fonts.Small)

        body.lines[idx] = line
    end

    line:ClearAllPoints()
    line:SetPoint("LEFT", 0, 0)
    line:SetPoint("RIGHT", 0, 0)
    line:SetPoint("TOP", 0, -(idx - 1) * 18 - 6)
    line:Show()

    line.key:SetText(text or "")
    line.val:SetText("")
end

----------------------------------------------------------------------
-- Populate from the current run state
----------------------------------------------------------------------
local function PopulateSummary(f, runData)
    f.body.usedLines = 0
    ResetBody(f.body)

    local mapID    = runData.mapID
    local level    = runData.keyLevel or 0
    local elapsed  = runData.elapsed or 0
    local limit    = runData.timeLimit or 0
    local timed    = runData.timed

    local dungeon  = MP.DungeonData and MP.DungeonData:GetByMapID(mapID)
    local name     = (dungeon and dungeon.shortName)
                  or (C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and C_ChallengeMode.GetMapUIInfo(mapID))
                  or "Unknown"

    f.title:SetText(string.format("%s  +%d", name, level))
    if timed then
        f.subtitle:SetText("|cff4dff4dTimed|r  " .. (runData.date or ""))
    else
        f.subtitle:SetText("|cffff5555Depleted|r  " .. (runData.date or ""))
    end

    -- === Time stats ===
    AddHeader(f.body, "Time")
    AddLine(f.body, "Elapsed", MP:FormatTime(elapsed))
    if limit > 0 then
        local delta = limit - elapsed
        local color = delta >= 0 and { 0.30, 1.00, 0.40 } or { 1.00, 0.35, 0.35 }
        AddLine(f.body, "vs +2 Timer",
            (delta >= 0 and "-" or "+") .. MP:FormatTime(math.abs(delta)),
            color)
    end

    -- PB delta
    local history = MP:GetModule("DungeonHistory")
    if history and history.GetPersonalBest then
        local best = history:GetPersonalBest(mapID, level)
        if best and best.elapsed and best.elapsed > 0 then
            local delta = best.elapsed - elapsed
            -- New run is already recorded, so if best == this run, delta == 0
            if delta > 0 then
                AddLine(f.body, "vs Previous PB",
                    "-" .. MP:FormatTime(delta), { 0.30, 1.00, 0.40 })
            elseif delta == 0 then
                AddLine(f.body, "Personal Best!", MP:FormatTime(elapsed), { 1.00, 0.82, 0.00 })
            else
                AddLine(f.body, "vs PB",
                    "+" .. MP:FormatTime(-delta), { 1.00, 0.55, 0.35 })
            end
        else
            AddLine(f.body, "Personal Best", "first timed run", { 1.00, 0.82, 0.00 })
        end
    end

    -- === Deaths ===
    AddHeader(f.body, "Deaths")
    local deaths = runData.deaths or 0
    AddLine(f.body, "Total", tostring(deaths),
        deaths == 0 and { 0.30, 1.00, 0.40 } or { 1.00, 0.35, 0.35 })

    if MP.DungeonData and MP.DungeonData.GetDeathPenalty then
        local penalty = MP.DungeonData:GetDeathPenalty(level) or 5
        local lost    = deaths * penalty
        if lost > 0 then
            AddLine(f.body, "Time Lost", "-" .. MP:FormatTime(lost),
                { 1.00, 0.35, 0.35 })
        end
    end

    -- === Boss splits ===
    if runData.bossSplits and #runData.bossSplits > 0 then
        AddHeader(f.body, "Boss Splits")
        local prev = 0
        for _, split in ipairs(runData.bossSplits) do
            local segment = (split.elapsed or 0) - prev
            AddLine(f.body,
                string.format("Boss %d", split.index or 0),
                string.format("%s  (+%s)",
                    MP:FormatTime(split.elapsed or 0),
                    MP:FormatTime(segment)))
            prev = split.elapsed or 0
        end
    end

    -- === Score prediction ===
    if MP.ScorePredictor and MP.ScorePredictor.PredictRun then
        local pred = MP.ScorePredictor:PredictRun(runData)
        if pred and pred.runScore and pred.runScore > 0 then
            AddHeader(f.body, "Score (estimated)")
            local chestLabel = "Depleted"
            if pred.chestTier == 1 then chestLabel = "Timed (+1)"
            elseif pred.chestTier == 2 then chestLabel = "+2 Chest"
            elseif pred.chestTier == 3 then chestLabel = "+3 Chest"
            end
            AddLine(f.body, "Result", chestLabel,
                pred.timed and { 0.30, 1.00, 0.40 } or { 1.00, 0.40, 0.40 })
            AddLine(f.body, "Run Score", tostring(pred.runScore), { 1.00, 0.85, 0.20 })
            if pred.existingBest then
                AddLine(f.body, "Previous Best", tostring(math.floor(pred.existingBest)),
                    { 0.7, 0.7, 0.75 })
                if pred.delta and pred.delta > 0 then
                    AddLine(f.body, "Estimated Gain", "+" .. pred.delta,
                        { 0.30, 1.00, 0.40 })
                else
                    AddLine(f.body, "Estimated Gain", "0",
                        { 0.6, 0.6, 0.65 })
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function MP.RunSummary:Show(runData)
    if not self.frame then
        self.frame = BuildPanel()
    end
    if not runData then return end
    PopulateSummary(self.frame, runData)
    self.frame:Show()
    self.frame:Raise()
end

function MP.RunSummary:Hide()
    if self.frame then self.frame:Hide() end
end

function MP.RunSummary:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    elseif self.lastRun then
        self:Show(self.lastRun)
    end
end
