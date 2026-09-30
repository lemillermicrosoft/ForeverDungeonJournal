# OSS, data, and license preflight (2026-09-30)

No upstream code, maps, databases, quest text, routes, or loot tables are copied into this addon.

| Resource | Verified repository / status | License finding | Decision |
|---|---|---|---|
| Atlas / Atlas variants | `laytya/Atlas`; variants differ by era and maintainer | GitHub did not expose a repository license for the reviewed fork | Optional load-order detection only; do not copy assets/data or call undocumented globals. |
| AtlasLootClassic | `Hoizame/AtlasLootClassic` | GPL-2.0 license detected | Detect installation; leave loot browsing to AtlasLoot. No loot data copied. |
| Questie / QuestieDB | `Questie/Questie`, `Questie/QuestieDB` | Reviewed repositories did not expose a machine-readable license endpoint for the database | Detect installation; require a documented, compatible API and explicit data terms before an adapter. |
| HandyNotes | canonical repository resolved as `Nevcairiel/HandyNotes` | Repository did not expose a machine-readable license endpoint | Detect installation; future entrance pins should use its maintained provider API only after exact Forever compatibility/license review. |
| Forever Atlas website | `benjamh681/wow-forever-atlas` | No repository license detected; site is a web guide, not an addon data API | Link/reference only in provenance research; copy nothing. |
| Installed WoW Forever client | build observed locally: `1.60.1.70124`, product `wow_classic_beta` | Blizzard client runtime | Read names/IDs/art returned by documented global Encounter Journal APIs at runtime; redistribute no extracted database/assets. |

## Architecture decision

The MVP owns only journal/discovery state and an API v2 authored-pack contract. At runtime it may load Blizzard's Encounter Journal UI module, then query `EJ_GetNumInstances`, `EJ_GetInstanceByIndex`, and `EJ_GetEncounterInfoByIndex`. Results are labeled `client`, include the exact build, and are never serialized as a redistributable source pack.

Atlas, AtlasLoot, Questie, and HandyNotes remain optional dependencies and appear in diagnostics. This is deliberate lawful integration: no fragile undocumented invocation and no license assumption.

## Precise bounded blocker

As of this check, no maintained, license-clear WoW Forever dataset/API was found that supplies verified entrance coordinates, dungeon quest associations, shortcuts, risky-pull routes, or redistributable floor maps for build 1.60.1.70124. Therefore those fields remain absent/unconfirmed unless an API v2 pack documents direct client verification and redistribution rights. Fabricating classic-era carryovers would be especially unsafe because Forever includes new/changed dungeons.

Sources checked:

- https://github.com/laytya/Atlas
- https://github.com/Hoizame/AtlasLootClassic
- https://github.com/Questie/Questie
- https://github.com/Questie/QuestieDB
- https://github.com/Nevcairiel/HandyNotes
- https://github.com/benjamh681/wow-forever-atlas
- https://wowforeveratlas.com/sources
