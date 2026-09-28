# Handoff — Past Curfew map

Current state: requested steps 1–10 are implemented. Final headless verification is recorded in STATUS.md. Optional step 11, real Roblox Studio play-mode inspection, remains pending. No publication, uploads, purchases, or audio assets.

## Ownership and constraints
Read this file first, then ../horrorgame.md (read-only). Map source belongs in claude-build; authoritative systems belong in codex-build. Integrate through tags and anchors; never copy modules between repositories. All map/runtime Lua uses the Lua 5.1 subset for the harness. The user explicitly authorized integration fixes in the sibling repository. These are separate Git repositories.

## Tooling
Run commands from claude-build:
- `./tools/run_tests.sh` runs the strict harness and 16 tests.
- `../codex-build/.venv/bin/python -B tools/preview.py build/review --views` generates geometry previews; rasterize selected SVGs using `qlmanage -t -s 1000 -o build/review <svg>` and inspect PNGs.
- `../codex-build/.tools/rojo build default.project.json -o build/PastCurfew.rbxlx` builds integrated gameplay.
- Same command with review.project.json and build/PastCurfewReview.rbxlx builds map-only review.
- `python3 tools/extract_spec.py --check` checks immutable spec extraction.
- In codex-build, `.venv/bin/python -B tools/verify.py` runs 27 systems tests, compilation, analysis, and standalone build.

## Ordered work completed
Initial inherited snapshots: map d23a785, systems e1c09e6.
1. 63bdf65 — wired and verified Hull and Superstructure.
2. f5610d0 — exterior decks, lifeboat gates, accommodation ladder and boarding details.
3. ce0c3e7 — environment, owned terrain sea fill/hull cuts, land and breakwaters.
4. e3849a3 — harbor, tender, office, industry, navigation details and omen slipway.
5. f170260 — all 32 room themes, mirrored variants and reserved interaction clearances.
6. cdab5bc — manifest, required tags, volumes and stored inactive variants.
7. ee5ed71 — atmosphere, lighting circuits, doors, exterior motion and review UI.
8. b779406 — integrated and map-only Rojo projects; systems adapter d5dd91f.
9. b538ddd — navigation, determinism, integration and budget tests; ladder/tender clearance fixes.
10. Documentation — README and docs cover scale, sources, budgets, API and explicit Studio checklist. Final verification passed: 43 tests, compilation, spec mirror, both places and inspected previews.

Each implementation step ran the harness, rendered and inspected previews, and passed a Rojo build. The final suite expands those checks; SVG previews do not simulate Roblox lighting or physics.

## Integration resolved
- Run clamp uses the union of tagged PlayableVolume boxes, including exterior and harbor.
- Integrated spawn/departure use PlayerSpawn and HarborDeparture. Config.DockPosition remains a standalone greybox fallback.
- LB_mid pad follows the door at x=80, z=44, avoiding the wall at the old marker.
- Spec vents/hatches remain physically closed and TraversableByAvatar=false. The systems clearance policy requires 4x6 vents / 4x4 hatches plus explicit enablement; the immutable 2x4 / 2x2 spec is not silently enlarged.
- AgentRadius is 1.5; SightTransparent glass is excluded from stalker LOS.
- ContractSpawn chooses authored rooms. Power restoration changes PastCurfewMap.PowerState to On; departure resets Emergency.
- Map readiness suppresses duplicate greybox generation. See docs/PRESENTATION_API.md and sibling INTEGRATION_CONTRACT.md.

## Current geometry and decisions
Bow is -X, port +Z, water Y=4, keel -15. Ship exterior is 480x68 studs; interior remains spec coordinates. The middle lifeboat is centered x=88 but extraction uses its x=80 door. Underway lights while moored are intentional horror dressing.
The harbor tender was moved to (162,4,568) and pontoon begins z=588 to clear the approach. Ladder uses half-stud treads and segmented guards; explicit stair graph links join decks. Review camera reveal lasts 27 seconds; gameplay departure still transfers immediately.
4,786 replicated map parts, 515 inactive variant parts, 103 active lights, 8 shadow lights. Manifest accounting is conservatively charged to REG_C. Both variants pass collision-derived reachability tests for all 32 rooms.
Research and the limitations of inherited maritime/competitor claims are documented in docs/RESEARCH_LOG.md; do not promote unverified inherited claims to facts.

## Remaining / next owner
Optional step 11: open build/PastCurfewReview.rbxlx in Studio and Play, then test the integrated place. Follow docs/MAP_REVIEW_CHECKLIST.md for real character/stalker clearance, doors, streaming, review controls, terrain water, multiplayer and mobile performance. These are unverified engine checks, not inferred passes from mocks. Audio zones contain metadata only. Device budgets are count ceilings, not measured frame-rate guarantees.
