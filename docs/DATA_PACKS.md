# Data-pack API v2

A pack is a separate addon with `## Dependencies: ForeverDungeonJournal`. API v2 rejects the entire pack before indexing if any required metadata or record is malformed.

```lua
_G.ForeverDungeonJournalAPI:RegisterDataPack({
  id = "publisher.forever-verified", name = "Forever Verified", version = "1.0.0",
  build = "1.60.1.70124", license = "CC-BY-4.0", verification = "verified",
  sources = {{
    title = "In-client verification session", kind = "first-party-test",
    url = "https://example.invalid/method", revision = "abc123", checked = "2026-09-30",
  }},
  dungeons = {{
    id = "stable-dungeon-id", name = "Verified in-game name", instanceID = 123, mapID = 456, floor = 1,
    verification = "verified",
    map = { texture = "Interface/AddOns/PublisherPack/Maps/example" },
    markers = {{
      id = "stable-boss-id", type = "boss", label = "Verified name", x = 0.5, y = 0.5,
      encounterID = 789, description = "Spoiler-light authored text", verification = "verified",
    }},
  }},
})
```

Required pack fields: `id`, `name`, `version`, `build`, `license`, `verification`, non-empty `sources`, and `dungeons`. Every source requires `title`, `kind`, and ISO check date; URL/revision are optional. Verification is one of `verified`, `client`, `community`, or `unconfirmed`.

Marker types: `entrance`, `boss`, `quest`, `shortcut`, `risky`. Coordinates must be supplied as an x/y pair normalized to 0..1 against the authored texture. Positive integer `encounterID` and `questID` values enable safe event matching. IDs must be stable and unique within the pack because SavedVariables use them as keys.

API facade: `_G.ForeverDungeonJournalAPI`, `API_VERSION = 2`. API v1 packs must be upgraded with provenance metadata.
