# Status — reviewable systems slice

## Implemented

- 1–4 player authoritative loop; fixed capacity, weight/speed/noise math; solo scaling.
- Ship data preserved with documented reachable-anchor/stair adapters; collision greybox and compact water/dock/boat/coast/lighthouse placeholders.
- Optional uncertain omen, immediate departure, 9-minute runs, early extraction, final call, quick retry and basic spectator camera.
- One server-owned stalker with hearing, LOS, pathfinding, roam/investigate/hunt/lose-track/stun states and door breaking.
- Flare, noisemaker, barricade; down/drop-bag/revive/bleed capture.
- Three rotating contracts; physical objective extraction; shared meaningful-participant unlock including early extractors and disconnected participants.
- Individual Salvage and artifact extraction; capped failed-run Research imprints; one named set with cosmetic/lore completion rewards; 100-Salvage cosmetic hideout sample.
- Versioned profile adapter, exclusive session lease, load-error protection, retries, reconnect guards, settlement and shutdown saves; analytics hooks; functional PC/touch harness.

## Verification completed

- 27 automated tests pass. Actual production Rules, Main orchestration, Interactions and Profiles modules execute against deterministic mocks.
- Tests include all contract templates, early/idle sharing, deadline failure, disconnect, bag transfer, down/revive, bleed/retry, crew cap, forged/interrupted/out-of-range holds, settlement once, collection/purchase rules, foreign leases, failed loads, corrupt data and pending-release retry.
- Baseline ship JSON validates against its supplied schema; generated Lua mirror reproduces exactly; non-optional room graph connected; room dimensions/overlap checked.
- Luau 0.740 compiles every source and analyzes shared Config/Rules/Types successfully.
- Rojo 7.7.0 builds `PastCurfew.rbxlx` successfully. Studio loaded the earlier generated place, confirmed in its place-load log. Final source has been rebuilt after fixes.

## Not verified / deliberately stubbed

Studio play-mode physics/pathfinding, real prompt signal order under latency, phone/tablet layout, four-client play and live DataStore/analytics remain unverified. UI automation could open the local place but could not select its new Studio window. `TEST_PLAN.md` gives concrete integration gates. No claim that mocks prove engine behavior or production anti-cheat.

Presentation/UI/audio are placeholders. Harbor boat travel is immediate transfer. Conditions currently expose presentation hooks only. The cosmetic hideout sample persists ownership/attributes; Claude supplies its display. Optional vents/hatches, full modular-kit generation, the exact baseline pacing measurement, matchmaking, broad content, resort, traitors and commerce are deferred.

## Next integration need

Claude should consume `INTEGRATION_CONTRACT.md`, retain system anchors/doors/stalker authority, replace the world collision/visual shell and HUD, then verify solo stair traversal + stalker chase before four-client/mobile testing. First-party source and generated build are confined to `codex-build`; `horrorgame.md` and any Claude directory are untouched. No publication/deployment occurred.

## Map takeover integration

2026-09-27: initial inherited state committed before edits. Integrated project is ../claude-build/default.project.json; standalone greybox remains available here. World waits for tagged map readiness, suppresses duplicate greybox, reads PlayerSpawn/HarborDeparture/OmenPoint/HideoutAlcove and EarlyExtraction. Run bounds use the union of PlayableVolume tags. LB_mid fallback now follows its door at x=80. AgentRadius stays 1.5 in shared Config. SightTransparent parts are excluded from stalker LOS. Optional connectors remain physically closed and TraversableByAvatar=false unless authored clearances meet 4x6 vent / 4x4 hatch policy; no spec edits. Contract/artifact fallback positions use clear room centres. Existing 27 tests plus compiler/analyzer and Rojo pass. Live Studio integration is still unverified.
