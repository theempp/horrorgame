# Past Curfew — harbor and Coral Meridian map

A primitive-built 1988 cruise liner, playable three-deck interior and Calder Harbour approach. Map ownership stays here; authoritative gameplay stays in `../codex-build`. The design spec `../horrorgame.md` is read-only. No asset uploads, publishing, Robux purchases or audio are needed.

## Build and inspect locally

From `claude-build/`:

```sh
./tools/run_tests.sh
../codex-build/.tools/rojo build review.project.json -o build/PastCurfewReview.rbxlx
../codex-build/.tools/rojo build default.project.json -o build/PastCurfew.rbxlx
PYTHONDONTWRITEBYTECODE=1 ../codex-build/.venv/bin/python -B tools/preview.py build/preview --views
qlmanage -t -s 1400 -o build/preview build/preview/elevation_port.svg
```

Open `build/PastCurfewReview.rbxlx` in Roblox Studio and press Play. The map is generated at runtime, so the edit-mode place initially contains scripts, not baked geometry. Review buttons select zone cameras, play a 27-second reveal, change power/quality, and show anchors. Stop Play to exit the scriptable review camera. The integrated `PastCurfew.rbxlx` includes the sibling gameplay sources by Rojo path; it does not copy them. Its existing Depart action begins a run immediately. The cinematic approach is currently a review presentation, not an authoritative transport mechanic.

For live source sync, use the existing Rojo Studio plugin with `../codex-build/.tools/rojo serve review.project.json`. Installing a plugin is not required to open the built place. `PC_PYTHON` can override the test interpreter; it needs lupa with `lua51`. Tools use the sibling virtual environment and binaries without changing them.

## Layout and programme

`src/Map/Config` defines scale, palette, 32 room programmes, lighting/audio metadata, world positions, tags and budgets. `Core/Ctx.lua` is the sole geometry factory and reservation tracker. `Kit` builds walls, props, rails, stairs and maritime equipment. `Build` assembles the hull, tiered superstructure, boarding decks, environment, harbor, dressed rooms and manifest. `Runtime` handles client presentation; `src/Server` builds the map; `src/Client` runs presentation/review.

Deck A contains public rooms, galley, purser, radio and lifeboat muster rooms. Deck B contains passenger cabins, medical/security rooms and entertainers' quarters. Deck C contains stores, crew rooms and machinery. The double-height ballroom, funnel, stair lighting, lighthouse and contrasting deck materials are navigation landmarks. All rooms have two dresser variants; `MapBuilder.build({seed="...", variant="v2"})` selects v2, with the other variant stored in ServerStorage. Room graph and door positions remain fixed.

The harbor includes the office/briefing, pier, gangway, pontoon, tender, warehouses, crane, fuel tanks, buoys, lighthouse, omen slipway and boundaries. The vessel shows underway navigation lights despite its deployed anchor: an intentional story detail.

## Validation and limits

See [STATUS](STATUS.md) for current counts and [HANDOFF](HANDOFF.md) for continuation. Tests execute actual Lua 5.1-compatible map modules against a strict Roblox mock. Voxel checks derive walkability from generated collision geometry and exercise both room variants; they are not a substitute for Roblox humanoid physics or its pathfinding mesh. SVG previews omit GUI text, actual lighting, streaming, physics, terrain voxel rendering and precise cylinder curvature; they use painter-order polygons, so close-ups can have occlusion artifacts.

No licensed audio has been supplied. AudioZone tags and profiles are metadata only. Baseline vents/hatches remain closed and explicitly non-traversable. Further geometry changes require agreement on the spec deviation. Device performance and live multiplayer remain unmeasured.

Documentation: [scale](docs/MAP_SCALE.md), [performance](docs/PERFORMANCE_BUDGET.md), [presentation API](docs/PRESENTATION_API.md), [research](docs/RESEARCH_LOG.md), [review checklist](docs/MAP_REVIEW_CHECKLIST.md).
