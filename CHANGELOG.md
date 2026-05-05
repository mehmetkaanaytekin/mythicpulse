# MythicPulse Changelog

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
