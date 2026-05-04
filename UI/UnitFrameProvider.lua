--[[
    MythicPulse - Unit Frame Provider
    Abstracts Blizzard vs ElvUI party/raid frame discovery.
    Call :GetFrame(unitToken) to get the live unit frame for anchoring.
    Call :RegisterCallback(owner, fn) to be notified when frames change.
]]

local _, MP = ...

MP.UnitFrameProvider = {}
local Provider = MP.UnitFrameProvider

local cache     = {}    -- unitToken -> Frame|false
local provider  = nil   -- "elvui"|"blizzard"
local callbacks = {}    -- owner -> fn(unitToken|nil)
local pending   = false
local elvHooked = false

----------------------------------------------------------------------
-- Provider detection
----------------------------------------------------------------------
local function ResolveProvider()
    local E = _G.ElvUI and _G.ElvUI[1]
    if not E or not E.initialized then return "blizzard" end
    local UF = E:GetModule("UnitFrames", true)
    if not UF then return "blizzard" end
    local db = E.db and E.db.unitframe and E.db.unitframe.units
    if not db or not db.party or db.party.enable == false then return "blizzard" end
    if not _G.ElvUF_Party then return "blizzard" end
    return "elvui"
end

----------------------------------------------------------------------
-- Frame walkers
----------------------------------------------------------------------
local function WalkChildren(parent, unitToken)
    for _, child in ipairs({parent:GetChildren()}) do
        if child.unit == unitToken then return child end
    end
    return nil
end

local function WalkChildrenDeep(parent, unitToken)
    for _, child in ipairs({parent:GetChildren()}) do
        if child.unit == unitToken then return child end
        local sub = WalkChildren(child, unitToken)
        if sub then return sub end
    end
    return nil
end

local function GetElvUIFrame(unitToken)
    local E = _G.ElvUI and _G.ElvUI[1]
    if not E then return nil end

    if unitToken == "player" then
        local db = E.db and E.db.unitframe and E.db.unitframe.units
        if db and db.player and db.player.enable ~= false then
            return _G.ElvUF_Player
        end
        return nil
    end

    local partyParent = _G.ElvUF_Party
    if partyParent then
        local f = WalkChildrenDeep(partyParent, unitToken)
        if f then return f end
    end

    if unitToken:match("^raid%d+$") then
        for i = 1, 8 do
            local raidParent = _G["ElvUF_Raid" .. i]
            if raidParent then
                local f = WalkChildrenDeep(raidParent, unitToken)
                if f then return f end
            end
        end
    end

    return nil
end

local function GetBlizzardFrame(unitToken)
    if unitToken == "player" then
        return _G.PlayerFrame
    end

    -- Non-raid-style: CompactPartyFrame (does not include player)
    local cpf = _G.CompactPartyFrame
    if cpf then
        if cpf.memberUnitFrames then
            for _, f in ipairs(cpf.memberUnitFrames) do
                if f and f.unit == unitToken then return f end
            end
        end
        local f = WalkChildren(cpf, unitToken)
        if f then return f end
    end

    -- Raid-style party / actual raid: CompactRaidFrameContainer
    local container = _G.CompactRaidFrameContainer
    if container then
        for i = 1, 8 do
            local group = _G["CompactRaidGroup" .. i]
            if group then
                local f = WalkChildren(group, unitToken)
                if f then return f end
            end
        end
    end

    return nil
end

----------------------------------------------------------------------
-- Public API
----------------------------------------------------------------------
function Provider:GetFrame(unitToken)
    if cache[unitToken] ~= nil then
        return cache[unitToken] or nil
    end
    local p = provider or "blizzard"
    local result
    if p == "elvui" then
        result = GetElvUIFrame(unitToken)
    else
        result = GetBlizzardFrame(unitToken)
    end
    cache[unitToken] = result or false  -- false = "checked, not found"
    return result
end

function Provider:GetProvider()
    return provider or "none"
end

function Provider:RegisterCallback(owner, fn)
    callbacks[owner] = fn
end

function Provider:UnregisterCallback(owner)
    callbacks[owner] = nil
end

function Provider:Refresh(reason)
    if pending then return end
    pending = true
    C_Timer.After(0.1, function()
        pending   = false
        cache     = {}
        provider  = ResolveProvider()
        if provider == "elvui" and not elvHooked then
            local E  = _G.ElvUI and _G.ElvUI[1]
            local UF = E and E:GetModule("UnitFrames", true)
            if UF then
                hooksecurefunc(UF, "UpdateAllHeaders", function()
                    Provider:Refresh("elvui-update")
                end)
                if UF.CreateAndUpdateHeaderGroup then
                    hooksecurefunc(UF, "CreateAndUpdateHeaderGroup", function()
                        Provider:Refresh("elvui-group")
                    end)
                end
                elvHooked = true
            end
        end
        for _, fn in pairs(callbacks) do
            local ok, err = pcall(fn, nil)
            if not ok then MP:Debug("UnitFrameProvider cb error:", err) end
        end
    end)
end

----------------------------------------------------------------------
-- Events
----------------------------------------------------------------------
local evFrame = CreateFrame("Frame")
evFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
evFrame:RegisterEvent("RAID_ROSTER_UPDATE")
evFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
evFrame:RegisterEvent("PLAYER_LOGIN")
evFrame:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")

evFrame:SetScript("OnEvent", function(_, event)
    Provider:Refresh(event)
end)
