# MythicPulse

**Your Mythic+ run, at a glance — no clutter, no clicking through five different addons.**

MythicPulse replaces Blizzard's default M+ UI with a single, clean, spec-aware HUD built for Midnight. Everything you actually look at during a key — timer, cooldowns, kicks, dispels, trinkets — in one lightweight addon that gets out of your way outside of keys.

**✅ Season 2 ready (Patch 12.1)** — dungeon data for the full 8-dungeon rotation is already in, including teleport buttons for every new and returning dungeon.

---

## Why MythicPulse

- **See what matters, when it matters.** Every HUD frame only shows inside an active key — no clutter in heroics, no clutter in raid.
- **Built for the group, not just you.** Party cooldowns, dispels, and kicks are tracked for the whole team, not just your own bars.
- **Zero setup.** Sensible defaults out of the box; `/mp config` if you want to tune it.

## Features

**⏱ Dungeon Timer** — live pace bar with +2/+3 thresholds, color-coded so you always know if you're ahead or behind, boss splits compared against your own personal best per dungeon and key level, plus an affix display with key level indicator.

**🛡 Party Cooldowns** — spec-aware icons anchored right onto your party frames (Blizzard or ElvUI). Defensives, externals, raid CDs, and utility spells for the whole group; active-buff highlight, dispel-ready indicator per player, fully configurable icon layout.

**⚔ Interrupt Tracker** — who's up, who's on cooldown, and last spell kicked, per player. `/mp rotation` auto-assigns and announces a kick order so nobody double-kicks a pack. Optional combat-only visibility.

**💥 Enemy Forces, Bloodlust & Battle Res** — real-time trash progress with a pace marker; lust tracked (Shaman/Mage/Hunter) even if the caster isn't running the addon, via the Sated debuff; brez charges and readiness for the whole group at a glance.

**🎒 Trinket Tracker** — your equipped on-use trinket with a Ready label or remaining cooldown, updates automatically when you swap gear.

**📖 Dungeon Utility Panel** — a live in-run reference for what to CC, what to stop, what to skip, for your class, spec, and race. Auto-shows on entering a dungeon.

**📊 Run History & Score Prediction** — every completed run saved locally (no external service), with a live estimated score and PB delta the moment you finish.

**🗝 Quality of Life** — auto-slots your keystone when you open the pedestal, tracks the whole party's keys (`/mp keys`), a death-penalty counter, and one-click dungeon teleports on the Challenges UI. All Blizzard scenario/objective frames hidden during M+ for a clean UI.

**🎮 Demo Mode** — `/mp display` previews the entire HUD with mock data, anywhere, no key required — set up your layout before you queue.

---

## Installation

**CurseForge / Wago App (recommended)**
Install and keep up to date automatically through the CurseForge or Wago Addons app.

**Manual**
1. Download the latest release zip from CurseForge
2. Extract the `MythicPulse` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Type `/reload` in-game

---

## Slash Commands

All commands work with `/mp` or `/mythicpulse`.

| Command | Action |
|---|---|
| `/mp` or `/mp help` | List all available commands |
| `/mp config` | Open the settings panel |
| `/mp lock` | Lock or unlock all frames |
| `/mp reset` | Reset all frame positions to default |
| `/mp display` | Toggle demo mode |
| `/mp keys` | Announce all party keystones in chat |
| `/mp utility` | Toggle the dungeon utility panel |
| `/mp rotation` | Announce the kick rotation to the group |

---

## Compatibility

- **WoW Version:** Midnight 12.0.x – 12.1.x (Interface 120005, 120100)
- **Midnight compliant** — no restricted events, no protected API calls, no automation
- **Unit frames** — works with default Blizzard party frames and ElvUI
- **Other addons** — does not conflict with WeakAuras, Details!, or MDT

---

## Configuration

Open the settings panel with `/mp config`.

| Section | Controls |
|---|---|
| **General** | Frame lock, position reset, reload UI |
| **Display** | Scale and opacity per frame, font size, icon sizes |
| **Party CDs** | Icon layout, growth direction, anchor point, offset, dispel bar |
| **Combat** | Interrupt tracker visibility options |
| **Utility** | Dungeon utility panel options, run history entry limit |
| **Modules** | Enable or disable any individual module |

---

## FAQ

**Does it work with ElvUI?**
Yes. The Party Cooldowns module detects ElvUI party frames and anchors icons to them automatically.

**Can I turn off features I don't use?**
Yes — every feature is an independent module with its own enable/disable toggle in `/mp config` → Modules.

**Will it conflict with WeakAuras or Details!?**
No. MythicPulse only reads game state and renders its own frames. It does not modify any shared or protected Blizzard frames.

**Is it built for Midnight?**
Yes, built from the ground up for Midnight 12.0.x. It avoids `COMBAT_LOG_EVENT_UNFILTERED` and all other APIs restricted in Midnight.

---

## Feedback & Bug Reports

Report issues on the [GitHub repository](https://github.com/KaanAytekin/MythicPulse) or through the CurseForge issue tracker. Include your WoW version, any error text from BugSack / BugGrabber, and steps to reproduce.

---

*Font: Expressway (bundled). Built for the Mythic+ community.*
