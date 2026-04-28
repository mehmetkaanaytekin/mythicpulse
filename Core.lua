--[[
    MythicPulse - Core Framework
    All-in-one Mythic+ addon for WoW: Midnight (12.0.5)
    
    Provides the addon namespace, event bus, module registration,
    slash commands, and shared utility functions.
]]

----------------------------------------------------------------------
-- Addon Namespace
----------------------------------------------------------------------
local ADDON_NAME, MP = ...
MythicPulse = MP  -- global reference

MP.name    = ADDON_NAME
MP.version = C_AddOns and C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "1.0.0"
MP.modules = {}
MP.events  = {}

----------------------------------------------------------------------
-- Constants
----------------------------------------------------------------------
MP.COLORS = {
    -- Brand
    brand       = { r = 0.00, g = 0.80, b = 1.00 },  -- #00ccff
    brandHex    = "|cff00ccff",
    
    -- Severity
    good        = { r = 0.30, g = 1.00, b = 0.40 },
    warning     = { r = 1.00, g = 0.82, b = 0.00 },
    danger      = { r = 1.00, g = 0.25, b = 0.25 },
    
    -- UI
    bg          = { r = 0.08, g = 0.08, b = 0.12, a = 0.85 },
    bgDark      = { r = 0.05, g = 0.05, b = 0.08, a = 0.92 },
    border      = { r = 0.20, g = 0.20, b = 0.30, a = 0.60 },
    borderGlow  = { r = 0.00, g = 0.60, b = 0.90, a = 0.35 },
    textPrimary = { r = 0.95, g = 0.95, b = 0.95 },
    textSecondary = { r = 0.60, g = 0.62, b = 0.70 },
    textMuted   = { r = 0.40, g = 0.42, b = 0.48 },
}

-- Death time penalties by affix tier
MP.DEATH_PENALTY = {
    default = 5,   -- standard 5s per death
    guile   = 15,  -- Xal'atath's Guile (level 12+)
}

----------------------------------------------------------------------
-- Event Frame
----------------------------------------------------------------------
local eventFrame = CreateFrame("Frame")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Dispatch to core handlers
    if MP.events[event] then
        for _, handler in ipairs(MP.events[event]) do
            handler(event, ...)
        end
    end

    -- Dispatch to modules
    for name, mod in pairs(MP.modules) do
        if mod.enabled and mod.OnEvent then
            mod:OnEvent(event, ...)
        end
    end
end)

----------------------------------------------------------------------
-- Event Registration
----------------------------------------------------------------------
function MP:RegisterEvent(event, handler)
    if not self.events[event] then
        self.events[event] = {}
        eventFrame:RegisterEvent(event)
    end
    table.insert(self.events[event], handler)
end

function MP:UnregisterEvent(event)
    eventFrame:UnregisterEvent(event)
    self.events[event] = nil
end

----------------------------------------------------------------------
-- Module System
----------------------------------------------------------------------
function MP:RegisterModule(name, module)
    module.name = name
    module.enabled = true
    self.modules[name] = module
    
    if module.registeredEvents then
        for _, event in ipairs(module.registeredEvents) do
            eventFrame:RegisterEvent(event)
        end
    end
end

function MP:GetModule(name)
    return self.modules[name]
end

function MP:EnableModule(name)
    local mod = self.modules[name]
    if mod then
        mod.enabled = true
        if mod.OnEnable then mod:OnEnable() end
    end
end

function MP:DisableModule(name)
    local mod = self.modules[name]
    if mod then
        mod.enabled = false
        if mod.OnDisable then mod:OnDisable() end
    end
end

----------------------------------------------------------------------
-- Utility Functions
----------------------------------------------------------------------

--- Format seconds into MM:SS or HH:MM:SS
function MP:FormatTime(seconds)
    if not seconds or seconds < 0 then return "00:00" end
    seconds = math.floor(seconds)
    
    local hours = math.floor(seconds / 3600)
    local mins  = math.floor((seconds % 3600) / 60)
    local secs  = seconds % 60
    
    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, mins, secs)
    end
    return string.format("%02d:%02d", mins, secs)
end

--- Format time with +/- prefix (for deltas)
function MP:FormatTimeDelta(seconds)
    local prefix = seconds >= 0 and "+" or "-"
    return prefix .. self:FormatTime(math.abs(seconds))
end

--- Get class color for a unit or class token
function MP:ClassColor(classOrUnit)
    local class = classOrUnit
    if UnitExists(classOrUnit) then
        _, class = UnitClass(classOrUnit)
    end
    
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return c.r, c.g, c.b
    end
    return 0.70, 0.70, 0.70
end

--- Get class-colored name string
function MP:ClassColoredName(name, class)
    if class and RAID_CLASS_COLORS[class] then
        local c = RAID_CLASS_COLORS[class]
        return string.format("|cff%02x%02x%02x%s|r", c.r * 255, c.g * 255, c.b * 255, name)
    end
    return name
end

--- Print a message to chat with addon prefix
function MP:Print(...)
    local msg = table.concat({...}, " ")
    DEFAULT_CHAT_FRAME:AddMessage(self.COLORS.brandHex .. "MythicPulse|r: " .. msg)
end

--- Print a debug message (only in debug mode)
function MP:Debug(...)
    if self.db and self.db.debug then
        local msg = table.concat({...}, " ")
        DEFAULT_CHAT_FRAME:AddMessage("|cff888888[MP Debug]|r " .. msg)
    end
end

--- Lerp between two values
function MP:Lerp(a, b, t)
    return a + (b - a) * t
end

--- Lerp between two colors
function MP:LerpColor(c1, c2, t)
    return {
        r = self:Lerp(c1.r, c2.r, t),
        g = self:Lerp(c1.g, c2.g, t),
        b = self:Lerp(c1.b, c2.b, t),
    }
end

--- Check if player is in a Mythic+ dungeon
function MP:IsInMythicPlus()
    local mapID = C_ChallengeMode.GetActiveChallengeMapID()
    return mapID and mapID > 0
end

--- Get the current key level of the active run
function MP:GetActiveKeyLevel()
    if not self:IsInMythicPlus() then return 0 end
    local level, affixes = C_ChallengeMode.GetActiveKeystoneInfo()
    return level or 0
end

--- Registry of frames that honor the showBackdrop setting
MP._backdropFrames = MP._backdropFrames or {}

--- Create a standard backdrop for MythicPulse frames
function MP:CreateBackdrop(frame, bgColor, borderColor)
    bgColor     = bgColor or self.COLORS.bg
    borderColor = borderColor or self.COLORS.border

    frame._mpBgColor     = bgColor
    frame._mpBorderColor = borderColor

    -- Register for global toggling (deduped by identity)
    local already = false
    for _, f in ipairs(self._backdropFrames) do
        if f == frame then already = true; break end
    end
    if not already then table.insert(self._backdropFrames, frame) end

    self:ApplyBackdrop(frame)
end

--- Apply or remove the backdrop based on the showBackdrop setting
function MP:ApplyBackdrop(frame)
    if not frame._mpBgColor then return end
    if InCombatLockdown() then
        if frame._mpBackdropDeferred then return end
        frame._mpBackdropDeferred = true
        C_Timer.After(0.5, function()
            if frame then
                frame._mpBackdropDeferred = nil
                MP:ApplyBackdrop(frame)
            end
        end)
        return
    end

    local show = not self.db or self.db.showBackdrop ~= false
    if show then
        frame:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets   = { left = 1, right = 1, top = 1, bottom = 1 },
        })
        local bg, bd = frame._mpBgColor, frame._mpBorderColor
        frame:SetBackdropColor(bg.r, bg.g, bg.b, bg.a or 0.85)
        frame:SetBackdropBorderColor(bd.r, bd.g, bd.b, bd.a or 0.60)
        if frame._mpGlow then
            local gc = self.COLORS.borderGlow
            frame._mpGlow:SetVertexColor(gc.r, gc.g, gc.b, gc.a or 0.25)
            frame._mpGlow:Show()
        end
        if frame._mpTitleSep then
            frame._mpTitleSep:SetVertexColor(1, 1, 1, 0.20)
            frame._mpTitleSep:Show()
        end
    else
        -- Defensive clear to avoid stale tint artifacts from prior backdrop state.
        frame:SetBackdropColor(0, 0, 0, 0)
        frame:SetBackdropBorderColor(0, 0, 0, 0)
        frame:SetBackdrop(nil)
        if frame._mpGlow then
            frame._mpGlow:SetVertexColor(0, 0, 0, 0)
            frame._mpGlow:Hide()
        end
        if frame._mpTitleSep then
            frame._mpTitleSep:SetVertexColor(0, 0, 0, 0)
            frame._mpTitleSep:Hide()
        end
    end
end

--- Refresh backdrop visibility on every registered frame
function MP:RefreshAllBackdrops()
    for _, frame in ipairs(self._backdropFrames) do
        if frame then self:ApplyBackdrop(frame) end
    end
end

--- Registry of M+-only sections (hidden outside M+)
MP._mythicOnlySections = MP._mythicOnlySections or {}

--- Register a section that should only show during M+ runs
function MP:RegisterMythicOnlySection(section)
    if section then
        table.insert(self._mythicOnlySections, section)
        section:SetShown(self:IsInMythicPlus())
    end
end

--- Refresh visibility of all M+-only sections
function MP:UpdateMythicOnlySections()
    local inM = self:IsInMythicPlus()
    for _, section in ipairs(self._mythicOnlySections) do
        if section then
            section:SetShown(inM)
        end
    end
    if MP.MainFrame then
        MP.MainFrame:Layout()
    end
end

--- Create a glow border effect
function MP:CreateGlow(frame, color, size)
    color = color or self.COLORS.borderGlow
    size  = size or 3

    local glow = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    glow:SetTexture("Interface\\Buttons\\WHITE8x8")
    glow:SetPoint("TOPLEFT", frame, -size, size)
    glow:SetPoint("BOTTOMRIGHT", frame, size, -size)
    glow:SetVertexColor(color.r, color.g, color.b, color.a or 0.25)
    glow:SetBlendMode("ADD")
    frame._mpGlow = glow
    return glow
end

----------------------------------------------------------------------
-- Addon Compartment (Midnight minimap button)
----------------------------------------------------------------------
function MythicPulse_OnAddonCompartmentClick(addonName, buttonName)
    if buttonName == "RightButton" then
        -- Right-click: open config
        if MP.ConfigPanel and MP.ConfigPanel.Toggle then
            MP.ConfigPanel:Toggle()
        end
    else
        -- Left-click: toggle main frame
        if MP.MainFrame and MP.MainFrame.Toggle then
            MP.MainFrame:Toggle()
        end
    end
end

function MythicPulse_OnAddonCompartmentEnter(addonName, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_NONE")
    GameTooltip:SetPoint("TOPRIGHT", menuButtonFrame, "BOTTOMRIGHT", 0, 0)
    GameTooltip:SetText("|cff00ccffMythicPulse|r", 1, 1, 1)

    -- Show current key info
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if level and level > 0 and mapID then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        GameTooltip:AddLine(string.format("Key: %s +%d", name or "?", level), 0.9, 0.9, 0.9)
    else
        GameTooltip:AddLine("No keystone", 0.5, 0.5, 0.5)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffffffffLeft-click:|r Toggle display", 0.7, 0.7, 0.7)
    GameTooltip:AddLine("|cffffffffRight-click:|r Open settings", 0.7, 0.7, 0.7)
    GameTooltip:Show()
end

function MythicPulse_OnAddonCompartmentLeave(addonName, menuButtonFrame)
    GameTooltip:Hide()
end

----------------------------------------------------------------------
-- Slash Commands
----------------------------------------------------------------------
SLASH_MYTHICPULSE1 = "/mp"

SlashCmdList["MYTHICPULSE"] = function(input)
    local cmd = strtrim(input):lower()

    if cmd == "" or cmd == "help" then
        MP:Print("|cff00ccffMythicPulse Commands:|r")
        MP:Print("  /mp toggle   — Toggle main display")
        MP:Print("  /mp config   — Open settings")
        MP:Print("  /mp lock     — Lock/unlock frames")
        MP:Print("  /mp reset    — Reset frame positions")
        MP:Print("  /mp key      — Announce your keystone")
        MP:Print("  /mp keys     — Announce all party keys")
        MP:Print("  /mp history  — Show run history")
        MP:Print("  /mp summary  — Show last run summary")
        MP:Print("  /mp utility  — Toggle dungeon utility")
        MP:Print("  /mp rotation — Announce kick rotation")
        MP:Print("  /mp demo     — Toggle demo mode (test layout)")
        
    elseif cmd == "config" or cmd == "options" or cmd == "settings" then
        if MP.ConfigPanel and MP.ConfigPanel.Toggle then
            MP.ConfigPanel:Toggle()
        else
            Settings.OpenToCategory("MythicPulse")
        end
        
    elseif cmd == "toggle" then
        -- Coordinate all three frames as a unit. If ANY is currently shown,
        -- hide all; if ALL are hidden, show all. This avoids the desync that
        -- results from each frame flipping independently when they start in
        -- different visibility states (e.g., MainFrame hidden outside M+
        -- while Tracker/Interrupt are shown).
        local frames = {
            (MP.MainFrame      and MP.MainFrame.frame)      or nil,
            (MP.TrackerFrame   and MP.TrackerFrame.frame)   or nil,
            (MP.InterruptFrame and MP.InterruptFrame.frame) or nil,
        }
        local anyShown = false
        for _, f in ipairs(frames) do
            if f and f:IsShown() then anyShown = true; break end
        end
        local targetShown = not anyShown
        if MP.MainFrame and MP.MainFrame.frame then
            MP.MainFrame.frame:SetShown(targetShown)
            MP.MainFrame.manualState = targetShown and "shown" or "hidden"
        end
        if MP.TrackerFrame and MP.TrackerFrame.frame then
            MP.TrackerFrame.frame:SetShown(targetShown)
            MP.TrackerFrame.manualState = targetShown and "shown" or "hidden"
        end
        if MP.InterruptFrame and MP.InterruptFrame.frame then
            MP.InterruptFrame.frame:SetShown(targetShown)
            MP.InterruptFrame.manualState = targetShown and "shown" or "hidden"
        end
        
    elseif cmd == "lock" then
        if MP.db then
            MP.db.locked = not MP.db.locked
            MP:Print("Frames " .. (MP.db.locked and "locked" or "unlocked"))
            if MP.MainFrame and MP.MainFrame.UpdateLock then
                MP.MainFrame:UpdateLock()
            end
            if MP.TrackerFrame and MP.TrackerFrame.UpdateLock then
                MP.TrackerFrame:UpdateLock()
            end
            if MP.InterruptFrame and MP.InterruptFrame.UpdateLock then
                MP.InterruptFrame:UpdateLock()
            end
        end
        
    elseif cmd == "reset" then
        if MP.MainFrame and MP.MainFrame.ResetPosition then
            MP.MainFrame:ResetPosition()
        end
        if MP.TrackerFrame and MP.TrackerFrame.ResetPosition then
            MP.TrackerFrame:ResetPosition()
        end
        if MP.InterruptFrame and MP.InterruptFrame.ResetPosition then
            MP.InterruptFrame:ResetPosition()
        end
        MP:Print("Frame positions reset.")
        
    elseif cmd == "history" then
        local history = MP:GetModule("DungeonHistory")
        if history and history.ShowSummary then
            history:ShowSummary()
        end

    elseif cmd == "summary" or cmd == "last" then
        if MP.RunSummary and MP.RunSummary.lastRun then
            MP.RunSummary:Show(MP.RunSummary.lastRun)
        else
            MP:Print("No completed run in this session yet.")
        end
        
    elseif cmd == "keys" then
        local kt = MP:GetModule("KeystoneTracker")
        if kt and kt.AnnounceKeys then
            kt:AnnounceKeys()
        else
            MP:Print("Keystone tracker unavailable.")
        end

    elseif cmd == "debug" then
        if MP.db then
            MP.db.debug = not MP.db.debug
            MP:Print("Debug mode " .. (MP.db.debug and "enabled" or "disabled"))
        end
        
    elseif cmd == "utility" or cmd == "util" then
        local du = MP:GetModule("DungeonUtility")
        if du and du.Toggle then
            du:Toggle()
        end

    elseif cmd == "demo" then
        if MP.Demo and MP.Demo.Toggle then
            MP.Demo:Toggle()
        else
            MP:Print("Demo module not available.")
        end

    elseif cmd == "rotation" or cmd == "rot" or cmd == "kicks" then
        local it = MP:GetModule("InterruptTracker")
        if it and it.AnnounceRotation then
            it:AnnounceRotation()
        else
            MP:Print("Interrupt tracker unavailable.")
        end

    elseif cmd == "version" or cmd == "ver" then
        MP:Print("Version: " .. MP.version)
        
    else
        MP:Print("Unknown command '" .. cmd .. "'. Type /mp help for a list.")
    end
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
MP:RegisterEvent("ADDON_LOADED", function(event, addon)
    if addon ~= ADDON_NAME then return end
    
    -- Initialize config (Config.lua handles SavedVariables merge)
    -- Modules register themselves during file load
    
    MP:Debug("Core loaded. Version:", MP.version)
end)

MP:RegisterEvent("PLAYER_ENTERING_WORLD", function(event, isInitialLogin, isReloadingUi)
    if isInitialLogin then
        MP:Print("v" .. MP.version .. " loaded. Type |cffffffff/mp help|r for commands.")
    end
    
    -- Notify modules of world entry
    for name, mod in pairs(MP.modules) do
        if mod.enabled and mod.OnPlayerEnteringWorld then
            mod:OnPlayerEnteringWorld(isInitialLogin, isReloadingUi)
        end
    end
end)

MP:RegisterEvent("PLAYER_LOGOUT", function()
    -- Let modules save any pending data
    for name, mod in pairs(MP.modules) do
        if mod.enabled and mod.OnSave then
            mod:OnSave()
        end
    end
end)
