--[[
    MythicPulse - Utility Spells Data
    Complete database of class, spec, and racial utility abilities
    with tag-based matching for dungeon mechanic cross-referencing.

    Each spell entry format:
        [spellID] = { tags = "[tag1][tag2]...", baseline = bool, pet = bool, alternatives = {ids}, override = id }

    Tags describe WHAT the ability does (CC type, dispel type, movement, etc.)
    The dungeon data has matching tags describing WHAT is needed.
    Cross-referencing these two produces the utility recommendations.
]]

local _, MP = ...

MP.UtilityData = MP.UtilityData or {}

----------------------------------------------------------------------
-- Class Specialisation ID Mapping
----------------------------------------------------------------------
MP.UtilityData.classSpecs = {
    DEATHKNIGHT = { [250] = true, [251] = true, [252] = true },
    DEMONHUNTER = { [577] = true, [581] = true, [1480] = true },
    DRUID       = { [102] = true, [103] = true, [104] = true, [105] = true },
    EVOKER      = { [1467] = true, [1468] = true, [1473] = true },
    HUNTER      = { [253] = true, [254] = true, [255] = true },
    MAGE        = { [62] = true, [63] = true, [64] = true },
    MONK        = { [268] = true, [270] = true, [269] = true },
    PALADIN     = { [65] = true, [66] = true, [70] = true },
    PRIEST      = { [256] = true, [257] = true, [258] = true },
    ROGUE       = { [259] = true, [260] = true, [261] = true },
    SHAMAN      = { [262] = true, [263] = true, [264] = true },
    WARLOCK     = { [265] = true, [266] = true, [267] = true },
    WARRIOR     = { [71] = true, [72] = true, [73] = true },
}

----------------------------------------------------------------------
-- Racial Utility Abilities
----------------------------------------------------------------------
MP.UtilityData.racialAbilities = {
    [107079] = { tags = "[creature_incapacitate]", racial = true },               -- Quaking Palm
    [20549]  = { tags = "[creature_stun]", racial = true },                       -- War Stomp
    [20589]  = { tags = "[self_only][slow][snare][root]", racial = true },         -- Escape Artist
    [20594]  = { tags = "[self_only][poison][disease][curse][bleed]", racial = true }, -- Stoneform
    [255654] = { tags = "[creature_stun]", racial = true },                       -- Bull Rush
    [265221] = { tags = "[self_only][poison][disease][curse][bleed]", racial = true }, -- Fireblood
    [28730]  = { tags = "[purge]", alternatives = {25046, 50613, 69179, 80483, 129597, 202719}, racial = true }, -- Arcane Torrent
    [357214] = { tags = "[creature_grip]", racial = true },                       -- Wing Buffet
    [358733] = { tags = "[self_only][player_jump]", racial = true },              -- Glide (Dracthyr racial)
    [58984]  = { tags = "[self_only][targeted_avoid]", racial = true },           -- Shadowmeld
    [59752]  = { tags = "[self_only][stun]", racial = true },                     -- Will to Survive
    [69070]  = { tags = "[self_only][player_jump]", racial = true },              -- Rocket Jump
    [7744]   = { tags = "[self_only][charm][fear][sleep]", racial = true },        -- Will of the Forsaken
}

----------------------------------------------------------------------
-- Class & Spec Utility Abilities
----------------------------------------------------------------------
MP.UtilityData.classAbilities = {
    ----------------------------------------------------------------
    -- DEATH KNIGHT
    ----------------------------------------------------------------
    DEATHKNIGHT = {
        [111673] = { tags = "[cast_cc_undead]" },                                      -- Control Undead
        [207167] = { tags = "[creature_incapacitate]" },                               -- Blinding Sleet
        [212552] = { tags = "[self_only][root]" },                                     -- Wraith Walk
        [221562] = { tags = "[creature_stun]", baseline = true },                      -- Asphyxiate
        [273952] = { tags = "[creature_slow]" },                                       -- Grip of the Dead
        [454786] = { tags = "[creature_slow][creature_root]", override = 45524 },      -- Ice Prison
        [45524]  = { tags = "[creature_slow]", baseline = true },                      -- Chains of Ice
        [48265]  = { tags = "[self_only][player_movement_immune]", baseline = true },  -- Death's Advance
        [48792]  = { tags = "[self_only][stun]", baseline = true },                    -- Icebound Fortitude
        [49039]  = { tags = "[self_only][charm][fear][sleep]", baseline = true },       -- Lichborne
        [49576]  = { tags = "[creature_grip]", baseline = true },                      -- Death Grip
    },
    [250] = { -- Blood
        [108199]  = { tags = "[creature_grip]", override = 1263569 },   -- Gorefiend's Grasp
        [1263569] = { tags = "[creature_grip]", override = 108199 },    -- Abomination Limb
    },
    [251] = {}, -- Frost
    [252] = {}, -- Unholy

    ----------------------------------------------------------------
    -- DEMON HUNTER
    ----------------------------------------------------------------
    DEMONHUNTER = {
        [1266316] = { tags = "[self_only][disease]" },                                  -- Burn It Out
        [1266496] = { tags = "[self_only][curse]" },                                    -- Soul Cleanse
        [131347]  = { tags = "[self_only][player_jump]", baseline = true },             -- Glide
        [188501]  = { tags = "[stealth]", baseline = true },                            -- Spectral Sight
        [198793]  = { tags = "[self_only][snare]", baseline = true },                   -- Vengeful Retreat
        [207684]  = { tags = "[creature_fear]", baseline = true },                      -- Sigil of Misery
        [217832]  = { tags = "[cc_demon][cc_beast][cc_humanoid]", baseline = true },    -- Imprison
        [278326]  = { tags = "[purge]" },                                               -- Consume Magic
    },
    [577] = { -- Havoc
        [179057] = { tags = "[creature_stun]", baseline = true },  -- Chaos Nova
    },
    [581] = { -- Vengeance
        [179057] = { tags = "[creature_stun]", baseline = true },  -- Chaos Nova
    },
    [1480] = { -- Devourer
        [1234195] = { tags = "[creature_stun]", baseline = true }, -- Void Nova
    },

    ----------------------------------------------------------------
    -- DRUID
    ----------------------------------------------------------------
    DRUID = {
        [102359] = { tags = "[creature_root]" },                                     -- Mass Entanglement
        [102793] = { tags = "[creature_slow][creature_root]" },                      -- Ursol's Vortex
        [132469] = { tags = "[creature_grip][creature_slow]" },                      -- Typhoon
        [22570]  = { tags = "[creature_stun]", baseline = true },                    -- Maim
        [2637]   = { tags = "[cast_cc_beast][cast_cc_dragonkin]" },                  -- Hibernate
        [2908]   = { tags = "[enrage]" },                                            -- Soothe
        [33786]  = { tags = "[cc_cyclone]" },                                        -- Cyclone
        [339]    = { tags = "[creature_root]", baseline = true },                    -- Entangling Roots
        [5211]   = { tags = "[creature_stun]", baseline = true },                    -- Mighty Bash
        [768]    = { tags = "[self_only][slow][snare][root]", baseline = true },      -- Cat Form
        [99]     = { tags = "[creature_incapacitate]" },                             -- Incapacitating Roar
    },
    [102] = { [2782]   = { tags = "[curse][poison]" } },      -- Balance: Remove Corruption
    [103] = { [2782]   = { tags = "[curse][poison]" } },      -- Feral: Remove Corruption
    [104] = { [2782]   = { tags = "[curse][poison]" } },      -- Guardian: Remove Corruption
    [105] = { [392378] = { tags = "[curse][poison]" } },      -- Restoration: Improved Nature's Cure

    ----------------------------------------------------------------
    -- EVOKER
    ----------------------------------------------------------------
    EVOKER = {
        [357210] = { tags = "[self_only][slow][snare][root][player_movement_immune]", override = 403631, baseline = true }, -- Deep Breath
        [358385] = { tags = "[creature_root]", baseline = true },                    -- Landslide
        [360806] = { tags = "[cast_cc_aberration][cast_cc_beast][cast_cc_critter][cast_cc_demon][cast_cc_dragonkin][cast_cc_elemental][cast_cc_giant][cast_cc_humanoid][cast_cc_mechanical][cast_cc_undead][cast_cc_other]" }, -- Sleep Walk
        [365585] = { tags = "[poison]", baseline = true },                           -- Expunge
        [368970] = { tags = "[creature_stun]", baseline = true },                    -- Tail Swipe
        [374251] = { tags = "[bleed][poison][curse][disease]", baseline = true },    -- Cauterizing Flame
        [374346] = { tags = "[enrage]" },                                            -- Overawe
        [387341] = { tags = "[creature_slow]" },                                     -- Walloping Blow
    },
    [1467] = {}, -- Devastation
    [1468] = { -- Preservation
        [403631] = { tags = "[self_only][slow][snare][root][player_movement_immune]", baseline = true }, -- Dream Flight
    },
    [1473] = { -- Augmentation
        [403631] = { tags = "[self_only][slow][snare][root][player_movement_immune]", override = 357210, baseline = true }, -- Breath of Eons
    },

    ----------------------------------------------------------------
    -- HUNTER
    ----------------------------------------------------------------
    HUNTER = {
        [109215] = { tags = "[self_only][slow][snare][root]", baseline = true },     -- Posthaste
        [109248] = { tags = "[creature_root]", baseline = true },                    -- Binding Shot
        [1513]   = { tags = "[cc_beast]" },                                          -- Scare Beast
        [1543]   = { tags = "[stealth]", baseline = true },                          -- Flare
        [187650] = { tags = "[cc_aberration][cc_beast][cc_critter][cc_demon][cc_dragonkin][cc_elemental][cc_giant][cc_humanoid][cc_mechanical][cc_undead][cc_other]", baseline = true }, -- Freezing Trap
        [187698] = { tags = "[creature_slow]" },                                     -- Tar Trap
        [195645] = { tags = "[creature_slow]", alternatives = {5116}, baseline = true }, -- Wing Clip
        [19801]  = { tags = "[enrage][purge]" },                                     -- Tranquilizing Shot
        [459517] = { tags = "[self_only][poison][disease]" },                        -- Emergency Salve
        [5384]   = { tags = "[self_only][targeted_avoid]", baseline = true },        -- Feign Death
        [781]    = { tags = "[self_only][player_jump]", baseline = true },            -- Disengage
    },
    [253] = { -- Beast Mastery
        [19577] = { tags = "[creature_stun]", baseline = true },  -- Intimidation
        [24423] = { tags = "[creature_mortal_strike]", pet = true,
                    alternatives = { 263863, 159936, 160060, 263856, 263861, 279362, 160018, 263853, 54680, 263857, 263854, 263858 },
                    baseline = true }, -- Mortal Wounds (pet)
        [53271] = { tags = "[slow][snare][root]", pet = true },   -- Master's Call (pet)
    },
    [254] = { -- Marksmanship
        [474421] = { tags = "[creature_stun]", baseline = true }, -- Intimidation
    },
    [255] = { -- Survival
        [19577] = { tags = "[creature_stun]", baseline = true },  -- Intimidation
        [24423] = { tags = "[creature_mortal_strike]", pet = true,
                    alternatives = { 263863, 159936, 160060, 263856, 263861, 279362, 160018, 263853, 54680, 263857, 263854, 263858 },
                    baseline = true }, -- Mortal Wounds (pet)
        [53271] = { tags = "[slow][snare][root]", pet = true },   -- Master's Call (pet)
    },

    ----------------------------------------------------------------
    -- MAGE
    ----------------------------------------------------------------
    MAGE = {
        [110959] = { tags = "[self_only][targeted_avoid]" },                         -- Greater Invisibility
        [113724] = { tags = "[creature_incapacitate]" },                             -- Ring of Frost
        [118]    = { tags = "[cast_cc_beast][cast_cc_humanoid][cast_cc_critter]", baseline = true }, -- Polymorph
        [120]    = { tags = "[creature_slow]", baseline = true },                    -- Cone of Cold
        [122]    = { tags = "[creature_root]", baseline = true },                    -- Frost Nova
        [157980] = { tags = "[creature_grip]" },                                     -- Supernova
        [157997] = { tags = "[creature_root]" },                                     -- Ice Nova
        [1953]   = { tags = "[self_only][root][player_jump]", alternatives = {212653}, baseline = true }, -- Blink
        [30449]  = { tags = "[purge]" },                                             -- Spellsteal
        [31661]  = { tags = "[creature_incapacitate]" },                             -- Dragon's Breath
        [342245] = { tags = "[alter_time]", baseline = true },                       -- Alter Time
        [386763] = { tags = "[creature_root]" },                                     -- Freezing Cold
        [386828] = { tags = "[self_only][snare]" },                                  -- Energized Barriers
        [45438]  = { tags = "[self_only][bleed][charm][curse][disease][enrage][fear][incapacitate][poison][sleep][slow][snare]", baseline = true }, -- Ice Block
        [475]    = { tags = "[curse]" },                                             -- Remove Curse
    },
    [62] = {},  -- Arcane
    [63] = {},  -- Fire
    [64] = {},  -- Frost

    ----------------------------------------------------------------
    -- MONK
    ----------------------------------------------------------------
    MONK = {
        [115078] = { tags = "[cc_aberration][cc_beast][cc_critter][cc_demon][cc_dragonkin][cc_elemental][cc_giant][cc_humanoid][cc_mechanical][cc_undead][cc_other][creature_incapacitate]", baseline = true }, -- Paralysis
        [116095] = { tags = "[creature_slow]" },                                     -- Disable
        [116841] = { tags = "[root][snare]", baseline = true },                      -- Tiger's Lust
        [116844] = { tags = "[creature_grip]" },                                     -- Ring of Peace
        [119381] = { tags = "[creature_stun]", baseline = true },                    -- Leg Sweep
        [198898] = { tags = "[creature_incapacitate]" },                             -- Song of Chi-Ji
        [449582] = { tags = "[self_only][player_jump]" },                            -- Lighter Than Air
        [450432] = { tags = "[enrage]" },                                            -- Pressure Points
        [450595] = { tags = "[creature_slow]" },                                     -- Spirit's Essence
        [450622] = { tags = "[self_only][snare]" },                                  -- Swift Art
    },
    [268] = { [218164] = { tags = "[poison][disease]" } },          -- Brewmaster: Detox
    [270] = { -- Mistweaver
        [107428] = { tags = "[creature_mortal_strike]", baseline = true },  -- Rising Sun Kick
        [388874] = { tags = "[poison][disease]" },                          -- Improved Detox
    },
    [269] = { -- Windwalker
        [107428] = { tags = "[creature_mortal_strike]", baseline = true },  -- Rising Sun Kick
        [218164] = { tags = "[poison][disease]" },                          -- Detox
    },

    ----------------------------------------------------------------
    -- PALADIN
    ----------------------------------------------------------------
    PALADIN = {
        [1022]   = { tags = "[bleed][physical_debuff]" },                            -- Blessing of Protection
        [10326]  = { tags = "[cast_cc_undead][cast_cc_aberration][cast_cc_demon]" },  -- Turn Evil
        [1044]   = { tags = "[slow][snare][root]" },                                 -- Blessing of Freedom
        [115750] = { tags = "[creature_incapacitate]" },                             -- Blinding Light
        [469304] = { tags = "[self_only][slow][snare][root]" },                      -- Steed of Liberty
        [469321] = { tags = "[poison][disease]" },                                   -- Righteous Protection
        [642]    = { tags = "[self_only][bleed][charm][curse][disease][enrage][fear][incapacitate][poison][sleep][slow][snare]", baseline = true }, -- Divine Shield
        [853]    = { tags = "[creature_stun]", baseline = true },                    -- Hammer of Justice
    },
    [65] = { [393024] = { tags = "[disease][poison]" } },           -- Holy: Improved Cleanse
    [66] = { -- Protection
        [204018] = { tags = "[magic_debuff]", baseline = true },    -- Blessing of Spellwarding
        [213644] = { tags = "[poison][disease]" },                  -- Cleanse Toxins
    },
    [70] = { [213644] = { tags = "[poison][disease]" } },           -- Retribution: Cleanse Toxins

    ----------------------------------------------------------------
    -- PRIEST
    ----------------------------------------------------------------
    PRIEST = {
        [108942]  = { tags = "[self_only][snare]" },                                 -- Phantasm
        [1250691] = { tags = "[creature_root]" },                                    -- Void Tendrils
        [205364]  = { tags = "[cast_cc_aberration][cast_cc_beast][cast_cc_critter][cast_cc_dragonkin][cast_cc_elemental][cast_cc_giant][cast_cc_humanoid][cast_cc_other]", override = 605 }, -- Dominate Mind
        [32375]   = { tags = "[purge]", baseline = true },                           -- Mass Dispel
        [528]     = { tags = "[purge]" },                                            -- Dispel Magic
        [605]     = { tags = "[cast_cc_aberration][cast_cc_beast][cast_cc_critter][cast_cc_dragonkin][cast_cc_elemental][cast_cc_giant][cast_cc_humanoid][cast_cc_other]", override = 205364 }, -- Mind Control
        [8122]    = { tags = "[creature_fear]", baseline = true },                   -- Psychic Scream
        [9484]    = { tags = "[cast_cc_aberration][cast_cc_undead]" },                -- Shackle Horror
    },
    [256] = { [390632] = { tags = "[disease]" } },                  -- Discipline: Improved Purify
    [257] = { [390632] = { tags = "[disease]" } },                  -- Holy: Improved Purify
    [258] = { [213634] = { tags = "[disease]" } },                  -- Shadow: Purify Disease

    ----------------------------------------------------------------
    -- ROGUE
    ----------------------------------------------------------------
    ROGUE = {
        [1856]  = { tags = "[self_only][slow][snare][root][targeted_avoid]", baseline = true }, -- Vanish
        [2094]  = { tags = "[cc_aberration][cc_beast][cc_critter][cc_demon][cc_dragonkin][cc_elemental][cc_giant][cc_humanoid][cc_mechanical][cc_undead][cc_other][creature_incapacitate]", baseline = true }, -- Blind
        [31224] = { tags = "[self_only][magic_debuff]", baseline = true },            -- Cloak of Shadows
        [3408]  = { tags = "[creature_slow]", baseline = true },                     -- Crippling Poison
        [408]   = { tags = "[creature_stun]", baseline = true },                     -- Kidney Shot
        [5938]  = { tags = "[enrage]", baseline = true },                            -- Shiv
        [8679]  = { tags = "[creature_mortal_strike]", baseline = true },             -- Wound Poison
    },
    [259] = {}, -- Assassination
    [260] = {}, -- Outlaw
    [261] = {}, -- Subtlety

    ----------------------------------------------------------------
    -- SHAMAN
    ----------------------------------------------------------------
    SHAMAN = {
        [192058] = { tags = "[creature_stun]", baseline = true },                    -- Capacitor Totem
        [192063] = { tags = "[self_only][player_jump]", baseline = true },           -- Gust of Wind
        [2484]   = { tags = "[creature_slow]", baseline = true },                    -- Earthbind Totem
        [370]    = { tags = "[purge]" },                                             -- Purge
        [378075] = { tags = "[self_only][snare]" },                                  -- Thunderous Paws
        [383013] = { tags = "[poison]" },                                            -- Poison Cleansing Totem
        [462817] = { tags = "[snare_jet]" },                                         -- Jet Stream (Wind Rush Totem)
        [51485]  = { tags = "[creature_slow][creature_root]", override = 2484 },     -- Earthgrab Totem
        [51514]  = { tags = "[cast_cc_humanoid][cast_cc_beast]" },                   -- Hex
        [58875]  = { tags = "[self_only][slow][snare][root]", baseline = true },     -- Spirit Walk
        [8143]   = { tags = "[fear][charm][sleep]" },                                -- Tremor Totem
    },
    [262] = { -- Elemental
        [51490] = { tags = "[creature_grip]", baseline = true },  -- Thunderstorm
        [51886] = { tags = "[curse]" },                           -- Cleanse Spirit
    },
    [263] = { [51886] = { tags = "[curse]" } },                   -- Enhancement: Cleanse Spirit
    [264] = { [383016] = { tags = "[curse]" } },                  -- Restoration: Improved Purify Spirit

    ----------------------------------------------------------------
    -- WARLOCK
    ----------------------------------------------------------------
    WARLOCK = {
        [19505]  = { tags = "[purge]", pet = true, baseline = true },                -- Devour Magic (pet)
        [268358] = { tags = "[self_only][slow][snare][root]" },                      -- Demonic Circle
        [30283]  = { tags = "[creature_stun]", baseline = true },                    -- Shadowfury
        [334275] = { tags = "[creature_slow]" },                                     -- Curse of Exhaustion
        [5484]   = { tags = "[creature_fear]" },                                     -- Howl of Terror
        [5782]   = { tags = "[creature_fear]", baseline = true },                    -- Fear
        [6358]   = { tags = "[cast_cc_humanoid]", pet = true, baseline = true },     -- Seduction (pet)
        [6789]   = { tags = "[creature_incapacitate]", baseline = true },            -- Mortal Coil
        [710]    = { tags = "[cast_cc_demon][cast_cc_aberration][cast_cc_elemental]" }, -- Banish
    },
    [265] = {}, -- Affliction
    [266] = { -- Demonology
        [89766] = { tags = "[creature_stun]", pet = true, baseline = true }, -- Axe Toss (pet)
    },
    [267] = {}, -- Destruction

    ----------------------------------------------------------------
    -- WARRIOR
    ----------------------------------------------------------------
    WARRIOR = {
        [107570] = { tags = "[creature_stun]", baseline = true },                    -- Storm Bolt
        [12323]  = { tags = "[creature_slow]" },                                     -- Piercing Howl
        [18499]  = { tags = "[self_only][fear][incapacitate]", baseline = true },     -- Berserker Rage
        [384100] = { tags = "[fear]" },                                              -- Berserker Shout
        [46968]  = { tags = "[creature_stun]", baseline = true },                    -- Shockwave
        [5246]   = { tags = "[creature_fear]" },                                     -- Intimidating Shout
        [6544]   = { tags = "[self_only][player_jump]", baseline = true },           -- Heroic Leap
    },
    [71] = { -- Arms
        [12294] = { tags = "[creature_mortal_strike]", baseline = true }, -- Mortal Strike
    },
    [72] = {}, -- Fury
    [73] = {}, -- Protection
}
