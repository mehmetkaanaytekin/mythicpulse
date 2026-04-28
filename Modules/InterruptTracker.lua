--[[
    MythicPulse - Interrupt Tracker Module
    Dedicated interrupt cooldown tracker for M+ groups.

    MIDNIGHT 12.0.5 COMPLIANCE:
    - UNIT_SPELLCAST_SUCCEEDED is used only for unit == "player" — non-self
      units return opaque spellIDs in M+ instances.
    - Party member casts are received via the Comm module: each MythicPulse
      user broadcasts their own interrupt casts with msg type "INT".
    - No combat automation or decision-making.
    - Click-to-announce uses SendChatMessage (standard API).
]]

local _, MP = ...

local InterruptTracker = {
    registeredEvents = {
        "UNIT_SPELLCAST_SUCCEEDED",
        "GROUP_ROSTER_UPDATE",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "PLAYER_SPECIALIZATION_CHANGED",
        "CHALLENGE_MODE_START",
        "CHALLENGE_MODE_RESET",
        "CHALLENGE_MODE_COMPLETED",
    },
    active   = false,
    inCombat = false,
    members  = {},   -- indexed array of { guid, name, class, specID, spellID, duration, ... }
    pending  = {},   -- guid -> { spellID, timestamp } for kick result correlation
}

----------------------------------------------------------------------
-- Interrupt Spell Database (one per class, spec overrides)
----------------------------------------------------------------------
local CLASS_INTERRUPTS = {
    DEATHKNIGHT = { spellID = 47528,  duration = 15, name = "Mind Freeze" },
    DEMONHUNTER = { spellID = 183752, duration = 15, name = "Disrupt" },
    DRUID       = { spellID = 106839, duration = 15, name = "Skull Bash" },
    EVOKER      = { spellID = 351338, duration = 40, name = "Quell" },
    HUNTER      = { spellID = 147362, duration = 24, name = "Counter Shot" },
    MAGE        = { spellID = 2139,   duration = 24, name = "Counterspell" },
    MONK        = { spellID = 116705, duration = 15, name = "Spear Hand Strike" },
    PALADIN     = { spellID = 96231,  duration = 15, name = "Rebuke" },
    PRIEST      = { spellID = 15487,  duration = 45, name = "Silence" },
    ROGUE       = { spellID = 1766,   duration = 15, name = "Kick" },
    SHAMAN      = { spellID = 57994,  duration = 12, name = "Wind Shear" },
    WARLOCK     = { spellID = 19647,  duration = 24, name = "Spell Lock", pet = true },
    WARRIOR     = { spellID = 6552,   duration = 15, name = "Pummel" },
}

-- Spec-specific overrides (specID -> interrupt data)
local SPEC_OVERRIDES = {
    -- Hunter: Survival uses Muzzle instead of Counter Shot
    [255] = { spellID = 187707, duration = 15, name = "Muzzle" },
    -- Warlock: Demonology also has Axe Toss (pet stun with interrupt)
    [266] = { spellID = 89766, duration = 30, name = "Axe Toss", pet = true },
    -- Evoker: All specs use Quell but it's the same
}

-- Alternative spell IDs that map to the same interrupt (talent morphs, pet variants)
local SPELL_ALIASES = {
    [132409] = 19647,   -- Spell Lock (Command Demon variant) -> Spell Lock
    [119910] = 19647,   -- Spell Lock (Grimoire variant)
    [171138] = 89766,   -- Shadow Lock -> Axe Toss family
    [171139] = 89766,   -- Fel Cleave interrupt
    [187707] = 187707,  -- Muzzle (self-reference for lookup)
}

-- Build reverse lookup: spellID -> true (for fast event filtering)
local ALL_INTERRUPT_IDS = {}
local INTERRUPT_IDS_ARRAY = {}

local function AddInterruptID(id)
    if not ALL_INTERRUPT_IDS[id] then
        ALL_INTERRUPT_IDS[id] = true
        table.insert(INTERRUPT_IDS_ARRAY, id)
    end
end

for _, data in pairs(CLASS_INTERRUPTS) do
    AddInterruptID(data.spellID)
end
for _, data in pairs(SPEC_OVERRIDES) do
    AddInterruptID(data.spellID)
end
for aliasID, _ in pairs(SPELL_ALIASES) do
    AddInterruptID(aliasID)
end

----------------------------------------------------------------------
-- Talent-based CD Reductions
----------------------------------------------------------------------
-- { talentSpellID = { class, reduction_seconds } }
local TALENT_CD_MODS = {
    [378848] = { class = "DEATHKNIGHT", reduction = 3 },   -- Coldthirst
    [388045] = { class = "WARRIOR",     reduction = 5 },   -- Imposing Presence
    [378209] = { class = "EVOKER",      reduction = 2 },   -- Interwoven Threads
    -- Add more as discovered
}

----------------------------------------------------------------------
-- Get interrupt data for a class/spec
----------------------------------------------------------------------
local function GetInterruptForUnit(class, specID)
    if specID and SPEC_OVERRIDES[specID] then
        return SPEC_OVERRIDES[specID]
    end
    return CLASS_INTERRUPTS[class]
end

----------------------------------------------------------------------
-- Resolve a spellID through aliases
----------------------------------------------------------------------
local function ResolveSpellID(spellID)
    return SPELL_ALIASES[spellID] or spellID
end

----------------------------------------------------------------------
-- Scan talents for CD reductions (self only — can't read others' talents)
----------------------------------------------------------------------
local function GetTalentCDReduction(class)
    local totalReduction = 0
    for talentID, info in pairs(TALENT_CD_MODS) do
        if info.class == class then
            -- Check if talent is known via C_SpellBook
            if C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(talentID) then
                totalReduction = totalReduction + info.reduction
            end
        end
    end
    return totalReduction
end

----------------------------------------------------------------------
-- Party Scanning
----------------------------------------------------------------------
local function GetSpecID(unit)
    if not UnitExists(unit) then return nil end
    local specID = nil
    if UnitIsUnit(unit, "player") then
        if C_SpecializationInfo and C_SpecializationInfo.GetSpecialization then
            local idx = C_SpecializationInfo.GetSpecialization()
            if idx then
                specID = C_SpecializationInfo.GetSpecializationInfo(idx)
            end
        end
    else
        -- For party members, we can inspect their spec via GetInspectSpecialization
        -- but this requires inspect permission. Fall back to nil (use class default).
        if GetInspectSpecialization then
            local id = GetInspectSpecialization(unit)
            if id and id > 0 then specID = id end
        end
    end
    return specID
end

function InterruptTracker:ScanGroup()
    self.members = {}
    local numMembers = GetNumGroupMembers()
    if numMembers == 0 then
        -- Solo: show self
        local guid = UnitGUID("player")
        local name = UnitName("player")
        local _, class = UnitClass("player")
        local specID = GetSpecID("player")
        local intData = GetInterruptForUnit(class, specID)
        if intData and guid then
            local cdReduction = GetTalentCDReduction(class)
            table.insert(self.members, {
                guid     = guid,
                name     = name,
                class    = class,
                specID   = specID,
                spellID  = intData.spellID,
                duration = math.max(1, intData.duration - cdReduction),
                spellName = intData.name,
                pet      = intData.pet,
                cdEnd    = 0,
                kickResult = nil,  -- nil=none, "success", "fail", "pending"
            })
        end
        return
    end

    for i = 1, numMembers do
        local unit
        if IsInRaid() then
            unit = "raid" .. i
        else
            unit = (i < numMembers) and ("party" .. i) or "player"
        end

        if UnitExists(unit) then
            local guid = UnitGUID(unit)
            local name = UnitName(unit)
            local _, class = UnitClass(unit)
            local specID = GetSpecID(unit)
            local intData = GetInterruptForUnit(class, specID)

            if intData and guid then
                local cdReduction = 0
                if UnitIsUnit(unit, "player") then
                    cdReduction = GetTalentCDReduction(class)
                end

                table.insert(self.members, {
                    guid      = guid,
                    name      = name,
                    class     = class,
                    specID    = specID,
                    spellID   = intData.spellID,
                    duration  = math.max(1, intData.duration - cdReduction),
                    spellName = intData.name,
                    pet       = intData.pet,
                    cdEnd     = 0,
                    kickResult = nil,
                })
            end
        end
    end

    MP:Debug("InterruptTracker: Scanned", #self.members, "members")
end

----------------------------------------------------------------------
-- Find member by GUID or name
----------------------------------------------------------------------
local function FindMember(guid)
    for _, m in ipairs(InterruptTracker.members) do
        if m.guid == guid then return m end
    end
    return nil
end

local function FindMemberByName(name)
    if not name then return nil end
    for _, m in ipairs(InterruptTracker.members) do
        if m.name == name then return m end
    end
    return nil
end

----------------------------------------------------------------------
-- Apply a cooldown to a specific member (used by self-event and comm)
----------------------------------------------------------------------
function InterruptTracker:OnInterruptCast(guid, name, spellID)
    local m = (guid and FindMember(guid)) or FindMemberByName(name)
    if not m then return end

    m.cdEnd = GetTime() + m.duration
    m.kickResult = "pending"
    m.kickResultTime = GetTime()
    self.pending[m.guid] = { spellID = spellID, time = GetTime() }

    C_Timer.After(0.4, function()
        m.kickResult = nil
        m.kickResultTime = nil
        InterruptTracker.pending[m.guid] = nil
    end)
end

----------------------------------------------------------------------
-- Handle interrupt broadcast from a party member
----------------------------------------------------------------------
local function OnRemoteInterrupt(payload, senderShort)
    if not InterruptTracker.active then return end
    if not payload or not senderShort then return end
    local spellID = tonumber(payload)
    if not spellID then return end
    InterruptTracker:OnInterruptCast(nil, senderShort, spellID)
end

----------------------------------------------------------------------
-- UI: Create the HUD section inside MainFrame
----------------------------------------------------------------------
local section, rows
local ROW_HEIGHT = 32
local BAR_INSET  = 68  -- name width
local RESULT_HOLD_TIME = 3  -- seconds to show green/red result

local function CreateRow(parent, index)
    local row = CreateFrame("Button", nil, parent)
    row:SetHeight(ROW_HEIGHT)

    -- No bar background or progress bar as requested by user

    -- Spell icon
    row.icon = row:CreateTexture(nil, "OVERLAY")
    row.icon:SetSize(ROW_HEIGHT - 4, ROW_HEIGHT - 4)
    row.icon:SetPoint("LEFT", 0, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Icon border: class-colored accent ring.
    -- Keep alpha LOW (0.45) so it tints the border without overpowering the icon.
    row.iconBorder = row:CreateTexture(nil, "OVERLAY", nil, 1)
    row.iconBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    row.iconBorder:SetPoint("TOPLEFT", row.icon, -1, 1)
    row.iconBorder:SetPoint("BOTTOMRIGHT", row.icon, 1, -1)
    row.iconBorder:SetVertexColor(0.3, 0.3, 0.4, 0.45)
    row.icon:SetDrawLayer("OVERLAY", 2)
    -- Start hidden; UpdateRows shows them only when a valid texture exists
    row.icon:Hide()
    row.iconBorder:Hide()

    -- Player name
    row.nameText = row:CreateFontString(nil, "OVERLAY")
    row.nameText:SetFontObject(MP.Fonts and MP.Fonts.Small or "GameFontNormalSmall")
    row.nameText:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.nameText:SetPoint("RIGHT", -60, 0) -- Leave space for status text
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    -- Status text (READY / 12s / etc)
    row.statusText = row:CreateFontString(nil, "OVERLAY")
    row.statusText:SetFontObject(MP.Fonts and MP.Fonts.Body or "GameFontNormal")
    row.statusText:SetPoint("RIGHT", -4, 0)
    row.statusText:SetJustifyH("RIGHT")

    -- "NEXT" rotation indicator (shown on the player who should kick next)
    row.nextBadge = row:CreateFontString(nil, "OVERLAY")
    row.nextBadge:SetFontObject(MP.Fonts and MP.Fonts.Small or "GameFontNormalSmall")
    row.nextBadge:SetPoint("LEFT", row.nameText, "LEFT", 0, 0)
    row.nextBadge:SetTextColor(1.0, 0.85, 0.20)
    row.nextBadge:SetText("|cffffd866>> NEXT|r")
    row.nextBadge:Hide()

    -- Tooltip: show player + spell info so the row is never ambiguous
    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        local m = self.memberData
        if not m then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        -- Header: class-colored player name
        local nameStr = MP:ClassColoredName(m.name or "?", m.class)
        GameTooltip:SetText(nameStr)
        -- Spell name + interrupt CD info
        if m.spellName then
            GameTooltip:AddLine(m.spellName, 1, 1, 1)
        end
        local remaining = (m.cdEnd or 0) - GetTime()
        if remaining > 0 then
            GameTooltip:AddLine(string.format("On cooldown: %.0fs", remaining), 0.9, 0.5, 0.5)
        else
            GameTooltip:AddLine("READY", 0.3, 1.0, 0.4)
        end
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Left-click to announce status", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Click-to-announce
    row:SetScript("OnClick", function(self)
        if not self.memberData then return end
        local m = self.memberData
        local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT"
                     or IsInGroup() and "PARTY" or "SAY"
        local remaining = m.cdEnd - GetTime()
        local msg
        if remaining > 0 then
            msg = string.format("[MythicPulse] %s's %s on CD (%.0fs)", m.name, m.spellName, remaining)
        else
            msg = string.format("[MythicPulse] %s's %s is READY", m.name, m.spellName)
        end
        SendChatMessage(msg, channel)
    end)

    row:Hide()
    return row
end

local function CreateUI()
    section = MP.InterruptFrame:CreateSection(nil, 10)
    rows = {}
    -- Note: rows are created dynamically as needed for raid support
    MP.InterruptFrame:AddSection(section)
end

-- Create or reuse a row as needed
local function GetOrCreateRow(idx)
    if not rows[idx] then
        local row = CreateRow(section, idx)
        row:SetPoint("TOPLEFT", 0, -(idx - 1) * ROW_HEIGHT)
        row:SetPoint("RIGHT", 0, 0)
        rows[idx] = row
    end
    return rows[idx]
end

----------------------------------------------------------------------
-- Update UI rows from member data
----------------------------------------------------------------------
----------------------------------------------------------------------
-- Kick Rotation: pick the next member to kick.
-- Strategy: among members ready (or readiest), prefer the one whose
-- interrupt has been off CD the longest (smallest cdEnd). When tied,
-- fall back to a stable order (registration index).
-- Returns: index of the member in InterruptTracker.members, or nil.
----------------------------------------------------------------------
local function GetNextKickerIndex()
    local members = InterruptTracker.members
    if not members or #members == 0 then return nil end
    local now = GetTime()
    local bestIdx, bestEnd
    for i, m in ipairs(members) do
        -- Only consider members who exist and have a cooldown duration set
        if m and m.duration and m.duration > 0 then
            -- Members on long CD won't be the next kicker; only the readiest
            local cdEnd = m.cdEnd or 0
            if not bestEnd or cdEnd < bestEnd then
                bestEnd = cdEnd
                bestIdx = i
            end
        end
    end
    -- If the best candidate is still on a long CD (>5s), no one is "next" yet
    if bestIdx and bestEnd and bestEnd - now > 5 then
        return nil
    end
    return bestIdx
end

local function UpdateRows()
    if not rows or not InterruptTracker.members then return end
    local now = GetTime()
    local nextIdx = GetNextKickerIndex()

    for i, m in ipairs(InterruptTracker.members) do
        local row = GetOrCreateRow(i)

        if m then
            row.memberData = m

            -- Icon: hide both icon and border if no valid texture (avoids blank rectangle)
            local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(m.spellID)
            if info and info.iconID then
                row.icon:SetTexture(info.iconID)
                row.icon:Show()
                row.iconBorder:Show()
            else
                row.icon:Hide()
                row.iconBorder:Hide()
            end

            -- Class-colored border accent (low alpha so the spell icon stays readable)
            if RAID_CLASS_COLORS[m.class] then
                local c = RAID_CLASS_COLORS[m.class]
                row.iconBorder:SetVertexColor(c.r, c.g, c.b, 0.45)
            end

            -- Name (class-colored). Highlight the next kicker with a gold dot.
            if i == nextIdx then
                row.nameText:SetText("|cffffd866· |r" .. MP:ClassColoredName(m.name or "?", m.class))
            else
                row.nameText:SetText(MP:ClassColoredName(m.name or "?", m.class))
            end
            if row.nextBadge then row.nextBadge:Hide() end

            -- CD state
            local remaining = m.cdEnd - now
            if remaining > 0 then
                -- On cooldown
                row.statusText:SetText(string.format("%.0fs", remaining))

                -- Kick result coloring
                if m.kickResult == "success" then
                    row.statusText:SetTextColor(0.30, 1.00, 0.30)  -- Green
                elseif m.kickResult == "fail" then
                    row.statusText:SetTextColor(1.00, 0.30, 0.30)  -- Red
                elseif m.kickResult == "pending" then
                    row.statusText:SetTextColor(1.00, 1.00, 1.00)  -- White
                else
                    row.statusText:SetTextColor(0.80, 0.80, 0.30)  -- Yellow
                end

                -- No progress bar width needed

                -- Clear kick result color after hold time
                if m.kickResultTime and (now - m.kickResultTime) > RESULT_HOLD_TIME then
                    m.kickResult = nil
                    m.kickResultTime = nil
                end

                row.icon:SetDesaturated(true)
                row.icon:SetAlpha(0.5)
            else
                -- Ready
                row.statusText:SetText("|cff4dff4dREADY|r")
                row.statusText:SetTextColor(0.30, 1.00, 0.30)
                -- No bar to hide
                row.icon:SetDesaturated(false)
                row.icon:SetAlpha(1.0)
                m.kickResult = nil
                m.kickResultTime = nil
            end

            row:Show()
        else
            row:Hide()
        end
    end

    -- Hide stale rows from a previously larger group
    for i = #InterruptTracker.members + 1, #rows do
        if rows[i] then rows[i]:Hide() end
    end

    -- Resize section to fit current members only
    if section then
        local count = #InterruptTracker.members
        section:SetHeight(count * ROW_HEIGHT)
        if count > 0 then section:Show() end
        MP.InterruptFrame:Layout()
    end
end

----------------------------------------------------------------------
-- OnUpdate ticker (0.1s for smooth CD updates)
----------------------------------------------------------------------
local ticker = CreateFrame("Frame")
ticker:Hide()
local elapsed = 0

ticker:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.1 then return end
    elapsed = 0

    if not InterruptTracker.active then
        self:Hide()
        return
    end
    UpdateRows()
end)

----------------------------------------------------------------------
-- Combat fade
----------------------------------------------------------------------
local function FadeSection(show)
    if not section then return end
    if show then
        section:Show()
        ticker:Show()
    else
        -- Defer hide slightly so last state is visible
        C_Timer.After(2.0, function()
            if not InterruptTracker.inCombat and section then
                section:Hide()
                ticker:Hide()
            end
        end)
    end
end

----------------------------------------------------------------------
-- Event Handling
----------------------------------------------------------------------
function InterruptTracker:OnEvent(event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        -- Only react to self / our pet. Non-self units return opaque
        -- spellIDs in M+, but unit "pet" / "playerpet" is treated as a
        -- trusted self-source.
        local unit, _, spellID = ...
        if not unit or not spellID then return end
        local isSelf  = (unit == "player")
        local isOurPet = (unit == "pet" or unit == "playerpet")
        if not isSelf and not isOurPet then return end
        if type(spellID) ~= "number" or spellID <= 0 then return end

        local resolvedID = ResolveSpellID(spellID)
        if not ALL_INTERRUPT_IDS[resolvedID] and not ALL_INTERRUPT_IDS[spellID] then return end

        local guid = UnitGUID("player")
        if not guid then return end

        -- Always attribute to the owner so the cooldown shows on the player row
        self:OnInterruptCast(guid, nil, resolvedID)

        -- Broadcast to party so other MythicPulse users see our kick
        if MP.Comm then
            MP.Comm:Send("INT", resolvedID)
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        C_Timer.After(0.5, function()
            InterruptTracker:ScanGroup()
            UpdateRows()
        end)

    elseif event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1.5, function()
            InterruptTracker:ScanGroup()
            if MP:IsInMythicPlus() then
                InterruptTracker.active = true
            end
        end)

    elseif event == "PLAYER_REGEN_DISABLED" then
        self.inCombat = true
        local cfg = MP.db and MP.db.modules and MP.db.modules.interruptTracker
        if cfg and cfg.showInCombatOnly then
            FadeSection(true)
        end

    elseif event == "PLAYER_REGEN_ENABLED" then
        self.inCombat = false
        local cfg = MP.db and MP.db.modules and MP.db.modules.interruptTracker
        if cfg and cfg.showInCombatOnly then
            FadeSection(false)
        end

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(0.5, function()
            InterruptTracker:ScanGroup()
            UpdateRows()
        end)

    elseif event == "CHALLENGE_MODE_START" then
        -- Re-activate after a reset so back-to-back keys work correctly.
        self.active = true
        if section then section:Show() end
        if ticker then ticker:Show() end
        C_Timer.After(0.5, function()
            InterruptTracker:ScanGroup()
            UpdateRows()
        end)

    elseif event == "CHALLENGE_MODE_RESET" or event == "CHALLENGE_MODE_COMPLETED" then
        self.members = {}
        self.pending = {}
        if section then section:Hide() end
        if ticker then ticker:Hide() end
        self.active = false
    end
end

----------------------------------------------------------------------
-- Module Callbacks
----------------------------------------------------------------------
function InterruptTracker:OnFrameReady()
    if not MP.InterruptFrame or not MP.InterruptFrame.frame then
        MP:Debug("InterruptFrame not ready, skipping InterruptTracker UI creation")
        return
    end
    CreateUI()
    self:ScanGroup()

    if MP.Comm then
        MP.Comm:RegisterHandler("INT", OnRemoteInterrupt)
    end

    local cfg = MP.db and MP.db.modules and MP.db.modules.interruptTracker
    -- Force showInCombatOnly to false to prevent user confusion
    if cfg then cfg.showInCombatOnly = false end

    if cfg and cfg.showInCombatOnly and not self.inCombat then
        if section then section:Hide() end
    else
        if section then section:Show() end
        ticker:Show()
    end

    -- Force initial UI layout update so the frame has height
    UpdateRows()
    
    -- Always activate the tracker if the module is enabled
    self.active = true
end

function InterruptTracker:OnPlayerEnteringWorld()
    -- Handled by OnEvent
end

----------------------------------------------------------------------
-- Public: Announce the kick rotation order to the party.
-- Lists members ordered by who is currently the most ready (lowest cdEnd),
-- prefixed with the "next" indicator.
----------------------------------------------------------------------
function InterruptTracker:AnnounceRotation()
    local members = self.members or {}
    if #members == 0 then
        MP:Print("No interrupters in group.")
        return
    end

    -- Build a stable, sortable copy
    local order = {}
    for i, m in ipairs(members) do
        table.insert(order, { idx = i, m = m })
    end
    local now = GetTime()
    table.sort(order, function(a, b)
        return (a.m.cdEnd or 0) < (b.m.cdEnd or 0)
    end)

    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT"
                 or IsInGroup() and "PARTY"
    if not channel then
        MP:Print("|cffffd866Kick rotation:|r")
        for i, e in ipairs(order) do
            local rem = (e.m.cdEnd or 0) - now
            local status = rem > 0 and string.format("(%.0fs)", rem) or "READY"
            MP:Print(string.format("  %d. %s — %s %s", i, e.m.name or "?",
                e.m.spellName or "Interrupt", status))
        end
        return
    end

    -- Send to chat
    local parts = {}
    for i, e in ipairs(order) do
        local rem = (e.m.cdEnd or 0) - now
        local label = rem > 0 and string.format("%s(%ds)", e.m.name or "?", math.ceil(rem))
                              or e.m.name or "?"
        if i == 1 then label = "▶" .. label end
        table.insert(parts, label)
    end
    SendChatMessage("[MythicPulse] Kicks: " .. table.concat(parts, " → "), channel)
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("InterruptTracker", InterruptTracker)
