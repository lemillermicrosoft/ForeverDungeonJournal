# Data author guide

## Evidence standard

1. Record the exact Forever client build and test date.
2. Verify names and IDs from the installed client API or direct in-client observation.
3. Use a source whose terms permit redistribution. Record title, URL/revision, license, author, and verification method.
4. Author map coordinates only against a map texture you created or may redistribute. Do not trace or extract restricted third-party maps.
5. Keep uncertain fields absent. If a dungeon is useful with known gaps, describe them in `dungeon.unknowns`; never estimate coordinates or IDs.
6. Use short spoiler-light descriptions. Risky-pull claims need reproducible route/build context, not hearsay.

## Stable IDs and updates

Use lowercase publisher-prefixed pack IDs and semantic versions. Dungeon and marker IDs become durable SavedVariables keys; never rename them merely to improve wording. If a fact is corrected, retain the ID, update provenance, bump the pack version, and document the correction.

## Validation checklist

- Pack has build, license, verification, and at least one source.
- Every dungeon/marker ID is unique; labels are non-empty.
- Numeric IDs are positive integers and confirmed on the target build.
- Coordinates are paired and normalized.
- Map/license provenance is explicit.
- Malformed-pack rejection leaves registry/index counts unchanged.
- Test discovery, annotation, scope, paging, and event progress in game.

The core repository's deterministic test harness provides examples of accepted and rejected API v2 packs.
