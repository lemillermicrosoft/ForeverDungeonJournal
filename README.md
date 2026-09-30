# Forever Dungeon Journal

An installable alpha framework for a spoiler-light dungeon atlas and personal discovery journal for WoW Forever (`Interface: 16001`). **No dungeon facts are bundled yet**: names, maps, coordinates, bosses, quests, shortcuts, risky pulls, and loot data must come from reviewed data packs.

## MVP behavior

- `/fdj` opens a searchable dungeon browser with marker filters.
- Discovery mode hides unrevealed markers by default. Markers can be manually revealed.
- Safe game events record first sighting, kill, quest completion, and personal encounter loot when a verified pack supplies matching IDs. The addon does not read the combat log.
- Right-click a visible marker to add a personal annotation.
- Progress and annotations can be per-character or account-wide.
- Esc > Options > Forever Dungeon Journal controls discovery, scope, and marker types.
- SavedVariables: `ForeverDungeonJournalDB` and `ForeverDungeonJournalCharDB`.

## Install

Copy the `ForeverDungeonJournal` folder into the WoW Forever `Interface/AddOns` directory. The folder must contain `ForeverDungeonJournal.toc` directly.

## Data packs

Data packs are separate addons loaded after this addon. See [`docs/DATA_PACKS.md`](docs/DATA_PACKS.md). The repository includes a deliberately fictional development fixture under `dev/`; it is absent from the TOC and production zip.

## Compatibility preflight

See [`docs/OSS_PREFLIGHT.md`](docs/OSS_PREFLIGHT.md). This project does not copy databases or assets from Atlas/AtlasLoot, HandyNotes, or Questie. Optional dependency declarations permit load ordering, while future adapters should use documented public APIs and honor upstream licenses.

## Package

Run `powershell -ExecutionPolicy Bypass -File tools/package.ps1`. Output: `dist/ForeverDungeonJournal-0.1.0-alpha.zip`.

