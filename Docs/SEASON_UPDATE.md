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

## Season 2 pool (confirmed 2026-08-14)

Live August 18, 2026 per Blizzard's "The Shadows Deepen: Midnight Season 2
Begins August 18" news post (cross-checked against Method.gg, Wowhead, Warcraft
Wiki). Eight dungeons — five Midnight, three legacy:

| Dungeon | Expansion |
|---|---|
| Altar of Fangs (new, patch 12.1) | Midnight |
| Murder Row | Midnight |
| Den of Nalorakk | Midnight |
| The Blinding Vale | Midnight |
| Voidscar Arena | Midnight |
| King's Rest | Battle for Azeroth |
| Temple of Sethraliss | Battle for Azeroth |
| Ruby Life Pools | Dragonflight |

**Update 2026-08-14:** ChallengeMapID, instanceID, and timeLimit were pulled
from the live MapChallengeMode DB2 via wago.tools and are filled into
`Data/Dungeons.lua` `Seasons[2]` and `Data/UtilityDungeons.lua` `dungeonNames`
— cross-checked twice and matched against Season 1's known-good rows
(Skyreach/Windrunner Spire), so treat these as solid. Teleport spellIDs in
`Modules/DungeonTeleport.lua` are filled too, but several dungeons had 2-3
same-named "Teleport: X" spells in the DB2 (old spells from a dungeon's prior
season/remix are never removed) — picked the newest ID each time, following
the same pattern already proven correct for Skyreach (410077 kept, a stale
169765 ignored). If a teleport button doesn't appear for a Season 2 dungeon
once live, that guess was wrong for that one — `IsSpellKnownOrPlayer()` already
makes a wrong ID fail silently (no button) rather than break anything, so
re-check with `/dump C_Spell.GetSpellName(<id>)` and swap it in.

Still genuinely unfillable from the web — needs someone standing in the
dungeon: gossip-gating NPC names (`Modules/AutoGossip.lua`), and the
`dungeonEntries` mechanic content (CC/stops/skips reference) in
`Data/UtilityDungeons.lua`.

## Two ID spaces — don't mix them up

| Data | ID type | How to read it |
|------|---------|----------------|
| `Data/Dungeons.lua`, `Modules/DungeonTeleport.lua` | **ChallengeMapID** | `/dump C_ChallengeMode.GetMapTable()` then `/dump C_ChallengeMode.GetMapUIInfo(<id>)` |
| `Data/UtilityDungeons.lua` | **instanceID** | stand in the dungeon: `/dump select(8, GetInstanceInfo())` |
| `Modules/AutoGossip.lua` | **NPC display name** | set `DEBUG_GOSSIP_NAMES = true` in that file, talk to the NPC |

## Checklist — what's left for Season 2

1. ~~`Data/Dungeons.lua`~~ — done. `Seasons` tables now merge into one lookup
   (see `MP.DungeonData.ByMapID`), so there's no per-season switch to flip
   for future seasons either — just add the new season's table.

2. `Modules/DungeonTeleport.lua` — spellIDs filled but best-effort where the
   DB2 had duplicate-named spells (see note above). Confirm in-game once
   Season 2 keys are active: does the teleport button appear / actually
   teleport? Swap the ID if not.

3. ~~`Data/UtilityDungeons.lua` `dungeonNames`~~ — done. Still open: author
   `dungeonEntries[<instanceID>]` mechanic blocks (CC/stops/skips, using the
   `{spell:ID}` / `{npc:ID}` placeholder syntax like the existing blocks) for
   the 8 Season 2 dungeons. This needs real route knowledge, not just IDs.

4. `Modules/AutoGossip.lua` — capture gating-NPC names in-game with
   `DEBUG_GOSSIP_NAMES = true`, then add `["<NPC Name>"] = { option, note }`
   entries in the Season 2 block.

5. `MythicPulse.toc` — bump `## X-Season` and `## Version` once the above is
   good enough to ship (doesn't have to be 100% — enrichment degrades
   gracefully per the intro).

6. `CHANGELOG.md` — add the new release entry.

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
