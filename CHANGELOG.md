# MythicPulse Changelog

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
