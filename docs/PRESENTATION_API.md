# Presentation API

## Ownership and assembly

`Workspace/PastCurfewMap` owns map geometry and `Manifest` marker parts. `ServerStorage/PastCurfewMapVariants` stores inactive dressers. The sibling gameplay code owns `Workspace/PastCurfewAnchors`, prompts, authoritative door collisions, player state, loot and stalker behavior. Map clients never require server modules. Rojo mounts both source trees without copying modules.

The map root sets `Ready=true` only after assembly and `PowerState="Emergency"` initially. The World adapter waits for readiness and suppresses its fallback greybox when the presentation Map mount is present. Rebuilding destroys only the owned map root, its named lighting effects, and inactive variants. Terrain fills are bounded to the map-owned sea box.

MapBuilder.build accepts `seed` and `variant` (v1 or v2). It returns stats and issues. Building v2 changes furniture layout while retaining shell, door graph and fixed gameplay anchors. Runtime variant switching is not exposed; rebuild in a review session instead.

## State

- Map root `PowerState`: On / Emergency / Blackout. The server resets Emergency at departure; the power contract sets On. Only presentation behavior is affected by this attribute; it grants no gameplay permissions.
- Player `MapQuality`: Low / Balanced / High; client presentation setting.
- Player `ReviewPower`: local preview override, set only by the review UI.
- Authoritative system door `Closed`: DoorPresenter matches a DoorVisual's ConnectionId to PCId/name in PastCurfewAnchors. Map door leafs never collide; gameplay door blocks own collision.
- `ReplicatedStorage/PastCurfew.MapReview`: project-defined boolean enabling the review UI. The review project omits game systems.

All manifest markers carry MapId, Zone and Deck. SpecId identifies source records; presentation-only additions use an explicit presentation identifier. Geometry and tags are discoverable through CollectionService. Query tagged instances again or handle add/remove events when streaming; do not cache a client instance forever without checking its parent.

## Required tag contracts

The following table is generated from Config/Tags.lua. Counts are minimums, not a request to instantiate gameplay rewards at every marker.

| Tag | Minimum | Attributes | Purpose |
|---|---:|---|---|
| AudioZone | 9 | Profile, Reverb | Ambient audio zone volume |
| BarricadePoint | 32 | ConnectionId, Width, Height | Doorway that can be barricaded (spec: any std door) |
| BoardingPoint | 4 | Stage | Boarding sequence stages: LadderFoot, LadderTop, AftDeck, BoardDoor |
| CapturePoint | 3 | Deck, RoomId | Where a captured player is held for recovery |
| ContractSpawn | 6 | ContractKind, Step, RoomId | Contract objective anchor (Codex Config.Contracts kinds) |
| EarlyExtraction | 3 | ExtractionId, SpecId | Extraction usable when armed (spec lifeboats) |
| EvidenceSpawn | 10 | EvidenceKind, RoomId | Lore/evidence item placement (manifests, logs, notes) |
| FinalExtraction | 3 | ExtractionId, SpecId | Extraction opened by the final call (all lifeboats) |
| HarborDeparture | 1 | TenderId | Where players board the tender |
| HeavyLootSpawn | 6 | Tier, RoomId, SpecId | Tier-3 heavy loot (weight 30) node |
| HidePoint | 12 | HideType, SpecId, RoomId | Hiding spot (spec hiding_spots) - prop built around it |
| LootSpawn | 18 | Tier, RoomId, SpecId | Loot placement node (spec loot_nodes + presentation search spots) |
| MajorZone | 9 | ZoneId, DisplayName | Major navigation zone volume |
| NoiseSurface | 8 | NoiseMultiplier, SurfaceKind | Volume whose footsteps/impacts are louder |
| PlayerSpawn | 4 | SpawnGroup, Index | Player spawn transform (harbor) |
| PoweredDoor | 2 | ConnectionId, RoomId, Circuit | Doorway that needs ship power (contract/power gating) |
| ReviveSafeArea | 4 | Deck, Reason | Volume out of patrol sightlines, good for reviving |
| StalkerNode | 30 | Links, Deck | Navigation graph node for the stalker (Links = comma ids) |
| StalkerZone | 6 | Deck, Priority | Volume the stalker patrols / searches |
| StreamingRegion | 6 | RegionId, SpecId | Streaming chunk volume (one per deck + harbor + exterior) |

## Additional tags

| Tag | Attributes | Purpose |
|---|---|---|
| Clock | ClockTime, Behaviour | Clock prop (conflicting times) |
| ContractBriefing |  | Harbor briefing board |
| DetailHigh |  | Decorative part hidden on the Low tier |
| DoorVisual | ConnectionId | Presentation door leaf; swings with the Codex door anchor |
| EntitySpawn | SpecId | Spec entity_spawns node (normalised to floor) |
| FlareBracket |  | Suggested flare placement (kit flare_bracket) |
| HideoutAlcove |  | Harbor office alcove for the hideout display |
| Landmark | ZoneId, LandmarkId | Navigation landmark |
| NavLight | NavKind | Navigation / landmark light that stays on in every tier |
| NoisemakerAnchor |  | Suggested noisemaker landing zone (kit noisemaker_anchor) |
| OmenPoint | OmenId | Optional harbor omen investigation spot |
| OptionalConnector | ConnectionId, Kind, OpenProbMin, OpenProbMax, TraversableByAvatar | Spec optional vent/hatch |
| PatrolWaypoint | RouteId, Index, Loop | Spec patrol_routes waypoint (normalised to floor) |
| PlayBoundary |  | Invisible containment wall |
| PlayableVolume | VolumeId, SpecExtension | Space a player may legitimately occupy (for bounds checks) |
| RoomVolume | RoomId, Theme, Deck | Spec room box with its programme |
| RotatingDetail | SpinPeriod | Client-animated radar detail |
| ShipLight | Circuit, Priority | Light managed by power state + quality tiers |
| SightTransparent |  | Glass: blocks movement, not sight. Include in LOS raycast exclusion |
| TenderPath | Index | Ordered tender route nodes |

## Adapter details

PlayerSpawn Index=1 supplies the harbor spawn, offset +3 Y for the HumanoidRootPart. HarborDeparture supplies the departure prompt. EarlyExtraction is keyed by ExtractionId; LB_mid is (80,34,44), not the partition at x=96. BoardingPoint stages are route metadata. Existing gameplay departure still places players directly inside the boarding corridor.

PlayableVolume is a union of OBB volumes for interior, promenade, aft deck, ladder and harbor. Gameplay retains its speed-based travel check alongside this containment test. ContractSpawn determines authored room selection by ContractKind and Step. Evidence/loot/hide extras remain presentation opportunities; gameplay decides which are active. StalkerNode Links form corridor chains connected through explicit stair/landing nodes. Actual stalking uses PathfindingService. SightTransparent geometry is excluded from stalker LOS.

OptionalConnector is never enabled solely because a round wants it open. The gameplay policy requires authored ClearWidth/ClearHeight meeting 4x6 vent or 4x4 hatch minimums plus TraversableByAvatar=true. Baseline panels lack these clearances and stay closed. No source data dimensions were changed.

AudioZone Profile and Reverb are metadata. All audio layer asset strings are empty; no playback runtime is installed. NoiseSurface similarly exposes a future surface multiplier hook; this map does not override authoritative movement noise.
