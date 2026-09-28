# Past Curfew integration contract — v2

codex-build owns authoritative systems and interaction anchors. claude-build owns map geometry, map tags and presentation; the gameplay HUD remains in codex-build. Source map coordinates remain in data/map_ship.json. Do not access server modules from presentation code.

## Roblox hierarchy
- `ReplicatedStorage/PastCurfew/Shared`: Config, Types, Rules, MapShip modules.
- `ReplicatedStorage/PastCurfew/Remotes/Action`: client → server `(action: string, payload?: string)`; only Sneak (`on`/`off`), Flare, Noisemaker, Barricade, Drop, Retry, Depart, BuyDecoration, Device (`Touch`/`Keyboard`/`Gamepad`). No client prices, damage, loot amounts, or positions.
- `.../Feedback`: server → one client, short text notification.
- `ReplicatedStorage/PastCurfew/State`: replicated attributes listed below.
- `Workspace/PastCurfewWorld`: replaceable greybox. Set Shared.Config.BuildGreybox=false when supplying presentation geometry. Keep collision geometry at map coordinates and preserve stair access.
- `Workspace/PastCurfewAnchors`: system-owned Parts with `PCId`, `PCKind`, `Available`, `DisplayName` attributes and built-in ProximityPrompts. Skin with noncolliding children or show your own visual at their CFrame. Do not destroy anchors or prompts. Kind: Loot, Extraction, Contract, Door, Omen, Departure, Hideout, Bag, Revive. Anchors are deliberately visible in this harness.
- `Workspace/PastCurfewStalker`: server-controlled placeholder rig. Attributes `State` (Roam/Investigate/Hunt/LoseTrack/Stunned), `TargetUserId`. Replace visual children only, keep Humanoid and HumanoidRootPart.

## State attributes
`Phase`: Dock/Run/Results; `RunId`: string; `EndsAt`: server timestamp (Workspace:GetServerTimeNow); `ContractTitle`, `ContractGoal`, `ContractReward`: dock-visible; `ContractProgress`, `ContractRequired`, `ContractSecured`; `Condition`: weather/tension label; `Omen`: uncertain clue after inspection (feedback only); `FinalCall`: boolean; `TraitorsEnabled`: always false.

## Player attributes
`PCStatus`: Loading/Dock/Active/Downed/Captured/Extracted/Spectating; `Weight`, `Capacity` (100), `NoiseRadius`, `Sneaking`; `Salvage`, `Research`, `HideoutLevel`; `Flares`, `Noisemakers`, `Barricades`; `BleedOutAt`; `LastPayout`; `ContractUnlocked`; `CollectionCount`, `CollectionComplete`; `SaveState`: Loading/Ready/Offline/Error. `Indoors`: first-person camera enforcement. `InputClass`: Touch/Keyboard/Gamepad/Unknown. Attributes are display mirrors, never authority. Inventory is deliberately private server state.

## Interaction and devices
Built-in prompts provide keyboard E + touch interaction. Prompt duration is mirrored server-side with distance, LOS, state and continuous hold checks; custom UI should invoke the built-in prompt input path, not grant interactions. Action controls use ContextActionService touch buttons; disable the placeholder client when integrating a complete UI and implement the above actions. Minimum 48 px targets; responsive HUD, no hover-only controls. Server Feedback is ephemeral and can be rendered as a toast.

Extraction is individual: hold at either enabled lifeboat for 3 seconds; normal loot banks only for its carrier. Final call at 60 seconds opens all lifeboats; deadline captures remaining players. A secured contract unlocks for every meaningful participant, including previously extracted or captured players, at settlement. Late joiners spectate until next dock. Crew size locks at departure (1–4); no mid-run scaling or role assignment. `Retry` is accepted only in Results and returns the whole lobby to Dock. Depart is available immediately at dock.

## Presentation ownership / map adapters
The integrated project is ../claude-build/default.project.json; review.project.json omits systems. World waits for PastCurfewMap.Ready and suppresses the standalone greybox when map modules are mounted. No module copies are required.

Run bounds use the union of PlayableVolume tags. PlayerSpawn Index=1 supplies dock spawn, HarborDeparture supplies departure, and OmenPoint/HideoutAlcove supply their interactions. Config.DockPosition remains only the standalone fallback. EarlyExtraction anchors supply lifeboat pads; LB_mid uses x=80, z=44, following its door instead of the old x=96 marker. Interior floor heights remain 32/16/0, with interaction anchors normalized above the floor.

AgentRadius is 1.5. SightTransparent glass is excluded from stalker LOS. Optional spec vents (2x4) and hatches (2x2) remain physically closed; systems require explicit TraversableByAvatar=true and authored clearances of at least 4x6 / 4x4 before enabling them. No source spec change is implied.

ContractSpawn tags choose rooms by ContractKind and Step. Restoring power sets Workspace.PastCurfewMap.PowerState to On; departure resets Emergency. Door presentation follows the gameplay anchor's Closed attribute. Map-generated volumes and visual anchors never grant rewards or replace server interaction validation. Harbor departure still transfers immediately; the 27-second reveal is a review-camera feature.

See ../claude-build/docs/PRESENTATION_API.md for the tag schema and ../claude-build/docs/MAP_REVIEW_CHECKLIST.md for pending Studio gates.

## Extension seams
Config.Contracts defines named recovery, restore power then recover, and multi-room evidence chains. RewardPolicy in Rules is the sole contract-sharing predicate; future traitor logic must extend it with notice and consolation protection. Config.Items / Collection defines artifact sets and cosmetic-only rewards. Profile module owns versioned persistence and session lease. Analytics module exposes named events, device class and a replaceable sink; never send personal text. No monetization remotes or marketplace calls exist. Profile load/save errors block subsequent departure; a reconnect cannot replace a pending unsaved session with stale stored data.
