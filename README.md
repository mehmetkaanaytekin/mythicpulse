# MythicPulse

**All-in-one Mythic+ companion for World of Warcraft: Midnight (12.x)**

MythicPulse replaces the cluttered default Blizzard M+ UI with a clean, information-dense HUD built specifically for Midnight. Spec-aware cooldown tracking, interrupt rotation, live dungeon timer, enemy forces, Bloodlust and trinket status, death penalties, and a dungeon utility reference — all in one lightweight addon.

---

## Features

### Dungeon Timer
- Live elapsed / time-limit bar with **+2 and +3 threshold markers**
- Color-coded pacing — shifts blue → orange → red as you fall behind
- Boss kill splits with **±personal best** comparison inline
- Personal best stored and displayed per dungeon and key level
- Affix display with key level indicator

### Enemy Forces
- Real-time trash progress bar fed by the Scenario API
- Pace marker showing where you need to be at the current elapsed time
- Bar color shifts green / blue / orange / red based on projected completion

### Party Cooldown Tracker
- Spec-aware icons anchored directly to Blizzard or ElvUI party unit frames
- Tracks defensives, externals, movement, raid cooldowns, and utility spells
- Aura highlight when a buff is currently active on a player
- Dispel indicator per player — lights up when you can remove a harmful debuff from them
- Configurable icon size, gap, growth direction, anchor point, and max icons per row

### Interrupt Tracker
- Per-player interrupt rows with cooldown timer and last-kicked spell name
- Kick rotation via `/mp rotation` — assigns order and announces it to the group
- Optional combat-only visibility

### Combat Utilities
- **Battle Res** — tracks available charges with shared pool support in M+; shows who has a brez and whether it is ready
- **Bloodlust** — detects sources from Shamans, Mages, and Hunters (exotic pet required); shows the Sated debuff timer when active
- **Trinket** — shows your equipped on-use trinket icon with a Ready label or remaining cooldown; updates automatically when you swap trinkets

### Dungeon Utility Panel
- In-dungeon reference for class, spec, and race abilities relevant to the current dungeon
- Auto-shows on entering a dungeon (configurable)
- Covers crowd control, stops, skips, and dungeon-specific interactions

### Run History & Score Prediction
- Every completed run is stored locally — no external API required
- Personal best shown live in the HUD timer and on boss split rows
- Estimated score and delta vs your existing best displayed after each run

### Quality of Life
- **Auto-slot** — automatically places your keystone when you open the M+ pedestal
- **Keystone tracker** — shows your key and all party member keys; announce with `/mp keys`
- **Death tracker** — counts deaths with the per-death time penalty for the current key level
- **Dungeon teleports** — adds teleport spell buttons directly onto the Challenges UI dungeon icons (if you know the spell)
- All Blizzard scenario and objective tracker frames are hidden during M+ for a clean UI

### Demo Mode
- `/mp display` — previews the full HUD with mock data from any zone, no dungeon required

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

- **WoW Version:** Midnight 12.0.x (Interface 120005)
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
