# Past Curfew — Codex systems slice

A Rojo-friendly, local first playable implementation of the loot-and-escape loop. All source, tooling and outputs live in this directory. The parent `horrorgame.md` is untouched. Claude's presentation work is separate.

## Play locally

1. Open `PastCurfew.rbxlx` in Roblox Studio. This generated file is included in the working directory; regenerate after source changes.
2. Press **Play**. Spawn on the dock; the HUD shows the optional contract goal and special reward. Inspect the omen or press **Depart now** immediately.
3. Hold **E** at loot/contract/door/extraction prompts (tap/hold their native prompt on mobile). **C** toggles sneak, **F** spends a flare, **N** throws a decoy, **B** barricades the nearest eligible door, **G** drops your entire bag. Touch buttons provide the same actions.
4. Two lifeboats are initially available in deck A's starboard rooms. Hold an extraction prompt for 3 seconds to escape individually. At 8 minutes all lifeboats open; at 9 minutes remaining players are captured.
5. A caught player drops the bag and has 45 seconds for a teammate's 5-second revive. Solo can evade with a lighter bag and tools; revive is optional teamwork. Spectators automatically watch an active crewmate; **V** cycles viewpoints. **V** also toggles first/third person at the dock; ship camera is first-person.
6. When the crew resolves, rewards settle once. Choose **Quick retry** to return to the dock. Spend 100 earned Salvage at the hideout anchor to unlock a cosmetic display alcove. Profile attributes expose the sample; Claude supplies its display.

For crew testing use Studio's local **Server & Clients** with 2–4 clients. The server caps active participants at four, locks scaling at departure, and makes late joins spectators. This is a single-lobby local slice, with immediate departure by any ready player; matchmaking/reservations are not implemented.

**Studio uses session-only profiles even with API access enabled.** It never reads or writes production player data. Leave API access off for local checks. In a separately authorized published test environment, the adapter uses `PastCurfew_v1`, `UpdateAsync`, a 180-second session lease, 60-second renew/save cycle, settlement saves, retries and shutdown release. Failed/corrupt/locked loads never fall back to writable defaults. An unavailable save blocks the next departure and is retried; permanent service outage can still lose unsaved progress. No live DataStore or analytics delivery is claimed verified.

## Build and verify

Tools used locally: Rojo 7.7.0 and Luau 0.740, downloaded from their official GitHub releases into `.tools/` (ignored). Python 3 with `lupa==2.8` and `jsonschema==4.25.1` executes the production Lua logic. No global packages are required.

```sh
cd /Users/zozo/Desktop/Horrorgame/codex-build
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
python3 tools/generate_data.py
.venv/bin/python -m unittest discover -s tests -v
.tools/rojo build default.project.json -o PastCurfew.rbxlx
```

If `.tools/` is absent, install the pinned tools from [Rojo releases](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.0) and [Luau releases](https://github.com/luau-lang/luau/releases/tag/0.740), or use your own `rojo`/`luau-compile` commands. For edit-and-play iteration, `rojo serve default.project.json` plus the official Studio Rojo plugin can sync this tree. A plugin is not needed to open the built place.

```sh
python3 tools/verify.py
```

This runs the automated checks, compiles every source with Luau if available, checks portable/shared modules, and rebuilds the place if Rojo is available. It fails on a check/build failure; prints explicitly skipped optional tool checks.

## Ownership and integration

Start with [INTEGRATION_CONTRACT.md](INTEGRATION_CONTRACT.md). `src/server` owns authority, `src/shared` owns config/types/pure rules and generated map data, and `src/client/Harness.client.lua` is disposable functional UI. The map JSON is extracted verbatim in meaning from Appendix A; `MapShip.lua` is generated and byte-reproducible.

`Config.BuildGreybox=false` preserves a supplied `Workspace/PastCurfewWorld` collision shell. System anchors, doors, prompts and stalker remain server-owned. Replace the visual child parts/UI, retain documented attributes and events. No dependency on `claude-build` exists.

Locked decisions supersede the old baseline's paid revives, traitors, resort and stat-adjacent progression. Salvage is the only spendable currency. Research is a capped non-spendable discovery record; physical artifacts require extraction. Set completion and hideout growth grant cosmetics/lore only. Every player starts with the same tool supply. No commerce APIs exist.

## Verification limits

Automated tests execute actual production rules, Main orchestration, prompt guards, and profile adapter against deterministic mocks. They cover settlement, all contracts, shared rewards, disconnects, retries, down/revive/bags, forged and interrupted holds, crew cap, deadline, profile locks and outages. Mocks do **not** simulate Humanoid physics, pathfinding, network ownership, streaming, touch layout, or Roblox service behavior. Studio loaded the build, but the available UI automation could not select its new window for play mode. Use [TEST_PLAN.md](TEST_PLAN.md) before integration signoff.

Presentation and audio remain placeholders. Harbor departure transfers the crew directly to the boarding corridor; an optional boat travel animation belongs to presentation. Baseline optional vents/hatches and full modular-kit generator are deferred. Regular doors, loot tiers, entity spawn, conditions and contracts vary per run. Conditions currently provide a cosmetic label/omen hook; they do not change monster stats. The baseline's 562.2-stud pacing claim is preserved as reference, not asserted for this adjusted stair/extraction adapter; measure traversal in Studio after final collisions land.
