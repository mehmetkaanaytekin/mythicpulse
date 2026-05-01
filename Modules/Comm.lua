--[[
    MythicPulse - Party Communication Module
    Centralized addon-to-addon messaging via CHAT_MSG_ADDON.

    Message format:  "<TYPE>:<payload>"
    Examples:
        KEY:mapID:level       (keystone broadcast)
        CD:spellID            (cooldown cast broadcast)
        INT:spellID           (interrupt cast broadcast)

    Handlers register per-type and receive (payload, senderShort, senderFull, channel).
    Self-messages (player casting) are filtered out by the dispatcher.

    MIDNIGHT 12.0.5 COMPLIANCE:
    - Uses the standard C_ChatInfo.SendAddonMessage API (whitelisted)
    - Messages are small strings; no combat automation is relayed
    - All send paths are gated by IsInGroup() so solo play never broadcasts
]]

local _, MP = ...

local Comm = {
    registeredEvents = { "CHAT_MSG_ADDON" },
}

local PREFIX = "MythicPulse"
Comm.PREFIX = PREFIX

local handlers = {}

----------------------------------------------------------------------
-- Handler Registration
----------------------------------------------------------------------
--- Register a handler for a message type.
--- handler signature: function(payload, senderShort, senderFull, channel)
function Comm:RegisterHandler(msgType, handler)
    if type(msgType) ~= "string" or type(handler) ~= "function" then return end
    handlers[msgType] = handlers[msgType] or {}
    table.insert(handlers[msgType], handler)
end

----------------------------------------------------------------------
-- Send a message to the group
----------------------------------------------------------------------
--- Sends "<msgType>:<payload>" to the best group channel.
--- Returns true if broadcast was attempted, false if not in a group.
function Comm:Send(msgType, payload)
    if type(msgType) ~= "string" then return false end

    local channel
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        channel = "INSTANCE_CHAT"
    elseif IsInGroup() then
        channel = "PARTY"
    else
        return false
    end

    local msg = msgType
    if payload ~= nil then
        msg = msgType .. ":" .. tostring(payload)
    end

    C_ChatInfo.SendAddonMessage(PREFIX, msg, channel)
    return true
end

----------------------------------------------------------------------
-- Event dispatcher
----------------------------------------------------------------------
local function ShortName(sender)
    if not sender then return nil end
    return sender:match("^[^-]+") or sender
end

function Comm:OnEvent(event, prefix, msg, channel, sender)
    if event ~= "CHAT_MSG_ADDON" then return end
    if prefix ~= PREFIX then return end
    if not msg or msg == "" then return end

    -- Ignore messages from ourselves (the sender doesn't receive their own
    -- addon messages in most cases, but REQUEST_KEYS round-trips can cause
    -- duplicates when the dispatcher fires before the direct call returns).
    if self:IsSelf(sender) then return end

    -- Parse "TYPE:payload" or just "TYPE"
    local msgType, payload = msg:match("^([^:]+):?(.*)$")
    if not msgType then return end
    if payload == "" then payload = nil end

    local list = handlers[msgType]
    if not list then return end

    local senderShort = ShortName(sender)

    for _, handler in ipairs(list) do
        -- Don't let a bad handler break the dispatch chain
        local ok, err = pcall(handler, payload, senderShort, sender, channel)
        if not ok then
            MP:Debug("Comm handler error for " .. msgType .. ": " .. tostring(err))
        end
    end
end

----------------------------------------------------------------------
-- Helper: is this sender actually me?
----------------------------------------------------------------------
function Comm:IsSelf(sender)
    if not sender then return false end
    local playerName = UnitName("player")
    local realm = GetRealmName() and GetRealmName():gsub("%s+", "")
    if sender == playerName then return true end
    if realm and sender == playerName .. "-" .. realm then return true end
    local short = ShortName(sender)
    return short == playerName
end

----------------------------------------------------------------------
-- Initialization
----------------------------------------------------------------------
function Comm:OnFrameReady()
    C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("Comm", Comm)
MP.Comm = Comm
