# Handoff — Past Curfew map (claude-build) → now owned by Codex

This is the single source of truth for the map work. Keep it updated in place (don't create parallel notes).
Read it first, then `../horrorgame.md` (the design spec, read-only).
Map work lives in `claude-build/`; game systems live in `codex-build/`. Integrate through CollectionService tags and anchors,
not by merging folders or duplicating modules. The "Integration issues" section below lists the mismatches to fix on the codex-build side.
Scope: the harbor approach, the ship exterior with boarding, and a representative ship interior. Deliverables: Rojo project, modular kit,
tags and anchors, review mode, validation tests, and docs (README, STATUS, RESEARCH_LOG, MAP_SCALE, PERFORMANCE_BUDGET, PRESENTATION_API,
MAP_REVIEW_CHECKLIST). Do not publish, upload assets, spend Robux, or use unlicensed audio.
Current state: step 1 verified and committed; steps 1–2 verified; next is step 3 (Environment).

## User working preferences
- Maximise work per session; be credit-efficient but prioritise map detail/quality.
- QA everything: build it, run it, render it, inspect it, fix it — only then call it done.
- Map work stays in `claude-build/`; the current user explicitly authorizes integration fixes in `codex-build/`. Never edit `horrorgame.md`. No publishing/uploads.

## Tooling (no global rojo/luau installed)
- Headless run: `PYTHONDONTWRITEBYTECODE=1 ../codex-build/.venv/bin/python -B tests/harness.py`
  (uses Codex's venv lupa read-only; lupa has Lua 5.1 only → all Luau is written in the Lua 5.1 subset:
  no type annotations, no `+=`, no `continue`, no string interpolation).
- Strict mock: `tests/mock/roblox.lua` (unknown classes/props/enums/materials error). Add classes there when needed — accurately.
- Previews: `tools/preview.py <outdir> [--views]` → SVGs; rasterise with `qlmanage -t -s 1400 -o . file.svg` (square crop) and Read the PNG.
- Rojo binary available read-only at `../codex-build/.tools/rojo` (v7.7.0) for `rojo build` checks.
- Spec modules: `python3 tools/extract_spec.py [--check]`.
- `git init` done; nothing committed yet.

## Done (ran clean where noted)
- Config: Scale, Palette, World, Rooms (all 32 slots themed), Zones, Lighting, Audio, Quality, Tags, Budgets.
- Core: Rng (Park-Miller), Ctx (factory/stats/reservations), RoomFrame (u/v/h local coords, v2 = mirrored).
- Kit: Walls (interval-split openings), Stairs, Rails (+anti-vault PlayBoundary), Signs, Props, Maritime.
- Build/InteriorShell.lua — RAN: 1,659 parts, 42 lights, plan slice checked visually.
- Build/Hull.lua, Build/Superstructure.lua — WRITTEN, NOT YET RUN.
- MapBuilder.lua is a temporary stub (shell only).

## Remaining (in order)
1. DONE: Hull + Superstructure wired; 3,173 parts / 48 lights. Harness and Rojo pass; elevation and harbor previews inspected.
2. DONE: ExteriorDecks (aft deck, port promenade + rails with lifeboat gates, accommodation ladder, board-door sign/lights).
3. Environment (Lighting/Atmosphere/Sky/post FX; terrain water fill, clear water inside hull, land/cliffs/breakwaters).
4. Harbor (quay, pier, pontoon, gangway, tender, office+briefing, warehouses, crane, lamps, buoys, lighthouse, omen slipway, boundaries).
5. Room dressers v1/v2 per theme (keep spec loot/hide nodes clear via ctx:reserve; hide props at spec hide positions).
6. Manifest + Anchors (all 20 required tags + extras in Config/Tags.lua), volumes (MajorZone, AudioZone, StreamingRegion, PlayableVolume, StalkerZone, ReviveSafeArea), variants to ServerStorage.
7. Runtime client modules (Atmosphere blend, Quality tiers, LightCircuits/PowerState, DoorPresenter, Lighthouse/radar) + Review mode UI.
8. default.project.json + review.project.json (Workspace streaming props set in project file — not scriptable).
9. Tests: determinism, tags/min counts, spec coverage, voxel nav reachability + containment, clearances, budgets, zone identity, rojo build.
10. Docs: README, STATUS, RESEARCH_LOG (sources already gathered — see below), MAP_SCALE, PERFORMANCE_BUDGET, PRESENTATION_API, MAP_REVIEW_CHECKLIST. Commit.
11. Optional: open review place in Roblox Studio (installed) for real inspection.

## Key decisions / facts
- Axes: bow = −X, stern = +X; starboard = −Z (L rooms), port = +Z (R rooms, lifeboats, faces harbor). Water Y=4, keel −15.
- Ship 480×68 studs ≈ Seabourn Pride original (~133 m × 19 m). Harbor ~600 studs north (+Z); tender route ~24 s.
- LB_mid boat centred x=88 (spec door x=80, marker x=96). Ship shows underway lights while anchored (deliberate wrongness).
- Research sources gathered (cite in RESEARCH_LOG): Roblox docs (streaming, Model.LevelOfDetail plugin-security, Lighting.Technology deprecated → LightingStyle/PrioritizeLightingQuality, Fog hidden with Atmosphere, terrain water props, perf/improve, collisions, pathfinding AgentRadius 2/Height 5, audio API, content maturity = Mild, packages, Rojo sync); SOLAS/load-line rails ≥1.0 m; FSS ch.13 stairs ≥0.9 m, ≤3.5 m rise per flight; accommodation ladder ≤55°; IALA region A buoys; COLREGs lights; Star Pride/Seabourn Pride Wikipedia; competitor stats (Pressure ~489M visits, DOORS >5B, 99 Nights peak 14.2M CCU — third-party reported).

## Integration issues for Codex (put in STATUS.md)
- Run bounds clamp X −2..194, Z −2..50, Y≤53 blocks promenade/aft deck/ladder → use PlayableVolume tags.
- Config.DockPosition (224,5,72) is 32 studs from the ship → read PlayerSpawn/HarborDeparture tags.
- LB_mid interior pad at x=96 sits inside the A_R3/A_R4 wall → use my anchor (x=80).
- Spec vents 2×4 / hatches 2×2 not avatar-traversable → built closed, TraversableByAvatar=false, proposed 4×6 / 4×4.
- Door width 4 = 2×pathfinding AgentRadius → recommend AgentRadius 1.5.
- Glass tagged SightTransparent: exclude from stalker LOS raycasts.
