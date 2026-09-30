# Verified data-pack authoring

A pack is a separate addon with `## Dependencies: ForeverDungeonJournal`. Its Lua calls:

```lua
local FDJ = _G.ForeverDungeonJournalAPI
FDJ:RegisterDataPack({
  id = "publisher.pack", name = "Verified Pack", version = "1.0.0",
  source = "URL or revision describing provenance and verification",
  dungeons = {
    {
      id = "stable-machine-id", name = "Verified in-game dungeon name",
      map = { texture = "Interface/AddOns/PackName/Maps/map-file" },
      markers = {
        { id = "stable-marker-id", type = "boss", label = "Verified name", x = 0.5, y = 0.5,
          encounterID = 123, npcID = 456, description = "Spoiler-light authored text" },
      },
    },
  },
})
```

Supported marker types are `entrance`, `boss`, `quest`, `shortcut`, and `risky`. Coordinates are normalized 0..1 against the authored map texture. Optional observation keys are `encounterID`, `npcID`, and `questID`.

Before release, verify every fact against the target WoW Forever client or a source whose terms allow redistribution. Record source URL/revision, verification date, author, client build, and image provenance. Do not derive or copy restricted/proprietary maps, databases, or text. Keep uncertain content out rather than guessing. Use unique pack/dungeon/marker IDs; IDs become SavedVariables keys and must remain stable.

The public registration facade is `_G.ForeverDungeonJournalAPI` (`API_VERSION = 1`). Keep `## Dependencies: ForeverDungeonJournal` so it exists before pack files execute.

