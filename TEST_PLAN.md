# Studio integration gates

Run the built place in Play and local Server & Clients; do not publish without separate authorization. Use an isolated test universe for live persistence later. Record pass/fail and observed latency in this file when exercised. All items below remain **not yet run in Studio play mode**.

| Scenario | Expected result |
|---|---|
| Solo dock + touch emulator | Read goal and special reward without location spoilers; omen optional; depart immediately; all touch controls fit portrait and landscape; default Roblox thumbstick/jump remain usable. |
| Ship traversal | Visit every deck through both reserved stair shafts; closed doors open; no landing/head collision; rooms reachable without vents. Time empty sneak and loaded return from C_L1 to aft extraction; tune only adapter geometry after measuring. |
| Authority | Two players hold same loot: exactly one gets it. Over-capacity pickup rejected. Remote spam, malformed payloads, out-of-range/interrupted holds and trigger without a completed hold grant nothing. Inspect server weight/speed after local attribute tampering. |
| Solo stalker | Roam → Investigate via noise → Hunt via close LOS; flare pauses 3 seconds; decoy retargets; barricade delays ~4 seconds; monster traverses stairs and closed doors. Unloaded solo can outrun, full bag creates chase pressure. |
| Crew 2 / 3 / 4 | Fixed scaling 14/15/16 hunt speed, hearing .9/1/1.1. Late joins spectate, departures do not reduce locked scaling. No traitors. |
| Down/revive/capture | Bag stays on ship; 5-second continuous teammate hold revives at temporary half speed with 10-second protection. Bleed after 45 seconds; solo failure transitions to retry. Character reset cannot respawn into run. |
| Contract rotation | Retry cycles luggage, power + secured room, three-room evidence. Each final objective is physical bag loot, can be dropped/recovered, and requires extraction. Over-capacity final pickup can be retried. |
| Reward sharing | Early-extracted, captured and disconnected meaningful participants receive unlock if another extracts objective; idle participants do not. Normal Salvage/artifacts remain individual. All fail retains ≤3 Research, zero new Salvage/artifacts. |
| Final call | At 60 seconds remaining, all lifeboats enable. Deadline captures remaining players. Repeated events/heartbeat do not duplicate settlement. |
| Progression | Extract three named artifacts over runs; set grants coat, plaque and lore only. Buy one 100-Salvage alcove; insufficient funds/double purchase rejected. Tools/capacity/speeds unchanged. |
| Retry + reconnect | Three consecutive crew retries clear bags, prompts, monster and revive anchors; counts reset. Reconnect during live crew run cannot replay a settlement or revive oneself. |
| Persistence (later isolated live test) | Two servers cannot own same profile; failed load blocks play; transient save retries; disconnect and close release leases; no progress overwritten by defaults. Verify reconnection after outage/lease expiry. |
| Analytics | Dock departure, first loot, first contract progress, first danger, extraction/failure, retry, input class and session completion logged once at intended cadence. Live delivery requires separate authorized deployment. |

Known scope: coarse movement correction is a guard, not a complete anti-cheat. Studio mocks cannot prove collision/pathfinding, prompt signal order under latency, mobile usability or DataStore behavior. First integration priority is solo traversal + stalker chase, then four clients + mobile emulator.
