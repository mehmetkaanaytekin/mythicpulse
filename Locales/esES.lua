--[[
    MythicPulse - Spanish Localization (esES / esMX)
    AI-generated using Blizzard localized terminology. Native-speaker corrections welcome via PR.
]]

local _, MP = ...

if GetLocale() ~= "esES" and GetLocale() ~= "esMX" then return end

local L = MP.L

-- General
L["ADDON_LOADED"]         = "MythicPulse cargado. Escribe /mp help para ver los comandos."
L["UNKNOWN"]              = "Desconocido"
L["ENABLED"]              = "Activado"
L["DISABLED"]             = "Desactivado"

-- Timer
L["TIMER_TITLE"]          = "Temporizador"
L["TIMER_PLUS_TWO"]       = "+2"
L["TIMER_PLUS_THREE"]     = "+3"
L["TIMER_OVERTIME"]       = "TIEMPO EXTRA"
L["TIMER_COMPLETED"]      = "¡Completado!"
L["TIMER_DEPLETED"]       = "Agotado"
L["BOSS_SPLIT"]           = "Jefe %d: %s"

-- Death Tracker
L["DEATHS"]               = "Muertes"
L["DEATH_LOG"]            = "Registro de muertes"
L["DEATH_PENALTY"]        = "Tiempo perdido"
L["DEATH_ENTRY"]          = "%s murió en %s"
L["NO_DEATHS"]            = "Sin muertes"

-- Enemy Forces
L["ENEMY_FORCES"]         = "Fuerzas enemigas"
L["FORCES_PROGRESS"]      = "%s / %s (%.1f%%)"
L["FORCES_COMPLETE"]      = "¡Fuerzas enemigas completadas!"
L["CURRENT_PULL"]         = "Grupo actual"

-- Affixes
L["AFFIXES"]              = "Afijos"

-- Keystone
L["KEYSTONE"]             = "Piedra Mítica"
L["YOUR_KEY"]             = "Tu piedra"
L["NO_KEY"]               = "Sin piedra"
L["PARTY_KEYS"]           = "Piedras del grupo"
L["KEY_FORMAT"]           = "%s +%d"

-- Party Cooldowns
L["PARTY_CDS"]            = "Enfriamientos del grupo"
L["CD_READY"]             = "Listo"

-- Dispel Tracker
L["DISPELS"]              = "Disipar"
L["DISPEL_READY"]         = "LISTO"

-- Combat Res
L["BREZ"]                 = "Resurrección de combate"
L["BREZ_READY"]           = "%d/%d listo"
L["BREZ_NEXT"]            = "siguiente en %s"
L["BREZ_NONE"]            = "Sin resurrección de combate en el grupo"

-- Dungeon History
L["HISTORY"]              = "Historial de mazmorras"
L["HISTORY_EMPTY"]        = "Aún no hay incursiones registradas."
L["HISTORY_TIMED"]        = "A tiempo"
L["HISTORY_DEPLETED"]     = "Agotado"

-- Config
L["CONFIG_TITLE"]         = "Configuración de MythicPulse"
L["CONFIG_GENERAL"]       = "General"
L["CONFIG_MODULES"]       = "Módulos"
L["CONFIG_SCALE"]         = "Escala de la interfaz"
L["CONFIG_OPACITY"]       = "Opacidad"
L["CONFIG_LOCK"]          = "Bloquear marcos"
L["CONFIG_RESET_POS"]     = "Restablecer posiciones"
L["CONFIG_RESET_ALL"]     = "Restablecer todos los ajustes"

-- Interrupt Tracker
L["INTERRUPTS"]           = "Interrupciones"

-- Dungeon Utility
L["UTILITY_TITLE"]        = "Utilidades de mazmorra"
L["UTILITY_NO_ABILITIES"] = "No hay habilidades útiles para esta mazmorra"
L["UTILITY_SELECT"]       = "Seleccionar mazmorra..."
L["UTILITY_KNOWN"]        = "Conocido"
L["UTILITY_ADD"]          = "Añadir"
L["UTILITY_REMOVE"]       = "Eliminar"
L["UTILITY_OPTIONAL"]     = "Opcional"
L["UTILITY_SELF_ONLY"]    = "Habilidad solo propia"

-- Slash Commands
L["SLASH_HELP_HEADER"]      = "Comandos de MythicPulse:"
L["SLASH_HELP_DISPLAY"]     = "  /mp display  \226\128\148 Mostrar todos los marcos con datos de prueba (para colocación)"
L["SLASH_HELP_CONFIG"]      = "  /mp config   \226\128\148 Abrir ajustes"
L["SLASH_HELP_LOCK"]        = "  /mp lock     \226\128\148 Bloquear/desbloquear marcos"
L["SLASH_HELP_RESET"]       = "  /mp reset    \226\128\148 Restablecer posiciones de marcos"
L["SLASH_HELP_KEYS"]        = "  /mp keys     \226\128\148 Anunciar todas las piedras del grupo"
L["SLASH_HELP_UTILITY"]     = "  /mp utility  \226\128\148 Alternar utilidades de mazmorra"
L["SLASH_HELP_FOOTNOTE"]    = "Los marcos solo se muestran dentro de una Piedra Mítica activa. Usa /mp display para colocarlos en cualquier lugar."
L["SLASH_FRAMES_LOCKED"]    = "Marcos bloqueados."
L["SLASH_FRAMES_UNLOCKED"]  = "Marcos desbloqueados."
L["SLASH_RESET_DONE"]       = "Posiciones de marcos restablecidas."
L["SLASH_KEYSTONE_UNAVAIL"] = "Seguidor de Piedra Mítica no disponible."
L["SLASH_DEBUG_ON"]         = "Modo de depuración activado."
L["SLASH_DEBUG_OFF"]        = "Modo de depuración desactivado."
L["SLASH_DISPLAY_UNAVAIL"]  = "Vista previa de pantalla no disponible."
L["SLASH_INT_UNAVAIL"]      = "Seguidor de interrupciones no disponible."
L["SLASH_VERSION_LABEL"]    = "Versión: "
L["SLASH_UNKNOWN_CMD"]      = "Comando desconocido '%s'. Escribe /mp help para ver la lista."

-- Compartment Tooltip
L["COMPARTMENT_KEY_FORMAT"] = "Piedra: %s +%d"
L["COMPARTMENT_LEFT_CLICK"] = "|cffffffffClic izquierdo:|r Alternar pantalla"
L["COMPARTMENT_RIGHT_CLICK"]= "|cffffffffClic derecho:|r Abrir ajustes"

-- Timer (additional)
L["TIMER_PB_FORMAT"]        = "MP |cffffffff%s|r  (+%d)"
L["TIMER_WK_PB_FORMAT"]     = "Sem |cffffffff%s|r"
L["TIMER_NO_PB"]            = "|cff666666Sin MP aún|r"
L["TIMER_ZERO_DEATHS"]      = "0 Muertes"
L["TIMER_DEATH_SINGULAR"]   = "Muerte"
L["TIMER_DEATH_PLURAL"]     = "Muertes"
L["TIMER_BOSS_FALLBACK"]    = "Jefe %d"
L["TIMER_TOOLTIP_KILLED"]   = "Eliminado en:"
L["TIMER_TOOLTIP_PREV"]     = "Desde el jefe anterior:"
L["TIMER_TOOLTIP_START"]    = "Desde el inicio:"
L["TIMER_TOOLTIP_VS_PB"]    = "vs Mejor personal:"

-- Enemy Forces (additional)
L["EF_COMPLETE"]            = "¡Completado!"

-- Keystone (additional)
L["KEY_NOT_IN_GROUP"]       = "No estás en un grupo."

-- Party Cooldowns (additional)
L["PC_DEMO_NEEDS_PARTY"]    = "|cff88ccffDemo:|r Los iconos de enfriamiento solo se muestran donde existe un marco de grupo/raid. Únete a un grupo o activa los marcos de grupo estilo raid para ver los 5 espacios demo."

-- Interrupt Tracker (additional)
L["INT_READY"]              = "LISTO"
L["INT_TOOLTIP_ON_CD"]      = "En enfriamiento: %.0fs"
L["INT_TOOLTIP_CLICK"]      = "Clic izquierdo para anunciar el estado"
L["INT_NO_INTERRUPTERS"]    = "No hay interruptores en el grupo."
L["INT_ROTATION_HEADER"]    = "Rotación de interrupciones:"
L["INT_FALLBACK_NAME"]      = "Interrupción"
L["INT_CD_ANNOUNCE"]        = "[MythicPulse] %s's %s on CD (%.0fs)"
L["INT_READY_ANNOUNCE"]     = "[MythicPulse] %s's %s is READY"
L["INT_ROTATION_ANNOUNCE"]  = "[MythicPulse] Kicks: %s"

-- Combat Res (additional)
L["CR_READY"]               = "Listo"
L["CR_ON_CD"]               = "En enfriamiento"
L["CR_AVAILABLE"]           = "Disponible"
L["CR_NO_BREZ"]             = "Sin resurrección de combate"
L["CR_BREZ_READY_FORMAT"]   = "Listo %d/%d"
L["CR_BL_SATED"]            = "Saciado"
L["CR_BL_NO_SOURCE"]        = "Sin fuente"

-- Dungeon History (additional)
L["HIST_HEADER"]            = "=== Historial de incursiones ==="
L["HIST_TOTAL_RUNS"]        = "Incursiones totales: |cffffffff%d|r"
L["HIST_TIMED_RUNS"]        = "A tiempo: |cff4dff4d%d|r (%.0f%%)"
L["HIST_DEPLETED_RUNS"]     = "Agotadas: |cffff4444%d|r"
L["HIST_HIGHEST_KEYS"]      = "--- Piedras más altas a tiempo ---"
L["HIST_MAP_FALLBACK"]      = "Mapa %d"
L["HIST_RECENT_RUNS"]       = "--- Incursiones recientes ---"
L["HIST_TIMED"]             = "A tiempo"
L["HIST_DEPLETED"]          = "Agotado"
L["HIST_NO_VALID_RUNS"]     = "Aún no hay incursiones válidas registradas."

-- Run Summary
L["RS_TIER_PLUS3"]          = "+3 COFRE"
L["RS_TIER_PLUS2"]          = "+2 COFRE"
L["RS_TIER_PLUS1"]          = "+1 A TIEMPO"
L["RS_TIER_DEPLETED"]       = "AGOTADO"
L["RS_TITLE"]               = "RESUMEN DE INCURSIÓN"
L["RS_CARD_TIME_PERF"]      = "RENDIMIENTO TEMPORAL"
L["RS_COL_ELAPSED"]         = "TRANSCURRIDO"
L["RS_COL_VS_TIMER"]        = "vs TEMPORIZADOR +2"
L["RS_COL_VS_PB"]           = "vs MP"
L["RS_COL_VS_WK_PB"]        = "vs MP Sem"
L["RS_CARD_DEATHS"]         = "MUERTES  |  BAJAS"
L["RS_COL_TIME_LOST"]       = "TIEMPO PERDIDO"
L["RS_HINT_AVOIDABLE"]      = "¡Minimiza\nevitables!"
L["RS_CARD_BOSS_SPLITS"]    = "TIEMPOS POR JEFE"
L["RS_CARD_INTERRUPTS"]     = "INTERRUPCIONES"
L["RS_CARD_SCORE"]          = "PUNTUACIÓN  |  RESUMEN DE VALORACIÓN"
L["RS_COL_RUN_SCORE"]       = "PUNTUACIÓN DE INCURSIÓN"
L["RS_COL_PREV_BEST"]       = "MEJOR ANTERIOR"
L["RS_COL_EST_GAIN"]        = "GANANCIA EST."
L["RS_BTN_CLOSE"]           = "Cerrar"
L["RS_BTN_COPY_CHAT"]       = "Copiar al chat"
L["RS_BTN_OPEN_HISTORY"]    = "Abrir historial"
L["RS_FIRST_RUN"]           = "¡1.ª incursión!"
L["RS_PILL_TIMED"]          = "|cff4dff4dA TIEMPO  -%s|r"
L["RS_PILL_DEPLETED"]       = "|cffff4040AGOTADO  +%s|r"
L["RS_TIMED"]               = "A TIEMPO"
L["RS_DEPLETED"]            = "AGOTADO"

-- Frame Headers
L["MAIN_ADDON_HEADER"]      = "MythicPulse"
L["COMBATRES_HDR"]          = "Combate"

-- Config Panel — Tabs
L["CONFIG_TAB_GENERAL"]     = "General"
L["CONFIG_TAB_DISPLAY"]     = "Pantalla"
L["CONFIG_TAB_PARTY_CDS"]   = "Enf. de grupo"
L["CONFIG_TAB_COMBAT"]      = "Combate"
L["CONFIG_TAB_UTILITY"]     = "Utilidad"
L["CONFIG_TAB_MODULES"]     = "Módulos"

-- Config Panel — General Tab
L["CONFIG_HDR_BEHAVIOR"]    = "Comportamiento"
L["CONFIG_LOCK_FRAME_POS"]  = "Bloquear posición de marcos"
L["CONFIG_HDR_ACTIONS"]     = "Acciones"
L["CONFIG_RESET_HUD_POS"]   = "Restablecer posición del HUD"
L["CONFIG_HUD_POS_RESET"]   = "Posición del marco principal restablecida."
L["CONFIG_RELOAD_UI"]       = "Recargar interfaz"
L["CONFIG_HDR_PREVIEW"]     = "Vista previa"
L["CONFIG_PREVIEW_DESC"]    = "Carga datos de prueba para posicionar y redimensionar los marcos sin estar en una Piedra Mítica."
L["CONFIG_TOGGLE_PREVIEW"]  = "Alternar vista previa"
L["CONFIG_HDR_ABOUT"]       = "Acerca de"
L["CONFIG_ABOUT_VERSION"]   = "MythicPulse v%s"
L["CONFIG_ABOUT_HELP"]      = "/mp help  \226\128\148  listar todos los comandos"
L["CONFIG_ABOUT_CONFIG"]    = "/mp config  \226\128\148  alternar este panel"

-- Config Panel — Display Tab
L["CONFIG_HDR_MAIN_HUD"]    = "HUD principal"
L["CONFIG_HDR_INT_FRAME"]   = "Marco de interrupciones"
L["CONFIG_HDR_FONT_ICON"]   = "Tamaño de fuente e iconos"
L["CONFIG_FONT_SCALE"]      = "Escala de fuente"
L["CONFIG_PC_ICON_SIZE"]    = "Tamaño de icono de enf. de grupo"
L["CONFIG_BRES_ICON_SIZE"]  = "Tamaño de icono de Resurrección / SG"
L["CONFIG_ICON_RELOAD"]     = "Recarga la interfaz (/reload) para aplicar cambios de tamaño de icono."

-- Config Panel — Party CDs Tab
L["CONFIG_HDR_LAYOUT"]      = "Disposición"
L["CONFIG_ICON_GAP"]        = "Separación de iconos"
L["CONFIG_MAX_ICONS"]       = "Máx. de iconos"
L["CONFIG_ICONS_PER_ROW"]   = "Iconos por fila"
L["CONFIG_SHOW_DISPEL_BAR"] = "Mostrar barra de disipar"
L["CONFIG_HDR_ANCHORING"]   = "Anclaje"
L["CONFIG_GROWTH_DIR"]      = "Dirección de crecimiento"
L["CONFIG_ROW_ANCHOR"]      = "Punto de anclaje de fila"
L["CONFIG_UF_ANCHOR"]       = "Ancla de marco de unidad"
L["CONFIG_OFFSET_X"]        = "Desplazamiento X"
L["CONFIG_OFFSET_Y"]        = "Desplazamiento Y"

-- Config Panel — Combat Tab
L["CONFIG_HDR_INTERRUPTS"]  = "Interrupciones"
L["CONFIG_AUTO_KICKS"]      = "Anuncio automático de rotación de interrupciones"
L["CONFIG_INT_COMBAT_ONLY"] = "Mostrar seguidor de interrupciones solo en combate"
L["CONFIG_HDR_BL_BREZ"]     = "Sed de sangre / Resurrección de combate"
L["CONFIG_BREZ_NOTE"]       = "Detección automática: Chamán, Mago y Cazador (con mascota activa)."

-- Config Panel — Utility Tab
L["CONFIG_HDR_UTILITY"]     = "Panel de utilidades de mazmorra"
L["CONFIG_UTIL_AUTO_SHOW"]  = "Mostrar automáticamente al entrar en una mazmorra"
L["CONFIG_UTIL_SHOW_REM"]   = "Mostrar botones de eliminación de habilidades"
L["CONFIG_UTIL_HIDE_OPT"]   = "Ocultar entradas no importantes"
L["CONFIG_HDR_HISTORY"]     = "Historial de incursiones"
L["CONFIG_MAX_HISTORY"]     = "Máx. de entradas en el historial"
L["CONFIG_HISTORY_PRUNE"]   = "Las entradas más antiguas se eliminan al alcanzar el límite."

-- Config Panel — Modules Tab
L["CONFIG_HDR_MODULES"]     = "Activar / Desactivar módulos"
L["CONFIG_MOD_TIMER"]       = "Temporizador de mazmorra"
L["CONFIG_MOD_DEATHS"]      = "Seguidor de muertes"
L["CONFIG_MOD_FORCES"]      = "Fuerzas enemigas"
L["CONFIG_MOD_KEYSTONE"]    = "Seguidor de Piedra Mítica"
L["CONFIG_MOD_PARTY_CDS"]   = "Enfriamientos del grupo"
L["CONFIG_MOD_INTERRUPT"]   = "Seguidor de interrupciones"
L["CONFIG_MOD_DISPEL"]      = "Seguidor de disipar"
L["CONFIG_MOD_TRINKET"]     = "Seguidor de chuchería"
L["CONFIG_MOD_GOSSIP"]      = "Diálogo automático"
L["CONFIG_MOD_BREZ"]        = "Seguidor de resurrección de combate"
L["CONFIG_MOD_HISTORY"]     = "Historial de mazmorras"
L["CONFIG_MOD_AUTO_SLOT"]   = "Ranura automática de Piedra Mítica"
L["CONFIG_MOD_TELEPORTS"]   = "Teletransportes de mazmorra"
L["CONFIG_MOD_UTILITY"]     = "Utilidades de mazmorra"
L["POPUP_RESET_CONFIRM"]    = "¿Restablecer todos los ajustes de MythicPulse a los valores predeterminados?"

-- Dungeon Utility (additional)
L["UTILITY_SELF_PREFIX"]    = "(Propio)"
L["UTILITY_UNKNOWN"]        = "Mazmorra desconocida"
L["UTIL_DISABLED_MSG"]      = "Las utilidades de mazmorra están desactivadas. Actívalas en /mp config \226\134\146 Módulos."

-- Dungeon Teleport
L["TP_CLICK_TO_TELEPORT"]   = "Clic para teletransportarse"

-- Demo Mode
L["DEMO_ALREADY_ACTIVE"]    = "La vista previa ya está activa. /mp display para detener."
L["DEMO_LOADING"]           = "Demo: el HUD se sigue cargando, reintentando en 2s..."
L["DEMO_ON"]                = "|cff4dff4dVista previa ACTIVADA|r \226\128\148 arrastra los marcos para reposicionarlos. /mp display para detener."
L["DEMO_OFF"]               = "|cffaaaaaaVista previa DESACTIVADA|r"

-- Auto Slot
L["AUTOSLOT_DONE"]          = "|cff4dff4d¡Piedra Mítica insertada automáticamente!|r"
