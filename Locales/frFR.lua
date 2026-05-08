--[[
    MythicPulse - French Localization (frFR)
    AI-generated using Blizzard localized terminology. Native-speaker corrections welcome via PR.
]]

local _, MP = ...

if GetLocale() ~= "frFR" then return end

local L = MP.L

-- General
L["ADDON_LOADED"]         = "MythicPulse chargé. Tapez /mp help pour afficher les commandes."
L["UNKNOWN"]              = "Inconnu"
L["ENABLED"]              = "Activé"
L["DISABLED"]             = "Désactivé"

-- Timer
L["TIMER_TITLE"]          = "Minuteur"
L["TIMER_PLUS_TWO"]       = "+2"
L["TIMER_PLUS_THREE"]     = "+3"
L["TIMER_OVERTIME"]       = "DÉPASSEMENT"
L["TIMER_COMPLETED"]      = "Terminé !"
L["TIMER_DEPLETED"]       = "Épuisé"
L["BOSS_SPLIT"]           = "Boss %d : %s"

-- Death Tracker
L["DEATHS"]               = "Morts"
L["DEATH_LOG"]            = "Journal des morts"
L["DEATH_PENALTY"]        = "Temps perdu"
L["DEATH_ENTRY"]          = "%s est mort à %s"
L["NO_DEATHS"]            = "Aucune mort"

-- Enemy Forces
L["ENEMY_FORCES"]         = "Forces ennemies"
L["FORCES_PROGRESS"]      = "%s / %s (%.1f%%)"
L["FORCES_COMPLETE"]      = "Forces ennemies complètes !"
L["CURRENT_PULL"]         = "Combat en cours"

-- Affixes
L["AFFIXES"]              = "Affixes"

-- Keystone
L["KEYSTONE"]             = "Pierre Mythique"
L["YOUR_KEY"]             = "Votre clé"
L["NO_KEY"]               = "Aucune pierre"
L["PARTY_KEYS"]           = "Clés du groupe"
L["KEY_FORMAT"]           = "%s +%d"

-- Party Cooldowns
L["PARTY_CDS"]            = "Délais du groupe"
L["CD_READY"]             = "Prêt"

-- Dispel Tracker
L["DISPELS"]              = "Dissipations"
L["DISPEL_READY"]         = "PRÊT"

-- Combat Res
L["BREZ"]                 = "Résurrection de combat"
L["BREZ_READY"]           = "%d/%d prêt"
L["BREZ_NEXT"]            = "prochain dans %s"
L["BREZ_NONE"]            = "Pas de résurrection dans le groupe"

-- Dungeon History
L["HISTORY"]              = "Historique des donjons"
L["HISTORY_EMPTY"]        = "Aucun donjon enregistré."
L["HISTORY_TIMED"]        = "Dans les temps"
L["HISTORY_DEPLETED"]     = "Épuisé"

-- Config
L["CONFIG_TITLE"]         = "Paramètres MythicPulse"
L["CONFIG_GENERAL"]       = "Général"
L["CONFIG_MODULES"]       = "Modules"
L["CONFIG_SCALE"]         = "Échelle de l'interface"
L["CONFIG_OPACITY"]       = "Opacité"
L["CONFIG_LOCK"]          = "Verrouiller les cadres"
L["CONFIG_RESET_POS"]     = "Réinitialiser les positions"
L["CONFIG_RESET_ALL"]     = "Réinitialiser tous les paramètres"

-- Interrupt Tracker
L["INTERRUPTS"]           = "Interruptions"

-- Dungeon Utility
L["UTILITY_TITLE"]        = "Capacités de donjon"
L["UTILITY_NO_ABILITIES"] = "Aucune capacité utilitaire pour ce donjon"
L["UTILITY_SELECT"]       = "Sélectionner un donjon..."
L["UTILITY_KNOWN"]        = "Connu"
L["UTILITY_ADD"]          = "Ajouter"
L["UTILITY_REMOVE"]       = "Supprimer"
L["UTILITY_OPTIONAL"]     = "Facultatif"
L["UTILITY_SELF_ONLY"]    = "Capacité personnelle uniquement"

-- Slash Commands
L["SLASH_HELP_HEADER"]     = "Commandes MythicPulse :"
L["SLASH_HELP_DISPLAY"]    = "  /mp display  \226\128\148 Afficher tous les cadres avec des données fictives (pour le placement)"
L["SLASH_HELP_CONFIG"]     = "  /mp config   \226\128\148 Ouvrir les paramètres"
L["SLASH_HELP_LOCK"]       = "  /mp lock     \226\128\148 Verrouiller/déverrouiller les cadres"
L["SLASH_HELP_RESET"]      = "  /mp reset    \226\128\148 Réinitialiser les positions des cadres"
L["SLASH_HELP_KEYS"]       = "  /mp keys     \226\128\148 Annoncer toutes les clés du groupe"
L["SLASH_HELP_UTILITY"]    = "  /mp utility  \226\128\148 Basculer l'utilitaire de donjon"
L["SLASH_HELP_FOOTNOTE"]   = "Les cadres ne s'affichent qu'à l'intérieur d'une Clé Mythique active. Utilisez /mp display pour les positionner n'importe où."
L["SLASH_FRAMES_LOCKED"]   = "Cadres verrouillés."
L["SLASH_FRAMES_UNLOCKED"] = "Cadres déverrouillés."
L["SLASH_RESET_DONE"]      = "Positions des cadres réinitialisées."
L["SLASH_KEYSTONE_UNAVAIL"]= "Suivi de Pierre Mythique indisponible."
L["SLASH_DEBUG_ON"]        = "Mode débogage activé."
L["SLASH_DEBUG_OFF"]       = "Mode débogage désactivé."
L["SLASH_DISPLAY_UNAVAIL"] = "Aperçu d'affichage indisponible."
L["SLASH_INT_UNAVAIL"]     = "Suivi des interruptions indisponible."
L["SLASH_VERSION_LABEL"]   = "Version : "
L["SLASH_UNKNOWN_CMD"]     = "Commande inconnue '%s'. Tapez /mp help pour la liste."

-- Addon Compartment Tooltip
L["COMPARTMENT_KEY_FORMAT"]  = "Clé : %s +%d"
L["COMPARTMENT_LEFT_CLICK"]  = "|cffffffffClic gauche :|r Basculer l'affichage"
L["COMPARTMENT_RIGHT_CLICK"] = "|cffffffffClic droit :|r Ouvrir les paramètres"

-- Timer (additional keys)
L["TIMER_PB_FORMAT"]       = "RP |cffffffff%s|r  (+%d)"
L["TIMER_NO_PB"]           = "|cff666666Aucun RP|r"
L["TIMER_ZERO_DEATHS"]     = "0 Mort"
L["TIMER_DEATH_SINGULAR"]  = "Mort"
L["TIMER_DEATH_PLURAL"]    = "Morts"
L["TIMER_BOSS_FALLBACK"]   = "Boss %d"
L["TIMER_TOOLTIP_KILLED"]  = "Tué à :"
L["TIMER_TOOLTIP_PREV"]    = "Depuis le boss précédent :"
L["TIMER_TOOLTIP_START"]   = "Depuis le début :"
L["TIMER_TOOLTIP_VS_PB"]   = "vs Record personnel :"

-- Enemy Forces (additional keys)
L["EF_COMPLETE"]           = "Terminé !"

-- Keystone (additional key)
L["KEY_NOT_IN_GROUP"]      = "Vous n'êtes pas dans un groupe."

-- Party Cooldowns (additional key)
L["PC_DEMO_NEEDS_PARTY"]   = "|cff88ccffDémonstration :|r Les icônes de délai ne s'affichent que là où un cadre de groupe existe. Rejoignez un groupe ou activez les cadres de groupe en mode raid pour voir les 5 emplacements de démonstration."

-- Interrupt Tracker (additional keys)
L["INT_READY"]             = "PRÊT"
L["INT_TOOLTIP_ON_CD"]     = "En recharge : %.0fs"
L["INT_TOOLTIP_CLICK"]     = "Clic gauche pour annoncer le statut"
L["INT_NO_INTERRUPTERS"]   = "Aucun interrupteur dans le groupe."
L["INT_ROTATION_HEADER"]   = "Rotation des interruptions :"
L["INT_FALLBACK_NAME"]     = "Interruption"
L["INT_CD_ANNOUNCE"]       = "[MythicPulse] %s's %s on CD (%.0fs)"
L["INT_READY_ANNOUNCE"]    = "[MythicPulse] %s's %s is READY"
L["INT_ROTATION_ANNOUNCE"] = "[MythicPulse] Kicks: %s"

-- Combat Res (additional keys)
L["CR_READY"]              = "Prêt"
L["CR_ON_CD"]              = "En recharge"
L["CR_AVAILABLE"]          = "Disponible"
L["CR_NO_BREZ"]            = "Pas de résurrection"
L["CR_BREZ_READY_FORMAT"]  = "Prêt %d/%d"
L["CR_BL_SATED"]           = "Repu"
L["CR_BL_NO_SOURCE"]       = "Pas de source"

-- Dungeon History (additional keys)
L["HIST_HEADER"]           = "=== Historique des donjons ==="
L["HIST_TOTAL_RUNS"]       = "Donjons totaux : |cffffffff%d|r"
L["HIST_TIMED_RUNS"]       = "Dans les temps : |cff4dff4d%d|r (%.0f%%)"
L["HIST_DEPLETED_RUNS"]    = "Épuisés : |cffff4444%d|r"
L["HIST_HIGHEST_KEYS"]     = "--- Clés les plus élevées dans les temps ---"
L["HIST_MAP_FALLBACK"]     = "Carte %d"
L["HIST_RECENT_RUNS"]      = "--- Donjons récents ---"
L["HIST_TIMED"]            = "Dans les temps"
L["HIST_DEPLETED"]         = "Épuisé"
L["HIST_NO_VALID_RUNS"]    = "Aucun donjon valide enregistré."

-- Run Summary
L["RS_TIER_PLUS3"]         = "+3 COFFRE"
L["RS_TIER_PLUS2"]         = "+2 COFFRE"
L["RS_TIER_PLUS1"]         = "+1 DANS LES TEMPS"
L["RS_TIER_DEPLETED"]      = "ÉPUISÉ"
L["RS_TITLE"]              = "RÉSUMÉ DU DONJON"
L["RS_CARD_TIME_PERF"]     = "PERFORMANCE TEMPORELLE"
L["RS_COL_ELAPSED"]        = "TEMPS ÉCOULÉ"
L["RS_COL_VS_TIMER"]       = "vs CHRONO +2"
L["RS_COL_VS_PB"]          = "vs RP"
L["RS_CARD_DEATHS"]        = "MORTS  |  VICTIMES"
L["RS_COL_TIME_LOST"]      = "TEMPS PERDU"
L["RS_HINT_AVOIDABLE"]     = "Minimisez\nles évitables !"
L["RS_CARD_BOSS_SPLITS"]   = "TEMPS PAR BOSS"
L["RS_CARD_SCORE"]         = "SCORE  |  RÉCAPITULATIF DE COTE"
L["RS_COL_RUN_SCORE"]      = "SCORE DU DONJON"
L["RS_COL_PREV_BEST"]      = "MEILLEUR PRÉCÉDENT"
L["RS_COL_EST_GAIN"]       = "GAIN EST."
L["RS_BTN_CLOSE"]          = "Fermer"
L["RS_BTN_COPY_CHAT"]      = "Copier dans le chat"
L["RS_BTN_OPEN_HISTORY"]   = "Ouvrir l'historique"
L["RS_FIRST_RUN"]          = "1er donjon !"
L["RS_PILL_TIMED"]         = "|cff4dff4dDANS LES TEMPS  -%s|r"
L["RS_PILL_DEPLETED"]      = "|cffff4040ÉPUISÉ  +%s|r"
L["RS_TIMED"]              = "DANS LES TEMPS"
L["RS_DEPLETED"]           = "ÉPUISÉ"

-- Frame Headers
L["MAIN_ADDON_HEADER"]     = "MythicPulse"
L["COMBATRES_HDR"]         = "Combat"

-- Config Panel — Tabs
L["CONFIG_TAB_GENERAL"]    = "Général"
L["CONFIG_TAB_DISPLAY"]    = "Affichage"
L["CONFIG_TAB_PARTY_CDS"]  = "DCs de groupe"
L["CONFIG_TAB_COMBAT"]     = "Combat"
L["CONFIG_TAB_UTILITY"]    = "Utilitaire"
L["CONFIG_TAB_MODULES"]    = "Modules"

-- Config Panel — General Tab
L["CONFIG_HDR_BEHAVIOR"]   = "Comportement"
L["CONFIG_LOCK_FRAME_POS"] = "Verrouiller la position des cadres"
L["CONFIG_HDR_ACTIONS"]    = "Actions"
L["CONFIG_RESET_HUD_POS"]  = "Réinitialiser la position du HUD"
L["CONFIG_HUD_POS_RESET"]  = "Position du cadre principal réinitialisée."
L["CONFIG_RELOAD_UI"]      = "Recharger l'interface"
L["CONFIG_HDR_PREVIEW"]    = "Aperçu"
L["CONFIG_PREVIEW_DESC"]   = "Charger des données fictives pour positionner et redimensionner les cadres sans être dans une clé."
L["CONFIG_TOGGLE_PREVIEW"] = "Basculer l'aperçu"
L["CONFIG_HDR_ABOUT"]      = "À propos"
L["CONFIG_ABOUT_VERSION"]  = "MythicPulse v%s"
L["CONFIG_ABOUT_HELP"]     = "/mp help  \226\128\148  liste de toutes les commandes"
L["CONFIG_ABOUT_CONFIG"]   = "/mp config  \226\128\148  ouvrir/fermer ce panneau"

-- Config Panel — Display Tab
L["CONFIG_HDR_MAIN_HUD"]   = "HUD principal"
L["CONFIG_HDR_INT_FRAME"]  = "Cadre d'interruptions"
L["CONFIG_HDR_FONT_ICON"]  = "Taille de police et d'icônes"
L["CONFIG_FONT_SCALE"]     = "Échelle de police"
L["CONFIG_PC_ICON_SIZE"]   = "Taille des icônes DC de groupe"
L["CONFIG_BRES_ICON_SIZE"] = "Taille des icônes Rés. combat / Hastement"
L["CONFIG_ICON_RELOAD"]    = "Rechargez l'interface (/reload) pour appliquer les changements de taille d'icône."

-- Config Panel — Party CDs Tab
L["CONFIG_HDR_LAYOUT"]     = "Disposition"
L["CONFIG_ICON_GAP"]       = "Espacement des icônes"
L["CONFIG_MAX_ICONS"]      = "Nombre max. d'icônes"
L["CONFIG_ICONS_PER_ROW"]  = "Icônes par rangée"
L["CONFIG_SHOW_DISPEL_BAR"]= "Afficher la barre de dissipation"
L["CONFIG_HDR_ANCHORING"]  = "Ancrage"
L["CONFIG_GROWTH_DIR"]     = "Direction de croissance"
L["CONFIG_ROW_ANCHOR"]     = "Point d'ancrage de rangée"
L["CONFIG_UF_ANCHOR"]      = "Ancrage de cadre d'unité"
L["CONFIG_OFFSET_X"]       = "Décalage X"
L["CONFIG_OFFSET_Y"]       = "Décalage Y"

-- Config Panel — Combat Tab
L["CONFIG_HDR_INTERRUPTS"] = "Interruptions"
L["CONFIG_AUTO_KICKS"]     = "Annoncer automatiquement la rotation des interruptions"
L["CONFIG_INT_COMBAT_ONLY"]= "Afficher le suivi des interruptions uniquement en combat"
L["CONFIG_HDR_BL_BREZ"]    = "Hastement / Résurrection de combat"
L["CONFIG_BREZ_NOTE"]      = "Détection automatique : Chaman, Mage et Chasseur (avec une invocation active)."
L["CONFIG_MORE_SOON"]      = "D'autres options arrivent bientôt."

-- Config Panel — Utility Tab
L["CONFIG_HDR_UTILITY"]    = "Panneau d'utilitaire de donjon"
L["CONFIG_UTIL_AUTO_SHOW"] = "Afficher automatiquement à l'entrée d'un donjon"
L["CONFIG_UTIL_SHOW_REM"]  = "Afficher les boutons de suppression de capacité"
L["CONFIG_UTIL_HIDE_OPT"]  = "Masquer les entrées non importantes"
L["CONFIG_HDR_HISTORY"]    = "Historique des donjons"
L["CONFIG_MAX_HISTORY"]    = "Nombre max. d'entrées dans l'historique"
L["CONFIG_HISTORY_PRUNE"]  = "Les entrées les plus anciennes sont supprimées lorsque la limite est atteinte."

-- Config Panel — Modules Tab
L["CONFIG_HDR_MODULES"]    = "Activer / Désactiver les modules"
L["CONFIG_MOD_TIMER"]      = "Minuteur de donjon"
L["CONFIG_MOD_DEATHS"]     = "Suivi des morts"
L["CONFIG_MOD_FORCES"]     = "Forces ennemies"
L["CONFIG_MOD_KEYSTONE"]   = "Suivi de Pierre Mythique"
L["CONFIG_MOD_PARTY_CDS"]  = "Délais de recharge du groupe"
L["CONFIG_MOD_INTERRUPT"]  = "Suivi des interruptions"
L["CONFIG_MOD_DISPEL"]     = "Suivi des dissipations"
L["CONFIG_MOD_TRINKET"]    = "Suivi des bibelots"
L["CONFIG_MOD_GOSSIP"]     = "Dialogue automatique"
L["CONFIG_MOD_BREZ"]       = "Suivi de résurrection de combat"
L["CONFIG_MOD_HISTORY"]    = "Historique des donjons"
L["CONFIG_MOD_AUTO_SLOT"]  = "Emplacement automatique de Pierre Mythique"
L["CONFIG_MOD_TELEPORTS"]  = "Téléportations de donjon"
L["CONFIG_MOD_UTILITY"]    = "Utilitaire de donjon"
L["POPUP_RESET_CONFIRM"]   = "Réinitialiser tous les paramètres MythicPulse par défaut ?"

-- Dungeon Utility (additional keys)
L["UTILITY_SELF_PREFIX"]   = "(Personnel)"
L["UTILITY_UNKNOWN"]       = "Donjon inconnu"
L["UTIL_DISABLED_MSG"]     = "L'utilitaire de donjon est désactivé. Activez-le dans /mp config \226\134\146 Modules."

-- Dungeon Teleport
L["TP_CLICK_TO_TELEPORT"]  = "Cliquer pour se téléporter"

-- Demo Mode
L["DEMO_ALREADY_ACTIVE"]   = "L'aperçu d'affichage est déjà actif. /mp display pour arrêter."
L["DEMO_LOADING"]          = "Démonstration : HUD en cours de chargement, nouvelle tentative dans 2s..."
L["DEMO_ON"]               = "|cff4dff4dAperçu d'affichage ACTIVÉ|r \226\128\148 faites glisser les cadres pour les repositionner. /mp display pour arrêter."
L["DEMO_OFF"]              = "|cffaaaaaaAperçu d'affichage DÉSACTIVÉ|r"

-- Auto Slot
L["AUTOSLOT_DONE"]         = "|cff4dff4dPierre Mythique placée automatiquement !|r"
