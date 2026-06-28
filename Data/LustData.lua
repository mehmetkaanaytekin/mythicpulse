--[[
    MythicPulse - Lust / Sated / Battle-Res Data

    Single source of truth for Bloodlust-equivalent spells, the Sated-family
    debuffs that gate them, and battle-res spells. Previously these tables were
    duplicated in PartyCooldowns.lua and CombatRes.lua and had to be kept in
    sync by hand — centralizing them here prevents drift.

    These are class/utility spell IDs and are NOT season-specific.
]]

local _, MP = ...

MP.LustData = {}

-- Bloodlust / Heroism-equivalent casts (the spell that grants the haste buff).
MP.LustData.LUST_SPELL_IDS = {
    [2825]   = true,   -- Bloodlust (Shaman)
    [32182]  = true,   -- Heroism (Shaman)
    [80353]  = true,   -- Time Warp (Mage)
    [390386] = true,   -- Fury of the Aspects (Evoker)
    [264667] = true,   -- Primal Rage (BM Hunter pet)
    [90355]  = true,   -- Ancient Hysteria (Hunter exotic pet)
}

-- Sated-family debuffs: presence on ANY party member means lust is on cooldown
-- (covers the case where the lust caster is not running MythicPulse).
MP.LustData.SATED_IDS = {
    [57724]  = true,   -- Sated
    [57723]  = true,   -- Exhaustion
    [80354]  = true,   -- Temporal Displacement
    [160455] = true,   -- Fatigued
    [390435] = true,   -- Enervation (Fury of the Aspects)
}

-- Battle-res spells by caster class.
MP.LustData.BREZ_SPELLS = {
    [20484]  = { class = "DRUID",       duration = 600 },
    [61999]  = { class = "DEATHKNIGHT", duration = 600 },
    [391054] = { class = "PALADIN",     duration = 600 },
    [20707]  = { class = "WARLOCK",     duration = 600 },
}
