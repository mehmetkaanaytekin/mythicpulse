--[[
    MythicPulse - Combat Res Tracker
    Icon-based Battle Res and Bloodlust status with timers/counters.
]]

local _, MP = ...

local CombatRes = {
    registeredEvents = {
        "UNIT_SPELLCAST_SUCCEEDED",
        "GROUP_ROSTER_UPDATE",
        "UNIT_AURA",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_RESET",
        "CHALLENGE_MODE_COMPLETED",
    },
    active = false,
    casters = {},
    blCasters = {},
}

local BL_CASTER_CD = 300
local SATED_DURATION = 600

local BL_CLASSES = {
    SHAMAN = "certain",
    MAGE = "certain",
    HUNTER = "possible",
}

local BL_SPELL_IDS = {
    [2825] = true,
    [32182] = true,
    [80353] = true,
    [264667] = true,
    [90355] = true,
}

local SATED_IDS = {
    [57724] = true,
    [57723] = true,
    [80354] = true,
    [160455] = true,
    [390435] = true,
}

local BREZ_SPELLS = {
    [20484] = { class = "DRUID", duration = 600 },
    [61999] = { class = "DEATHKNIGHT", duration = 600 },
    [391054] = { class = "PALADIN", duration = 600 },
    [20707] = { class = "WARLOCK", duration = 600 },
}

local BY_CLASS = {}
for spellID, data in pairs(BREZ_SPELLS) do
    BY_CLASS[data.class] = { spellID = spellID, duration = data.duration }
end

local section
local brezIcon
local blIcon
local satedExpiry = 0

local function TryCall(fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then return nil end
    return a, b, c, d
end

local function ShortName(name)
    if not name then return nil end
    return tostring(name):match("^[^-]+")
end

local function SpellTexture(spellID, fallback)
    if C_Spell and C_Spell.GetSpellTexture then
        local icon = C_Spell.GetSpellTexture(spellID)
        if icon then return icon end
    end
    if GetSpellTexture then
        local icon = GetSpellTexture(spellID)
        if icon then return icon end
    end
    return fallback
end

local function CreateStatusIcon(parent, xOffset, spellID, label)
    local size = MP:GetSetting("modules.combatRes.iconSize") or 38
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    frame:SetSize(size, size)
    frame:SetPoint("TOPLEFT", xOffset, -20)
    MP:CreateBackdrop(frame)

    frame.icon = frame:CreateTexture(nil, "ARTWORK")
    frame.icon:SetAllPoints()
    frame.icon:SetTexture(SpellTexture(spellID, 136243))

    frame.countText = frame:CreateFontString(nil, "OVERLAY")
    frame.countText:SetFontObject(MP.Fonts.Body)
    frame.countText:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.countText:SetJustifyH("RIGHT")
    frame.countText:SetText("")

    frame.timerText = frame:CreateFontString(nil, "OVERLAY")
    frame.timerText:SetFontObject(MP.Fonts.Small)
    frame.timerText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 2)
    frame.timerText:SetText("")

    frame.stateText = frame:CreateFontString(nil, "OVERLAY")
    frame.stateText:SetFontObject(MP.Fonts.Small)
    frame.stateText:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    frame.stateText:SetText(label or "")

    return frame
end

local function PaintIcon(iconFrame, opts)
    if not iconFrame then return end
    iconFrame.icon:SetDesaturated(opts.desaturated or false)
    iconFrame.icon:SetVertexColor(opts.r or 1, opts.g or 1, opts.b or 1, opts.a or 1)
    iconFrame.countText:SetText(opts.count or "")
    iconFrame.timerText:SetText(opts.timer or "")
    iconFrame.stateText:SetText(opts.state or "")
    if opts.stateColor then
        local c = opts.stateColor
        iconFrame.stateText:SetTextColor(c[1], c[2], c[3])
    else
        iconFrame.stateText:SetTextColor(0.8, 0.8, 0.8)
    end
end

local function CreateUI()
    local size = MP:GetSetting("modules.combatRes.iconSize") or 38
    local iconGap = 12
    local sectionHeight = size + 38
    section = MP.MainFrame:CreateSection(MP.L["BREZ"] or "Battle Res", sectionHeight)

    brezIcon = CreateStatusIcon(section, 0, 20484, "Battle Res")
    blIcon = CreateStatusIcon(section, size + iconGap, 2825, "Bloodlust")

    MP.MainFrame:AddSection(section)
end

local function ScanForBL()
    local previousCDs = {}
    for _, c in ipairs(CombatRes.blCasters) do
        previousCDs[c.name] = c.cdEnd or 0
    end

    local casters, seen = {}, {}
    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local fullName = UnitName(unit)
        local name = ShortName(fullName)
        if not name or seen[name] then return end
        local _, class = UnitClass(unit)
        local confidence = class and BL_CLASSES[class]
        if not confidence then return end
        seen[name] = true
        casters[#casters + 1] = {
            name = name,
            class = class,
            confidence = confidence,
            cdEnd = previousCDs[name] or 0,
        }
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            addUnit("raid" .. i)
        end
    else
        addUnit("player")
        for i = 1, 4 do
            addUnit("party" .. i)
        end
    end

    CombatRes.blCasters = casters
end

local function PollSatedAura()
    if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID) then return end
    for spellID in pairs(SATED_IDS) do
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellID, "player", spellID, "HARMFUL")
        if ok and aura then
            local exp = aura.expirationTime
            if exp and exp > GetTime() then
                satedExpiry = exp
            elseif satedExpiry <= GetTime() then
                satedExpiry = GetTime() + SATED_DURATION
            end
            return
        end
    end
    satedExpiry = 0
end

local function ApplyBLCooldown(name)
    local short = ShortName(name)
    if not short then return end
    local now = GetTime()
    local applied = false
    for _, c in ipairs(CombatRes.blCasters) do
        if c.name == short then
            c.cdEnd = now + BL_CASTER_CD
            applied = true
            break
        end
    end
    if not applied then
        CombatRes.blCasters[#CombatRes.blCasters + 1] = {
            name = short,
            class = "UNKNOWN",
            confidence = "certain",
            cdEnd = now + BL_CASTER_CD,
        }
    end
end

local function OnBLDetected()
    satedExpiry = GetTime() + SATED_DURATION
end

local function ScanParty()
    local oldByName = {}
    for _, c in ipairs(CombatRes.casters) do
        oldByName[c.name] = c.cdEnd or 0
    end

    local casters = {}
    local seen = {}
    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local name = ShortName(UnitName(unit))
        if not name or seen[name] then return end
        local _, class = UnitClass(unit)
        local entry = class and BY_CLASS[class]
        if not entry then return end
        seen[name] = true
        casters[#casters + 1] = {
            name = name,
            class = class,
            spellID = entry.spellID,
            duration = entry.duration,
            cdEnd = oldByName[name] or 0,
        }
    end

    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            addUnit("raid" .. i)
        end
    else
        addUnit("player")
        for i = 1, 4 do
            addUnit("party" .. i)
        end
    end

    CombatRes.casters = casters
end

local function NormalizeSharedPoolFromValues(a, b, c, d)
    if type(a) ~= "number" or type(b) ~= "number" or b <= 0 then return nil end
    local current = math.max(0, math.min(b, a))
    local nextIn
    if current < b and type(c) == "number" and type(d) == "number" and d > 0 then
        nextIn = math.max(0, (c + d) - GetTime())
    end
    return { current = current, max = b, nextIn = nextIn }
end

local function NormalizeSharedPoolFromTable(info)
    if type(info) ~= "table" then return nil end
    local current = info.charges or info.currentCharges or info.numCharges or info.quantity
    local maxv = info.maxCharges or info.totalCharges or info.maxQuantity
    if type(current) ~= "number" or type(maxv) ~= "number" or maxv <= 0 then
        return nil
    end
    local start = info.cooldownStartTime or info.chargeStartTime or info.startTime
    local dur = info.cooldownDuration or info.chargeDuration or info.duration
    local nextIn
    if current < maxv and type(start) == "number" and type(dur) == "number" and dur > 0 then
        nextIn = math.max(0, (start + dur) - GetTime())
    end
    return { current = math.max(0, math.min(maxv, current)), max = maxv, nextIn = nextIn }
end

local function GetMythicSharedBrezPool()
    if not MP:IsInMythicPlus() then return nil end
    if C_ChallengeMode then
        local a, b, c, d = TryCall(C_ChallengeMode.GetCombatResurrectionCharges)
        local out = NormalizeSharedPoolFromValues(a, b, c, d)
        if out then return out end

        a, b, c, d = TryCall(C_ChallengeMode.GetCombatResurrectionInfo)
        out = NormalizeSharedPoolFromValues(a, b, c, d)
        if out then return out end
    end
    if C_Scenario and C_Scenario.GetSpellInfo then
        for i = 1, 8 do
            local info = TryCall(C_Scenario.GetSpellInfo, i)
            local out = NormalizeSharedPoolFromTable(info)
            if out then return out end
        end
    end
    return nil
end

local function UpdateDisplay()
    if not brezIcon then return end
    local now = GetTime()
    local ready, nextReady = 0, nil
    for _, c in ipairs(CombatRes.casters) do
        if c.cdEnd <= now then
            ready = ready + 1
        else
            local remain = c.cdEnd - now
            if not nextReady or remain < nextReady then
                nextReady = remain
            end
        end
    end

    local total = #CombatRes.casters
    if total == 0 then
        PaintIcon(brezIcon, {
            desaturated = true,
            state = "No brez",
            stateColor = { 0.45, 0.45, 0.45 },
        })
        return
    end

    local sharedPool = GetMythicSharedBrezPool()
    if sharedPool then
        local poolReady = math.floor(sharedPool.current + 0.5)
        local poolMax = math.floor(sharedPool.max + 0.5)
        PaintIcon(brezIcon, {
            desaturated = poolReady <= 0,
            count = string.format("%d/%d", poolReady, poolMax),
            timer = (sharedPool.nextIn and sharedPool.nextIn > 0) and MP:FormatTime(sharedPool.nextIn) or "",
            state = string.format("Ready %d/%d", ready, total),
            stateColor = poolReady > 0 and { 0.3, 1, 0.3 } or { 1, 0.35, 0.35 },
        })
        return
    end

    PaintIcon(brezIcon, {
        desaturated = ready <= 0,
        count = string.format("%d/%d", ready, total),
        timer = (nextReady and nextReady > 0) and MP:FormatTime(nextReady) or "",
        state = ready > 0 and "Available" or "On CD",
        stateColor = ready > 0 and { 0.3, 1, 0.3 } or { 1, 0.35, 0.35 },
    })
end

local function UpdateBLStatus()
    if not blIcon then return end

    local now = GetTime()
    if satedExpiry <= now then
        PollSatedAura()
    end

    local rem = satedExpiry > now and (satedExpiry - now) or 0
    if rem > 1 then
        PaintIcon(blIcon, {
            desaturated = true,
            timer = MP:FormatTime(rem),
            state = "Sated",
            stateColor = { 1, 0.6, 0.2 },
        })
        return
    end

    local certainTotal, certainReady, certainNext = 0, 0, nil
    local possibleTotal, possibleReady, possibleNext = 0, 0, nil
    for _, caster in ipairs(CombatRes.blCasters) do
        local remain = math.max(0, (caster.cdEnd or 0) - now)
        if caster.confidence == "certain" then
            certainTotal = certainTotal + 1
            if remain <= 0 then
                certainReady = certainReady + 1
            elseif not certainNext or remain < certainNext then
                certainNext = remain
            end
        else
            possibleTotal = possibleTotal + 1
            if remain <= 0 then
                possibleReady = possibleReady + 1
            elseif not possibleNext or remain < possibleNext then
                possibleNext = remain
            end
        end
    end

    if certainTotal > 0 then
        local ready = certainReady > 0
        PaintIcon(blIcon, {
            desaturated = not ready,
            count = string.format("%d/%d", certainReady, certainTotal),
            timer = (not ready and certainNext) and MP:FormatTime(certainNext) or "",
            state = ready and "Ready" or "Caster CD",
            stateColor = ready and { 0.3, 1, 0.3 } or { 1, 0.35, 0.35 },
        })
        return
    end

    if possibleTotal > 0 then
        local ready = possibleReady > 0
        PaintIcon(blIcon, {
            desaturated = not ready,
            count = string.format("%d/%d", possibleReady, possibleTotal),
            timer = (not ready and possibleNext) and MP:FormatTime(possibleNext) or "",
            state = ready and "Possible" or "Possible CD",
            stateColor = ready and { 1, 0.95, 0.2 } or { 1, 0.5, 0.2 },
        })
        return
    end

    PaintIcon(blIcon, {
        desaturated = true,
        state = (IsInGroup() or IsInRaid()) and "No source" or "",
        stateColor = { 0.45, 0.45, 0.45 },
    })
end

local function ApplyBrez(name, spellID)
    local short = ShortName(name)
    for _, c in ipairs(CombatRes.casters) do
        if c.name == short and c.spellID == spellID then
            c.cdEnd = GetTime() + c.duration
            return true
        end
    end
    return false
end

local function OnRemoteBrez(payload, senderShort)
    if not senderShort or not payload then return end
    local spellID = tonumber(payload)
    if not spellID or not BREZ_SPELLS[spellID] then return end
    ApplyBrez(senderShort, spellID)
    UpdateDisplay()
end

local function OnRemoteBLUsed(_, senderShort)
    if senderShort then
        ApplyBLCooldown(senderShort)
    end
    OnBLDetected()
    UpdateBLStatus()
end

local ticker = CreateFrame("Frame")
ticker:Hide()
local elapsed = 0
ticker:SetScript("OnUpdate", function(_, dt)
    elapsed = elapsed + dt
    if elapsed < 1.0 then return end
    elapsed = 0
    UpdateDisplay()
    UpdateBLStatus()
end)

function CombatRes:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit ~= "player" or type(spellID) ~= "number" or spellID <= 0 then return end

        if BREZ_SPELLS[spellID] then
            local playerName = UnitName("player")
            ApplyBrez(playerName, spellID)
            UpdateDisplay()
            if MP.Comm then MP.Comm:Send("BREZ", spellID) end
        end

        if BL_SPELL_IDS[spellID] then
            ApplyBLCooldown(UnitName("player"))
            OnBLDetected()
            UpdateBLStatus()
            if MP.Comm then MP.Comm:Send("BL_USED", "") end
        end
        return
    end

    if event == "UNIT_AURA" then
        local unit = ...
        if unit == "player" and satedExpiry <= GetTime() then
            PollSatedAura()
            UpdateBLStatus()
        end
        return
    end

    if event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(0.5, function()
            ScanParty()
            ScanForBL()
            UpdateDisplay()
            UpdateBLStatus()
        end)
        return
    end

    if event == "CHALLENGE_MODE_START" then
        satedExpiry = 0
        ScanParty()
        ScanForBL()
        for _, c in ipairs(self.casters) do c.cdEnd = 0 end
        for _, c in ipairs(self.blCasters) do c.cdEnd = 0 end
        UpdateDisplay()
        UpdateBLStatus()
        ticker:Show()
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        ticker:Hide()
    end
end

function CombatRes:OnFrameReady()
    CreateUI()
    if MP.Comm then
        MP.Comm:RegisterHandler("BREZ", OnRemoteBrez)
        MP.Comm:RegisterHandler("BL_USED", OnRemoteBLUsed)
    end
    ScanParty()
    ScanForBL()
    UpdateDisplay()
    UpdateBLStatus()
    ticker:Show()
end

function CombatRes:OnPlayerEnteringWorld()
    C_Timer.After(2, function()
        ScanParty()
        ScanForBL()
        UpdateDisplay()
        UpdateBLStatus()
    end)
end

MP:RegisterModule("CombatRes", CombatRes)
