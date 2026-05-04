--[[
    MythicPulse - Keystone Tracker Module
    Displays current keystone info and party members' keys.
]]

local _, MP = ...

local KeystoneTracker = {
    registeredEvents = {
        "CHALLENGE_MODE_MAPS_UPDATE",
        "BAG_UPDATE",
        "GROUP_ROSTER_UPDATE",
    },
}

local partyKeys = {}

----------------------------------------------------------------------
-- Update keystone display (cache only, no UI)
----------------------------------------------------------------------

-- Extract dungeon name from keystone item link as a reliable fallback
local function GetDungeonNameFromKeystoneLink()
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and itemLink:match("keystone:") then
                -- Extract name from link format: |cffffffff|Hkeystone:...|h[Keystone: DungeonName (level)]|h|r
                local dungeonName = itemLink:match("%[Keystone: ([^(]+)")
                if dungeonName then
                    return dungeonName:match("^%s*(.-)%s*$")  -- trim whitespace
                end
            end
        end
    end
    return nil
end

-- Track which mapIDs we've already logged to avoid debug spam
local loggedMissingMapIDs = {}

local function UpdateKeystoneInfo()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()

    if not (level and level > 0 and mapID) then return end

    local resolvedName = GetDungeonNameFromKeystoneLink()
    if not resolvedName then
        local apiName = C_ChallengeMode.GetMapUIInfo(mapID)
        if apiName then
            resolvedName = apiName
        elseif not loggedMissingMapIDs[mapID] then
            MP:Debug("Map name not yet cached for keystone mapID:", mapID)
            loggedMissingMapIDs[mapID] = true
        end
    end
    if not resolvedName and MP.DungeonData then
        resolvedName = MP.DungeonData:GetShortName(mapID)
    end

    if MP.db then
        MP.db.keystoneCache = { level = level, mapID = mapID, name = resolvedName }
    end
end

----------------------------------------------------------------------
-- Broadcast key to party via Comm
----------------------------------------------------------------------
local function BroadcastKey()
    if not MP.Comm then return end
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    local mapID = C_MythicPlus.GetOwnedKeystoneMapID()
    if level and level > 0 and mapID then
        MP.Comm:Send("KEY", string.format("%d:%d", mapID, level))
    end
end

----------------------------------------------------------------------
-- Handle incoming key broadcasts from Comm
----------------------------------------------------------------------
local function OnKeyMessage(payload, senderShort, senderFull)
    if not payload then return end
    local mapIDStr, levelStr = strsplit(":", payload)
    local mapID = tonumber(mapIDStr)
    local level = tonumber(levelStr)
    if not mapID or not level then return end

    local name = C_ChallengeMode.GetMapUIInfo(mapID)
    if not name then
        name = MP.DungeonData and MP.DungeonData:GetShortName(mapID) or "Unknown"
    end
    partyKeys[senderFull or senderShort] = {
        mapID = mapID,
        level = level,
        name  = name,
    }
end


----------------------------------------------------------------------
-- Clean up party keys when roster changes
----------------------------------------------------------------------
local function CleanRoster()
    for player in pairs(partyKeys) do
        if not UnitExists(player) then
            partyKeys[player] = nil
        end
    end
end

----------------------------------------------------------------------
-- Module Callbacks
----------------------------------------------------------------------
function KeystoneTracker:OnEvent(event, ...)
    if event == "BAG_UPDATE" then
        if self._bagUpdatePending then return end
        self._bagUpdatePending = true
        C_Timer.After(1, function()
            self._bagUpdatePending = false
            UpdateKeystoneInfo()
        end)
    elseif event == "CHALLENGE_MODE_MAPS_UPDATE" then
        UpdateKeystoneInfo()
    elseif event == "GROUP_ROSTER_UPDATE" then
        CleanRoster()
        UpdateKeystoneInfo()
        C_Timer.After(2, BroadcastKey)
    end
end

----------------------------------------------------------------------
-- Chat Link Enhancement: Enrich keystone links with color-coded levels
-- and dungeon names. Hooks all major chat channels.
----------------------------------------------------------------------
local KEY_LEVEL_COLORS = {
    -- thresholds: gray < +5, white < +10, green < +15, blue < +20, purple < +25, orange 25+
    [0]  = "ffaaaaaa",   -- gray
    [5]  = "ffffffff",   -- white
    [10] = "ff1eff00",   -- green (uncommon)
    [15] = "ff0070dd",   -- blue (rare)
    [20] = "ffa335ee",   -- purple (epic)
    [25] = "ffff8000",   -- orange (legendary)
}

local function GetKeyLevelColor(level)
    local best = 0
    for threshold, _ in pairs(KEY_LEVEL_COLORS) do
        if level >= threshold and threshold > best then
            best = threshold
        end
    end
    return KEY_LEVEL_COLORS[best] or KEY_LEVEL_COLORS[0]
end

local function EnhanceKeystoneLink(link)
    -- Extract data from keystone link
    -- Format: |cXXXXXXXX|Hkeystone:itemID:mapID:level:affix1:...|h[Keystone: Name (X)]|h|r
    local mapID, level = link:match("|Hkeystone:%d+:(%d+):(%d+):")
    if not mapID or not level then return link end

    mapID = tonumber(mapID)
    level = tonumber(level)
    if not mapID or not level then return link end

    -- Resolve dungeon short name
    local name
    if MP.DungeonData and MP.DungeonData.GetShortName then
        name = MP.DungeonData:GetShortName(mapID)
    end
    if not name then
        name = C_ChallengeMode.GetMapUIInfo(mapID)
    end
    if not name then return link end

    -- Build enhanced text with color-coded level
    local color = GetKeyLevelColor(level)
    local enhancedText = string.format("|c%s[%s +%d]|r", color, name, level)

    -- Replace the visible text portion (between |h[ and ]|h)
    return link:gsub("|h%[.-%]|h", "|h" .. enhancedText .. "|h")
end

local function ChatLinkFilter(self, event, msg, ...)
    if not msg or not msg:find("|Hkeystone:", 1, true) then
        return false, msg, ...
    end
    -- Replace each keystone link found in the message
    local newMsg = msg:gsub("(|c%x+|Hkeystone:[%d:]+|h%[[^%]]+%]|h|r)", EnhanceKeystoneLink)
    return false, newMsg, ...
end

local function InstallChatLinkFilter()
    local channels = {
        "CHAT_MSG_CHANNEL",
        "CHAT_MSG_GUILD",
        "CHAT_MSG_OFFICER",
        "CHAT_MSG_PARTY",
        "CHAT_MSG_PARTY_LEADER",
        "CHAT_MSG_RAID",
        "CHAT_MSG_RAID_LEADER",
        "CHAT_MSG_INSTANCE_CHAT",
        "CHAT_MSG_INSTANCE_CHAT_LEADER",
        "CHAT_MSG_SAY",
        "CHAT_MSG_YELL",
        "CHAT_MSG_WHISPER",
        "CHAT_MSG_WHISPER_INFORM",
        "CHAT_MSG_BN_WHISPER",
        "CHAT_MSG_BN_WHISPER_INFORM",
    }
    for _, ev in ipairs(channels) do
        ChatFrame_AddMessageEventFilter(ev, ChatLinkFilter)
    end
end

local function SendOwnKeystoneLink()
    if not IsInGroup() then return end
    local channel = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or "PARTY"
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink and itemLink:match("keystone:") then
                SendChatMessage(itemLink, channel)
                return
            end
        end
    end
end

function KeystoneTracker:AnnounceKeys()
    if not IsInGroup() then
        MP:Print("You are not in a group.")
        return
    end
    -- Ask every addon user in the group to send their own keystone link
    if MP.Comm then
        MP.Comm:Send("REQUEST_KEYS", nil)
    end
    -- Sender doesn't receive their own addon message, so send ours directly
    SendOwnKeystoneLink()
end

function KeystoneTracker:OnFrameReady()
    -- Prime the challenge-mode map cache so GetMapUIInfo returns names
    if C_MythicPlus and C_MythicPlus.RequestMapInfo then
        C_MythicPlus.RequestMapInfo()
    end
    UpdateKeystoneInfo()
    if MP.Comm then
        MP.Comm:RegisterHandler("KEY", OnKeyMessage)
        MP.Comm:RegisterHandler("REQUEST_KEYS", SendOwnKeystoneLink)
    end
    C_Timer.After(3, BroadcastKey)

    -- Install chat link enhancement filter
    InstallChatLinkFilter()
end

function KeystoneTracker:OnPlayerEnteringWorld()
    C_Timer.After(2, UpdateKeystoneInfo)
end

function KeystoneTracker:GetPartyKeys()
    return partyKeys
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("KeystoneTracker", KeystoneTracker)
