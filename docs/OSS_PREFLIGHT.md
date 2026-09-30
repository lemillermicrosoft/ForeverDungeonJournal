# Lightweight OSS preflight (2026-09-30)

The goal was to avoid duplicating mature addon responsibilities. Repository pages and project documentation were reviewed; no upstream code or data was imported.

- **Atlas / Atlas Classic variants:** mature atlas/map presentation and authored map modules. Prefer an optional adapter or independently licensed data pack over replacing or copying Atlas assets. Atlas variants and eras differ; confirm the exact upstream repository and license before integration.
- **AtlasLootClassic:** mature loot-table browser with profile/favorites features. FDJ should deep-link or use a documented API if one exists rather than ship loot tables. The reviewed project describes dungeon/raid loot browsing and links Atlas modules. Confirm license for any code-level adapter.
- **HandyNotes:** an ecosystem for map-pin providers. Prefer a small optional pin-provider bridge for discovered entrances rather than implementing world-map pin infrastructure. Repository location varies; confirm canonical project/API and license before implementation.
- **Questie:** mature Classic quest database/helper with documented QuestieDB integration. Prefer optional lookup/link integration; never copy its quest database. Its repository documents Lua 5.1 tooling and integration material. Confirm the current license and API compatibility with WoW Forever.

Decision: build only the journal/discovery layer and an authored-pack contract. Declare all four families as optional dependencies, bundle none of their assets/data/code, and leave adapters off until target-client and license verification. This avoids license assumptions and keeps production facts empty.

Sources reviewed:
- https://github.com/Hoizame/AtlasLootClassic
- https://github.com/laytya/Atlas
- https://github.com/Questie/Questie
- HandyNotes project identity could not be reliably resolved during preflight; verify canonical repository before adapter work.

