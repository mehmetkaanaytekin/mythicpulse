# MythicPulse Changelog

## 1.4.1 — 2026-08-14

### Fix

- Corrected the 12.1 `## Interface` number — 1.4.0 shipped with `121000`,
  which doesn't match any real client build and made the addon show as
  "out of date" in-game. The correct value for patch 12.1.0 is `120100`
  (confirmed against live `GetBuildInfo()` output: `12.1.0.69273`).

## 1.4.0 — 2026-08-14

### Season 2 Data

- Filled in the real Midnight Season 2 dungeon pool: Altar of Fangs, Murder Row,
  Den of Nalorakk, The Blinding Vale, Voidscar Arena (new Midnight dungeons) plus
  King's Rest, Temple of Sethraliss, Ruby Life Pools (returning legacy dungeons).
  ChallengeMapID/instanceID/timeLimit sourced from the live MapChallengeMode DB2
  and cross-checked against known-good Season 1 rows.
- `Data/Dungeons.lua` no longer gates on a "current season" — every season's
  table is merged into one lookup, so a future season only needs its data added,
  no code change.
- Added teleport buttons for all 8 Season 2 dungeons (best-effort spellIDs where
  the game data had duplicate-named spells from a dungeon's earlier season — see
  `Docs/SEASON_UPDATE.md` for the disambiguation note and how to fix one if wrong).
- Still open for Season 2, tracked in `Docs/SEASON_UPDATE.md`: Dungeon Utility
  mechanic content (CC/stops/skips) and auto-gossip NPC entries — both need
  someone standing in the dungeon, not just data lookups. Everything else
  (timer, affixes, score prediction, run summary) already works on any dungeon
  via the live API regardless.

## 1.3.0 — 2026-06-28

### Season 2 Readiness

- **Works on any dungeon rotation with no code change.** Core features (timer, dungeon name, time limit, affix row, enemy forces, boss splits, run summary, score prediction) already resolve from live Blizzard `C_ChallengeMode`/`C_MythicPlus` APIs. Consolidated the table→API fallback into a single `MP.DungeonData:GetInfo()` resolver so unknown (new-season) dungeons get the live name/time limit instead of blank/zero, and `GetShortName`/`GetTimeLimit` now fall back to the API too.
- Restructured `Data/Dungeons.lua` into a season-keyed pool (`MP.DungeonData.Seasons` + `CURRENT_SEASON`) with a clearly-marked Season 2 stub — switching seasons is a one-line change plus a data fill.
- Added commented Season 2 data stubs to `DungeonTeleport`, `UtilityDungeons`, and `AutoGossip`, and `GetDefaultDungeonID()` so the Dungeon Utility panel never shows a stale default after a rotation.
- New `Docs/SEASON_UPDATE.md` — a maintainer checklist for populating a new season (which files, which ID space, how to capture IDs in-game).

### Maintenance

- Centralized the Bloodlust / Sated / battle-res spell tables into `Data/LustData.lua` — they were duplicated in `PartyCooldowns` and `CombatRes` and had to be hand-synced. Single source of truth now.
- Removed the lingering "More options coming soon" placeholder note from the config panel (and all locales).
- Excluded `ruvector.db`, `.claude`, and `Docs` from the packaged CurseForge zip via `.pkgmeta`.

## 1.2.3 — 2026-05-xx

### Features

**Full Localization**
- Added a crash-safe `MP:Loc()` helper that falls back to the key name on a missing translation.
- Externalized hardcoded UI strings across Core, InterruptTracker, Timer, ConfigPanel, RunSummary, and the UI modules.
- Added 5 new locales: French (frFR), German (deDE), Spanish (esES), Italian (itIT), Brazilian Portuguese (ptBR), alongside the existing Russian (ruRU).

### Bug Fixes

- **Interrupt rotation:** healer specs (Disc/Holy Priest, Holy Paladin, Mistweaver Monk, Preservation Evoker, Resto Druid) are now excluded from the kick rotation per patch 12.0.5; Resto Shaman (Wind Shear) is retained.
- **Bloodlust/Sated:** lust icons now correctly show on cooldown while any party member carries a Sated-family debuff — covering the case where the lust caster is not running MythicPulse (no Comm message arrives).

## 1.2.2 — 2026-05-06

### Features

**M+-Only Activation**
- All HUD frames (Timer, Party CDs, Interrupt, Combat/BRes) now only appear inside an active Mythic+ key. They no longer show in heroic dungeons or raids.
- Use `/mp display` (or the "Toggle Preview" button in settings) anywhere to show all frames with mock data for placement.
- `ShouldShowHUD()` helper added to Core.lua as the single source of truth — inherits Demo's `IsInMythicPlus` override automatically.

### Bug Fixes

**Module Enable/Disable**
- Fixed: Dungeon History checkbox now prevents run recording when disabled (was silently recording regardless).
- Fixed: Dungeon Utility checkbox now immediately hides the utility panel when disabled; `/mp utility` and auto-show on dungeon enter are suppressed.
- Fixed: Dispel Tracker checkbox now instantly clears dispel bars from all party rows when disabled; re-enabling refreshes them immediately.
- Fixed: "Show Interrupt Tracker in Combat Only" checkbox now correctly toggles the Interrupt frame visibility (was calling a non-existent method).
- Fixed: `/mp lock` and `/mp reset` now also apply to the Combat/BRes frame (was previously missed).

**Trinket Tracker**
- Fixed: Pressing an on-use trinket now actually starts the cooldown sweep on its icon in the Party Cooldowns row. The sweep was being recorded internally but never displayed.
- Fixed: Equipping a different trinket now rebuilds the Party Cooldowns row so the correct icon appears within ~0.5s.
- Fixed: Trinket cooldowns are now restored after a row rebuild (e.g. spec change or group roster update) — the icon picks up mid-flight cooldowns.
- Fixed: `SPELLS_CHANGED` and `PLAYER_SPECIALIZATION_CHANGED` now trigger a rescan so trinkets whose spell duration returned 0 on equip are caught when the game catches up.

**Dispel Tracker**
- Fixed: The dispel-ready colored bar now also appears on the local player's own Party Cooldowns row when they have a self-dispellable debuff (Magic/Curse/Poison/Disease for applicable classes). Previously this was always suppressed.
- Added missing `DISPEL_COLORS` entries for `offMagic`, `mass`, and `immunity` dispel types (shown as grey/gold) so offensive-dispel classes (Mage, Hunter, Rogue, Warrior) get a visual indicator.

---

## 1.2.1 — 2026-05-05

### Bug Fixes

**Module Enable/Disable (Config Panel)**
- Fixed: disabling a module and re-enabling it now takes effect immediately — no `/reload` required
- Dungeon Timer now reappears when re-enabled inside a key
- Battle Res Tracker now reappears with correct BL/brez state when re-enabled
- Trinket Tracker toggle now actually removes the trinket from the Party CDs row and the BRes trinket icon when disabled; re-enabling repopulates it from your equipped trinkets
- Death Tracker now resumes polling on re-enable without needing a reload
- Enemy Forces bar now reappears correctly on re-enable
- Dispel Tracker, Keystone Tracker, and Interrupt Tracker re-enable reliably (fixes from 1.2.0 are now all consistent)
- Removed the stale "Changes take effect after /reload" note from the config panel — toggles are live

**Party Cooldowns**
- Fixed a duplicate-handler bug where toggling Party CDs off/on multiple times would cause remote cooldown broadcasts to fire 2×, 3×, etc. per cycle
- Comm handler registration is now idempotent — re-enabling any module no longer stacks duplicate listeners

**Interrupt Tracker**
- Fixed Shadow Priest Silence showing 50s instead of the correct 30s (spec override now applied)
- Added Balance Druid Solar Beam to tracked kicks (60s, spec-specific to Balance spec)

**Config Panel**
- Auto Gossip no longer shows "(coming soon)" — it is live for all current Midnight Season 1 dungeons

---

## 1.2.0 — 2026-05-04

- Fixed 6 reported issues from CurseForge launch
- Set correct CurseForge project ID in TOC

## 1.1.0

- Added CurseForge auto-packaging via BigWigsMods/packager
