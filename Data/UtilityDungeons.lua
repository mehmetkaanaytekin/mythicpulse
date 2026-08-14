--[[
    MythicPulse - Utility Dungeon Data
    Dungeon-specific mechanic entries for all Season 1 M+ dungeons.
    
    Each entry describes a boss/trash mechanic and which utility tags apply.
    Text uses {spell:ID} and {npc:ID} placeholders that get resolved at runtime
    into clickable hyperlinks with icons.
    
    Tags:
        [important]       = Strong impact, must-have pick
        [super_important] = Highest priority, shown with ! marker
        (no importance)   = Moderate impact, recommended
        
    Matching tags correspond to tags in UtilitySpells.lua to cross-reference
    which player abilities are useful for each mechanic.
]]

local _, MP = ...

MP.UtilityData = MP.UtilityData or {}

----------------------------------------------------------------------
-- Supported Tags (master list for validation)
----------------------------------------------------------------------
MP.UtilityData.supportedTags = {
    self_only = true,
    cast_cc_aberration = true, cast_cc_beast = true, cast_cc_critter = true,
    cast_cc_demon = true, cast_cc_dragonkin = true, cast_cc_elemental = true,
    cast_cc_giant = true, cast_cc_humanoid = true, cast_cc_mechanical = true,
    cast_cc_undead = true, cast_cc_other = true,
    cc_aberration = true, cc_beast = true, cc_critter = true,
    cc_demon = true, cc_dragonkin = true, cc_elemental = true,
    cc_giant = true, cc_humanoid = true, cc_mechanical = true,
    cc_undead = true, cc_other = true,
    cc_cyclone = true,
    creature_grip = true, creature_root = true, creature_slow = true,
    creature_stun = true, creature_fear = true, creature_incapacitate = true,
    creature_mortal_strike = true,
    bleed = true, charm = true, curse = true, disease = true,
    enrage = true, fear = true, incapacitate = true, poison = true,
    purge = true, sleep = true, slow = true, root = true,
    snare = true, snare_jet = true, stealth = true, stun = true,
    player_jump = true, player_movement_immune = true, alter_time = true,
    targeted_avoid = true, magic_debuff = true, physical_debuff = true,
}

----------------------------------------------------------------------
-- Dungeon Names (instanceID -> display name)
----------------------------------------------------------------------
-- NOTE: keyed by instanceID (GetInstanceInfo), NOT ChallengeMapID. See Docs/SEASON_UPDATE.md.
MP.UtilityData.dungeonNames = {
    [2526] = "Algeth'ar Academy",
    [2811] = "Magisters' Terrace",
    [2874] = "Maisara Caverns",
    [2915] = "Nexus-Point Xenas",
    [658]  = "Pit of Saron",
    [1753] = "Seat of the Triumvirate",
    [1209] = "Skyreach",
    [2805] = "Windrunner Spire",
    -- Season 2. instanceID = MapChallengeMode.MapID field (verified against
    -- Skyreach/Windrunner Spire above, which match exactly), wago.tools 2026-08-14.
    [2993] = "Altar of Fangs",
    [2813] = "Murder Row",
    [2825] = "Den of Nalorakk",
    [2859] = "The Blinding Vale",
    [2923] = "Voidscar Arena",
    [1762] = "Kings' Rest",
    [1877] = "Temple of Sethraliss",
    [2521] = "Ruby Life Pools",
    -- No dungeonEntries (CC/stops/skips content) authored yet for these —
    -- they'll show in the dropdown with an empty panel until written.
}

-- Default dungeon to show when not in a dungeon. May be stale across a season
-- rotation, so consumers should call GetDefaultDungeonID() instead of reading
-- this directly.
MP.UtilityData.defaultDungeonID = 2526

--- Return a default instanceID that is guaranteed to exist in dungeonEntries.
--- Prefers defaultDungeonID, but falls back to any available entry so a stale
--- default (e.g. after a season rotation) never shows an empty panel by mistake.
function MP.UtilityData:GetDefaultDungeonID()
    local entries = self.dungeonEntries
    if not entries then return self.defaultDungeonID end
    if self.defaultDungeonID and entries[self.defaultDungeonID] then
        return self.defaultDungeonID
    end
    return (next(entries))
end

----------------------------------------------------------------------
-- Dungeon Entries (instanceID -> array of mechanic entries)
----------------------------------------------------------------------
MP.UtilityData.dungeonEntries = {
    ----------------------------------------------------------------
    -- Algeth'ar Academy (2526)
    ----------------------------------------------------------------
    [2526] = {
        -- Boss
        { text = "{spell:388623} debuff is inflicted on the first boss {npc:196482}.",
          tags = "[important][bleed][physical_debuff]" },
        { text = "{spell:389033} debuff is inflicted by {npc:197398} on the first boss {npc:196482}.",
          tags = "[important][poison][magic_debuff]" },
        { text = "{spell:376997} debuff is inflicted by the second boss {npc:191736}.",
          tags = "[bleed][physical_debuff]" },
        { text = "Mitigates effects of {spell:388822} on the last boss {npc:190609}.",
          tags = "[important][player_jump][player_movement_immune][alter_time]" },
        -- Trash
        { text = "{spell:377389} buff is cast by {npc:192333} (trash before {npc:191736}). Also, this cast can be interrupted.",
          tags = "[important][enrage]" },
        { text = "{spell:388392} debuff is inflicted by {npc:196044} (trash before {npc:194181}). Also, this cast can be interrupted.",
          tags = "[important][sleep]" },
        { text = "{spell:388392} is cast by {npc:196044} (trash before {npc:194181}). Also, this cast can be interrupted.",
          tags = "[important][creature_stun][creature_incapacitate][creature_grip][cc_elemental]" },
        { text = "Avoid {spell:388392} when {npc:196044} casts on last seconds.",
          tags = "[important][targeted_avoid]" },
        { text = "Avoid {spell:388940} when {npc:196671} jumps. Targets the furthest player.",
          tags = "[important][targeted_avoid]" },
        { text = "{spell:390938} buff on {npc:197406} (trash before {npc:191736}).",
          tags = "[enrage]" },
        { text = "{spell:377344} debuff is inflicted by {npc:192329} (trash before {npc:191736}).",
          tags = "[bleed][physical_debuff]" },
        { text = "{spell:1282244} debuff is inflicted by {npc:197219} (trash before {npc:196482}).",
          tags = "[bleed][physical_debuff]" },
    },

    ----------------------------------------------------------------
    -- Magisters' Terrace (2811)
    ----------------------------------------------------------------
    [2811] = {
        -- Boss
        { text = "{spell:1214038} debuff is inflicted by the first boss {npc:231861}.",
          tags = "[important][slow][root][magic_debuff]" },
        { text = "{spell:1248689} buff on the second boss {npc:231863}.",
          tags = "[super_important][purge]" },
        { text = "{spell:1269631} debuff is inflicted by contact with orbs on the last boss {npc:231865}.",
          tags = "[important][slow][root][magic_debuff]" },
        -- Trash
        { text = "{spell:1254306} buff is cast by {npc:234486}.",
          tags = "[super_important][purge]" },
        { text = "{spell:1265977} is cast by {npc:234068}.",
          tags = "[important][creature_mortal_strike]" },
        { text = "Avoid {spell:1244907} when {npc:240973} throws glaive.",
          tags = "[important][targeted_avoid]" },
        { text = "{spell:1264693} debuff is inflicted by {npc:231552} (trash before {npc:231864}). Also, this cast can be interrupted and LoS.",
          tags = "[important][fear]" },
        { text = "Avoid {spell:1282050} when {npc:257476} casts on last seconds.",
          tags = "[targeted_avoid]" },
        { text = "{spell:1252909} buff on {npc:234124}.",
          tags = "[purge]" },
        { text = "Skips add pack before the last boss {npc:231865}. This is route specific.",
          tags = "[player_jump]" },
    },

    ----------------------------------------------------------------
    -- Maisara Caverns (2874)
    ----------------------------------------------------------------
    [2874] = {
        -- Boss
        { text = "{spell:1266488} debuff is inflicted by the first boss {npc:247572}.",
          tags = "[important][bleed][physical_debuff]" },
        { text = "Avoid {spell:1260643} when the first boss {npc:247570} starts channeling.",
          tags = "[targeted_avoid]" },
        { text = "{spell:1246666} debuff is inflicted by the first boss {npc:247572}.",
          tags = "[disease][magic_debuff]" },
        { text = "{spell:1260709} debuff is inflicted by the first boss {npc:247570}.",
          tags = "[snare][magic_debuff]" },
        { text = "{spell:1260709} debuff is inflicted by the first boss {npc:247570}. Debuff is removed only from yourself.",
          tags = "[snare_jet]" },
        { text = "Avoid {spell:1252777} when totem starts channeling on the last boss {npc:248595}.",
          tags = "[important][targeted_avoid]" },
        { text = "{spell:1254175} debuff is inflicted by contact with {npc:1531} on the last boss {npc:248605}.",
          tags = "[slow][root][magic_debuff]" },
        -- Trash
        { text = "{spell:1259794} debuff is inflicted by {npc:253683}.",
          tags = "[super_important][slow][root][magic_debuff][targeted_avoid]" },
        { text = "{spell:1270079} buff on {npc:248690}.",
          tags = "[important][purge]" },
        { text = "{spell:1255765} buff on {npc:248684}.",
          tags = "[enrage]" },
        { text = "{spell:1271623} debuff is inflicted by {npc:249024}.",
          tags = "[slow][root][magic_debuff]" },
        { text = "{spell:1266381} debuff is inflicted by {npc:242964}. Also, this cast can be interrupted.",
          tags = "[slow][root][physical_debuff]" },
        { text = "{spell:1257716} is cast by {npc:248692}.",
          tags = "[creature_stun][creature_incapacitate][creature_grip][cc_undead]" },
        { text = "{spell:1255966} is cast by {npc:242964}.",
          tags = "[creature_mortal_strike]" },
        { text = "{spell:1255966} is cast by {npc:248684}.",
          tags = "[creature_mortal_strike]" },
        { text = "{spell:1256059} debuff is inflicted by {npc:248678}.",
          tags = "[bleed][physical_debuff]" },
        { text = "Avoid {spell:1263292} when {npc:254740} starts channeling.",
          tags = "[targeted_avoid]" },
    },

    ----------------------------------------------------------------
    -- Nexus-Point Xenas (2915)
    ----------------------------------------------------------------
    [2915] = {
        -- Trash
        { text = "{spell:1263785} buff on {npc:254928}.",
          tags = "[important][purge]" },
        { text = "{spell:249081} debuff is inflicted by {npc:241647}.",
          tags = "[important][slow][snare][magic_debuff]" },
        { text = "{spell:249081} debuff is inflicted by {npc:241647}. Debuff is removed only from yourself.",
          tags = "[important][snare_jet]" },
        { text = "Avoid {spell:1252062} when {npc:241660} starts channeling.",
          tags = "[targeted_avoid]" },
        { text = "{spell:1285445} is channeled by {npc:241644}.",
          tags = "[creature_stun][creature_fear][creature_incapacitate][creature_grip][cc_humanoid]" },
        { text = "{spell:1281636} debuff is inflicted by {npc:248706}.",
          tags = "[curse][magic_debuff]" },
        { text = "{spell:1282724} debuff is inflicted by {npc:251853}. Also, this debuff can be avoided.",
          tags = "[fear]" },
        { text = "{spell:1252204} is cast by {npc:241645}.",
          tags = "[creature_stun][creature_fear][creature_incapacitate][creature_grip][creature_mortal_strike][cc_aberration]" },
        { text = "Prevent {npc:248769} from reaching {npc:252903}.",
          tags = "[creature_slow][creature_grip]" },
    },

    ----------------------------------------------------------------
    -- Pit of Saron (658)
    ----------------------------------------------------------------
    [658] = {
        -- Boss
        { text = "{spell:1261921} debuff is inflicted by the first boss {npc:36494}.",
          tags = "[important][slow][snare][magic_debuff]" },
        { text = "{spell:1261921} debuff is inflicted by the first boss {npc:36494}. Debuff is removed only from yourself.",
          tags = "[important][snare_jet]" },
        { text = "{spell:1264186} debuff is inflicted by the second boss {npc:36477}.",
          tags = "[super_important][slow][snare][curse][magic_debuff]" },
        { text = "{spell:1264186} debuff is inflicted by the second boss {npc:36477}. Debuff is removed only from yourself.",
          tags = "[super_important][snare_jet]" },
        { text = "{spell:1262930} debuff is inflicted on the last boss {npc:36658}.",
          tags = "[disease][physical_debuff]" },
        -- Trash
        { text = "{spell:1258997} debuff is inflicted by {npc:252707}.",
          tags = "[super_important][slow][root][physical_debuff]" },
        { text = "{spell:1258997} is channeled by {npc:252707}. The caster is immune to CC while it has {spell:1271543}",
          tags = "[important][creature_stun][creature_incapacitate][creature_grip][cc_undead]" },
        { text = "{spell:1258434} debuff is inflicted by {npc:252561}.",
          tags = "[important][curse][magic_debuff]" },
        { text = "{spell:1258437} debuff is inflicted by {npc:252566}.",
          tags = "[important][slow][snare][magic_debuff]" },
        { text = "{spell:1258437} debuff is inflicted by {npc:252566}. Debuff is removed only from yourself.",
          tags = "[important][snare_jet]" },
        { text = "{spell:1258448} buff is cast by {npc:252551}.",
          tags = "[purge]" },
        { text = "{spell:1259132} buff on {npc:252555}.",
          tags = "[enrage]" },
        { text = "{spell:1258459} debuff is inflicted by {npc:252558}.",
          tags = "[disease][physical_debuff]" },
        { text = "Avoid {spell:1258826} when {npc:252563} starts channeling.",
          tags = "[targeted_avoid]" },
    },

    ----------------------------------------------------------------
    -- Seat of the Triumvirate (1753)
    ----------------------------------------------------------------
    [1753] = {
        -- Boss
        { text = "Prevent {npc:122716} from reaching the first boss {npc:122313}.",
          tags = "[important][creature_slow][creature_grip][cc_aberration][cast_cc_aberration]" },
        { text = "{spell:245742} debuff is inflicted on the second boss {npc:122316}.",
          tags = "[bleed][physical_debuff]" },
        { text = "{spell:1268733} is channeled by {npc:122827} on the third boss {npc:124309}.",
          tags = "[creature_stun][creature_fear][creature_incapacitate][cc_aberration]" },
        { text = "Avoid {spell:1268733} when {npc:122827} starts channeling on the third boss {npc:124309}.",
          tags = "[targeted_avoid]" },
        -- Trash
        { text = "{spell:1262509} debuff is inflicted by {npc:124171}.",
          tags = "[important][slow][snare][magic_debuff]" },
        { text = "{spell:1262509} debuff is inflicted by {npc:124171}. Debuff is removed only from yourself.",
          tags = "[important][snare_jet]" },
        { text = "{spell:1262526} buff on {npc:122404}.",
          tags = "[purge]" },
        { text = "{spell:1264036} buff on {npc:122403}.",
          tags = "[enrage]" },
        { text = "{spell:1264678} is cast by {npc:255320}.",
          tags = "[creature_mortal_strike]" },
        { text = "{spell:1277339} is cast by {npc:122413}.",
          tags = "[creature_stun][creature_fear][creature_incapacitate][creature_grip][cc_humanoid]" },
        { text = "Avoid {spell:1262508} when {npc:122423} starts channeling.",
          tags = "[targeted_avoid]" },
    },

    ----------------------------------------------------------------
    -- Skyreach (1209)
    ----------------------------------------------------------------
    [1209] = {
        -- Boss
        { text = "{spell:153757} debuff is inflicted on the first boss {npc:75964}.",
          tags = "[bleed][physical_debuff]" },
        { text = "Prevent {npc:76227} from reaching players on the third boss {npc:76379}.",
          tags = "[creature_slow][creature_grip]" },
        { text = "Stun {npc:76267} on the last boss {npc:76266}.",
          tags = "[creature_stun]" },
        { text = "Avoid {spell:154044} when the last boss {npc:76266} targets you.",
          tags = "[important][targeted_avoid]" },
        { text = "Jump back to the platform if you are thrown off by {npc:76267} on the last boss {npc:76266}.",
          tags = "[important][player_jump]" },
        -- Trash
        { text = "{spell:1254475} debuff is inflicted by {npc:79303}.",
          tags = "[important][bleed][physical_debuff]" },
        { text = "Avoid {spell:1254475} when {npc:79303} jumps on you.",
          tags = "[important][targeted_avoid]" },
        { text = "{spell:1254686} is cast by {npc:76154}.",
          tags = "[important][creature_stun][creature_fear][creature_incapacitate][cc_humanoid]" },
        { text = "Avoid {spell:1253446} when {npc:76087} starts channeling.",
          tags = "[important][targeted_avoid]" },
        { text = "Skips part of the wind maze after the third boss {npc:76379}.",
          tags = "[important][player_jump][player_movement_immune]" },
        { text = "{spell:1254690} is cast by {npc:79093}.",
          tags = "[creature_slow]" },
        { text = "{spell:1254670} buff on {npc:78096}.",
          tags = "[purge]" },
        { text = "{spell:1273356} buff is cast by {npc:79462}.",
          tags = "[purge]" },
        { text = "{spell:1254678} buff on {npc:250992}.",
          tags = "[enrage]" },
    },

    ----------------------------------------------------------------
    -- Windrunner Spire (2805)
    ----------------------------------------------------------------
    [2805] = {
        -- Boss
        { text = "{spell:1215803} debuff is inflicted by the second boss {npc:231626}.",
          tags = "[super_important][curse][magic_debuff]" },
        { text = "{spell:1253030} debuff is inflicted by the third boss {npc:231631}. Also, this debuff can be avoided.",
          tags = "[fear]" },
        { text = "Avoid {spell:474528} when the last boss {npc:231636} starts channeling.",
          tags = "[targeted_avoid]" },
        -- Trash
        { text = "{spell:1216459} buff is cast by {npc:232146}.",
          tags = "[important][enrage]" },
        { text = "Avoid {spell:1216848} when {npc:236891} starts channeling.",
          tags = "[important][targeted_avoid]" },
        { text = "{spell:1216848} is channeled by {npc:236891}.",
          tags = "[important][creature_stun][creature_fear][creature_incapacitate][creature_grip][cc_beast]" },
        { text = "{spell:473794} debuff is inflicted by {npc:232171}. Also, this cast can be interrupted.",
          tags = "[important][poison][magic_debuff]" },
        { text = "{spell:1217094} debuff is inflicted by {npc:232447}.",
          tags = "[important][bleed][physical_debuff]" },
        { text = "Avoid {spell:1217094} when {npc:232447} throws axe.",
          tags = "[important][targeted_avoid]" },
        { text = "{spell:1216860} buff on {npc:236891}.",
          tags = "[important][purge]" },
        { text = "{spell:1216449} is channeled by {npc:238035}.",
          tags = "[creature_stun][creature_incapacitate][creature_grip][cc_undead]" },
        { text = "{spell:1216637} is channeled by {npc:232147}.",
          tags = "[creature_stun][creature_incapacitate][creature_grip][cc_undead]" },
        { text = "{spell:1216822} debuff is inflicted by {npc:232067}.",
          tags = "[poison][magic_debuff]" },
        { text = "{spell:1216985} debuff is inflicted by {npc:232063}.",
          tags = "[bleed][physical_debuff]" },
        { text = "{spell:1253739} debuff is inflicted by {npc:232283}.",
          tags = "[bleed][physical_debuff]" },
    },
}
