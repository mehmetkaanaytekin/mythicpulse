--[[
    MythicPulse - Cooldown Icon Widget
    Individual spell cooldown icon with sweep animation and class-colored border.

    The cooldown countdown text is sized proportionally to the icon so the
    number always fits inside the icon frame — including smaller icons where
    a fixed-size font would overflow.
]]

local _, MP = ...

MP.CooldownIconWidget = {}

local BASE_FONT = "Fonts\\FRIZQT__.TTF"

--- Pick a readable font size for the CD text given an icon size.
local function CDTextSize(iconSize)
    -- ~55% of icon is a good rule of thumb; minimum 10 to stay legible.
    local s = math.floor(iconSize * 0.55 + 0.5)
    if s < 10 then s = 10 end
    return s
end

function MP.CooldownIconWidget:Create(parent, size)
    size = size or 28

    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(size, size)

    -- Class-colored border (Background)
    frame.border = frame:CreateTexture(nil, "BACKGROUND")
    frame.border:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.border:SetAllPoints()
    frame.border:SetVertexColor(0.3, 0.3, 0.4, 1)

    -- Inner black background (Optional, underneath icon if it has transparency)
    frame.innerBorder = frame:CreateTexture(nil, "ARTWORK", nil, -1)
    frame.innerBorder:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.innerBorder:SetPoint("TOPLEFT", 1, -1)
    frame.innerBorder:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.innerBorder:SetVertexColor(0, 0, 0, 1)

    -- Icon texture (Shrunk by 1px to reveal the border underneath)
    frame.icon = frame:CreateTexture(nil, "ARTWORK", nil, 0)
    frame.icon:SetPoint("TOPLEFT", 1, -1)
    frame.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown sweep
    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetAllPoints(frame.icon)
    frame.cooldown:SetDrawEdge(true)
    frame.cooldown:SetDrawSwipe(true)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.65)
    -- Suppress the built-in cooldown text so our overlay is authoritative
    frame.cooldown:SetHideCountdownNumbers(true)

    -- Active-aura glow: pulsating green border shown while the buff is up.
    -- Hidden by default and toggled via SetActive().
    frame.activeGlow = frame:CreateTexture(nil, "OVERLAY", nil, 6)
    frame.activeGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    frame.activeGlow:SetPoint("TOPLEFT", -2, 2)
    frame.activeGlow:SetPoint("BOTTOMRIGHT", 2, -2)
    frame.activeGlow:SetVertexColor(0.3, 1.0, 0.4, 0.7)
    frame.activeGlow:SetBlendMode("ADD")
    frame.activeGlow:Hide()

    -- Cooldown text overlay (on top of the sweep)
    frame.cdText = frame.cooldown:CreateFontString(nil, "OVERLAY")
    frame.cdText:SetFont(BASE_FONT, CDTextSize(size), "OUTLINE")
    frame.cdText:SetPoint("CENTER", 0, 0)
    frame.cdText:SetTextColor(1, 1, 1)
    frame.cdText:SetDrawLayer("OVERLAY", 7)
    frame.cdText:Hide()

    -- Tooltip
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function(self)
        if self.spellID then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    --- Re-apply text sizing after the widget's size changes.
    --- Callers that resize the icon via frame:SetSize(w, h) should call this.
    function frame:ApplySize(w)
        if self.cdText then
            self.cdText:SetFont(BASE_FONT, CDTextSize(w), "OUTLINE")
        end
    end

    --- Set the spell icon
    function frame:SetSpell(spellID, className)
        self.spellID = spellID
        local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if info and info.iconID then
            self.icon:SetTexture(info.iconID)
        end
        -- Class-colored border
        if className and RAID_CLASS_COLORS[className] then
            local c = RAID_CLASS_COLORS[className]
            self.border:SetVertexColor(c.r, c.g, c.b, 0.9)
        end
    end

    --- Start cooldown animation
    function frame:StartCooldown(duration, startTime)
        startTime = startTime or GetTime()
        self.cooldown:SetCooldown(startTime, duration)
        self.endTime = startTime + duration
        self.icon:SetDesaturated(true)
        self.icon:SetAlpha(0.5)
    end

    --- Clear cooldown (spell is ready)
    function frame:ClearCooldown()
        self.cooldown:Clear()
        self.endTime = nil
        self.cdText:Hide()
        self.icon:SetDesaturated(false)
        self.icon:SetAlpha(1.0)
    end

    --- Check if on cooldown
    function frame:IsOnCooldown()
        return self.endTime and GetTime() < self.endTime
    end

    --- Update the cooldown text
    function frame:UpdateCDText()
        if self.endTime then
            local remain = self.endTime - GetTime()
            if remain > 0 then
                if remain > 60 then
                    self.cdText:SetText(math.floor(remain / 60) .. "m")
                else
                    self.cdText:SetText(math.floor(remain))
                end
                self.cdText:Show()
            else
                self:ClearCooldown()
            end
        end
    end

    --- Toggle the active-aura highlight. When the underlying buff is up,
    --- the icon shows a green glow border to indicate "currently active".
    function frame:SetActive(active)
        if active then
            self.activeGlow:Show()
            -- Brighten the icon even if also on cooldown — buff is active right now
            self.icon:SetAlpha(1.0)
            self.icon:SetDesaturated(false)
        else
            self.activeGlow:Hide()
            -- Restore CD-state appearance if applicable
            if self:IsOnCooldown() then
                self.icon:SetDesaturated(true)
                self.icon:SetAlpha(0.5)
            end
        end
        self._active = active and true or false
    end

    function frame:IsActive()
        return self._active == true
    end

    return frame
end
