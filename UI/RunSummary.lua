--[[
    MythicPulse - Run Summary v2
    Card-based end-of-run panel: tier-themed hero banner, time performance bar,
    deaths/casualties, boss splits with raid-marker icons, animated score card,
    and a footer with Close / Copy to Chat / Open History.
]]

local _, MP = ...

MP.RunSummary = {}

----------------------------------------------------------------------
-- Layout constants
----------------------------------------------------------------------
local PANEL_WIDTH = 396
local PADDING     = 14
local CARD_GAP    = 10
local CARD_PAD    = 10
local HERO_H      = 116
local SPLIT_ROW_H = 22
local COL_W       = math.floor((PANEL_WIDTH - PADDING * 2 - CARD_PAD * 2) / 3)

----------------------------------------------------------------------
-- Tier themes
----------------------------------------------------------------------
local TIER_THEME = {
    [3] = {
        name = "+3 CHEST",
        bg   = { r=0.18, g=0.14, b=0.04, a=0.92 },
        bd   = { r=1.00, g=0.82, b=0.10, a=0.85 },
        glow = { r=1.00, g=0.82, b=0.10, a=0.30 },
        tierColor = { 1.00, 0.85, 0.20 },
    },
    [2] = {
        name = "+2 CHEST",
        bg   = { r=0.13, g=0.13, b=0.16, a=0.92 },
        bd   = { r=0.78, g=0.80, b=0.86, a=0.75 },
        glow = { r=0.78, g=0.80, b=0.86, a=0.20 },
        tierColor = { 0.85, 0.88, 0.95 },
    },
    [1] = {
        name = "+1 TIMED",
        bg   = { r=0.14, g=0.10, b=0.06, a=0.92 },
        bd   = { r=0.82, g=0.55, b=0.30, a=0.75 },
        glow = { r=0.82, g=0.55, b=0.30, a=0.20 },
        tierColor = { 0.95, 0.65, 0.35 },
    },
    [0] = {
        name = "DEPLETED",
        bg   = { r=0.18, g=0.06, b=0.06, a=0.92 },
        bd   = { r=0.85, g=0.20, b=0.20, a=0.75 },
        glow = { r=0.85, g=0.20, b=0.20, a=0.15 },
        tierColor = { 1.00, 0.30, 0.30 },
    },
}
local CHEST_TEXTURE = "Interface\\Challenges\\ChallengeMode-icon-chest"

----------------------------------------------------------------------
-- Helper: animate a number fontstring (ease-out cubic countup)
----------------------------------------------------------------------
local function AnimateNumber(fs, target, duration, formatter)
    formatter = formatter or function(v) return tostring(math.floor(v + 0.5)) end
    duration  = duration or 1.0
    if not fs._mpAnim then
        fs._mpAnim = CreateFrame("Frame", nil, fs:GetParent())
        fs._mpAnim:Hide()
    end
    local driver = fs._mpAnim
    local t = 0
    driver:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        local u = math.min(t / duration, 1.0)
        local eased = 1 - (1 - u) * (1 - u) * (1 - u)
        fs:SetText(formatter(target * eased))
        if u >= 1 then driver:Hide() end
    end)
    fs:SetText(formatter(0))
    t = 0
    driver:Show()
end

----------------------------------------------------------------------
-- Helper: make a card frame with brand header + hairline rule
----------------------------------------------------------------------
local function MakeCard(parent, headerText)
    local c = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    c._mpBgColor     = MP.COLORS.bgDark
    c._mpBorderColor = { r=MP.COLORS.border.r, g=MP.COLORS.border.g, b=MP.COLORS.border.b, a=0.40 }
    MP:ApplyBackdrop(c)

    c.headerText = c:CreateFontString(nil, "OVERLAY")
    c.headerText:SetFontObject(MP.Fonts.Label)
    c.headerText:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
    c.headerText:SetPoint("TOPLEFT", CARD_PAD, -6)
    if headerText then c.headerText:SetText(headerText) end

    c.headerRule = c:CreateTexture(nil, "ARTWORK")
    c.headerRule:SetTexture("Interface\\Buttons\\WHITE8x8")
    c.headerRule:SetHeight(1)
    c.headerRule:SetPoint("LEFT",  c.headerText, "RIGHT", 6, 0)
    c.headerRule:SetPoint("RIGHT", c, "RIGHT", -CARD_PAD, 0)
    c.headerRule:SetVertexColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b, 0.35)

    c.body = CreateFrame("Frame", nil, c)
    c.body:SetPoint("TOPLEFT",  CARD_PAD,  -28)
    c.body:SetPoint("TOPRIGHT", -CARD_PAD, -28)
    return c
end

----------------------------------------------------------------------
-- Helper: small two-line column (label on top, value below)
----------------------------------------------------------------------
local function MakeColumn(parent, labelText)
    local col = CreateFrame("Frame", nil, parent)
    col.lbl = col:CreateFontString(nil, "OVERLAY")
    col.lbl:SetFontObject(MP.Fonts.Small)
    col.lbl:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)
    col.lbl:SetPoint("TOPLEFT", 0, 0)
    col.lbl:SetText(labelText or "")
    col.val = col:CreateFontString(nil, "OVERLAY")
    col.val:SetFontObject(MP.Fonts.Body)
    col.val:SetTextColor(MP.COLORS.textPrimary.r, MP.COLORS.textPrimary.g, MP.COLORS.textPrimary.b)
    col.val:SetPoint("TOPLEFT", 0, -17)
    return col
end

----------------------------------------------------------------------
-- Build the panel (called once, lazily)
----------------------------------------------------------------------
local function BuildPanel()
    local f = CreateFrame("Frame", "MythicPulseRunSummary", UIParent, "BackdropTemplate")
    f:SetWidth(PANEL_WIDTH)
    f:SetHeight(300)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if not MP.db or not MP.db.locked then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if MP.db then
            local point, _, relPoint, x, y = self:GetPoint()
            MP.db.runSummary = MP.db.runSummary or {}
            MP.db.runSummary.point    = point
            MP.db.runSummary.relPoint = relPoint
            MP.db.runSummary.x        = x
            MP.db.runSummary.y        = y
        end
    end)
    f:Hide()

    if MP.db and MP.db.runSummary and MP.db.runSummary.point then
        local rs = MP.db.runSummary
        f:ClearAllPoints()
        f:SetPoint(rs.point, UIParent, rs.relPoint or rs.point, rs.x or 0, rs.y or 0)
    end

    MP:CreateBackdrop(f, MP.COLORS.bgDark)
    MP:CreateGlow(f, MP.COLORS.borderGlow, 4)

    -- Chrome title
    f.titleText = f:CreateFontString(nil, "OVERLAY")
    f.titleText:SetFontObject(MP.Fonts.Header)
    f.titleText:SetTextColor(MP.COLORS.brand.r, MP.COLORS.brand.g, MP.COLORS.brand.b)
    f.titleText:SetPoint("TOPLEFT", PADDING, -PADDING)
    f.titleText:SetText("|TInterface\\Icons\\inv_relics_hourglass:18|t  RUN SUMMARY")

    f.close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    f.close:SetPoint("TOPRIGHT", -4, -4)

    local titleSep = f:CreateTexture(nil, "ARTWORK")
    titleSep:SetTexture("Interface\\Buttons\\WHITE8x8")
    titleSep:SetHeight(1)
    titleSep:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  -(PADDING + 20 + 8))
    titleSep:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, -(PADDING + 20 + 8))
    titleSep:SetVertexColor(MP.COLORS.border.r, MP.COLORS.border.g, MP.COLORS.border.b, 0.5)

    local chromeH = PADDING + 20 + 8 + 1 + 8  -- title + sep + gap

    -- ── Hero result card (Card 0, no standard header) ─────────────────
    local hero = CreateFrame("Frame", nil, f, "BackdropTemplate")
    hero:SetHeight(HERO_H)
    hero:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  -chromeH)
    hero:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, -chromeH)
    f.hero = hero

    -- Glow overlay (ADD blend, horizontal gradient from theme color to transparent)
    hero.glowOverlay = hero:CreateTexture(nil, "ARTWORK", nil, -1)
    hero.glowOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    hero.glowOverlay:SetBlendMode("ADD")
    hero.glowOverlay:SetPoint("TOPLEFT",     hero, "TOPLEFT",     1, -1)
    hero.glowOverlay:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -1, 1)

    -- Chest icon
    hero.chestIcon = hero:CreateTexture(nil, "ARTWORK")
    hero.chestIcon:SetSize(52, 52)
    hero.chestIcon:SetPoint("TOPLEFT", CARD_PAD, -CARD_PAD)
    hero.chestIcon:SetTexture(CHEST_TEXTURE)

    -- Spark behind chest for focal glow
    hero.chestSpark = hero:CreateTexture(nil, "OVERLAY")
    hero.chestSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    hero.chestSpark:SetBlendMode("ADD")
    hero.chestSpark:SetSize(96, 64)
    hero.chestSpark:SetPoint("CENTER", hero.chestIcon, "CENTER", 4, 0)

    -- Tier text ("+3 CHEST" etc.)
    hero.tierText = hero:CreateFontString(nil, "OVERLAY")
    hero.tierText:SetFontObject(MP.Fonts.Title)
    hero.tierText:SetPoint("TOPLEFT", hero.chestIcon, "TOPRIGHT", 10, -4)

    -- Dungeon name + key level
    hero.nameText = hero:CreateFontString(nil, "OVERLAY")
    hero.nameText:SetFontObject(MP.Fonts.Header)
    hero.nameText:SetPoint("TOPLEFT", hero.tierText, "BOTTOMLEFT", 0, -4)
    hero.nameText:SetTextColor(0.95, 0.95, 0.95)

    -- Delta pill (timed/depleted + time delta)
    hero.deltaPill = CreateFrame("Frame", nil, hero, "BackdropTemplate")
    hero.deltaPill:SetSize(140, 20)
    hero.deltaPill:SetPoint("TOPLEFT", hero.nameText, "BOTTOMLEFT", 0, -6)
    hero.deltaPillText = hero.deltaPill:CreateFontString(nil, "OVERLAY")
    hero.deltaPillText:SetFontObject(MP.Fonts.Small)
    hero.deltaPillText:SetPoint("CENTER", 0, 0)

    -- Affix row (bottom of hero card)
    hero.affixRow = CreateFrame("Frame", nil, hero)
    hero.affixRow:SetHeight(20)
    hero.affixRow:SetPoint("BOTTOMLEFT",  hero, "BOTTOMLEFT",  CARD_PAD, CARD_PAD)
    hero.affixRow:SetPoint("BOTTOMRIGHT", hero, "BOTTOMRIGHT", -CARD_PAD, CARD_PAD)
    hero.affixIcons = {}
    for i = 1, 4 do
        local tex = hero.affixRow:CreateTexture(nil, "ARTWORK")
        tex:SetSize(16, 16)
        tex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if i == 1 then
            tex:SetPoint("LEFT", hero.affixRow, "LEFT", 0, 0)
        else
            tex:SetPoint("LEFT", hero.affixIcons[i-1], "RIGHT", 4, 0)
        end
        tex:Hide()
        hero.affixIcons[i] = tex
    end
    -- Affix name labels (inline after each icon, hidden by default)
    hero.affixNames = {}
    for i = 1, 4 do
        local lbl = hero.affixRow:CreateFontString(nil, "OVERLAY")
        lbl:SetFontObject(MP.Fonts.Small)
        lbl:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
        lbl:Hide()
        hero.affixNames[i] = lbl
    end

    -- ── Card 1: TIME PERFORMANCE ───────────────────────────────────────
    local timeCard = MakeCard(f, "TIME PERFORMANCE")
    timeCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  0)  -- y set in layout
    timeCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, 0)
    f.timeCard = timeCard

    -- Progress bar (spans card body width, height 18)
    local timeBar = MP.ProgressBarWidget:Create(timeCard.body, 300, 18, "MythicPulseRunSummaryTimeBar")
    timeBar:SetPoint("TOPLEFT",  timeCard.body, "TOPLEFT",  0, 0)
    timeBar:SetPoint("TOPRIGHT", timeCard.body, "TOPRIGHT", 0, 0)
    timeCard.timeBar = timeBar

    -- +3 threshold marker (gold, at 60%)
    timeCard.plus3Line = timeBar:CreateTexture(nil, "OVERLAY")
    timeCard.plus3Line:SetTexture("Interface\\Buttons\\WHITE8x8")
    timeCard.plus3Line:SetSize(2, 18)
    timeCard.plus3Line:SetVertexColor(1.0, 0.85, 0.0, 0.9)
    timeCard.plus3Line:Hide()

    -- Three columns under the bar
    timeCard.colElapsed = MakeColumn(timeCard.body, "ELAPSED")
    timeCard.colElapsed:SetPoint("TOPLEFT", timeBar, "BOTTOMLEFT", 0, -8)
    timeCard.colElapsed:SetWidth(COL_W)

    timeCard.colVs2 = MakeColumn(timeCard.body, "vs +2 TIMER")
    timeCard.colVs2:SetPoint("LEFT", timeCard.colElapsed, "RIGHT", 0, 0)
    timeCard.colVs2:SetWidth(COL_W)

    timeCard.colPB = MakeColumn(timeCard.body, "vs PB")
    timeCard.colPB:SetPoint("LEFT", timeCard.colVs2, "RIGHT", 0, 0)
    timeCard.colPB:SetWidth(COL_W)

    -- Card height: 28 (header) + 18 (bar) + 8 (gap) + 35 (2 text rows) + CARD_PAD
    timeCard:SetHeight(28 + 18 + 8 + 34 + CARD_PAD)
    timeCard.body:SetHeight(18 + 8 + 34)

    -- ── Card 2: DEATHS | CASUALTIES ────────────────────────────────────
    local deathCard = MakeCard(f, "DEATHS  |  CASUALTIES")
    deathCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  0)
    deathCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, 0)
    f.deathCard = deathCard

    deathCard.deathOverlay = deathCard.body:CreateTexture(nil, "ARTWORK", nil, -1)
    deathCard.deathOverlay:SetTexture("Interface\\Buttons\\WHITE8x8")
    deathCard.deathOverlay:SetBlendMode("ADD")
    deathCard.deathOverlay:SetAllPoints(deathCard.body)
    deathCard.deathOverlay:SetVertexColor(1.0, 0.25, 0.25, 0.0)

    local SKULL = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:22:22:0:-1|t "
    deathCard.deathCount = deathCard.body:CreateFontString(nil, "OVERLAY")
    deathCard.deathCount:SetFontObject(MP.Fonts.Number)
    deathCard.deathCount:SetPoint("TOPLEFT", 0, 0)

    deathCard.colTimeLost = MakeColumn(deathCard.body, "TIME LOST")
    deathCard.colTimeLost:SetPoint("LEFT", deathCard.deathCount, "RIGHT", 24, 0)

    deathCard.hintText = deathCard.body:CreateFontString(nil, "OVERLAY")
    deathCard.hintText:SetFontObject(MP.Fonts.Small)
    deathCard.hintText:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)
    deathCard.hintText:SetPoint("TOPRIGHT", deathCard.body, "TOPRIGHT", 0, 0)
    deathCard.hintText:SetText("Minimize\nAvoidable!")
    deathCard.hintText:SetJustifyH("RIGHT")

    deathCard._skullPrefix = SKULL
    deathCard:SetHeight(28 + 36 + CARD_PAD)
    deathCard.body:SetHeight(36)

    -- ── Card 3: BOSS SPLITS ─────────────────────────────────────────────
    local splitsCard = MakeCard(f, "BOSS SPLITS")
    splitsCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  0)
    splitsCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, 0)
    f.splitsCard = splitsCard
    splitsCard.rows = {}

    -- ── Card 4: SCORE | RATING SUMMARY ────────────────────────────────
    local scoreCard = MakeCard(f, "SCORE  |  RATING SUMMARY")
    scoreCard:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  0)
    scoreCard:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, 0)
    f.scoreCard = scoreCard

    scoreCard.colRunScore = MakeColumn(scoreCard.body, "RUN SCORE")
    scoreCard.colRunScore:SetPoint("TOPLEFT", scoreCard.body, "TOPLEFT", 0, 0)
    scoreCard.colRunScore:SetWidth(COL_W)
    -- Override val font to Number for the big score
    scoreCard.colRunScore.val:SetFontObject(MP.Fonts.Number)
    scoreCard.colRunScore.val:SetTextColor(MP.COLORS.warning.r, MP.COLORS.warning.g, MP.COLORS.warning.b)

    scoreCard.colPrevBest = MakeColumn(scoreCard.body, "PREVIOUS BEST")
    scoreCard.colPrevBest:SetPoint("LEFT", scoreCard.colRunScore, "RIGHT", 0, 0)
    scoreCard.colPrevBest:SetWidth(COL_W)

    scoreCard.colGain = MakeColumn(scoreCard.body, "EST. GAIN")
    scoreCard.colGain:SetPoint("LEFT", scoreCard.colPrevBest, "RIGHT", 0, 0)
    scoreCard.colGain:SetWidth(COL_W)

    scoreCard:SetHeight(28 + 50 + CARD_PAD)
    scoreCard.body:SetHeight(50)

    -- ── Footer ─────────────────────────────────────────────────────────
    local footer = CreateFrame("Frame", nil, f)
    footer:SetHeight(36)
    footer:SetPoint("BOTTOMLEFT",  f, "BOTTOMLEFT",  PADDING,  PADDING)
    footer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -PADDING, PADDING)
    f.footer = footer

    local btnW = math.floor((PANEL_WIDTH - PADDING * 2 - 8) / 3)

    local btnClose = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    btnClose:SetSize(btnW, 24)
    btnClose:SetPoint("LEFT", footer, "LEFT", 0, 0)
    btnClose:SetText("Close")
    btnClose:SetScript("OnClick", function() MP.RunSummary:Hide() end)
    f.btnClose = btnClose

    local btnCopy = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
    btnCopy:SetSize(btnW, 24)
    btnCopy:SetPoint("CENTER", footer, "CENTER", 0, 0)
    btnCopy:SetText("Copy to Chat")
    btnCopy:SetScript("OnClick", function()
        local rd = MP.RunSummary.lastRun
        if not rd then return end
        local pred = MP.ScorePredictor and MP.ScorePredictor.PredictRun and MP.ScorePredictor:PredictRun(rd)
        local tstr = rd.timed and "TIMED" or "DEPLETED"
        local delta = rd.timeLimit > 0 and (rd.timeLimit - rd.elapsed) or 0
        local dSign = delta >= 0 and "-" or "+"
        local msg = string.format("[MythicPulse] %s +%d - %s in %s (%s%s) - %d death%s - score ~%d",
            rd.dungeonName or "?",
            rd.keyLevel or 0,
            tstr,
            MP:FormatTime(rd.elapsed),
            dSign, MP:FormatTime(math.abs(delta)),
            rd.deaths or 0,
            (rd.deaths or 0) == 1 and "" or "s",
            pred and pred.runScore or 0
        )
        local channel = "SAY"
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            channel = "INSTANCE_CHAT"
        elseif IsInGroup() then
            channel = "PARTY"
        end
        SendChatMessage(msg, channel)
    end)
    f.btnCopy = btnCopy

    local histMod = MP:GetModule("DungeonHistory")
    if histMod and histMod.ShowSummary then
        local btnHist = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
        btnHist:SetSize(btnW, 24)
        btnHist:SetPoint("RIGHT", footer, "RIGHT", 0, 0)
        btnHist:SetText("Open History")
        btnHist:SetScript("OnClick", function()
            local h = MP:GetModule("DungeonHistory")
            if h and h.ShowSummary then h:ShowSummary() end
        end)
        f.btnHist = btnHist
    end

    MP:ApplyBackdrop(f)
    return f
end

----------------------------------------------------------------------
-- Layout cards vertically, resize panel
----------------------------------------------------------------------
local function LayoutPanel(f)
    local chromeH = PADDING + 20 + 8 + 1 + 8
    local y = chromeH + HERO_H + CARD_GAP

    local cards = { f.timeCard, f.deathCard, f.splitsCard, f.scoreCard }
    for _, card in ipairs(cards) do
        if card:IsShown() then
            card:ClearAllPoints()
            card:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  -y)
            card:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, -y)
            y = y + card:GetHeight() + CARD_GAP
        end
    end

    -- Also re-anchor the hero card (its y is fixed)
    f.hero:ClearAllPoints()
    local heroY = chromeH
    f.hero:SetPoint("TOPLEFT",  f, "TOPLEFT",  PADDING,  -heroY)
    f.hero:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PADDING, -heroY)

    local footerH = 36 + PADDING
    f:SetHeight(y + footerH)
end

----------------------------------------------------------------------
-- Populate hero card
----------------------------------------------------------------------
local function PopulateHero(f, runData, pred)
    local hero = f.hero
    local tier = (pred and pred.chestTier) or (runData.timed and 1 or 0)
    local theme = TIER_THEME[tier] or TIER_THEME[0]

    -- Apply tier-themed backdrop
    hero._mpBgColor     = theme.bg
    hero._mpBorderColor = theme.bd
    MP:ApplyBackdrop(hero)

    -- Glow overlay
    local g = theme.glow
    if hero.glowOverlay.SetGradient then
        pcall(function()
            hero.glowOverlay:SetGradient("HORIZONTAL",
                CreateColor(g.r, g.g, g.b, g.a),
                CreateColor(g.r, g.g, g.b, 0))
        end)
    else
        hero.glowOverlay:SetVertexColor(g.r, g.g, g.b, g.a)
    end

    -- Chest icon
    local tc = theme.tierColor
    if tier > 0 then
        hero.chestIcon:SetTexture(CHEST_TEXTURE)
        if hero.chestIcon:GetTexture() then
            hero.chestIcon:SetVertexColor(tc[1], tc[2], tc[3])
            hero.chestSpark:SetVertexColor(tc[1], tc[2], tc[3])
            hero.chestSpark:SetAlpha(0.45)
            hero.chestIcon:Show()
            hero.chestSpark:Show()
        else
            hero.chestIcon:Hide()
            hero.chestSpark:Hide()
        end
    else
        hero.chestIcon:Hide()
        hero.chestSpark:Hide()
    end

    -- Tier text
    hero.tierText:SetText(theme.name)
    hero.tierText:SetTextColor(tc[1], tc[2], tc[3])

    -- Dungeon name + level
    local dname = runData.dungeonName
    if not dname or dname == "" then
        local dungeon = MP.DungeonData and MP.DungeonData:GetByMapID(runData.mapID)
        dname = (dungeon and dungeon.shortName)
             or (C_ChallengeMode and C_ChallengeMode.GetMapUIInfo and
                 C_ChallengeMode.GetMapUIInfo(runData.mapID))
             or "Unknown"
    end
    hero.nameText:SetText(string.format("%s  +%d", dname, runData.keyLevel or 0))

    -- Delta pill
    local limit   = runData.timeLimit or 0
    local elapsed = runData.elapsed   or 0
    local delta   = limit - elapsed
    local pillBg, pillBd, pillText
    if runData.timed then
        pillBg   = { r=0.05, g=0.20, b=0.08, a=0.85 }
        pillBd   = { r=0.30, g=1.00, b=0.40, a=0.60 }
        pillText = string.format("|cff4dff4dTIMED  -%s|r", MP:FormatTime(math.abs(delta)))
    else
        pillBg   = { r=0.20, g=0.05, b=0.05, a=0.85 }
        pillBd   = { r=1.00, g=0.25, b=0.25, a=0.60 }
        pillText = string.format("|cffff4040DEPLETED  +%s|r", MP:FormatTime(math.abs(delta)))
    end
    hero.deltaPill._mpBgColor     = pillBg
    hero.deltaPill._mpBorderColor = pillBd
    MP:ApplyBackdrop(hero.deltaPill)
    hero.deltaPillText:SetText(pillText)

    -- Affix row — icons only, chain-anchored; names hidden (available for tooltips)
    local affixes    = runData.affixes
    local affixShown = 0
    for i = 1, 4 do
        hero.affixIcons[i]:Hide()
        if hero.affixNames[i] then hero.affixNames[i]:Hide() end
    end
    if affixes and #affixes > 0 then
        local lastIcon = nil
        for i = 1, math.min(#affixes, 4) do
            local id   = affixes[i]
            local info = C_ChallengeMode and C_ChallengeMode.GetAffixInfo and C_ChallengeMode.GetAffixInfo(id)
            local fid  = type(info) == "table" and info.filedataid
            local icon = hero.affixIcons[i]
            if fid then
                icon:SetTexture(fid)
                if lastIcon then
                    icon:ClearAllPoints()
                    icon:SetPoint("LEFT", lastIcon, "RIGHT", 6, 0)
                else
                    icon:ClearAllPoints()
                    icon:SetPoint("LEFT", hero.affixRow, "LEFT", 0, 0)
                end
                icon:Show()
                lastIcon    = icon
                affixShown  = affixShown + 1
            end
        end
    end
    if affixShown > 0 then
        hero.affixRow:Show()
    else
        hero.affixRow:Hide()
    end
    hero.deltaPill:ClearAllPoints()
    hero.deltaPill:SetPoint("TOPLEFT", hero.nameText, "BOTTOMLEFT", 0, -6)
end

----------------------------------------------------------------------
-- Populate time performance card
----------------------------------------------------------------------
local function PopulateTimeCard(f, runData)
    local tc     = f.timeCard
    local bar    = tc.timeBar
    local elapsed = runData.elapsed   or 0
    local limit   = runData.timeLimit or 0
    local ratio   = limit > 0 and math.min(elapsed / limit, 1.0) or 0

    -- Color and text
    bar:SetTimerColor(1 - ratio)
    bar.text:SetText(MP:FormatTime(elapsed) .. "  /  " .. MP:FormatTime(limit))

    local cfg = MP.db and MP.db.modules and MP.db.modules.runSummary
    local doAnim = not cfg or cfg.animate ~= false

    if doAnim then
        bar:SetProgress(0)
        C_Timer.After(0.05, function()
            if bar and bar.SetProgressAnimated then
                bar:SetProgressAnimated(ratio, 0.6)
            end
        end)
    else
        bar:SetProgress(ratio)
    end

    -- Position +3 marker at 60% and +2 marker (SetPaceMarker) at 80%
    C_Timer.After(0.1, function()
        local barW = bar:GetWidth()
        if not barW or barW < 4 then barW = 300 end
        local p3x = 0.60 * barW
        if limit > 0 then
            tc.plus3Line:ClearAllPoints()
            tc.plus3Line:SetPoint("LEFT", bar, "LEFT", p3x, 0)
            tc.plus3Line:Show()
            bar:SetPaceMarker(0.80)
        else
            tc.plus3Line:Hide()
            bar:SetPaceMarker(nil)
        end
    end)

    -- Columns
    tc.colElapsed.val:SetText(MP:FormatTime(elapsed))
    tc.colElapsed.val:SetTextColor(0.95, 0.95, 0.95)

    if limit > 0 then
        local d2 = limit - elapsed
        local vs2 = (d2 >= 0 and "-" or "+") .. MP:FormatTime(math.abs(d2))
        tc.colVs2.val:SetText(vs2)
        if d2 >= 0 then
            tc.colVs2.val:SetTextColor(MP.COLORS.good.r, MP.COLORS.good.g, MP.COLORS.good.b)
        else
            tc.colVs2.val:SetTextColor(MP.COLORS.danger.r, MP.COLORS.danger.g, MP.COLORS.danger.b)
        end
    else
        tc.colVs2.val:SetText("--")
        tc.colVs2.val:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)
    end

    local history = MP:GetModule("DungeonHistory")
    if history and history.GetPersonalBest then
        local best = history:GetPersonalBest(runData.mapID, runData.keyLevel)
        if best and best.elapsed and best.elapsed > 0 then
            local dpb = best.elapsed - elapsed
            local pbStr = (dpb > 0 and "-" or "+") .. MP:FormatTime(math.abs(dpb))
            tc.colPB.val:SetText(pbStr)
            if dpb > 0 then
                tc.colPB.val:SetTextColor(MP.COLORS.good.r, MP.COLORS.good.g, MP.COLORS.good.b)
            elseif dpb < 0 then
                tc.colPB.val:SetTextColor(MP.COLORS.danger.r, MP.COLORS.danger.g, MP.COLORS.danger.b)
            else
                tc.colPB.val:SetTextColor(MP.COLORS.warning.r, MP.COLORS.warning.g, MP.COLORS.warning.b)
            end
        else
            tc.colPB.val:SetText("1st run!")
            tc.colPB.val:SetTextColor(MP.COLORS.warning.r, MP.COLORS.warning.g, MP.COLORS.warning.b)
        end
    else
        tc.colPB.val:SetText("--")
        tc.colPB.val:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)
    end
end

----------------------------------------------------------------------
-- Populate deaths card
----------------------------------------------------------------------
local function PopulateDeathCard(f, runData)
    local dc     = f.deathCard
    local deaths = runData.deaths or 0

    local skull = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:22:22:0:-1|t "
    if deaths == 0 then
        dc.deathCount:SetText(skull .. "|cff4dff4d0|r")
        dc.deathOverlay:SetVertexColor(1.0, 0.25, 0.25, 0.0)
        dc.colTimeLost.lbl:Hide()
        dc.colTimeLost.val:Hide()
        dc.hintText:Hide()
    else
        dc.deathCount:SetText(skull .. string.format("|cffff4040%d|r", deaths))
        dc.deathOverlay:SetVertexColor(1.0, 0.25, 0.25, 0.06)

        local penalty = runData.deathPenalty
        if not penalty then
            penalty = MP.DungeonData and MP.DungeonData:GetDeathPenalty(runData.keyLevel) or 5
        end
        local lost = deaths * penalty
        dc.colTimeLost.lbl:SetText("TIME LOST")
        dc.colTimeLost.lbl:Show()
        dc.colTimeLost.val:SetText("+" .. MP:FormatTime(lost))
        dc.colTimeLost.val:SetTextColor(MP.COLORS.danger.r, MP.COLORS.danger.g, MP.COLORS.danger.b)
        dc.colTimeLost.val:Show()
        dc.hintText:Show()
    end
end

----------------------------------------------------------------------
-- Populate boss splits card
----------------------------------------------------------------------
local function PopulateSplitsCard(f, runData)
    local sc    = f.splitsCard
    local splits = runData.bossSplits
    if not splits or #splits == 0 then
        sc:Hide()
        return
    end
    sc:Show()

    -- Pre-compute segments
    local segs = {}
    local minSeg, minSegIdx = math.huge, 1
    for i, split in ipairs(splits) do
        local prev = splits[i-1]
        segs[i] = split.elapsed - (prev and prev.elapsed or 0)
        if segs[i] < minSeg then
            minSeg    = segs[i]
            minSegIdx = i
        end
    end

    -- PB boss splits for comparison
    local pbSplits = nil
    local history  = MP:GetModule("DungeonHistory")
    if history and history.GetPersonalBest then
        local pb = history:GetPersonalBest(runData.mapID, runData.keyLevel)
        if pb and pb.bossSplits then
            local pbSegs = {}
            for i, ps in ipairs(pb.bossSplits) do
                local pp = pb.bossSplits[i-1]
                pbSegs[i] = ps.elapsed - (pp and pp.elapsed or 0)
            end
            pbSplits = pbSegs
        end
    end

    local count = #splits
    -- Reuse or create rows
    for i = 1, count do
        local row = sc.rows[i]
        if not row then
            row = CreateFrame("Frame", nil, sc.body)
            row:SetHeight(SPLIT_ROW_H)
            row.marker = row:CreateTexture(nil, "ARTWORK")
            row.marker:SetSize(18, 18)
            row.marker:SetPoint("TOPLEFT", 0, -2)
            row.fastGlow = row:CreateTexture(nil, "ARTWORK", nil, -1)
            row.fastGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
            row.fastGlow:SetBlendMode("ADD")
            row.fastGlow:SetAllPoints(row)
            row.nameText = row:CreateFontString(nil, "OVERLAY")
            row.nameText:SetFontObject(MP.Fonts.Body)
            row.nameText:SetPoint("LEFT", row.marker, "RIGHT", 6, 0)
            row.nameText:SetPoint("RIGHT", row, "RIGHT", -145, 0)
            row.nameText:SetJustifyH("LEFT")
            row.nameText:SetWordWrap(false)
            row.totalText = row:CreateFontString(nil, "OVERLAY")
            row.totalText:SetFontObject(MP.Fonts.Body)
            row.totalText:SetPoint("RIGHT", row, "RIGHT", -70, 0)
            row.segText = row:CreateFontString(nil, "OVERLAY")
            row.segText:SetFontObject(MP.Fonts.Small)
            row.segText:SetPoint("RIGHT", row, "RIGHT", -2, 0)
            sc.rows[i] = row
        end
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT",  sc.body, "TOPLEFT",  0, -(i-1) * SPLIT_ROW_H)
        row:SetPoint("TOPRIGHT", sc.body, "TOPRIGHT", 0, -(i-1) * SPLIT_ROW_H)
        row:Show()

        local split   = splits[i]
        local isFinal = (i == count)
        local markerIdx = math.min(i, 7)
        if isFinal then markerIdx = 8 end
        row.marker:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. markerIdx)

        -- Fastest segment: gold marker + faint gold row glow
        if i == minSegIdx then
            row.marker:SetVertexColor(1.0, 0.85, 0.10, 1.0)
            row.fastGlow:SetVertexColor(1.0, 0.82, 0.10, 0.07)
        else
            row.marker:SetVertexColor(1.0, 1.0, 1.0, 1.0)
            row.fastGlow:SetVertexColor(0, 0, 0, 0)
        end

        local bname = split.name or ("Boss " .. i)
        if isFinal and bname == split.name then bname = split.name end
        row.nameText:SetText(bname)
        row.nameText:SetTextColor(0.95, 0.95, 0.95)

        row.totalText:SetText(MP:FormatTime(split.elapsed))
        row.totalText:SetTextColor(0.95, 0.95, 0.95)

        -- Segment text: colored by PB comparison if available
        local segStr = "(+" .. MP:FormatTime(segs[i]) .. ")"
        if pbSplits and pbSplits[i] then
            local d = segs[i] - pbSplits[i]
            if d < 0 then
                row.segText:SetText(segStr)
                row.segText:SetTextColor(MP.COLORS.good.r, MP.COLORS.good.g, MP.COLORS.good.b)
            elseif d > 0 then
                row.segText:SetText(segStr)
                row.segText:SetTextColor(MP.COLORS.danger.r, MP.COLORS.danger.g, MP.COLORS.danger.b)
            else
                row.segText:SetText(segStr)
                row.segText:SetTextColor(MP.COLORS.warning.r, MP.COLORS.warning.g, MP.COLORS.warning.b)
            end
        else
            row.segText:SetText(segStr)
            row.segText:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
        end
    end

    -- Hide leftover rows from a longer previous run
    for i = count + 1, #sc.rows do
        if sc.rows[i] then sc.rows[i]:Hide() end
    end

    local bodyH = count * SPLIT_ROW_H
    sc.body:SetHeight(bodyH)
    sc:SetHeight(28 + bodyH + CARD_PAD)
end

----------------------------------------------------------------------
-- Populate score card
----------------------------------------------------------------------
local function PopulateScoreCard(f, runData, pred)
    local sc = f.scoreCard

    local runScore    = pred and pred.runScore    or 0
    local existBest   = pred and pred.existingBest
    local delta       = pred and pred.delta

    local cfg    = MP.db and MP.db.modules and MP.db.modules.runSummary
    local doAnim = not cfg or cfg.animate ~= false

    if doAnim and runScore > 0 then
        AnimateNumber(sc.colRunScore.val, runScore, 1.0)
    else
        sc.colRunScore.val:SetText(runScore > 0 and tostring(runScore) or "--")
    end

    if existBest then
        sc.colPrevBest.val:SetText(tostring(math.floor(existBest)))
        sc.colPrevBest.val:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
    else
        sc.colPrevBest.val:SetText("--")
        sc.colPrevBest.val:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)
    end

    if delta and delta > 0 then
        sc.colGain.val:SetText("+" .. tostring(delta))
        sc.colGain.val:SetTextColor(MP.COLORS.good.r, MP.COLORS.good.g, MP.COLORS.good.b)
    elseif delta and delta == 0 then
        sc.colGain.val:SetText("0")
        sc.colGain.val:SetTextColor(MP.COLORS.textSecondary.r, MP.COLORS.textSecondary.g, MP.COLORS.textSecondary.b)
    else
        sc.colGain.val:SetText("--")
        sc.colGain.val:SetTextColor(MP.COLORS.textMuted.r, MP.COLORS.textMuted.g, MP.COLORS.textMuted.b)
    end
end

----------------------------------------------------------------------
-- Full populate
----------------------------------------------------------------------
local function PopulateSummary(f, runData)
    local pred = nil
    if MP.ScorePredictor and MP.ScorePredictor.PredictRun then
        pred = MP.ScorePredictor:PredictRun(runData)
    end

    PopulateHero(f, runData, pred)
    PopulateTimeCard(f, runData)
    PopulateDeathCard(f, runData)
    PopulateSplitsCard(f, runData)
    PopulateScoreCard(f, runData, pred)

    LayoutPanel(f)
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function MP.RunSummary:Show(runData)
    if not self.frame then
        self.frame = BuildPanel()
    end
    if not runData then return end
    self.lastRun = runData
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
