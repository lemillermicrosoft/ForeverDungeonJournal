# Forever Dungeon Journal

A spoiler-light dungeon browser and personal discovery journal for WoW Forever (`Interface: 16001`). Candidate build: **0.2.0-alpha.1**.

## What works

- `/fdj` opens a searchable, filterable dungeon browser.
- At load, the addon asks the installed Forever client's Encounter Journal for dungeon names, instance/map references, boss names, encounter IDs, descriptions, and journal artwork. These runtime facts are labeled **client** and are not redistributed as a copied database.
- Authored API v2 data packs can add verified entrances, quests, coordinates, shortcuts, and risky-pull notes with mandatory source/build/license/verification metadata.
- Encounter artwork is rendered when the client reports it. Authored normalized coordinates render colored pins. **Open world map** gracefully opens a verified map ID or explains why it cannot.
- Discovery mode hides labels until manual reveal. Right-click revealed entries for notes.
- `BOSS_KILL` and `QUEST_TURNED_IN` record first completion only for an explicitly numeric, registered ID. No combat log, target, name/realm, loot payload, secret comparison, or protected action is used.
- Progress and annotations can be per-character or account-wide. General expedition notes are account-wide.
- Blizzard/native is the default: warm bronze outer frame, dark-umber header/body, subtle inner dividers. Bronze/custom remains optional.
- `/fdj diagnostics` reports provider, data-pack, rejection, and optional-addon status.

## Honest coverage boundary

The client-derived provider is the most complete lawful source currently available to this project. It can expose only fields returned by the installed beta build. Entrance coordinates, dungeon quests, shortcuts, and risky-pull annotations remain explicitly unconfirmed unless an independently verified API v2 pack supplies them. The addon does not infer these facts and does not copy Atlas, AtlasLoot, Questie, HandyNotes, or fan-site databases/assets.

## Install and smoke test

Copy the `ForeverDungeonJournal` folder into `_classic_beta_/Interface/AddOns/`. The folder must directly contain `ForeverDungeonJournal.toc`.

1. Log into build 1.60.x, run `/fdj`, and confirm the window opens without Lua errors.
2. Confirm native styling, search, dungeon selection, marker filters, paging, and tooltips.
3. With Discovery mode on, click an unknown row; reload and confirm it stays revealed.
4. Right-click a revealed row, save a note, reload, and verify it persists.
5. Change character/account scope and verify each store remains independent.
6. Select Bronze and back to Blizzard/native without reloading.
7. Click **Open world map**; verify a reported map opens or a bounded message appears.
8. Run `/fdj diagnostics`; record dungeon/marker counts and optional integration states.
9. Verify boss/quest progress only through ordinary play; do not synthesize protected or secret values.

## Development

```powershell
npm ci
npm test
npm run package
```

Packaging writes `dist/ForeverDungeonJournal-0.2.0-alpha.1.zip` and verifies the exact allowlist. See [data-pack authoring](docs/DATA_AUTHOR_GUIDE.md), [API contract](docs/DATA_PACKS.md), and [OSS/provenance preflight](docs/OSS_PREFLIGHT.md).

No release has been published for this candidate; player smoke testing is required first.
