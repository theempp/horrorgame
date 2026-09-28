# Past Curfew

Roblox horror game source and local review workflow.

- `horrorgame.md`: original design specification; do not edit during implementation.
- `claude-build/`: map, presentation, review mode, map tests and documentation.
- `codex-build/`: authoritative gameplay, HUD, data and systems tests.

Start with [map handoff](claude-build/HANDOFF.md), [build instructions](claude-build/README.md), and [Studio review checklist](claude-build/docs/MAP_REVIEW_CHECKLIST.md).

Build the integrated game from `claude-build/default.project.json`; `claude-build/review.project.json` is map-only. Generated places, local tool binaries and Python environments are intentionally excluded. Install development dependencies per each folder's README.

The two original repositories were imported with their commit histories preserved. This root repository is the GitHub source of truth. In the original local workspace, nested Git metadata remains for recovery; use root-level Git commands when committing the combined project.

Headless checks passed before import: 16 map tests, 27 systems tests, compilation and both Rojo builds. Live Studio physics, streaming, multiplayer and device testing remain pending. Nothing has been published to Roblox.
