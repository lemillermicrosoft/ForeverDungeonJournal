# Forever Dungeon Journal

An installable alpha framework for a spoiler-light dungeon atlas and personal discovery journal for WoW Forever (`Interface: 16001`). **No dungeon facts are bundled yet**: names, maps, coordinates, bosses, quests, shortcuts, risky pulls, and loot data must come from reviewed data packs.

## MVP behavior

- `/fdj` opens a searchable dungeon browser with marker filters.
- Fresh installs use a Blizzard-native frame and control appearance; the original bronze presentation remains available and applies immediately without a reload.
- With no verified packs installed, onboarding explains the safe discovery workflow and provides persistent general expedition notes without inventing game facts.
- Discovery mode hides unrevealed markers by default. Markers can be manually revealed.
- Manual reveals record their first-revealed time. `BOSS_KILL` and `QUEST_TURNED_IN` record first kill/completion only when the event ID is an explicitly non-secret number and a verified pack supplies the matching ID.
- Target GUIDs and encounter-loot payloads are deliberately not inspected, so automatic first-seen and first-loot tracking are not claimed in this alpha. The addon does not read the combat log.
- Right-click a visible marker to add a personal annotation.
- Progress and annotations can be per-character or account-wide.
- Esc > Options > Forever Dungeon Journal—or the always-available Options button—controls appearance, discovery, scope, and marker types, including when no packs are installed.
- SavedVariables: `ForeverDungeonJournalDB` and `ForeverDungeonJournalCharDB`.

## Install

Copy the `ForeverDungeonJournal` folder into the WoW Forever `Interface/AddOns` directory. The folder must contain `ForeverDungeonJournal.toc` directly.

## Data packs

Data packs are separate addons loaded after this addon. See [`docs/DATA_PACKS.md`](docs/DATA_PACKS.md). The repository includes a deliberately fictional development fixture under `dev/`; it is absent from the TOC and production zip.

## Compatibility preflight

See [`docs/OSS_PREFLIGHT.md`](docs/OSS_PREFLIGHT.md). This project does not copy databases or assets from Atlas/AtlasLoot, HandyNotes, or Questie. Optional dependency declarations permit load ordering, while future adapters should use documented public APIs and honor upstream licenses.

## Package

Run `npm run package`. It validates Lua 5.1 syntax, builds a clean allowlisted staging tree, validates archive integrity, and writes `dist/ForeverDungeonJournal-0.1.0-alpha.zip`. Development files and `node_modules` are excluded.

