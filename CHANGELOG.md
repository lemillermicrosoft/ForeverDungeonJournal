# Changelog

## 0.2.0-alpha.1 — candidate (2026-09-30)

- Added runtime Forever Encounter Journal provider for client-verified dungeon, map, boss, encounter-ID, description, and artwork metadata.
- Added API v2 atomic pack validation with mandatory build/license/verification/provenance fields and malformed-pack diagnostics.
- Added marker legend, authored map pins, world-map integration, dungeon/marker paging, richer source/ID tooltips, and `/fdj diagnostics`.
- Added schema 3 migration and malformed SavedVariables repair.
- Added deterministic registry, native-provider, provenance, malformed-pack, migration, package, and Lua 5.1 tests; packaging now requires all tests to pass.
- Documented the bounded data-coverage blocker and data-author workflow.
- No release published; awaiting in-client smoke testing.

## 0.1.0-alpha

- Initial installable spoiler-light journal framework, saved progress/annotations, settings, and native/bronze appearances.
