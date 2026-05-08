--[[
    MythicPulse - Auto Keystone Slotting Module
    Automatically finds and slots the keystone when the receptacle UI opens.
    
    COMPLIANCE:
    - Uses C_ChallengeMode.SlotKeystone() which is whitelisted
    - Only triggers after player physically interacts with the pedestal
    - One interaction = one action (player clicks pedestal, addon slots key)
]]

local _, MP = ...

local AutoSlot = {
    registeredEvents = {
        "ADDON_LOADED",
    },
}

----------------------------------------------------------------------
-- Find a keystone in the player's bags by scanning item links for
-- the "keystone:" link-type substring. This avoids brute-forcing
-- C_ChallengeMode.SlotKeystone on every bag slot.
----------------------------------------------------------------------
local function FindKeystoneInBags()
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, numSlots do
            local link = C_Container.GetContainerItemLink(bag, slot)
            if link and link:match("|Hkeystone:") then
                return bag, slot, link
            end
        end
    end
    return nil
end

----------------------------------------------------------------------
-- Slot the keystone, if one exists and isn't already slotted.
----------------------------------------------------------------------
local function TrySlotKeystone()
    if C_ChallengeMode.HasSlottedKeystone() then return false end

    if MP.db and MP.db.modules and MP.db.modules.autoSlot
       and not MP.db.modules.autoSlot.enabled then
        return false
    end

    local bag, slot = FindKeystoneInBags()
    if not bag then
        MP:Debug("AutoSlot: no keystone in bags.")
        return false
    end

    local ok = pcall(C_ChallengeMode.SlotKeystone, bag, slot)
    if ok and C_ChallengeMode.HasSlottedKeystone() then
        MP:Print(MP:Loc("AUTOSLOT_DONE"))
        return true
    end
    return false
end

local function HookKeystoneFrame()
    if AutoSlot.hooked then return end
    if ChallengesKeystoneFrame then
        ChallengesKeystoneFrame:HookScript("OnShow", function()
            C_Timer.After(0.2, TrySlotKeystone)
        end)
        AutoSlot.hooked = true
    end
end

----------------------------------------------------------------------
-- Event Handler
----------------------------------------------------------------------
function AutoSlot:OnEvent(event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == "Blizzard_ChallengesUI" then
            HookKeystoneFrame()
        end
    end
end

function AutoSlot:OnFrameReady()
    -- Check if it was already loaded
    if C_AddOns and C_AddOns.IsAddOnLoaded("Blizzard_ChallengesUI") then
        HookKeystoneFrame()
    end
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP:RegisterModule("AutoSlot", AutoSlot)
