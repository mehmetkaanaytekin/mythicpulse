--[[
    MythicPulse - Russian Localization (ruRU)
]]

local _, MP = ...

if GetLocale() ~= "ruRU" then return end

local L = MP.L

-- General
L["ADDON_LOADED"]         = "MythicPulse загружен. Напишите в чат /mp help для отображения команд."
L["UNKNOWN"]              = "Неизвестно"
L["ENABLED"]              = "Вкл."
L["DISABLED"]             = "Выкл."

-- Timer
L["TIMER_TITLE"]          = "Таймер"
L["TIMER_PLUS_TWO"]       = "+2"
L["TIMER_PLUS_THREE"]     = "+3"
L["TIMER_OVERTIME"]       = "Время вышло"
L["TIMER_COMPLETED"]      = "Завершено!"
L["TIMER_DEPLETED"]       = "Неудача"
L["BOSS_SPLIT"]           = "Босс %d: %s"

-- Death Tracker
L["DEATHS"]               = "Смерти"
L["DEATH_LOG"]            = "Журнал смертей"
L["DEATH_PENALTY"]        = "Потеряно времени"
L["DEATH_ENTRY"]          = "%s умер в %s"
L["NO_DEATHS"]            = "Нет смертей"

-- Enemy Forces
L["ENEMY_FORCES"]         = "Силы противников"
L["FORCES_PROGRESS"]      = "%s / %s (%.1f%%)"
L["FORCES_COMPLETE"]      = "Силы противников завершены!"
L["CURRENT_PULL"]         = "Текущий пулл"

-- Affixes
L["AFFIXES"]              = "Аффиксы"

-- Keystone
L["KEYSTONE"]             = "Ключ"
L["YOUR_KEY"]             = "Ваш ключ"
L["NO_KEY"]               = "Нет ключа"
L["PARTY_KEYS"]           = "Ключи группы"
L["KEY_FORMAT"]           = "%s +%d"

-- Party Cooldowns
L["PARTY_CDS"]            = "Перезарядки группы"
L["CD_READY"]             = "Готов"

-- Dispel Tracker
L["DISPELS"]              = "Рассеивания"
L["DISPEL_READY"]         = "ГОТОВ"

-- Combat Res
L["BREZ"]                 = "Воскрешение в бою"
L["BREZ_READY"]           = "%d/%d готов"
L["BREZ_NEXT"]            = "следующий через %s"
L["BREZ_NONE"]            = "Нет воскрешений в Вашей группе"

-- Dungeon History
L["HISTORY"]              = "История прохождений"
L["HISTORY_EMPTY"]        = "Прохождений пока не зафиксировано."
L["HISTORY_TIMED"]        = "Пройдено вовремя"
L["HISTORY_DEPLETED"]     = "Неудача"

-- Config
L["CONFIG_TITLE"]         = "Настройки MythicPulse"
L["CONFIG_GENERAL"]       = "Общее"
L["CONFIG_MODULES"]       = "Модули"
L["CONFIG_SCALE"]         = "Масштаб интерфейса"
L["CONFIG_OPACITY"]       = "Прозрачность"
L["CONFIG_LOCK"]          = "Блокировка фреймов"
L["CONFIG_RESET_POS"]     = "Сбросить положение"
L["CONFIG_RESET_ALL"]     = "Сбросить все настройки"

-- Interrupt Tracker
L["INTERRUPTS"]           = "Прерывания"

-- Dungeon Utility
L["UTILITY_TITLE"]        = "Полезные функции подземелья"
L["UTILITY_NO_ABILITIES"] = "Нет полезных функций для этого подземелья"
L["UTILITY_SELECT"]       = "Выбрать подземелье..."
L["UTILITY_KNOWN"]        = "Известно"
L["UTILITY_ADD"]          = "Добавить"
L["UTILITY_REMOVE"]       = "Удалить"
L["UTILITY_OPTIONAL"]     = "Необязательно"
L["UTILITY_SELF_ONLY"]    = "Способность, доступная только самому себе"

-- Slash Command Help
L["SLASH_HELP_HEADER"]     = "Команды MythicPulse:"
L["SLASH_HELP_DISPLAY"]    = "  /mp display  \226\128\148 Показать все фреймы с тестовыми данными (для позиционирования)"
L["SLASH_HELP_CONFIG"]     = "  /mp config   \226\128\148 Открыть настройки"
L["SLASH_HELP_LOCK"]       = "  /mp lock     \226\128\148 Заблокировать/разблокировать фреймы"
L["SLASH_HELP_RESET"]      = "  /mp reset    \226\128\148 Сбросить положение фреймов"
L["SLASH_HELP_KEYS"]       = "  /mp keys     \226\128\148 Объявить все ключи группы"
L["SLASH_HELP_UTILITY"]    = "  /mp utility  \226\128\148 Переключить утилиты подземелья"
L["SLASH_HELP_FOOTNOTE"]   = "Фреймы отображаются только внутри активного Мифического ключа. Используйте /mp display для позиционирования в любом месте."
L["SLASH_FRAMES_LOCKED"]   = "Фреймы заблокированы."
L["SLASH_FRAMES_UNLOCKED"] = "Фреймы разблокированы."
L["SLASH_RESET_DONE"]      = "Положение фреймов сброшено."
L["SLASH_KEYSTONE_UNAVAIL"]= "Трекер ключа недоступен."
L["SLASH_DEBUG_ON"]        = "Режим отладки включён."
L["SLASH_DEBUG_OFF"]       = "Режим отладки выключен."
L["SLASH_DISPLAY_UNAVAIL"] = "Предпросмотр недоступен."
L["SLASH_INT_UNAVAIL"]     = "Трекер прерываний недоступен."
L["SLASH_VERSION_LABEL"]   = "Версия: "
L["SLASH_UNKNOWN_CMD"]     = "Неизвестная команда '%s'. Введите /mp help для списка."

-- Addon Compartment Tooltip
L["COMPARTMENT_KEY_FORMAT"]  = "Ключ: %s +%d"
L["COMPARTMENT_LEFT_CLICK"]  = "|cffffffffЛКМ:|r Переключить отображение"
L["COMPARTMENT_RIGHT_CLICK"] = "|cffffffffПКМ:|r Открыть настройки"

-- Timer (missing keys)
L["TIMER_PB_FORMAT"]       = "ЛР |cffffffff%s|r  (+%d)"
L["TIMER_WK_PB_FORMAT"]    = "Нед |cffffffff%s|r"
L["TIMER_NO_PB"]           = "|cff666666Нет личного рекорда|r"
L["TIMER_ZERO_DEATHS"]     = "0 смертей"
L["TIMER_DEATH_SINGULAR"]  = "Смерть"
L["TIMER_DEATH_PLURAL"]    = "Смертей"
L["TIMER_BOSS_FALLBACK"]   = "Босс %d"
L["TIMER_TOOLTIP_KILLED"]  = "Убит в:"
L["TIMER_TOOLTIP_PREV"]    = "С предыдущего босса:"
L["TIMER_TOOLTIP_START"]   = "С начала:"
L["TIMER_TOOLTIP_VS_PB"]   = "vs Личный рекорд:"

-- Enemy Forces (missing keys)
L["EF_COMPLETE"]           = "Завершено!"

-- Keystone (missing keys)
L["KEY_NOT_IN_GROUP"]      = "Вы не состоите в группе."

-- Party Cooldowns (missing keys)
L["PC_DEMO_NEEDS_PARTY"]   = "|cff88ccffДемо:|r Иконки перезарядок отображаются только там, где есть фрейм группы/рейда. Вступите в группу или включите рейдовые фреймы группы, чтобы увидеть все 5 слотов демонстрации."

-- Interrupt Tracker (missing keys)
L["INT_READY"]             = "ГОТОВ"
L["INT_TOOLTIP_ON_CD"]     = "Перезарядка: %.0fs"
L["INT_TOOLTIP_CLICK"]     = "ЛКМ для объявления статуса"
L["INT_NO_INTERRUPTERS"]   = "Нет прерывателей в группе."
L["INT_ROTATION_HEADER"]   = "Ротация прерываний:"
L["INT_FALLBACK_NAME"]     = "Прерывание"
L["INT_CD_ANNOUNCE"]       = "[MythicPulse] %s's %s на перезарядке (%.0fs)"
L["INT_READY_ANNOUNCE"]    = "[MythicPulse] %s's %s ГОТОВ"
L["INT_ROTATION_ANNOUNCE"] = "[MythicPulse] Прерывания: %s"

-- Combat Res (missing keys)
L["CR_READY"]              = "Готово"
L["CR_ON_CD"]              = "Перезарядка"
L["CR_AVAILABLE"]          = "Доступно"
L["CR_NO_BREZ"]            = "Нет воскрешения"
L["CR_BREZ_READY_FORMAT"]  = "Готово %d/%d"
L["CR_BL_SATED"]           = "Пресыщение"
L["CR_BL_NO_SOURCE"]       = "Нет источника"

-- Dungeon History (missing keys)
L["HIST_HEADER"]           = "=== История прохождений ==="
L["HIST_TOTAL_RUNS"]       = "Всего прохождений: |cffffffff%d|r"
L["HIST_TIMED_RUNS"]       = "В срок: |cff4dff4d%d|r (%.0f%%)"
L["HIST_DEPLETED_RUNS"]    = "Неудача: |cffff4444%d|r"
L["HIST_HIGHEST_KEYS"]     = "--- Наибольшие ключи в срок ---"
L["HIST_MAP_FALLBACK"]     = "Карта %d"
L["HIST_RECENT_RUNS"]      = "--- Последние прохождения ---"
L["HIST_TIMED"]            = "В срок"
L["HIST_DEPLETED"]         = "Неудача"
L["HIST_NO_VALID_RUNS"]    = "Действительных прохождений пока не зафиксировано."

-- Run Summary
L["RS_TIER_PLUS3"]         = "+3 СУНДУК"
L["RS_TIER_PLUS2"]         = "+2 СУНДУК"
L["RS_TIER_PLUS1"]         = "+1 В СРОК"
L["RS_TIER_DEPLETED"]      = "НЕУДАЧА"
L["RS_TITLE"]              = "ИТОГИ ПРОХОЖДЕНИЯ"
L["RS_CARD_TIME_PERF"]     = "РЕЗУЛЬТАТ ПО ВРЕМЕНИ"
L["RS_COL_ELAPSED"]        = "ЗАТРАЧЕНО"
L["RS_COL_VS_TIMER"]       = "vs ТАЙМЕР +2"
L["RS_COL_VS_PB"]          = "vs ЛР"
L["RS_COL_VS_WK_PB"]       = "vs ЛР нед"
L["RS_CARD_DEATHS"]        = "СМЕРТИ  |  ПОТЕРИ"
L["RS_COL_TIME_LOST"]      = "ПОТЕРЯНО ВРЕМЕНИ"
L["RS_HINT_AVOIDABLE"]     = "Минимизируйте\nИзбегаемое!"
L["RS_CARD_BOSS_SPLITS"]   = "ВРЕМЯ НА БОССАХ"
L["RS_CARD_INTERRUPTS"]    = "ПРЕРЫВАНИЯ"
L["RS_CARD_SCORE"]         = "ОЧКИ  |  СВОДКА РЕЙТИНГА"
L["RS_COL_RUN_SCORE"]      = "ОЧКИ ЗА ПРОХОЖДЕНИЕ"
L["RS_COL_PREV_BEST"]      = "ПРЕДЫДУЩИЙ РЕКОРД"
L["RS_COL_EST_GAIN"]       = "ПРИРОСТ (ОЦ.)"
L["RS_BTN_CLOSE"]          = "Закрыть"
L["RS_BTN_COPY_CHAT"]      = "Скопировать в чат"
L["RS_BTN_OPEN_HISTORY"]   = "Открыть историю"
L["RS_FIRST_RUN"]          = "1-й заход!"
L["RS_PILL_TIMED"]         = "|cff4dff4dВ СРОК  -%s|r"
L["RS_PILL_DEPLETED"]      = "|cffff4040НЕУДАЧА  +%s|r"
L["RS_TIMED"]              = "В СРОК"
L["RS_DEPLETED"]           = "НЕУДАЧА"

-- Frame Headers
L["MAIN_ADDON_HEADER"]     = "MythicPulse"
L["COMBATRES_HDR"]         = "Боевое"

-- Config Panel — Tabs
L["CONFIG_TAB_GENERAL"]    = "Общее"
L["CONFIG_TAB_DISPLAY"]    = "Отображение"
L["CONFIG_TAB_PARTY_CDS"]  = "Перезарядки группы"
L["CONFIG_TAB_COMBAT"]     = "Бой"
L["CONFIG_TAB_UTILITY"]    = "Утилиты"
L["CONFIG_TAB_MODULES"]    = "Модули"

-- Config Panel — General Tab
L["CONFIG_HDR_BEHAVIOR"]   = "Поведение"
L["CONFIG_LOCK_FRAME_POS"] = "Заблокировать положение фреймов"
L["CONFIG_HDR_ACTIONS"]    = "Действия"
L["CONFIG_RESET_HUD_POS"]  = "Сбросить положение HUD"
L["CONFIG_HUD_POS_RESET"]  = "Положение главного фрейма сброшено."
L["CONFIG_RELOAD_UI"]      = "Перезагрузить интерфейс"
L["CONFIG_HDR_PREVIEW"]    = "Предпросмотр"
L["CONFIG_PREVIEW_DESC"]   = "Загружает тестовые данные, чтобы можно было позиционировать и изменять размер фреймов без активного ключа."
L["CONFIG_TOGGLE_PREVIEW"] = "Переключить предпросмотр"
L["CONFIG_HDR_ABOUT"]      = "О программе"
L["CONFIG_ABOUT_VERSION"]  = "MythicPulse v%s"
L["CONFIG_ABOUT_HELP"]     = "/mp help  \226\128\148  список всех команд"
L["CONFIG_ABOUT_CONFIG"]   = "/mp config  \226\128\148  открыть/закрыть эту панель"

-- Config Panel — Display Tab
L["CONFIG_HDR_MAIN_HUD"]   = "Основной HUD"
L["CONFIG_HDR_INT_FRAME"]  = "Фрейм прерываний"
L["CONFIG_HDR_FONT_ICON"]  = "Размеры шрифта и иконок"
L["CONFIG_FONT_SCALE"]     = "Масштаб шрифта"
L["CONFIG_PC_ICON_SIZE"]   = "Размер иконки перезарядок группы"
L["CONFIG_BRES_ICON_SIZE"] = "Размер иконки Боевого воскрешения / BL"
L["CONFIG_ICON_RELOAD"]    = "Перезагрузите интерфейс (/reload) для применения изменений размера иконок."

-- Config Panel — Party CDs Tab
L["CONFIG_HDR_LAYOUT"]     = "Расположение"
L["CONFIG_ICON_GAP"]       = "Расстояние между иконками"
L["CONFIG_MAX_ICONS"]      = "Макс. иконок"
L["CONFIG_ICONS_PER_ROW"]  = "Иконок в строке"
L["CONFIG_SHOW_DISPEL_BAR"]= "Показывать полосу рассеивания"
L["CONFIG_HDR_ANCHORING"]  = "Привязка"
L["CONFIG_GROWTH_DIR"]     = "Направление роста"
L["CONFIG_ROW_ANCHOR"]     = "Точка привязки строки"
L["CONFIG_UF_ANCHOR"]      = "Привязка к фрейму персонажа"
L["CONFIG_OFFSET_X"]       = "Смещение X"
L["CONFIG_OFFSET_Y"]       = "Смещение Y"

-- Config Panel — Combat Tab
L["CONFIG_HDR_INTERRUPTS"] = "Прерывания"
L["CONFIG_AUTO_KICKS"]     = "Авто-объявление ротации прерываний"
L["CONFIG_INT_COMBAT_ONLY"]= "Показывать трекер прерываний только в бою"
L["CONFIG_HDR_BL_BREZ"]    = "Боевой клич / Боевое воскрешение"
L["CONFIG_BREZ_NOTE"]      = "Авто-определение: Шаман, Маг и Охотник (с активным питомцем)."
L["CONFIG_MORE_SOON"]      = "Больше настроек скоро."

-- Config Panel — Utility Tab
L["CONFIG_HDR_UTILITY"]    = "Панель утилит подземелья"
L["CONFIG_UTIL_AUTO_SHOW"] = "Авто-показ при входе в подземелье"
L["CONFIG_UTIL_SHOW_REM"]  = "Показывать кнопки удаления способностей"
L["CONFIG_UTIL_HIDE_OPT"]  = "Скрывать неважные записи"
L["CONFIG_HDR_HISTORY"]    = "История прохождений"
L["CONFIG_MAX_HISTORY"]    = "Макс. записей истории"
L["CONFIG_HISTORY_PRUNE"]  = "Старые записи удаляются при достижении лимита."

-- Config Panel — Modules Tab
L["CONFIG_HDR_MODULES"]    = "Включить / Отключить модули"
L["CONFIG_MOD_TIMER"]      = "Таймер подземелья"
L["CONFIG_MOD_DEATHS"]     = "Трекер смертей"
L["CONFIG_MOD_FORCES"]     = "Силы противников"
L["CONFIG_MOD_KEYSTONE"]   = "Трекер ключа"
L["CONFIG_MOD_PARTY_CDS"]  = "Перезарядки группы"
L["CONFIG_MOD_INTERRUPT"]  = "Трекер прерываний"
L["CONFIG_MOD_DISPEL"]     = "Трекер рассеиваний"
L["CONFIG_MOD_TRINKET"]    = "Трекер аксессуаров"
L["CONFIG_MOD_GOSSIP"]     = "Авто-диалог"
L["CONFIG_MOD_BREZ"]       = "Трекер боевого воскрешения"
L["CONFIG_MOD_HISTORY"]    = "История подземелий"
L["CONFIG_MOD_AUTO_SLOT"]  = "Авто-вставка ключа"
L["CONFIG_MOD_TELEPORTS"]  = "Телепорты в подземелье"
L["CONFIG_MOD_UTILITY"]    = "Утилиты подземелья"
L["POPUP_RESET_CONFIRM"]   = "Сбросить все настройки MythicPulse до значений по умолчанию?"

-- Dungeon Utility (missing keys)
L["UTILITY_SELF_PREFIX"]   = "(Себе)"
L["UTILITY_UNKNOWN"]       = "Неизвестное подземелье"
L["UTIL_DISABLED_MSG"]     = "Утилиты подземелья отключены. Включите в /mp config \226\134\146 Модули."

-- Dungeon Teleport
L["TP_CLICK_TO_TELEPORT"]  = "Нажмите для телепортации"

-- Demo Mode
L["DEMO_ALREADY_ACTIVE"]   = "Предпросмотр уже активен. /mp display для остановки."
L["DEMO_LOADING"]          = "Демо: HUD ещё загружается, повтор через 2с..."
L["DEMO_ON"]               = "|cff4dff4dПредпросмотр ВКЛ|r \226\128\148 перетащите фреймы для перемещения. /mp display для остановки."
L["DEMO_OFF"]              = "|cffaaaaaaПредпросмотр ВЫКЛ|r"

-- Auto Slot
L["AUTOSLOT_DONE"]         = "|cff4dff4dКлюч автоматически вставлен!|r"
