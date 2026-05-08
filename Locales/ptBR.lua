--[[
    MythicPulse - Brazilian Portuguese Localization (ptBR)
    AI-generated using Blizzard localized terminology. Native-speaker corrections welcome via PR.
]]

local _, MP = ...

if GetLocale() ~= "ptBR" then return end

local L = MP.L

-- General
L["ADDON_LOADED"]         = "MythicPulse carregado. Digite /mp help para ver os comandos."
L["UNKNOWN"]              = "Desconhecido"
L["ENABLED"]              = "Ativado"
L["DISABLED"]             = "Desativado"

-- Timer
L["TIMER_TITLE"]          = "Temporizador"
L["TIMER_PLUS_TWO"]       = "+2"
L["TIMER_PLUS_THREE"]     = "+3"
L["TIMER_OVERTIME"]       = "TEMPO EXTRA"
L["TIMER_COMPLETED"]      = "Concluído!"
L["TIMER_DEPLETED"]       = "Esgotado"
L["BOSS_SPLIT"]           = "Chefe %d: %s"

-- Death Tracker
L["DEATHS"]               = "Mortes"
L["DEATH_LOG"]            = "Registro de mortes"
L["DEATH_PENALTY"]        = "Tempo perdido"
L["DEATH_ENTRY"]          = "%s morreu em %s"
L["NO_DEATHS"]            = "Sem mortes"

-- Enemy Forces
L["ENEMY_FORCES"]         = "Forças inimigas"
L["FORCES_PROGRESS"]      = "%s / %s (%.1f%%)"
L["FORCES_COMPLETE"]      = "Forças inimigas completas!"
L["CURRENT_PULL"]         = "Grupo atual"

-- Affixes
L["AFFIXES"]              = "Afixos"

-- Keystone
L["KEYSTONE"]             = "Pedra Mítica"
L["YOUR_KEY"]             = "Sua pedra"
L["NO_KEY"]               = "Sem pedra"
L["PARTY_KEYS"]           = "Pedras do grupo"
L["KEY_FORMAT"]           = "%s +%d"

-- Party Cooldowns
L["PARTY_CDS"]            = "Recarga do grupo"
L["CD_READY"]             = "Pronto"

-- Dispel Tracker
L["DISPELS"]              = "Dissipar"
L["DISPEL_READY"]         = "PRONTO"

-- Combat Res
L["BREZ"]                 = "Ressurreição de combate"
L["BREZ_READY"]           = "%d/%d pronto"
L["BREZ_NEXT"]            = "próximo em %s"
L["BREZ_NONE"]            = "Sem ressurreição de combate no grupo"

-- Dungeon History
L["HISTORY"]              = "Histórico de masmorras"
L["HISTORY_EMPTY"]        = "Nenhuma corrida registrada ainda."
L["HISTORY_TIMED"]        = "No tempo"
L["HISTORY_DEPLETED"]     = "Esgotada"

-- Config
L["CONFIG_TITLE"]         = "Configurações do MythicPulse"
L["CONFIG_GENERAL"]       = "Geral"
L["CONFIG_MODULES"]       = "Módulos"
L["CONFIG_SCALE"]         = "Escala da interface"
L["CONFIG_OPACITY"]       = "Opacidade"
L["CONFIG_LOCK"]          = "Travar molduras"
L["CONFIG_RESET_POS"]     = "Redefinir posições"
L["CONFIG_RESET_ALL"]     = "Redefinir todas as configurações"

-- Interrupt Tracker
L["INTERRUPTS"]           = "Interrupções"

-- Dungeon Utility
L["UTILITY_TITLE"]        = "Utilidades da masmorra"
L["UTILITY_NO_ABILITIES"] = "Nenhuma habilidade de utilidade para esta masmorra"
L["UTILITY_SELECT"]       = "Selecionar masmorra..."
L["UTILITY_KNOWN"]        = "Conhecido"
L["UTILITY_ADD"]          = "Adicionar"
L["UTILITY_REMOVE"]       = "Remover"
L["UTILITY_OPTIONAL"]     = "Opcional"
L["UTILITY_SELF_ONLY"]    = "Habilidade apenas própria"

-- Slash Command Help
L["SLASH_HELP_HEADER"]     = "Comandos do MythicPulse:"
L["SLASH_HELP_DISPLAY"]    = "  /mp display  \226\128\148 Mostrar todos os frames com dados de exemplo (para posicionamento)"
L["SLASH_HELP_CONFIG"]     = "  /mp config   \226\128\148 Abrir configurações"
L["SLASH_HELP_LOCK"]       = "  /mp lock     \226\128\148 Travar/destravar frames"
L["SLASH_HELP_RESET"]      = "  /mp reset    \226\128\148 Redefinir posições dos frames"
L["SLASH_HELP_KEYS"]       = "  /mp keys     \226\128\148 Anunciar todas as pedras do grupo"
L["SLASH_HELP_UTILITY"]    = "  /mp utility  \226\128\148 Alternar utilitários da masmorra"
L["SLASH_HELP_FOOTNOTE"]   = "Os frames aparecem apenas dentro de uma Pedra Mítica ativa. Use /mp display para posicioná-los em qualquer lugar."
L["SLASH_FRAMES_LOCKED"]   = "Frames travados."
L["SLASH_FRAMES_UNLOCKED"] = "Frames destravados."
L["SLASH_RESET_DONE"]      = "Posições dos frames redefinidas."
L["SLASH_KEYSTONE_UNAVAIL"]= "Rastreador de Pedra Mítica indisponível."
L["SLASH_DEBUG_ON"]        = "Modo de depuração ativado."
L["SLASH_DEBUG_OFF"]       = "Modo de depuração desativado."
L["SLASH_DISPLAY_UNAVAIL"] = "Pré-visualização indisponível."
L["SLASH_INT_UNAVAIL"]     = "Rastreador de interrupção indisponível."
L["SLASH_VERSION_LABEL"]   = "Versão: "
L["SLASH_UNKNOWN_CMD"]     = "Comando desconhecido '%s'. Digite /mp help para ver a lista."

-- Addon Compartment Tooltip
L["COMPARTMENT_KEY_FORMAT"]  = "Pedra: %s +%d"
L["COMPARTMENT_LEFT_CLICK"]  = "|cffffffffClique esquerdo:|r Alternar exibição"
L["COMPARTMENT_RIGHT_CLICK"] = "|cffffffffClique direito:|r Abrir configurações"

-- Timer (missing keys)
L["TIMER_PB_FORMAT"]       = "MP |cffffffff%s|r  (+%d)"
L["TIMER_NO_PB"]           = "|cff666666Sem MP ainda|r"
L["TIMER_ZERO_DEATHS"]     = "0 Mortes"
L["TIMER_DEATH_SINGULAR"]  = "Morte"
L["TIMER_DEATH_PLURAL"]    = "Mortes"
L["TIMER_BOSS_FALLBACK"]   = "Chefe %d"
L["TIMER_TOOLTIP_KILLED"]  = "Morto em:"
L["TIMER_TOOLTIP_PREV"]    = "Desde o chefe anterior:"
L["TIMER_TOOLTIP_START"]   = "Desde o início:"
L["TIMER_TOOLTIP_VS_PB"]   = "vs Melhor pessoal:"

-- Enemy Forces (missing keys)
L["EF_COMPLETE"]           = "Completo!"

-- Keystone (missing keys)
L["KEY_NOT_IN_GROUP"]      = "Você não está em um grupo."

-- Party Cooldowns (missing keys)
L["PC_DEMO_NEEDS_PARTY"]   = "|cff88ccffDemo:|r Os ícones de recarga só aparecem onde existe um frame de grupo/raid. Entre em um grupo ou ative os frames de grupo no estilo raid para ver todos os 5 slots de demonstração."

-- Interrupt Tracker (missing keys)
L["INT_READY"]             = "PRONTO"
L["INT_TOOLTIP_ON_CD"]     = "Em recarga: %.0fs"
L["INT_TOOLTIP_CLICK"]     = "Clique esquerdo para anunciar o estado"
L["INT_NO_INTERRUPTERS"]   = "Sem interruptores no grupo."
L["INT_ROTATION_HEADER"]   = "Rotação de interrupção:"
L["INT_FALLBACK_NAME"]     = "Interrupção"
L["INT_CD_ANNOUNCE"]       = "[MythicPulse] %s's %s em recarga (%.0fs)"
L["INT_READY_ANNOUNCE"]    = "[MythicPulse] %s's %s está PRONTO"
L["INT_ROTATION_ANNOUNCE"] = "[MythicPulse] Interrupções: %s"

-- Combat Res (missing keys)
L["CR_READY"]              = "Pronto"
L["CR_ON_CD"]              = "Em recarga"
L["CR_AVAILABLE"]          = "Disponível"
L["CR_NO_BREZ"]            = "Sem ressurreição"
L["CR_BREZ_READY_FORMAT"]  = "Pronto %d/%d"
L["CR_BL_SATED"]           = "Saciado"
L["CR_BL_NO_SOURCE"]       = "Sem fonte"

-- Dungeon History (missing keys)
L["HIST_HEADER"]           = "=== Histórico de Corridas ==="
L["HIST_TOTAL_RUNS"]       = "Total de Corridas: |cffffffff%d|r"
L["HIST_TIMED_RUNS"]       = "No tempo: |cff4dff4d%d|r (%.0f%%)"
L["HIST_DEPLETED_RUNS"]    = "Esgotadas: |cffff4444%d|r"
L["HIST_HIGHEST_KEYS"]     = "--- Pedras Mais Altas No Tempo ---"
L["HIST_MAP_FALLBACK"]     = "Mapa %d"
L["HIST_RECENT_RUNS"]      = "--- Corridas Recentes ---"
L["HIST_TIMED"]            = "No tempo"
L["HIST_DEPLETED"]         = "Esgotada"
L["HIST_NO_VALID_RUNS"]    = "Nenhuma corrida válida registrada ainda."

-- Run Summary
L["RS_TIER_PLUS3"]         = "+3 BAÚ"
L["RS_TIER_PLUS2"]         = "+2 BAÚ"
L["RS_TIER_PLUS1"]         = "+1 NO TEMPO"
L["RS_TIER_DEPLETED"]      = "ESGOTADO"
L["RS_TITLE"]              = "RESUMO DA CORRIDA"
L["RS_CARD_TIME_PERF"]     = "DESEMPENHO DE TEMPO"
L["RS_COL_ELAPSED"]        = "DECORRIDO"
L["RS_COL_VS_TIMER"]       = "vs TIMER +2"
L["RS_COL_VS_PB"]          = "vs MP"
L["RS_CARD_DEATHS"]        = "MORTES  |  BAIXAS"
L["RS_COL_TIME_LOST"]      = "TEMPO PERDIDO"
L["RS_HINT_AVOIDABLE"]     = "Minimize\nEvitável!"
L["RS_CARD_BOSS_SPLITS"]   = "TEMPOS DOS CHEFES"
L["RS_CARD_SCORE"]         = "PONTUAÇÃO  |  RESUMO DE RATING"
L["RS_COL_RUN_SCORE"]      = "PONTUAÇÃO DA CORRIDA"
L["RS_COL_PREV_BEST"]      = "MELHOR ANTERIOR"
L["RS_COL_EST_GAIN"]       = "GANHO ESTIMADO"
L["RS_BTN_CLOSE"]          = "Fechar"
L["RS_BTN_COPY_CHAT"]      = "Copiar para o Chat"
L["RS_BTN_OPEN_HISTORY"]   = "Abrir Histórico"
L["RS_FIRST_RUN"]          = "1ª corrida!"
L["RS_PILL_TIMED"]         = "|cff4dff4dNO TEMPO  -%s|r"
L["RS_PILL_DEPLETED"]      = "|cffff4040ESGOTADO  +%s|r"
L["RS_TIMED"]              = "NO TEMPO"
L["RS_DEPLETED"]           = "ESGOTADO"

-- Frame Headers
L["MAIN_ADDON_HEADER"]     = "MythicPulse"
L["COMBATRES_HDR"]         = "Combate"

-- Config Panel — Tabs
L["CONFIG_TAB_GENERAL"]    = "Geral"
L["CONFIG_TAB_DISPLAY"]    = "Exibição"
L["CONFIG_TAB_PARTY_CDS"]  = "Recargas do Grupo"
L["CONFIG_TAB_COMBAT"]     = "Combate"
L["CONFIG_TAB_UTILITY"]    = "Utilidades"
L["CONFIG_TAB_MODULES"]    = "Módulos"

-- Config Panel — General Tab
L["CONFIG_HDR_BEHAVIOR"]   = "Comportamento"
L["CONFIG_LOCK_FRAME_POS"] = "Travar Posição dos Frames"
L["CONFIG_HDR_ACTIONS"]    = "Ações"
L["CONFIG_RESET_HUD_POS"]  = "Redefinir Posição do HUD"
L["CONFIG_HUD_POS_RESET"]  = "Posição do frame principal redefinida."
L["CONFIG_RELOAD_UI"]      = "Recarregar Interface"
L["CONFIG_HDR_PREVIEW"]    = "Pré-visualização"
L["CONFIG_PREVIEW_DESC"]   = "Carrega dados de exemplo para que você possa posicionar e redimensionar os frames sem estar em uma Pedra Mítica."
L["CONFIG_TOGGLE_PREVIEW"] = "Alternar Pré-visualização"
L["CONFIG_HDR_ABOUT"]      = "Sobre"
L["CONFIG_ABOUT_VERSION"]  = "MythicPulse v%s"
L["CONFIG_ABOUT_HELP"]     = "/mp help  \226\128\148  listar todos os comandos de barra"
L["CONFIG_ABOUT_CONFIG"]   = "/mp config  \226\128\148  alternar este painel"

-- Config Panel — Display Tab
L["CONFIG_HDR_MAIN_HUD"]   = "HUD Principal"
L["CONFIG_HDR_INT_FRAME"]  = "Frame de Interrupção"
L["CONFIG_HDR_FONT_ICON"]  = "Tamanhos de Fonte e Ícone"
L["CONFIG_FONT_SCALE"]     = "Escala da Fonte"
L["CONFIG_PC_ICON_SIZE"]   = "Tamanho do Ícone de Recarga do Grupo"
L["CONFIG_BRES_ICON_SIZE"] = "Tamanho do Ícone de Res de Combate / BL"
L["CONFIG_ICON_RELOAD"]    = "Recarregue a interface (/reload) para aplicar as alterações de tamanho de ícone."

-- Config Panel — Party CDs Tab
L["CONFIG_HDR_LAYOUT"]     = "Layout"
L["CONFIG_ICON_GAP"]       = "Espaço entre Ícones"
L["CONFIG_MAX_ICONS"]      = "Máximo de Ícones"
L["CONFIG_ICONS_PER_ROW"]  = "Ícones por Linha"
L["CONFIG_SHOW_DISPEL_BAR"]= "Mostrar Barra de Dissipar"
L["CONFIG_HDR_ANCHORING"]  = "Ancoragem"
L["CONFIG_GROWTH_DIR"]     = "Direção de Crescimento"
L["CONFIG_ROW_ANCHOR"]     = "Ponto de Ancoragem da Linha"
L["CONFIG_UF_ANCHOR"]      = "Âncora do Frame de Unidade"
L["CONFIG_OFFSET_X"]       = "Deslocamento X"
L["CONFIG_OFFSET_Y"]       = "Deslocamento Y"

-- Config Panel — Combat Tab
L["CONFIG_HDR_INTERRUPTS"] = "Interrupções"
L["CONFIG_AUTO_KICKS"]     = "Anunciar Automaticamente a Rotação de Interrupção"
L["CONFIG_INT_COMBAT_ONLY"]= "Mostrar Rastreador de Interrupção Apenas em Combate"
L["CONFIG_HDR_BL_BREZ"]    = "Bloodlust / Ressurreição de Combate"
L["CONFIG_BREZ_NOTE"]      = "Detecta automaticamente: Xamã, Mago e Caçador (com pet ativo)."
L["CONFIG_MORE_SOON"]      = "Mais opções em breve."

-- Config Panel — Utility Tab
L["CONFIG_HDR_UTILITY"]    = "Painel de Utilidades da Masmorra"
L["CONFIG_UTIL_AUTO_SHOW"] = "Mostrar Automaticamente ao Entrar em uma Masmorra"
L["CONFIG_UTIL_SHOW_REM"]  = "Mostrar Botões de Remoção de Habilidade"
L["CONFIG_UTIL_HIDE_OPT"]  = "Ocultar Entradas Não Importantes"
L["CONFIG_HDR_HISTORY"]    = "Histórico de Corridas"
L["CONFIG_MAX_HISTORY"]    = "Máximo de Entradas no Histórico"
L["CONFIG_HISTORY_PRUNE"]  = "Entradas mais antigas são removidas quando o limite é atingido."

-- Config Panel — Modules Tab
L["CONFIG_HDR_MODULES"]    = "Ativar / Desativar Módulos"
L["CONFIG_MOD_TIMER"]      = "Temporizador de Masmorra"
L["CONFIG_MOD_DEATHS"]     = "Rastreador de Mortes"
L["CONFIG_MOD_FORCES"]     = "Forças Inimigas"
L["CONFIG_MOD_KEYSTONE"]   = "Rastreador de Pedra Mítica"
L["CONFIG_MOD_PARTY_CDS"]  = "Recargas do Grupo"
L["CONFIG_MOD_INTERRUPT"]  = "Rastreador de Interrupção"
L["CONFIG_MOD_DISPEL"]     = "Rastreador de Dissipar"
L["CONFIG_MOD_TRINKET"]    = "Rastreador de Acessório"
L["CONFIG_MOD_GOSSIP"]     = "Diálogo Automático"
L["CONFIG_MOD_BREZ"]       = "Rastreador de Ressurreição de Combate"
L["CONFIG_MOD_HISTORY"]    = "Histórico de Masmorras"
L["CONFIG_MOD_AUTO_SLOT"]  = "Encaixe Automático de Pedra Mítica"
L["CONFIG_MOD_TELEPORTS"]  = "Teleportes de Masmorra"
L["CONFIG_MOD_UTILITY"]    = "Utilidades de Masmorra"
L["POPUP_RESET_CONFIRM"]   = "Redefinir todas as configurações do MythicPulse para os padrões?"

-- Dungeon Utility (missing keys)
L["UTILITY_SELF_PREFIX"]   = "(Próprio)"
L["UTILITY_UNKNOWN"]       = "Masmorra Desconhecida"
L["UTIL_DISABLED_MSG"]     = "Utilidades da Masmorra estão desativadas. Ative em /mp config \226\134\146 Módulos."

-- Dungeon Teleport
L["TP_CLICK_TO_TELEPORT"]  = "Clique para Teleportar"

-- Demo Mode
L["DEMO_ALREADY_ACTIVE"]   = "Pré-visualização já ativa. /mp display para parar."
L["DEMO_LOADING"]          = "Demo: HUD ainda carregando, tentando novamente em 2s..."
L["DEMO_ON"]               = "|cff4dff4dPré-visualização ATIVA|r \226\128\148 arraste os frames para reposicioná-los. /mp display para parar."
L["DEMO_OFF"]              = "|cffaaaaaaaPré-visualização DESATIVADA|r"

-- Auto Slot
L["AUTOSLOT_DONE"]         = "|cff4dff4dPedra Mítica encaixada automaticamente!|r"
