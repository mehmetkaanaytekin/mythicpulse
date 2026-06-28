--[[
    MythicPulse - German Localization (deDE)
    AI-generated using Blizzard localized terminology. Native-speaker corrections welcome via PR.
]]

local _, MP = ...

if GetLocale() ~= "deDE" then return end

local L = MP.L

-- General
L["ADDON_LOADED"]         = "MythicPulse geladen. Gib /mp help für Befehle ein."
L["UNKNOWN"]              = "Unbekannt"
L["ENABLED"]              = "Aktiviert"
L["DISABLED"]             = "Deaktiviert"

-- Timer
L["TIMER_TITLE"]          = "Timer"
L["TIMER_PLUS_TWO"]       = "+2"
L["TIMER_PLUS_THREE"]     = "+3"
L["TIMER_OVERTIME"]       = "ÜBERSCHRITTEN"
L["TIMER_COMPLETED"]      = "Abgeschlossen!"
L["TIMER_DEPLETED"]       = "Fehlgeschlagen"
L["BOSS_SPLIT"]           = "Boss %d: %s"

-- Death Tracker
L["DEATHS"]               = "Tode"
L["DEATH_LOG"]            = "Todesprotokoll"
L["DEATH_PENALTY"]        = "Verlorene Zeit"
L["DEATH_ENTRY"]          = "%s starb bei %s"
L["NO_DEATHS"]            = "Keine Tode"

-- Enemy Forces
L["ENEMY_FORCES"]         = "Feindliche Kräfte"
L["FORCES_PROGRESS"]      = "%s / %s (%.1f%%)"
L["FORCES_COMPLETE"]      = "Feindliche Kräfte abgeschlossen!"
L["CURRENT_PULL"]         = "Aktueller Kampf"

-- Affixes
L["AFFIXES"]              = "Affixe"

-- Keystone
L["KEYSTONE"]             = "Schlüsselstein"
L["YOUR_KEY"]             = "Dein Schlüsselstein"
L["NO_KEY"]               = "Kein Schlüsselstein"
L["PARTY_KEYS"]           = "Schlüsselsteine der Gruppe"
L["KEY_FORMAT"]           = "%s +%d"

-- Party Cooldowns
L["PARTY_CDS"]            = "Gruppen-Abklingzeiten"
L["CD_READY"]             = "Bereit"

-- Dispel Tracker
L["DISPELS"]              = "Entzauberungen"
L["DISPEL_READY"]         = "BEREIT"

-- Combat Res
L["BREZ"]                 = "Kampfauferstehung"
L["BREZ_READY"]           = "%d/%d bereit"
L["BREZ_NEXT"]            = "nächste in %s"
L["BREZ_NONE"]            = "Keine Kampfauferstehung in der Gruppe"

-- Dungeon History
L["HISTORY"]              = "Dungeon-Verlauf"
L["HISTORY_EMPTY"]        = "Noch keine Läufe aufgezeichnet."
L["HISTORY_TIMED"]        = "In der Zeit"
L["HISTORY_DEPLETED"]     = "Fehlgeschlagen"

-- Config
L["CONFIG_TITLE"]         = "MythicPulse Einstellungen"
L["CONFIG_GENERAL"]       = "Allgemein"
L["CONFIG_MODULES"]       = "Module"
L["CONFIG_SCALE"]         = "Benutzeroberfläche Skalierung"
L["CONFIG_OPACITY"]       = "Transparenz"
L["CONFIG_LOCK"]          = "Rahmen sperren"
L["CONFIG_RESET_POS"]     = "Positionen zurücksetzen"
L["CONFIG_RESET_ALL"]     = "Alle Einstellungen zurücksetzen"

-- Interrupt Tracker
L["INTERRUPTS"]           = "Unterbrechungen"

-- Dungeon Utility
L["UTILITY_TITLE"]        = "Dungeon-Fähigkeiten"
L["UTILITY_NO_ABILITIES"] = "Keine Utility-Fähigkeiten für diesen Dungeon"
L["UTILITY_SELECT"]       = "Dungeon auswählen..."
L["UTILITY_KNOWN"]        = "Bekannt"
L["UTILITY_ADD"]          = "Hinzufügen"
L["UTILITY_REMOVE"]       = "Entfernen"
L["UTILITY_OPTIONAL"]     = "Optional"
L["UTILITY_SELF_ONLY"]    = "Nur eigene Fähigkeit"

-- Slash Commands
L["SLASH_HELP_HEADER"]     = "MythicPulse Befehle:"
L["SLASH_HELP_DISPLAY"]    = "  /mp display  \226\128\148 Alle Rahmen mit Beispieldaten anzeigen (zur Positionierung)"
L["SLASH_HELP_CONFIG"]     = "  /mp config   \226\128\148 Einstellungen öffnen"
L["SLASH_HELP_LOCK"]       = "  /mp lock     \226\128\148 Rahmen sperren/entsperren"
L["SLASH_HELP_RESET"]      = "  /mp reset    \226\128\148 Rahmenpositionen zurücksetzen"
L["SLASH_HELP_KEYS"]       = "  /mp keys     \226\128\148 Alle Gruppenkeys ankündigen"
L["SLASH_HELP_UTILITY"]    = "  /mp utility  \226\128\148 Dungeon-Hilfsmittel umschalten"
L["SLASH_HELP_FOOTNOTE"]   = "Rahmen werden nur innerhalb eines aktiven Mythisch+-Schlüsselsteins angezeigt. Benutze /mp display um sie überall zu positionieren."
L["SLASH_FRAMES_LOCKED"]   = "Rahmen gesperrt."
L["SLASH_FRAMES_UNLOCKED"] = "Rahmen entsperrt."
L["SLASH_RESET_DONE"]      = "Rahmenpositionen zurückgesetzt."
L["SLASH_KEYSTONE_UNAVAIL"]= "Schlüsselstein-Verfolgung nicht verfügbar."
L["SLASH_DEBUG_ON"]        = "Debug-Modus aktiviert."
L["SLASH_DEBUG_OFF"]       = "Debug-Modus deaktiviert."
L["SLASH_DISPLAY_UNAVAIL"] = "Anzeigevorschau nicht verfügbar."
L["SLASH_INT_UNAVAIL"]     = "Unterbrechungs-Verfolgung nicht verfügbar."
L["SLASH_VERSION_LABEL"]   = "Version: "
L["SLASH_UNKNOWN_CMD"]     = "Unbekannter Befehl '%s'. Tippe /mp help für eine Liste."

-- Addon Compartment Tooltip
L["COMPARTMENT_KEY_FORMAT"]  = "Schlüssel: %s +%d"
L["COMPARTMENT_LEFT_CLICK"]  = "|cffffffffLinksklick:|r Anzeige umschalten"
L["COMPARTMENT_RIGHT_CLICK"] = "|cffffffffRechtsklick:|r Einstellungen öffnen"

-- Timer (additional keys)
L["TIMER_PB_FORMAT"]       = "PB |cffffffff%s|r  (+%d)"
L["TIMER_WK_PB_FORMAT"]    = "Wo |cffffffff%s|r"
L["TIMER_NO_PB"]           = "|cff666666Kein PB|r"
L["TIMER_ZERO_DEATHS"]     = "0 Tode"
L["TIMER_DEATH_SINGULAR"]  = "Tod"
L["TIMER_DEATH_PLURAL"]    = "Tode"
L["TIMER_BOSS_FALLBACK"]   = "Boss %d"
L["TIMER_TOOLTIP_KILLED"]  = "Gestorben bei:"
L["TIMER_TOOLTIP_PREV"]    = "Seit letztem Boss:"
L["TIMER_TOOLTIP_START"]   = "Seit Beginn:"
L["TIMER_TOOLTIP_VS_PB"]   = "vs Persönliche Bestzeit:"

-- Enemy Forces (additional key)
L["EF_COMPLETE"]           = "Abgeschlossen!"

-- Keystone (additional key)
L["KEY_NOT_IN_GROUP"]      = "Du bist nicht in einer Gruppe."

-- Party Cooldowns (additional key)
L["PC_DEMO_NEEDS_PARTY"]   = "|cff88ccffDemo:|r Abklingzeit-Symbole werden nur angezeigt, wo ein Gruppen-/Schlachtzugsrahmen vorhanden ist. Tritt einer Gruppe bei oder aktiviere Schlachtzugsstil-Gruppenrahmen, um alle 5 Demo-Slots zu sehen."

-- Interrupt Tracker (additional keys)
L["INT_READY"]             = "BEREIT"
L["INT_TOOLTIP_ON_CD"]     = "Auf Abklingzeit: %.0fs"
L["INT_TOOLTIP_CLICK"]     = "Linksklick zum Ankündigen des Status"
L["INT_NO_INTERRUPTERS"]   = "Keine Unterbrecher in der Gruppe."
L["INT_ROTATION_HEADER"]   = "Unterbrechungsrotation:"
L["INT_FALLBACK_NAME"]     = "Unterbrechung"
L["INT_CD_ANNOUNCE"]       = "[MythicPulse] %s's %s on CD (%.0fs)"
L["INT_READY_ANNOUNCE"]    = "[MythicPulse] %s's %s is READY"
L["INT_ROTATION_ANNOUNCE"] = "[MythicPulse] Kicks: %s"

-- Combat Res (additional keys)
L["CR_READY"]              = "Bereit"
L["CR_ON_CD"]              = "Auf AKZ"
L["CR_AVAILABLE"]          = "Verfügbar"
L["CR_NO_BREZ"]            = "Keine Kampfauferstehung"
L["CR_BREZ_READY_FORMAT"]  = "Bereit %d/%d"
L["CR_BL_SATED"]           = "Gesättigt"
L["CR_BL_NO_SOURCE"]       = "Keine Quelle"

-- Dungeon History (additional keys)
L["HIST_HEADER"]           = "=== Dungeon-Verlauf ==="
L["HIST_TOTAL_RUNS"]       = "Läufe gesamt: |cffffffff%d|r"
L["HIST_TIMED_RUNS"]       = "In der Zeit: |cff4dff4d%d|r (%.0f%%)"
L["HIST_DEPLETED_RUNS"]    = "Fehlgeschlagen: |cffff4444%d|r"
L["HIST_HIGHEST_KEYS"]     = "--- Höchste in-time Schlüsselsteine ---"
L["HIST_MAP_FALLBACK"]     = "Karte %d"
L["HIST_RECENT_RUNS"]      = "--- Letzte Läufe ---"
L["HIST_TIMED"]            = "In der Zeit"
L["HIST_DEPLETED"]         = "Fehlgeschlagen"
L["HIST_NO_VALID_RUNS"]    = "Noch keine gültigen Läufe aufgezeichnet."

-- Run Summary
L["RS_TIER_PLUS3"]         = "+3 TRUHE"
L["RS_TIER_PLUS2"]         = "+2 TRUHE"
L["RS_TIER_PLUS1"]         = "+1 IN DER ZEIT"
L["RS_TIER_DEPLETED"]      = "FEHLGESCHLAGEN"
L["RS_TITLE"]              = "LAUF-ZUSAMMENFASSUNG"
L["RS_CARD_TIME_PERF"]     = "ZEITPERFORMANCE"
L["RS_COL_ELAPSED"]        = "VERSTRICHEN"
L["RS_COL_VS_TIMER"]       = "vs +2 TIMER"
L["RS_COL_VS_PB"]          = "vs PB"
L["RS_COL_VS_WK_PB"]       = "vs Wo PB"
L["RS_CARD_DEATHS"]        = "TODE  |  VERLUSTE"
L["RS_COL_TIME_LOST"]      = "VERLORENE ZEIT"
L["RS_HINT_AVOIDABLE"]     = "Vermeidbare\nreduzieren!"
L["RS_CARD_BOSS_SPLITS"]   = "BOSS-ZEITEN"
L["RS_CARD_INTERRUPTS"]    = "UNTERBRECHUNGEN"
L["RS_CARD_SCORE"]         = "WERTUNG  |  RATING-ÜBERSICHT"
L["RS_COL_RUN_SCORE"]      = "LAUF-WERTUNG"
L["RS_COL_PREV_BEST"]      = "VORHERIGES BESTES"
L["RS_COL_EST_GAIN"]       = "GESCH. GEWINN"
L["RS_BTN_CLOSE"]          = "Schließen"
L["RS_BTN_COPY_CHAT"]      = "In Chat kopieren"
L["RS_BTN_OPEN_HISTORY"]   = "Verlauf öffnen"
L["RS_FIRST_RUN"]          = "1. Lauf!"
L["RS_PILL_TIMED"]         = "|cff4dff4dIN DER ZEIT  -%s|r"
L["RS_PILL_DEPLETED"]      = "|cffff4040FEHLGESCHLAGEN  +%s|r"
L["RS_TIMED"]              = "IN DER ZEIT"
L["RS_DEPLETED"]           = "FEHLGESCHLAGEN"

-- Frame Headers
L["MAIN_ADDON_HEADER"]     = "MythicPulse"
L["COMBATRES_HDR"]         = "Kampf"

-- Config Panel — Tabs
L["CONFIG_TAB_GENERAL"]    = "Allgemein"
L["CONFIG_TAB_DISPLAY"]    = "Anzeige"
L["CONFIG_TAB_PARTY_CDS"]  = "Gruppen-AKZ"
L["CONFIG_TAB_COMBAT"]     = "Kampf"
L["CONFIG_TAB_UTILITY"]    = "Hilfsmittel"
L["CONFIG_TAB_MODULES"]    = "Module"

-- Config Panel — General Tab
L["CONFIG_HDR_BEHAVIOR"]   = "Verhalten"
L["CONFIG_LOCK_FRAME_POS"] = "Rahmenposition sperren"
L["CONFIG_HDR_ACTIONS"]    = "Aktionen"
L["CONFIG_RESET_HUD_POS"]  = "HUD-Position zurücksetzen"
L["CONFIG_HUD_POS_RESET"]  = "Hauptrahmen-Position zurückgesetzt."
L["CONFIG_RELOAD_UI"]      = "Benutzeroberfläche neu laden"
L["CONFIG_HDR_PREVIEW"]    = "Vorschau"
L["CONFIG_PREVIEW_DESC"]   = "Beispieldaten laden, um Rahmen ohne aktiven Schlüsselstein zu positionieren und in der Größe anzupassen."
L["CONFIG_TOGGLE_PREVIEW"] = "Vorschau umschalten"
L["CONFIG_HDR_ABOUT"]      = "Über"
L["CONFIG_ABOUT_VERSION"]  = "MythicPulse v%s"
L["CONFIG_ABOUT_HELP"]     = "/mp help  \226\128\148  alle Befehle auflisten"
L["CONFIG_ABOUT_CONFIG"]   = "/mp config  \226\128\148  dieses Panel umschalten"

-- Config Panel — Display Tab
L["CONFIG_HDR_MAIN_HUD"]   = "Haupt-HUD"
L["CONFIG_HDR_INT_FRAME"]  = "Unterbrechungsrahmen"
L["CONFIG_HDR_FONT_ICON"]  = "Schrift- & Symbolgröße"
L["CONFIG_FONT_SCALE"]     = "Schriftskalierung"
L["CONFIG_PC_ICON_SIZE"]   = "Gruppen-AKZ Symbolgröße"
L["CONFIG_BRES_ICON_SIZE"] = "Kampfauferstehung / Schlachtruf Symbolgröße"
L["CONFIG_ICON_RELOAD"]    = "Lade die Benutzeroberfläche neu (/reload), um Symbolgrößenänderungen anzuwenden."

-- Config Panel — Party CDs Tab
L["CONFIG_HDR_LAYOUT"]     = "Layout"
L["CONFIG_ICON_GAP"]       = "Symbolabstand"
L["CONFIG_MAX_ICONS"]      = "Max. Symbole"
L["CONFIG_ICONS_PER_ROW"]  = "Symbole pro Reihe"
L["CONFIG_SHOW_DISPEL_BAR"]= "Entzauberungs-Leiste anzeigen"
L["CONFIG_HDR_ANCHORING"]  = "Verankerung"
L["CONFIG_GROWTH_DIR"]     = "Wachstumsrichtung"
L["CONFIG_ROW_ANCHOR"]     = "Reihen-Ankerpunkt"
L["CONFIG_UF_ANCHOR"]      = "Einheitenrahmen-Anker"
L["CONFIG_OFFSET_X"]       = "Versatz X"
L["CONFIG_OFFSET_Y"]       = "Versatz Y"

-- Config Panel — Combat Tab
L["CONFIG_HDR_INTERRUPTS"] = "Unterbrechungen"
L["CONFIG_AUTO_KICKS"]     = "Unterbrechungsrotation automatisch ankündigen"
L["CONFIG_INT_COMBAT_ONLY"]= "Unterbrechungs-Verfolgung nur im Kampf anzeigen"
L["CONFIG_HDR_BL_BREZ"]    = "Schlachtruf / Kampfauferstehung"
L["CONFIG_BREZ_NOTE"]      = "Automatische Erkennung: Schamane, Magier und Jäger (mit aktivem Begleiter)."

-- Config Panel — Utility Tab
L["CONFIG_HDR_UTILITY"]    = "Dungeon-Hilfsmittel-Panel"
L["CONFIG_UTIL_AUTO_SHOW"] = "Automatisch anzeigen beim Betreten eines Dungeons"
L["CONFIG_UTIL_SHOW_REM"]  = "Fähigkeit-Entfernen-Schaltflächen anzeigen"
L["CONFIG_UTIL_HIDE_OPT"]  = "Unwichtige Einträge ausblenden"
L["CONFIG_HDR_HISTORY"]    = "Dungeon-Verlauf"
L["CONFIG_MAX_HISTORY"]    = "Max. Verlaufseinträge"
L["CONFIG_HISTORY_PRUNE"]  = "Ältere Einträge werden gelöscht, wenn das Limit erreicht wird."

-- Config Panel — Modules Tab
L["CONFIG_HDR_MODULES"]    = "Module aktivieren / deaktivieren"
L["CONFIG_MOD_TIMER"]      = "Dungeon-Timer"
L["CONFIG_MOD_DEATHS"]     = "Todes-Verfolgung"
L["CONFIG_MOD_FORCES"]     = "Feindliche Kräfte"
L["CONFIG_MOD_KEYSTONE"]   = "Schlüsselstein-Verfolgung"
L["CONFIG_MOD_PARTY_CDS"]  = "Gruppen-Abklingzeiten"
L["CONFIG_MOD_INTERRUPT"]  = "Unterbrechungs-Verfolgung"
L["CONFIG_MOD_DISPEL"]     = "Entzauberungs-Verfolgung"
L["CONFIG_MOD_TRINKET"]    = "Schmuckstück-Verfolgung"
L["CONFIG_MOD_GOSSIP"]     = "Automatisches Gespräch"
L["CONFIG_MOD_BREZ"]       = "Kampfauferstehungs-Verfolgung"
L["CONFIG_MOD_HISTORY"]    = "Dungeon-Verlauf"
L["CONFIG_MOD_AUTO_SLOT"]  = "Automatischer Schlüsselstein-Slot"
L["CONFIG_MOD_TELEPORTS"]  = "Dungeon-Teleporte"
L["CONFIG_MOD_UTILITY"]    = "Dungeon-Hilfsmittel"
L["POPUP_RESET_CONFIRM"]   = "Alle MythicPulse-Einstellungen auf Standard zurücksetzen?"

-- Dungeon Utility (additional keys)
L["UTILITY_SELF_PREFIX"]   = "(Selbst)"
L["UTILITY_UNKNOWN"]       = "Unbekannter Dungeon"
L["UTIL_DISABLED_MSG"]     = "Dungeon-Hilfsmittel ist deaktiviert. Aktiviere es in /mp config \226\134\146 Module."

-- Dungeon Teleport
L["TP_CLICK_TO_TELEPORT"]  = "Klicken zum Teleportieren"

-- Demo Mode
L["DEMO_ALREADY_ACTIVE"]   = "Anzeigevorschau ist bereits aktiv. /mp display zum Beenden."
L["DEMO_LOADING"]          = "Demo: HUD wird noch geladen, erneuter Versuch in 2s..."
L["DEMO_ON"]               = "|cff4dff4dAnzeigevorschau EIN|r \226\128\148 Rahmen ziehen zum Neupositionieren. /mp display zum Beenden."
L["DEMO_OFF"]              = "|cffaaaaaaAnzeigevorschau AUS|r"

-- Auto Slot
L["AUTOSLOT_DONE"]         = "|cff4dff4dSchlüsselstein automatisch eingelegt!|r"
