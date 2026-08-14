--[[
    MythicPulse - Dungeon Teleport Module
    Integrates directly with the Blizzard Challenges UI to provide teleport buttons.
]]

local _, MP = ...

local DungeonTeleport = {
    registeredEvents = {
        "ADDON_LOADED",
        "SPELLS_CHANGED",
    },
}

----------------------------------------------------------------------
-- Dungeon Teleport Spell Data (keyed by ChallengeMapID)
-- Buttons only appear for dungeons listed here whose teleport spell the
-- player knows; an unknown (e.g. new-season) dungeon simply shows no button.
-- See Docs/SEASON_UPDATE.md for how to add a new season's teleports.
----------------------------------------------------------------------
local TELEPORT_SPELLS = {
    -- Season 1 — Midnight Dungeons
    [558] = { name = "Magisters' Terrace",      spellID = 410071 },
    [560] = { name = "Maisara Caverns",         spellID = 410072 },
    [559] = { name = "Nexus-Point Xenas",       spellID = 410073 },
    [557] = { name = "Windrunner Spire",        spellID = 410074 },
    -- Season 1 — Legacy Dungeons
    [402] = { name = "Algeth'ar Academy",       spellID = 395273 },
    [556] = { name = "Pit of Saron",            spellID = 410075 },
    [239] = { name = "Seat of the Triumvirate", spellID = 410076 },
    [161] = { name = "Skyreach",                spellID = 410077 },

    -- Season 2 — Midnight Dungeons. spellIDs from the live SpellName DB2
    -- (wago.tools, 2026-08-14); button only shows if IsSpellKnownOrPlayer()
    -- passes, so a wrong/stale ID just means no button, never a bad teleport.
    [588] = { name = "Altar of Fangs",      spellID = 1289772 },
    [586] = { name = "Den of Nalorakk",     spellID = 1289773 },
    [587] = { name = "Murder Row",          spellID = 1289775 }, -- picked newest of 3 same-named candidates
    [584] = { name = "The Blinding Vale",   spellID = 1289776 },
    [585] = { name = "Voidscar Arena",      spellID = 1289777 }, -- picked newest of 2 same-named candidates
    -- Season 2 — Legacy Dungeons (each had an older same-named spell from its
    -- original season too; picked the newest ID, matching the pattern already
    -- confirmed for Skyreach above: 410077 (kept) vs. a stale 169765 (unused)).
    [249] = { name = "Kings' Rest",         spellID = 1289778 },
    [250] = { name = "Temple of Sethraliss",spellID = 1289782 },
    [399] = { name = "Ruby Life Pools",     spellID = 1289780 },
}

local function IsSpellKnownOrPlayer(spellID)
    local known = false
    if C_SpellBook and C_SpellBook.IsSpellKnown then
        known = C_SpellBook.IsSpellKnown(spellID)
    end
    return known or IsPlayerSpell(spellID)
end

local integrated = false

local function UpdateTeleportButtons()
    if not integrated or InCombatLockdown() then return end
    if not (ChallengesFrame and ChallengesFrame.DungeonIcons) then return end
    local enabled = DungeonTeleport.enabled ~= false
    for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
        if icon.mapID and icon.teleportBtn then
            local data = TELEPORT_SPELLS[icon.mapID]
            local visible = enabled and data ~= nil and IsSpellKnownOrPlayer(data.spellID)
            icon.teleportBtn:SetShown(visible and true or false)
        end
    end
end

local function IntegrateWithChallengesUI()
    if integrated then return end
    if not ChallengesFrame or not ChallengesFrame.DungeonIcons then return end

    for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
        local mapID = icon.mapID
        if mapID and TELEPORT_SPELLS[mapID] then
            local data = TELEPORT_SPELLS[mapID]
            
            -- Create a small SecureActionButton inside the DungeonIcon
            local btn = CreateFrame("Button", "MPTeleportBtn_"..mapID, icon, "SecureActionButtonTemplate")
            btn:SetSize(22, 22)
            -- Position in the bottom right corner of the dungeon icon
            btn:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 6, -6)
            btn:RegisterForClicks("AnyUp")
            
            -- Set up secure cast
            btn:SetAttribute("type", "spell")
            local spellName = C_Spell and C_Spell.GetSpellName(data.spellID) or GetSpellInfo(data.spellID)
            btn:SetAttribute("spell", spellName)
            
            -- Visuals
            btn.tex = btn:CreateTexture(nil, "OVERLAY")
            btn.tex:SetAllPoints()
            local spellIcon = C_Spell and C_Spell.GetSpellTexture(data.spellID) or select(3, GetSpellInfo(data.spellID))
            btn.tex:SetTexture(spellIcon or 137213) -- default to arcane portal if missing
            
            -- Rounded mask to make it circular
            local mask = btn:CreateMaskTexture()
            mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(btn.tex)
            btn.tex:AddMaskTexture(mask)
            
            -- Border ring
            btn.border = btn:CreateTexture(nil, "OVERLAY", nil, 1)
            btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
            btn.border:SetSize(46, 46)
            btn.border:SetPoint("TOPLEFT", btn, "TOPLEFT", -12, 12)
            btn.border:SetVertexColor(1, 0.8, 0, 1) -- Gold border to match Challenge UI
            
            -- Highlight
            btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
            
            -- Tooltip
            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetSpellByID(data.spellID)
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine(MP:Loc("TP_CLICK_TO_TELEPORT"), 0, 1, 0)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            
            icon.teleportBtn = btn
        end
    end

    integrated = true
    UpdateTeleportButtons()
end

function DungeonTeleport:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_ChallengesUI" then
            IntegrateWithChallengesUI()
        end
    elseif event == "SPELLS_CHANGED" then
        UpdateTeleportButtons()
    end
end

function DungeonTeleport:OnDisable()
    UpdateTeleportButtons()
end

function DungeonTeleport:OnEnable()
    UpdateTeleportButtons()
end

function DungeonTeleport:OnFrameReady()
    if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
        IntegrateWithChallengesUI()
    end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("DungeonTeleport", DungeonTeleport)
