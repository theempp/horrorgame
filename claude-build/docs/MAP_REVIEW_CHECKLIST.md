# Map review checklist

## Automated / inspected locally

- [x] Original state committed in both repositories before edits.
- [x] Hull and superstructure assembled; port elevation and harbor reveal inspected.
- [x] Exterior deck/ladder close-ups and harbor plan inspected.
- [x] All 32 room programmes and both variants build; deck plans and ballroom inspected.
- [x] Required tag minima, attributes, baseline spec coverage and reproducible data extraction pass.
- [x] Collision-derived voxel routes reach every room in both variants.
- [x] Aft deck, promenade and ladder are connected; reached ship cells remain inside playable volumes.
- [x] Harbor spawn-to-departure route passes; ladder guard and tender overlap defects fixed.
- [x] World adapter executes against the real generated tag manifest.
- [x] Determinism, rebuild idempotence, budgets, Lua 5.1 syntax and runtime module checks pass.
- [x] Integrated and review Rojo projects build; game regression suite passes.
- [x] No uploads, asset purchases, publishing or audio playback.

## Roblox Studio / device checks still pending

- [ ] Open review place, press Play and confirm no Output errors.
- [ ] Walk harbor → pontoon and aft deck → ladder without snagging.
- [ ] Walk all 32 rooms and both stairs with intended avatar rigs; test jumping at every drop edge.
- [ ] Check real PathfindingService routes, especially 4-stud doors, stairs and closed/barricaded doors.
- [ ] Inspect terrain water clearance around the hull in actual voxels.
- [ ] Check dark-room readability at Low/Balanced/High and Emergency/Blackout/On.
- [ ] Check door visual alignment against authoritative collisions during open/close/break.
- [ ] Test zone-camera/reveal buttons and streaming when changing zones remotely.
- [ ] Confirm integrated harbor spawn/departure, three extraction pads, power contract and retries.
- [ ] Run 1–4 local players; profile memory/frame time on a representative low-end device.
- [ ] Review audio licences before any sound sourcing or playback implementation.

Passing the headless checks does not check these Studio/device items automatically. The map is ready for this review, not certified for release.
