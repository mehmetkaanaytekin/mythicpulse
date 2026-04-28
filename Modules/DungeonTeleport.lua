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
-- Dungeon Teleport Spell Data (Season 1)
----------------------------------------------------------------------
local TELEPORT_SPELLS = {
    -- Midnight Dungeons
    [501] = { name = "Magisters' Terrace",      spellID = 410071 },
    [502] = { name = "Maisara Caverns",         spellID = 410072 },
    [503] = { name = "Nexus-Point Xenas",       spellID = 410073 },
    [504] = { name = "Windrunner Spire",        spellID = 410074 },
    -- Legacy Dungeons
    [505] = { name = "Algeth'ar Academy",       spellID = 395273 },
    [506] = { name = "Pit of Saron",            spellID = 410075 },
    [507] = { name = "Seat of the Triumvirate", spellID = 410076 },
    [508] = { name = "Skyreach",                spellID = 410077 },
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
    
    if ChallengesFrame and ChallengesFrame.DungeonIcons then
        for _, icon in ipairs(ChallengesFrame.DungeonIcons) do
            if icon.mapID and icon.teleportBtn then
                local data = TELEPORT_SPELLS[icon.mapID]
                if data and IsSpellKnownOrPlayer(data.spellID) then
                    icon.teleportBtn:Show()
                else
                    icon.teleportBtn:Hide()
                end
            end
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
                GameTooltip:AddLine("Click to Teleport", 0, 1, 0)
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

function DungeonTeleport:OnFrameReady()
    if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
        IntegrateWithChallengesUI()
    end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("DungeonTeleport", DungeonTeleport)
