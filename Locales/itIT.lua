--[[
    MythicPulse - Italian Localization (itIT)
    AI-generated using Blizzard localized terminology. Native-speaker corrections welcome via PR.
]]

local _, MP = ...

if GetLocale() ~= "itIT" then return end

local L = MP.L

-- General
L["ADDON_LOADED"]         = "MythicPulse caricato. Scrivi /mp help per i comandi."
L["UNKNOWN"]              = "Sconosciuto"
L["ENABLED"]              = "Attivato"
L["DISABLED"]             = "Disattivato"

-- Timer
L["TIMER_TITLE"]          = "Cronometro"
L["TIMER_PLUS_TWO"]       = "+2"
L["TIMER_PLUS_THREE"]     = "+3"
L["TIMER_OVERTIME"]       = "FUORI TEMPO"
L["TIMER_COMPLETED"]      = "Completato!"
L["TIMER_DEPLETED"]       = "Esaurito"
L["BOSS_SPLIT"]           = "Boss %d: %s"

-- Death Tracker
L["DEATHS"]               = "Morti"
L["DEATH_LOG"]            = "Registro delle morti"
L["DEATH_PENALTY"]        = "Tempo perso"
L["DEATH_ENTRY"]          = "%s è morto a %s"
L["NO_DEATHS"]            = "Nessuna morte"

-- Enemy Forces
L["ENEMY_FORCES"]         = "Forze nemiche"
L["FORCES_PROGRESS"]      = "%s / %s (%.1f%%)"
L["FORCES_COMPLETE"]      = "Forze nemiche completate!"
L["CURRENT_PULL"]         = "Combattimento attuale"

-- Affixes
L["AFFIXES"]              = "Affissi"

-- Keystone
L["KEYSTONE"]             = "Pietra Mitica"
L["YOUR_KEY"]             = "La tua pietra"
L["NO_KEY"]               = "Nessuna pietra"
L["PARTY_KEYS"]           = "Pietre del gruppo"
L["KEY_FORMAT"]           = "%s +%d"

-- Party Cooldowns
L["PARTY_CDS"]            = "Cooldown del gruppo"
L["CD_READY"]             = "Pronto"

-- Dispel Tracker
L["DISPELS"]              = "Dispel"
L["DISPEL_READY"]         = "PRONTO"

-- Combat Res
L["BREZ"]                 = "Resurrezione di combattimento"
L["BREZ_READY"]           = "%d/%d pronto"
L["BREZ_NEXT"]            = "prossimo tra %s"
L["BREZ_NONE"]            = "Nessuna resurrezione di combattimento nel gruppo"

-- Dungeon History
L["HISTORY"]              = "Cronologia delle istanze"
L["HISTORY_EMPTY"]        = "Nessuna istanza registrata."
L["HISTORY_TIMED"]        = "Completata in tempo"
L["HISTORY_DEPLETED"]     = "Esaurita"

-- Config
L["CONFIG_TITLE"]         = "Impostazioni MythicPulse"
L["CONFIG_GENERAL"]       = "Generale"
L["CONFIG_MODULES"]       = "Moduli"
L["CONFIG_SCALE"]         = "Scala interfaccia"
L["CONFIG_OPACITY"]       = "Opacità"
L["CONFIG_LOCK"]          = "Blocca cornici"
L["CONFIG_RESET_POS"]     = "Reimposta posizioni"
L["CONFIG_RESET_ALL"]     = "Reimposta tutte le impostazioni"

-- Interrupt Tracker
L["INTERRUPTS"]           = "Interruzioni"

-- Dungeon Utility
L["UTILITY_TITLE"]        = "Utilità istanza"
L["UTILITY_NO_ABILITIES"] = "Nessuna abilità di utilità per questa istanza"
L["UTILITY_SELECT"]       = "Seleziona istanza..."
L["UTILITY_KNOWN"]        = "Conosciuto"
L["UTILITY_ADD"]          = "Aggiungi"
L["UTILITY_REMOVE"]       = "Rimuovi"
L["UTILITY_OPTIONAL"]     = "Opzionale"
L["UTILITY_SELF_ONLY"]    = "Abilità solo per sé stessi"

-- Slash Commands
L["SLASH_HELP_HEADER"]      = "Comandi MythicPulse:"
L["SLASH_HELP_DISPLAY"]     = "  /mp display  \226\128\148 Mostra tutti i frame con dati fittizi (per il posizionamento)"
L["SLASH_HELP_CONFIG"]      = "  /mp config   \226\128\148 Apri impostazioni"
L["SLASH_HELP_LOCK"]        = "  /mp lock     \226\128\148 Blocca/sblocca frame"
L["SLASH_HELP_RESET"]       = "  /mp reset    \226\128\148 Reimposta posizioni frame"
L["SLASH_HELP_KEYS"]        = "  /mp keys     \226\128\148 Annuncia tutte le pietre del gruppo"
L["SLASH_HELP_UTILITY"]     = "  /mp utility  \226\128\148 Attiva/disattiva utilità istanza"
L["SLASH_HELP_FOOTNOTE"]    = "I frame vengono mostrati solo all'interno di una Pietra Mitica attiva. Usa /mp display per posizionarli ovunque."
L["SLASH_FRAMES_LOCKED"]    = "Frame bloccati."
L["SLASH_FRAMES_UNLOCKED"]  = "Frame sbloccati."
L["SLASH_RESET_DONE"]       = "Posizioni dei frame reimpostate."
L["SLASH_KEYSTONE_UNAVAIL"] = "Tracker Pietra Mitica non disponibile."
L["SLASH_DEBUG_ON"]         = "Modalità debug attivata."
L["SLASH_DEBUG_OFF"]        = "Modalità debug disattivata."
L["SLASH_DISPLAY_UNAVAIL"]  = "Anteprima display non disponibile."
L["SLASH_INT_UNAVAIL"]      = "Tracker interruzioni non disponibile."
L["SLASH_VERSION_LABEL"]    = "Versione: "
L["SLASH_UNKNOWN_CMD"]      = "Comando sconosciuto '%s'. Scrivi /mp help per la lista."

-- Compartment Tooltip
L["COMPARTMENT_KEY_FORMAT"] = "Pietra: %s +%d"
L["COMPARTMENT_LEFT_CLICK"] = "|cffffffffClic sinistro:|r Attiva/disattiva display"
L["COMPARTMENT_RIGHT_CLICK"]= "|cffffffffClic destro:|r Apri impostazioni"

-- Timer (additional)
L["TIMER_PB_FORMAT"]        = "MP |cffffffff%s|r  (+%d)"
L["TIMER_WK_PB_FORMAT"]     = "Sett |cffffffff%s|r"
L["TIMER_NO_PB"]            = "|cff666666Nessun MP ancora|r"
L["TIMER_ZERO_DEATHS"]      = "0 Morti"
L["TIMER_DEATH_SINGULAR"]   = "Morte"
L["TIMER_DEATH_PLURAL"]     = "Morti"
L["TIMER_BOSS_FALLBACK"]    = "Boss %d"
L["TIMER_TOOLTIP_KILLED"]   = "Sconfitto a:"
L["TIMER_TOOLTIP_PREV"]     = "Dal boss precedente:"
L["TIMER_TOOLTIP_START"]    = "Dall'inizio:"
L["TIMER_TOOLTIP_VS_PB"]    = "vs Miglior personale:"

-- Enemy Forces (additional)
L["EF_COMPLETE"]            = "Completato!"

-- Keystone (additional)
L["KEY_NOT_IN_GROUP"]       = "Non sei in un gruppo."

-- Party Cooldowns (additional)
L["PC_DEMO_NEEDS_PARTY"]    = "|cff88ccffDemo:|r Le icone cooldown vengono visualizzate solo dove esiste un frame gruppo/raid. Entra in un gruppo o attiva i frame gruppo in stile raid per vedere tutti i 5 slot demo."

-- Interrupt Tracker (additional)
L["INT_READY"]              = "PRONTO"
L["INT_TOOLTIP_ON_CD"]      = "In cooldown: %.0fs"
L["INT_TOOLTIP_CLICK"]      = "Clic sinistro per annunciare lo stato"
L["INT_NO_INTERRUPTERS"]    = "Nessun interrompitore nel gruppo."
L["INT_ROTATION_HEADER"]    = "Rotazione interruzioni:"
L["INT_FALLBACK_NAME"]      = "Interruzione"
L["INT_CD_ANNOUNCE"]        = "[MythicPulse] %s's %s on CD (%.0fs)"
L["INT_READY_ANNOUNCE"]     = "[MythicPulse] %s's %s is READY"
L["INT_ROTATION_ANNOUNCE"]  = "[MythicPulse] Kicks: %s"

-- Combat Res (additional)
L["CR_READY"]               = "Pronto"
L["CR_ON_CD"]               = "In cooldown"
L["CR_AVAILABLE"]           = "Disponibile"
L["CR_NO_BREZ"]             = "Nessuna resurrezione di combattimento"
L["CR_BREZ_READY_FORMAT"]   = "Pronto %d/%d"
L["CR_BL_SATED"]            = "Sazio"
L["CR_BL_NO_SOURCE"]        = "Nessuna fonte"

-- Dungeon History (additional)
L["HIST_HEADER"]            = "=== Cronologia istanze ==="
L["HIST_TOTAL_RUNS"]        = "Istanze totali: |cffffffff%d|r"
L["HIST_TIMED_RUNS"]        = "In tempo: |cff4dff4d%d|r (%.0f%%)"
L["HIST_DEPLETED_RUNS"]     = "Esaurite: |cffff4444%d|r"
L["HIST_HIGHEST_KEYS"]      = "--- Pietre più alte in tempo ---"
L["HIST_MAP_FALLBACK"]      = "Mappa %d"
L["HIST_RECENT_RUNS"]       = "--- Istanze recenti ---"
L["HIST_TIMED"]             = "In tempo"
L["HIST_DEPLETED"]          = "Esaurito"
L["HIST_NO_VALID_RUNS"]     = "Nessuna istanza valida registrata ancora."

-- Run Summary
L["RS_TIER_PLUS3"]          = "+3 FORZIERE"
L["RS_TIER_PLUS2"]          = "+2 FORZIERE"
L["RS_TIER_PLUS1"]          = "+1 IN TEMPO"
L["RS_TIER_DEPLETED"]       = "ESAURITA"
L["RS_TITLE"]               = "RIEPILOGO ISTANZA"
L["RS_CARD_TIME_PERF"]      = "PRESTAZIONE TEMPORALE"
L["RS_COL_ELAPSED"]         = "TRASCORSO"
L["RS_COL_VS_TIMER"]        = "vs TIMER +2"
L["RS_COL_VS_PB"]           = "vs MP"
L["RS_COL_VS_WK_PB"]        = "vs MP Sett"
L["RS_CARD_DEATHS"]         = "MORTI  |  VITTIME"
L["RS_COL_TIME_LOST"]       = "TEMPO PERSO"
L["RS_HINT_AVOIDABLE"]      = "Minimizza\nevitabili!"
L["RS_CARD_BOSS_SPLITS"]    = "TEMPI PER BOSS"
L["RS_CARD_INTERRUPTS"]     = "INTERRUZIONI"
L["RS_CARD_SCORE"]          = "PUNTEGGIO  |  RIEPILOGO VALUTAZIONE"
L["RS_COL_RUN_SCORE"]       = "PUNTEGGIO ISTANZA"
L["RS_COL_PREV_BEST"]       = "MIGLIORE PRECEDENTE"
L["RS_COL_EST_GAIN"]        = "GUADAGNO STIMATO"
L["RS_BTN_CLOSE"]           = "Chiudi"
L["RS_BTN_COPY_CHAT"]       = "Copia in chat"
L["RS_BTN_OPEN_HISTORY"]    = "Apri cronologia"
L["RS_FIRST_RUN"]           = "1a istanza!"
L["RS_PILL_TIMED"]          = "|cff4dff4dIN TEMPO  -%s|r"
L["RS_PILL_DEPLETED"]       = "|cffff4040ESAURITA  +%s|r"
L["RS_TIMED"]               = "IN TEMPO"
L["RS_DEPLETED"]            = "ESAURITA"

-- Frame Headers
L["MAIN_ADDON_HEADER"]      = "MythicPulse"
L["COMBATRES_HDR"]          = "Combattimento"

-- Config Panel — Tabs
L["CONFIG_TAB_GENERAL"]     = "Generale"
L["CONFIG_TAB_DISPLAY"]     = "Display"
L["CONFIG_TAB_PARTY_CDS"]   = "CD gruppo"
L["CONFIG_TAB_COMBAT"]      = "Combattimento"
L["CONFIG_TAB_UTILITY"]     = "Utilità"
L["CONFIG_TAB_MODULES"]     = "Moduli"

-- Config Panel — General Tab
L["CONFIG_HDR_BEHAVIOR"]    = "Comportamento"
L["CONFIG_LOCK_FRAME_POS"]  = "Blocca posizione frame"
L["CONFIG_HDR_ACTIONS"]     = "Azioni"
L["CONFIG_RESET_HUD_POS"]   = "Reimposta posizione HUD"
L["CONFIG_HUD_POS_RESET"]   = "Posizione frame principale reimpostata."
L["CONFIG_RELOAD_UI"]       = "Ricarica interfaccia"
L["CONFIG_HDR_PREVIEW"]     = "Anteprima"
L["CONFIG_PREVIEW_DESC"]    = "Carica dati fittizi per posizionare e ridimensionare i frame senza essere in un'istanza."
L["CONFIG_TOGGLE_PREVIEW"]  = "Attiva/disattiva anteprima"
L["CONFIG_HDR_ABOUT"]       = "Informazioni"
L["CONFIG_ABOUT_VERSION"]   = "MythicPulse v%s"
L["CONFIG_ABOUT_HELP"]      = "/mp help  \226\128\148  elenco tutti i comandi"
L["CONFIG_ABOUT_CONFIG"]    = "/mp config  \226\128\148  attiva/disattiva questo pannello"

-- Config Panel — Display Tab
L["CONFIG_HDR_MAIN_HUD"]    = "HUD principale"
L["CONFIG_HDR_INT_FRAME"]   = "Frame interruzioni"
L["CONFIG_HDR_FONT_ICON"]   = "Dimensioni font e icone"
L["CONFIG_FONT_SCALE"]      = "Scala font"
L["CONFIG_PC_ICON_SIZE"]    = "Dimensione icone CD gruppo"
L["CONFIG_BRES_ICON_SIZE"]  = "Dimensione icone Resurr. / SG"
L["CONFIG_ICON_RELOAD"]     = "Ricarica interfaccia (/reload) per applicare le modifiche alle dimensioni delle icone."

-- Config Panel — Party CDs Tab
L["CONFIG_HDR_LAYOUT"]      = "Layout"
L["CONFIG_ICON_GAP"]        = "Spazio icone"
L["CONFIG_MAX_ICONS"]       = "Icone massime"
L["CONFIG_ICONS_PER_ROW"]   = "Icone per riga"
L["CONFIG_SHOW_DISPEL_BAR"] = "Mostra barra Dispel"
L["CONFIG_HDR_ANCHORING"]   = "Ancoraggio"
L["CONFIG_GROWTH_DIR"]      = "Direzione di crescita"
L["CONFIG_ROW_ANCHOR"]      = "Punto di ancoraggio riga"
L["CONFIG_UF_ANCHOR"]       = "Ancora frame unità"
L["CONFIG_OFFSET_X"]        = "Scostamento X"
L["CONFIG_OFFSET_Y"]        = "Scostamento Y"

-- Config Panel — Combat Tab
L["CONFIG_HDR_INTERRUPTS"]  = "Interruzioni"
L["CONFIG_AUTO_KICKS"]      = "Annuncio automatico rotazione interruzioni"
L["CONFIG_INT_COMBAT_ONLY"] = "Mostra tracker interruzioni solo in combattimento"
L["CONFIG_HDR_BL_BREZ"]     = "Sete di sangue / Resurrezione di combattimento"
L["CONFIG_BREZ_NOTE"]       = "Rilevamento automatico: Sciamano, Mago e Cacciatore (con pet attivo)."
L["CONFIG_MORE_SOON"]       = "Altre opzioni in arrivo."

-- Config Panel — Utility Tab
L["CONFIG_HDR_UTILITY"]     = "Pannello utilità istanza"
L["CONFIG_UTIL_AUTO_SHOW"]  = "Mostra automaticamente all'ingresso in un'istanza"
L["CONFIG_UTIL_SHOW_REM"]   = "Mostra pulsanti rimozione abilità"
L["CONFIG_UTIL_HIDE_OPT"]   = "Nascondi voci non importanti"
L["CONFIG_HDR_HISTORY"]     = "Cronologia istanze"
L["CONFIG_MAX_HISTORY"]     = "Max voci cronologia"
L["CONFIG_HISTORY_PRUNE"]   = "Le voci più vecchie vengono eliminate al raggiungimento del limite."

-- Config Panel — Modules Tab
L["CONFIG_HDR_MODULES"]     = "Attiva / Disattiva moduli"
L["CONFIG_MOD_TIMER"]       = "Timer istanza"
L["CONFIG_MOD_DEATHS"]      = "Tracker morti"
L["CONFIG_MOD_FORCES"]      = "Forze nemiche"
L["CONFIG_MOD_KEYSTONE"]    = "Tracker Pietra Mitica"
L["CONFIG_MOD_PARTY_CDS"]   = "Cooldown gruppo"
L["CONFIG_MOD_INTERRUPT"]   = "Tracker interruzioni"
L["CONFIG_MOD_DISPEL"]      = "Tracker Dispel"
L["CONFIG_MOD_TRINKET"]     = "Tracker trinket"
L["CONFIG_MOD_GOSSIP"]      = "Dialogo automatico"
L["CONFIG_MOD_BREZ"]        = "Tracker resurrezione di combattimento"
L["CONFIG_MOD_HISTORY"]     = "Cronologia istanze"
L["CONFIG_MOD_AUTO_SLOT"]   = "Slot automatico Pietra Mitica"
L["CONFIG_MOD_TELEPORTS"]   = "Teletrasporti istanza"
L["CONFIG_MOD_UTILITY"]     = "Utilità istanza"
L["POPUP_RESET_CONFIRM"]    = "Reimpostare tutte le impostazioni di MythicPulse ai valori predefiniti?"

-- Dungeon Utility (additional)
L["UTILITY_SELF_PREFIX"]    = "(Personale)"
L["UTILITY_UNKNOWN"]        = "Istanza sconosciuta"
L["UTIL_DISABLED_MSG"]      = "Utilità istanza disattivata. Attivala in /mp config \226\134\146 Moduli."

-- Dungeon Teleport
L["TP_CLICK_TO_TELEPORT"]   = "Clic per teletrasportarsi"

-- Demo Mode
L["DEMO_ALREADY_ACTIVE"]    = "Anteprima display già attiva. /mp display per fermare."
L["DEMO_LOADING"]           = "Demo: HUD ancora in caricamento, riprovo tra 2s..."
L["DEMO_ON"]                = "|cff4dff4dAnteprima display ATTIVA|r \226\128\148 trascina i frame per riposizionarli. /mp display per fermare."
L["DEMO_OFF"]               = "|cffaaaaaaAnteprima display DISATTIVA|r"

-- Auto Slot
L["AUTOSLOT_DONE"]          = "|cff4dff4dPietra Mitica inserita automaticamente!|r"
