# Past Curfew integration contract — v1

Codex owns authoritative systems and invisible interaction anchors. Claude owns visual world and UI. Source map coordinates remain in data/map_ship.json. Do not access server modules from presentation code.

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
Ship bounds remain X 0–192, Y 0–48, Z 0–48; deck floor heights 32/16/0. Baseline A markers often use Y=40 while other decks use floor Y: gameplay anchors normalize to the owning deck floor + 2. Extraction uses a reachable inside pad at Z=44 (baseline exterior marker retained in data); board arrival uses corridor at X=184. Baseline LB_mid door is X=80 while extraction marker is X=96: interior extraction pad uses marker X. Greybox uses stairs within reserved footprints with traversable landings. Optional vents are not enabled in this slice; regular room doors randomize initial closed/open state and loot, entity start, conditions and contracts rotate. The full baseline generator/kit and optional connectors are future map work, not a dependency for the core slice.

Harbor is an optional compact staging area, immediately departable, with water/dock/boat/coast/lighthouse placeholders and no loot. Replace freely but retain anchors and dock spawn from Config. Claude can turn off both greybox ship and harbor via BuildGreybox and provide its collision shell.

## Extension seams
Config.Contracts defines named recovery, restore power then recover, and multi-room evidence chains. RewardPolicy in Rules is the sole contract-sharing predicate; future traitor logic must extend it with notice and consolation protection. Config.Items / Collection defines artifact sets and cosmetic-only rewards. Profile module owns versioned persistence and session lease. Analytics module exposes named events, device class and a replaceable sink; never send personal text. No monetization remotes or marketplace calls exist. Profile load/save errors block subsequent departure; a reconnect cannot replace a pending unsaved session with stale stored data.
