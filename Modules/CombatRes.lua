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
        "UNIT_PET",
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
    MAGE   = "certain",
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
local trinketIcon
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
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)
    frame:SetPoint("TOPLEFT", xOffset, 0)

    -- Class-colored border (Background)
    frame.border = frame:CreateTexture(nil, "BACKGROUND")
    frame.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.border:SetAllPoints()
    frame.border:SetVertexColor(0.3, 0.3, 0.4, 1)

    -- Inner black background
    frame.innerBorder = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    frame.innerBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.innerBorder:SetPoint("TOPLEFT", 1, -1)
    frame.innerBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.innerBorder:SetVertexColor(0, 0, 0, 1)

    -- Icon texture
    frame.icon = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
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
    local iconGap = 24
    local sectionHeight = size + 18
    section = MP.CombatResFrame:CreateSection(nil, sectionHeight)

    brezIcon    = CreateStatusIcon(section, 0,                       20484, "Battle Res")
    blIcon      = CreateStatusIcon(section, size + iconGap,          2825,  "Bloodlust")
    trinketIcon = CreateStatusIcon(section, (size + iconGap) * 2,    0,     "Trinket")
    -- Start trinket icon greyed until first scan
    if trinketIcon then
        trinketIcon.icon:SetDesaturated(true)
        trinketIcon.icon:SetVertexColor(0.5, 0.5, 0.5)
    end

    MP.CombatResFrame:AddSection(section)
    MP.CombatResFrame:SetWidth((size + iconGap) * 2 + size)
    MP.CombatResFrame:Layout()
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
        if not class then return end

        local confidence = BL_CLASSES[class]
        if not confidence then
            -- Hunters provide BL through their exotic pet (Primal Rage).
            -- Only include them if a pet is currently active; dismiss = no BL.
            if class == "HUNTER" then
                local petUnit = unit == "player" and "pet" or (unit .. "pet")
                if not UnitExists(petUnit) then return end
                confidence = "certain"
            else
                return
            end
        end

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
    local now = GetTime()
    local bestExpiry = 0

    local function checkUnit(unit)
        if not UnitExists(unit) then return end
        if not (C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID) then return end
        for spellID in pairs(SATED_IDS) do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellID, unit, spellID, "HARMFUL")
            if ok and aura then
                -- expirationTime may be a secret value in Midnight; guard with pcall
                local expOk, exp = pcall(function() return aura.expirationTime end)
                exp = (expOk and exp) or (now + SATED_DURATION)
                if exp > bestExpiry then bestExpiry = exp end
                return
            end
        end
    end

    checkUnit("player")
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do checkUnit("raid" .. i) end
    else
        for i = 1, 4 do checkUnit("party" .. i) end
    end

    satedExpiry = bestExpiry > now and bestExpiry or 0
end

local function UpdateTrinketDisplay()
    if not trinketIcon then return end
    local tt = MP:GetModule("TrinketTracker")
    if not (tt and tt.active and tt.GetNextReady) then
        PaintIcon(trinketIcon, { desaturated = true, state = "", stateColor = { 0.45, 0.45, 0.45 } })
        return
    end

    local best = tt:GetNextReady()
    if not best then
        PaintIcon(trinketIcon, { desaturated = true, state = "", stateColor = { 0.45, 0.45, 0.45 } })
        return
    end

    -- Update icon to the actual equipped trinket's art
    local tex
    if best.itemID and C_Item and C_Item.GetItemIconByID then
        tex = C_Item.GetItemIconByID(best.itemID)
    end
    if not tex and best.spellID then
        tex = SpellTexture(best.spellID, 136243)
    end
    if tex then trinketIcon.icon:SetTexture(tex) end

    if best.ready then
        PaintIcon(trinketIcon, {
            desaturated = false,
            state       = MP:Loc("CR_READY"),
            stateColor  = { 0.3, 1, 0.3 },
        })
    else
        local remain = math.max(0, best.at - GetTime())
        PaintIcon(trinketIcon, {
            desaturated = true,
            timer       = remain > 0 and MP:FormatTime(remain) or "",
            state       = MP:Loc("CR_ON_CD"),
            stateColor  = { 1, 0.35, 0.35 },
        })
    end
end

local function ApplyBLCooldown(name)
    local short = ShortName(name)
    if not short then return end
    local now = GetTime()
    local applied = false
    for _, c in ipairs(CombatRes.blCasters) do
        if MP:SafeStringEquals(c.name, short) then
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
            state = MP:Loc("CR_NO_BREZ"),
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
            state = MP:Loc("CR_BREZ_READY_FORMAT", ready, total),
            stateColor = poolReady > 0 and { 0.3, 1, 0.3 } or { 1, 0.35, 0.35 },
        })
        return
    end

    PaintIcon(brezIcon, {
        desaturated = ready <= 0,
        count = string.format("%d/%d", ready, total),
        timer = (nextReady and nextReady > 0) and MP:FormatTime(nextReady) or "",
        state = ready > 0 and MP:Loc("CR_AVAILABLE") or MP:Loc("CR_ON_CD"),
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
            state = MP:Loc("CR_BL_SATED"),
            stateColor = { 1, 0.6, 0.2 },
        })
        return
    end

    local total, ready, nextCD = 0, 0, nil
    for _, caster in ipairs(CombatRes.blCasters) do
        local remain = math.max(0, (caster.cdEnd or 0) - now)
        total = total + 1
        if remain <= 0 then
            ready = ready + 1
        elseif not nextCD or remain < nextCD then
            nextCD = remain
        end
    end

    if total > 0 then
        local isReady = ready > 0
        PaintIcon(blIcon, {
            desaturated = not isReady,
            count = string.format("%d/%d", ready, total),
            timer = (not isReady and nextCD) and MP:FormatTime(nextCD) or "",
            state = isReady and MP:Loc("CR_READY") or MP:Loc("CR_ON_CD"),
            stateColor = isReady and { 0.3, 1, 0.3 } or { 1, 0.35, 0.35 },
        })
        return
    end

    PaintIcon(blIcon, {
        desaturated = true,
        state = (IsInGroup() or IsInRaid()) and MP:Loc("CR_BL_NO_SOURCE") or "",
        stateColor = { 0.45, 0.45, 0.45 },
    })
end

local function ApplyBrez(name, spellID)
    local short = ShortName(name)
    for _, c in ipairs(CombatRes.casters) do
        if MP:SafeStringEquals(c.name, short) and c.spellID == spellID then
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
    UpdateTrinketDisplay()
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
        if satedExpiry <= GetTime() then
            local relevant = unit == "player"
            if not relevant then
                if IsInRaid() then
                    relevant = unit:match("^raid%d+$") ~= nil
                else
                    relevant = unit:match("^party%d+$") ~= nil
                end
            end
            if relevant then
                PollSatedAura()
                UpdateBLStatus()
            end
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

    if event == "UNIT_PET" then
        -- A Hunter summoned or dismissed their pet — re-evaluate BL sources
        C_Timer.After(0.2, function()
            ScanForBL()
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
        UpdateTrinketDisplay()
        ticker:Show()
        if MP.CombatResFrame then MP.CombatResFrame:UpdateVisibility() end
        return
    end

    if event == "CHALLENGE_MODE_COMPLETED" or event == "CHALLENGE_MODE_RESET" then
        ticker:Hide()
    end
end

function CombatRes:OnFrameReady()
    if not MP.CombatResFrame or not MP.CombatResFrame.frame then
        MP:Debug("CombatResFrame not ready, skipping CombatRes UI creation")
        return
    end
    CreateUI()
    if MP.Comm then
        MP.Comm:RegisterHandler("BREZ", OnRemoteBrez)
        MP.Comm:RegisterHandler("BL_USED", OnRemoteBLUsed)
    end
    ScanParty()
    ScanForBL()
    UpdateDisplay()
    UpdateBLStatus()
    UpdateTrinketDisplay()
    ticker:Show()
end

function CombatRes:OnDisable()
    self.active = false
    ticker:Hide()
    if section then section:Hide() end
    if MP.CombatResFrame then MP.CombatResFrame:Layout() end
end

function CombatRes:OnEnable()
    if section then section:Show() end
    self.active = true
    ScanParty()
    ScanForBL()
    UpdateDisplay()
    UpdateBLStatus()
    UpdateTrinketDisplay()
    if ticker then ticker:Show() end
    if MP.CombatResFrame then
        MP.CombatResFrame:Layout()
        if MP.CombatResFrame.UpdateVisibility then
            MP.CombatResFrame:UpdateVisibility()
        end
    end
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
