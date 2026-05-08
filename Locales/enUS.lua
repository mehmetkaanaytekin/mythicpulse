--[[
    MythicPulse - English Localization (enUS)
    Baseline locale. Non-English files overlay only their keys; missing keys fall back here.
]]

local _, MP = ...

MP.L = {
    -- ===== General =====
    ["ADDON_LOADED"]          = "MythicPulse loaded. Type /mp help for commands.",
    ["UNKNOWN"]               = "Unknown",
    ["ENABLED"]               = "Enabled",
    ["DISABLED"]              = "Disabled",

    -- ===== Slash Command Help =====
    ["SLASH_HELP_HEADER"]     = "MythicPulse Commands:",
    ["SLASH_HELP_DISPLAY"]    = "  /mp display  \226\128\148 Show all frames with mock data (for placement)",
    ["SLASH_HELP_CONFIG"]     = "  /mp config   \226\128\148 Open settings",
    ["SLASH_HELP_LOCK"]       = "  /mp lock     \226\128\148 Lock/unlock frames",
    ["SLASH_HELP_RESET"]      = "  /mp reset    \226\128\148 Reset frame positions",
    ["SLASH_HELP_KEYS"]       = "  /mp keys     \226\128\148 Announce all party keys",
    ["SLASH_HELP_UTILITY"]    = "  /mp utility  \226\128\148 Toggle dungeon utility",
    ["SLASH_HELP_FOOTNOTE"]   = "Frames only show inside an active Mythic+ key. Use /mp display to position them anywhere.",
    ["SLASH_FRAMES_LOCKED"]   = "Frames locked.",
    ["SLASH_FRAMES_UNLOCKED"] = "Frames unlocked.",
    ["SLASH_RESET_DONE"]      = "Frame positions reset.",
    ["SLASH_KEYSTONE_UNAVAIL"]= "Keystone tracker unavailable.",
    ["SLASH_DEBUG_ON"]        = "Debug mode enabled.",
    ["SLASH_DEBUG_OFF"]       = "Debug mode disabled.",
    ["SLASH_DISPLAY_UNAVAIL"] = "Display preview unavailable.",
    ["SLASH_INT_UNAVAIL"]     = "Interrupt tracker unavailable.",
    ["SLASH_VERSION_LABEL"]   = "Version: ",
    ["SLASH_UNKNOWN_CMD"]     = "Unknown command '%s'. Type /mp help for a list.",

    -- ===== Addon Compartment Tooltip =====
    ["COMPARTMENT_KEY_FORMAT"]  = "Key: %s +%d",
    ["COMPARTMENT_LEFT_CLICK"]  = "|cffffffffLeft-click:|r Toggle display",
    ["COMPARTMENT_RIGHT_CLICK"] = "|cffffffffRight-click:|r Open settings",

    -- ===== Timer =====
    ["TIMER_TITLE"]           = "Timer",
    ["TIMER_PLUS_TWO"]        = "+2",
    ["TIMER_PLUS_THREE"]      = "+3",
    ["TIMER_OVERTIME"]        = "OVERTIME",
    ["TIMER_COMPLETED"]       = "Completed!",
    ["TIMER_DEPLETED"]        = "Depleted",
    ["TIMER_PB_FORMAT"]       = "PB |cffffffff%s|r  (+%d)",
    ["TIMER_NO_PB"]           = "|cff666666No PB yet|r",
    ["TIMER_ZERO_DEATHS"]     = "0 Deaths",
    ["TIMER_DEATH_SINGULAR"]  = "Death",
    ["TIMER_DEATH_PLURAL"]    = "Deaths",
    ["TIMER_BOSS_FALLBACK"]   = "Boss %d",
    ["TIMER_TOOLTIP_KILLED"]  = "Killed at:",
    ["TIMER_TOOLTIP_PREV"]    = "Since prev boss:",
    ["TIMER_TOOLTIP_START"]   = "From start:",
    ["TIMER_TOOLTIP_VS_PB"]   = "vs Personal Best:",
    ["BOSS_SPLIT"]            = "Boss %d: %s",

    -- ===== Death Tracker =====
    ["DEATHS"]                = "Deaths",
    ["DEATH_LOG"]             = "Death Log",
    ["DEATH_PENALTY"]         = "Time Lost",
    ["DEATH_ENTRY"]           = "%s died at %s",
    ["NO_DEATHS"]             = "No deaths",

    -- ===== Enemy Forces =====
    ["ENEMY_FORCES"]          = "Enemy Forces",
    ["FORCES_PROGRESS"]       = "%s / %s (%.1f%%)",
    ["FORCES_COMPLETE"]       = "Forces Complete!",
    ["EF_COMPLETE"]           = "Complete!",
    ["CURRENT_PULL"]          = "Current Pull",

    -- ===== Affixes =====
    ["AFFIXES"]               = "Affixes",

    -- ===== Keystone =====
    ["KEYSTONE"]              = "Keystone",
    ["YOUR_KEY"]              = "Your Key",
    ["NO_KEY"]                = "No keystone",
    ["PARTY_KEYS"]            = "Party Keys",
    ["KEY_FORMAT"]            = "%s +%d",
    ["KEY_NOT_IN_GROUP"]      = "You are not in a group.",

    -- ===== Party Cooldowns =====
    ["PARTY_CDS"]             = "Party Cooldowns",
    ["CD_READY"]              = "Ready",
    ["PC_DEMO_NEEDS_PARTY"]   = "|cff88ccffDemo:|r Cooldown icons only display where a party/raid frame exists. Join a party or enable raid-style party frames to see all 5 demo slots.",

    -- ===== Interrupt Tracker =====
    ["INTERRUPTS"]            = "Interrupts",
    ["INT_READY"]             = "READY",
    ["INT_TOOLTIP_ON_CD"]     = "On cooldown: %.0fs",
    ["INT_TOOLTIP_CLICK"]     = "Left-click to announce status",
    ["INT_NO_INTERRUPTERS"]   = "No interrupters in group.",
    ["INT_ROTATION_HEADER"]   = "Kick rotation:",
    ["INT_FALLBACK_NAME"]     = "Interrupt",
    ["INT_CD_ANNOUNCE"]       = "[MythicPulse] %s's %s on CD (%.0fs)",
    ["INT_READY_ANNOUNCE"]    = "[MythicPulse] %s's %s is READY",
    ["INT_ROTATION_ANNOUNCE"] = "[MythicPulse] Kicks: %s",

    -- ===== Dispel Tracker =====
    ["DISPELS"]               = "Dispels",
    ["DISPEL_READY"]          = "READY",

    -- ===== Combat Res =====
    ["BREZ"]                  = "Battle Res",
    ["BREZ_READY"]            = "%d/%d ready",
    ["BREZ_NEXT"]             = "next in %s",
    ["BREZ_NONE"]             = "No brez in group",
    ["CR_READY"]              = "Ready",
    ["CR_ON_CD"]              = "On CD",
    ["CR_AVAILABLE"]          = "Available",
    ["CR_NO_BREZ"]            = "No brez",
    ["CR_BREZ_READY_FORMAT"]  = "Ready %d/%d",
    ["CR_BL_SATED"]           = "Sated",
    ["CR_BL_NO_SOURCE"]       = "No source",

    -- ===== Dungeon History =====
    ["HISTORY"]               = "Run History",
    ["HISTORY_EMPTY"]         = "No runs recorded yet.",
    ["HISTORY_TIMED"]         = "Timed",
    ["HISTORY_DEPLETED"]      = "Depleted",
    ["HIST_HEADER"]           = "=== Run History ===",
    ["HIST_TOTAL_RUNS"]       = "Total Runs: |cffffffff%d|r",
    ["HIST_TIMED_RUNS"]       = "Timed: |cff4dff4d%d|r (%.0f%%)",
    ["HIST_DEPLETED_RUNS"]    = "Depleted: |cffff4444%d|r",
    ["HIST_HIGHEST_KEYS"]     = "--- Highest Timed Keys ---",
    ["HIST_MAP_FALLBACK"]     = "Map %d",
    ["HIST_RECENT_RUNS"]      = "--- Recent Runs ---",
    ["HIST_TIMED"]            = "Timed",
    ["HIST_DEPLETED"]         = "Depleted",
    ["HIST_NO_VALID_RUNS"]    = "No valid runs recorded yet.",

    -- ===== Run Summary =====
    ["RS_TIER_PLUS3"]         = "+3 CHEST",
    ["RS_TIER_PLUS2"]         = "+2 CHEST",
    ["RS_TIER_PLUS1"]         = "+1 TIMED",
    ["RS_TIER_DEPLETED"]      = "DEPLETED",
    ["RS_TITLE"]              = "RUN SUMMARY",
    ["RS_CARD_TIME_PERF"]     = "TIME PERFORMANCE",
    ["RS_COL_ELAPSED"]        = "ELAPSED",
    ["RS_COL_VS_TIMER"]       = "vs +2 TIMER",
    ["RS_COL_VS_PB"]          = "vs PB",
    ["RS_CARD_DEATHS"]        = "DEATHS  |  CASUALTIES",
    ["RS_COL_TIME_LOST"]      = "TIME LOST",
    ["RS_HINT_AVOIDABLE"]     = "Minimize\nAvoidable!",
    ["RS_CARD_BOSS_SPLITS"]   = "BOSS SPLITS",
    ["RS_CARD_SCORE"]         = "SCORE  |  RATING SUMMARY",
    ["RS_COL_RUN_SCORE"]      = "RUN SCORE",
    ["RS_COL_PREV_BEST"]      = "PREVIOUS BEST",
    ["RS_COL_EST_GAIN"]       = "EST. GAIN",
    ["RS_BTN_CLOSE"]          = "Close",
    ["RS_BTN_COPY_CHAT"]      = "Copy to Chat",
    ["RS_BTN_OPEN_HISTORY"]   = "Open History",
    ["RS_FIRST_RUN"]          = "1st run!",
    ["RS_PILL_TIMED"]         = "|cff4dff4dTIMED  -%s|r",
    ["RS_PILL_DEPLETED"]      = "|cffff4040DEPLETED  +%s|r",
    ["RS_TIMED"]              = "TIMED",
    ["RS_DEPLETED"]           = "DEPLETED",

    -- ===== Frame Headers =====
    ["MAIN_ADDON_HEADER"]     = "MythicPulse",
    ["COMBATRES_HDR"]         = "Combat",

    -- ===== Config Panel — Tabs =====
    ["CONFIG_TITLE"]          = "MythicPulse Settings",
    ["CONFIG_TAB_GENERAL"]    = "General",
    ["CONFIG_TAB_DISPLAY"]    = "Display",
    ["CONFIG_TAB_PARTY_CDS"]  = "Party CDs",
    ["CONFIG_TAB_COMBAT"]     = "Combat",
    ["CONFIG_TAB_UTILITY"]    = "Utility",
    ["CONFIG_TAB_MODULES"]    = "Modules",

    -- ===== Config Panel — General Tab =====
    ["CONFIG_GENERAL"]        = "General",
    ["CONFIG_HDR_BEHAVIOR"]   = "Behavior",
    ["CONFIG_LOCK_FRAME_POS"] = "Lock Frame Position",
    ["CONFIG_LOCK"]           = "Lock Frames",
    ["CONFIG_HDR_ACTIONS"]    = "Actions",
    ["CONFIG_RESET_HUD_POS"]  = "Reset HUD Position",
    ["CONFIG_RESET_POS"]      = "Reset Positions",
    ["CONFIG_HUD_POS_RESET"]  = "Main frame position reset.",
    ["CONFIG_RESET_ALL"]      = "Reset All Settings",
    ["CONFIG_RELOAD_UI"]      = "Reload UI",
    ["CONFIG_HDR_PREVIEW"]    = "Preview",
    ["CONFIG_PREVIEW_DESC"]   = "Load mock data so you can position and resize frames without being in a key.",
    ["CONFIG_TOGGLE_PREVIEW"] = "Toggle Preview",
    ["CONFIG_HDR_ABOUT"]      = "About",
    ["CONFIG_ABOUT_VERSION"]  = "MythicPulse v%s",
    ["CONFIG_ABOUT_HELP"]     = "/mp help  \226\128\148  list all slash commands",
    ["CONFIG_ABOUT_CONFIG"]   = "/mp config  \226\128\148  toggle this panel",

    -- ===== Config Panel — Display Tab =====
    ["CONFIG_HDR_MAIN_HUD"]   = "Main HUD",
    ["CONFIG_SCALE"]          = "UI Scale",
    ["CONFIG_OPACITY"]        = "Opacity",
    ["CONFIG_HDR_INT_FRAME"]  = "Interrupt Frame",
    ["CONFIG_HDR_FONT_ICON"]  = "Font & Icon Sizes",
    ["CONFIG_FONT_SCALE"]     = "Font Scale",
    ["CONFIG_PC_ICON_SIZE"]   = "Party CD Icon Size",
    ["CONFIG_BRES_ICON_SIZE"] = "BRes / BL Icon Size",
    ["CONFIG_ICON_RELOAD"]    = "Reload UI (/reload) to apply icon size changes.",

    -- ===== Config Panel — Party CDs Tab =====
    ["CONFIG_HDR_LAYOUT"]     = "Layout",
    ["CONFIG_ICON_GAP"]       = "Icon Gap",
    ["CONFIG_MAX_ICONS"]      = "Max Icons",
    ["CONFIG_ICONS_PER_ROW"]  = "Icons Per Row",
    ["CONFIG_SHOW_DISPEL_BAR"]= "Show Dispel Bar",
    ["CONFIG_HDR_ANCHORING"]  = "Anchoring",
    ["CONFIG_GROWTH_DIR"]     = "Growth Direction",
    ["CONFIG_ROW_ANCHOR"]     = "Row Anchor Point",
    ["CONFIG_UF_ANCHOR"]      = "Unit Frame Anchor",
    ["CONFIG_OFFSET_X"]       = "Offset X",
    ["CONFIG_OFFSET_Y"]       = "Offset Y",

    -- ===== Config Panel — Combat Tab =====
    ["CONFIG_HDR_INTERRUPTS"] = "Interrupts",
    ["CONFIG_MODULES"]        = "Modules",
    ["CONFIG_AUTO_KICKS"]     = "Auto-Announce Kick Rotation",
    ["CONFIG_INT_COMBAT_ONLY"]= "Show Interrupt Tracker in Combat Only",
    ["CONFIG_HDR_BL_BREZ"]    = "Bloodlust / Battle Res",
    ["CONFIG_BREZ_NOTE"]      = "Auto-detects: Shaman, Mage, and Hunter (with active pet).",
    ["CONFIG_MORE_SOON"]      = "More options coming soon.",

    -- ===== Config Panel — Utility Tab =====
    ["CONFIG_HDR_UTILITY"]    = "Dungeon Utility Panel",
    ["CONFIG_UTIL_AUTO_SHOW"] = "Auto-Show When Entering a Dungeon",
    ["CONFIG_UTIL_SHOW_REM"]  = "Show Ability Remove Buttons",
    ["CONFIG_UTIL_HIDE_OPT"]  = "Hide Non-Important Entries",
    ["CONFIG_HDR_HISTORY"]    = "Run History",
    ["CONFIG_MAX_HISTORY"]    = "Max History Entries",
    ["CONFIG_HISTORY_PRUNE"]  = "Older entries are pruned when the limit is reached.",

    -- ===== Config Panel — Modules Tab =====
    ["CONFIG_HDR_MODULES"]    = "Enable / Disable Modules",
    ["CONFIG_MOD_TIMER"]      = "Dungeon Timer",
    ["CONFIG_MOD_DEATHS"]     = "Death Tracker",
    ["CONFIG_MOD_FORCES"]     = "Enemy Forces",
    ["CONFIG_MOD_KEYSTONE"]   = "Keystone Tracker",
    ["CONFIG_MOD_PARTY_CDS"]  = "Party Cooldowns",
    ["CONFIG_MOD_INTERRUPT"]  = "Interrupt Tracker",
    ["CONFIG_MOD_DISPEL"]     = "Dispel Tracker",
    ["CONFIG_MOD_TRINKET"]    = "Trinket Tracker",
    ["CONFIG_MOD_GOSSIP"]     = "Auto Gossip",
    ["CONFIG_MOD_BREZ"]       = "Battle Res Tracker",
    ["CONFIG_MOD_HISTORY"]    = "Dungeon History",
    ["CONFIG_MOD_AUTO_SLOT"]  = "Auto Keystone Slot",
    ["CONFIG_MOD_TELEPORTS"]  = "Dungeon Teleports",
    ["CONFIG_MOD_UTILITY"]    = "Dungeon Utility",
    ["POPUP_RESET_CONFIRM"]   = "Reset all MythicPulse settings to defaults?",

    -- ===== Dungeon Utility =====
    ["UTILITY_TITLE"]         = "Dungeon Utility",
    ["UTILITY_NO_ABILITIES"]  = "No utility abilities for this dungeon",
    ["UTILITY_SELECT"]        = "Select Dungeon...",
    ["UTILITY_KNOWN"]         = "Known",
    ["UTILITY_ADD"]           = "Add",
    ["UTILITY_REMOVE"]        = "Remove",
    ["UTILITY_OPTIONAL"]      = "Optional",
    ["UTILITY_SELF_ONLY"]     = "Self-only ability",
    ["UTILITY_SELF_PREFIX"]   = "(Self)",
    ["UTILITY_UNKNOWN"]       = "Unknown Dungeon",
    ["UTIL_DISABLED_MSG"]     = "Dungeon Utility is disabled. Enable it in /mp config \226\134\146 Modules.",

    -- ===== Dungeon Teleport =====
    ["TP_CLICK_TO_TELEPORT"]  = "Click to Teleport",

    -- ===== Demo Mode =====
    ["DEMO_ALREADY_ACTIVE"]   = "Display preview already active. /mp display to stop.",
    ["DEMO_LOADING"]          = "Demo: HUD still loading, retrying in 2s...",
    ["DEMO_ON"]               = "|cff4dff4dDisplay preview ON|r \226\128\148 drag frames to reposition. /mp display to stop.",
    ["DEMO_OFF"]              = "|cffaaaaaaDisplay preview OFF|r",

    -- ===== Auto Slot =====
    ["AUTOSLOT_DONE"]         = "|cff4dff4dKeystone auto-slotted!|r",
}
