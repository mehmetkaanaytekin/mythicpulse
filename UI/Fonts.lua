--[[
    MythicPulse - Font Definitions
    Shared font objects used across all UI elements.

    Fonts are backed by named font objects so SetFont can be called at
    runtime to re-apply the user's font scale (fixes readability at high
    resolutions).

    Cyrillic / Unicode strategy:
    WoW's bundled TTF files (ARIALN, FRIZQT__) do not include Cyrillic glyphs
    on non-ruRU clients. ChatFontNormal is configured by the engine with a full
    Unicode fallback stack that does render Cyrillic. We copy that object first
    so our fonts inherit the same stack, then override only the size and style.
]]

local _, MP = ...

MP.Fonts = {}

local FONT_PATH = "Interface\\AddOns\\MythicPulse\\Fonts\\expressway.ttf"

-- Base (1.0x) sizes. Apply() multiplies these by the current scale.
local BASE_SIZES = {
    Title    = 20,
    Header   = 17,
    Body     = 15,
    Small    = 14,
    Timer    = 30,
    TimerSm  = 20,
    Number   = 26,
    Label    = 16,
}

local FLAGS = {
    Title    = "OUTLINE",
    Header   = "OUTLINE",
    Body     = "",
    Small    = "",
    Timer    = "OUTLINE",
    TimerSm  = "OUTLINE",
    Number   = "OUTLINE",
    Label    = "OUTLINE",
}

local function MakeFont(name, size, flags, shadowX, shadowY)
    local font = CreateFont("MythicPulse" .. name)
    font:SetFont(FONT_PATH, size, flags or "")
    if shadowX then
        font:SetShadowOffset(shadowX, shadowY or -1)
        font:SetShadowColor(0, 0, 0, 0.8)
    end
    font.__mpBaseSize = size
    font.__mpFlags    = flags or ""
    return font
end

for name, size in pairs(BASE_SIZES) do
    MP.Fonts[name] = MakeFont(name, size, FLAGS[name], 1, -1)
end

--- Return the current font scale from saved settings.
function MP.Fonts:GetScale()
    local s = MP.db and MP.db.fontScale
    if type(s) ~= "number" or s <= 0 then return 1.0 end
    if s < 0.7 then s = 0.7 end
    if s > 2.0 then s = 2.0 end
    return s
end

--- Re-apply all font objects using the current scale.
--- Uses each font's cached locale path so CopyFontObject's locale is preserved.
function MP.Fonts:Apply()
    local scale = self:GetScale()
    for name, base in pairs(BASE_SIZES) do
        local font = self[name]
        if font then
            font:SetFont(FONT_PATH, math.floor(base * scale + 0.5), FLAGS[name] or "")
        end
    end
end

-- Re-apply after settings load
MP:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    MP.Fonts:Apply()
end)
