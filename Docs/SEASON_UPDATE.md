# Updating MythicPulse for a New M+ Season

MythicPulse is built to **survive a dungeon rotation with no code changes**. Core
features — the timer, dungeon name, time limit, affix row, enemy forces, boss
splits, death tracking, run summary, and score prediction — all read live from
Blizzard's `C_ChallengeMode` / `C_MythicPlus` / `C_ScenarioInfo` APIs, so they
work on any new dungeon the moment a season goes live.

The hardcoded tables in this addon are only an **enrichment / value-add layer**.
Until they're filled in for the new season you lose *only* these niceties (never
core function):

- Short dungeon codes (e.g. `MT`, `WS`) in the HUD — falls back to the full name.
- Teleport buttons on the Challenges UI.
- The per-dungeon Dungeon Utility panel (CC/stops/skips reference).
- Auto-gossip at dungeon-gating NPCs.

This doc is the checklist for restoring those for a new season.

## Two ID spaces — don't mix them up

| Data | ID type | How to read it |
|------|---------|----------------|
| `Data/Dungeons.lua`, `Modules/DungeonTeleport.lua` | **ChallengeMapID** | `/dump C_ChallengeMode.GetMapTable()` then `/dump C_ChallengeMode.GetMapUIInfo(<id>)` |
| `Data/UtilityDungeons.lua` | **instanceID** | stand in the dungeon: `/dump select(8, GetInstanceInfo())` |
| `Modules/AutoGossip.lua` | **NPC display name** | set `DEBUG_GOSSIP_NAMES = true` in that file, talk to the NPC |

## Checklist

1. **`Data/Dungeons.lua`** — fill in `MP.DungeonData.Seasons[2]` with one row per
   dungeon: `{ id = <ChallengeMapID>, name, shortName, timeLimit, numBosses, expansion }`.
   Then set `MP.DungeonData.CURRENT_SEASON = 2`. (`timeLimit`/`name` come from the
   live API anyway; the table just adds the short code + metadata.)

2. **`Modules/DungeonTeleport.lua`** — add `[ChallengeMapID] = { name, spellID }`
   rows in the `TELEPORT_SPELLS` table. Find teleport spell IDs on Wowhead or via
   `/dump C_Spell.GetSpellName(<id>)`.

3. **`Data/UtilityDungeons.lua`** — add the new instanceIDs to `dungeonNames`, then
   author a `dungeonEntries[<instanceID>]` block of mechanic entries (use the
   `{spell:ID}` / `{npc:ID}` placeholder syntax like the existing blocks). Update
   `defaultDungeonID` to a current-season instanceID. (Consumers call
   `GetDefaultDungeonID()`, which already falls back to any valid entry if the
   default is stale.)

4. **`Modules/AutoGossip.lua`** — capture gating-NPC names in-game with
   `DEBUG_GOSSIP_NAMES = true`, then add `["<NPC Name>"] = { option, note }` entries
   in the Season 2 block.

5. **`MythicPulse.toc`** — bump `## X-Season` to the new season number and bump
   `## Version`.

6. **`CHANGELOG.md`** — add the new release entry.

## Affixes

No action needed. The affix row (`Modules/Timer.lua`, `UI/RunSummary.lua`) renders
names/icons live via `C_ChallengeMode.GetAffixInfo()`, so new seasonal affixes show
up automatically. The hardcoded `MP.AffixData.Affixes` table is used only for
death-penalty tiering; revisit `MP.DungeonData:GetDeathPenalty` /
`DeathsPenalized` in `Data/Dungeons.lua` only if Blizzard changes the
no-death-penalty / guile key thresholds.

## Score formula

`Modules/ScorePredictor.lua` is an approximation, not an official formula. If the
season changes M+ scoring, update the `base`/`bonus` constants in
`EstimateRunScore` — but it degrades gracefully if left alone.
