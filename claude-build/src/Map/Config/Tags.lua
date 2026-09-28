-- CollectionService tags and their attribute contracts. PRESENTATION_API.md is
-- generated from / checked against this table by tests.
--
-- Every tagged anchor also carries: MapId (unique), Zone (Zones id), Deck.
local Tags = {}

Tags.required = {
	LootSpawn = { attrs = { "Tier", "RoomId", "SpecId" }, desc = "Loot placement node (spec loot_nodes + presentation search spots)" },
	HeavyLootSpawn = { attrs = { "Tier", "RoomId", "SpecId" }, desc = "Tier-3 heavy loot (weight 30) node" },
	ContractSpawn = { attrs = { "ContractKind", "Step", "RoomId" }, desc = "Contract objective anchor (Codex Config.Contracts kinds)" },
	EvidenceSpawn = { attrs = { "EvidenceKind", "RoomId" }, desc = "Lore/evidence item placement (manifests, logs, notes)" },
	PoweredDoor = { attrs = { "ConnectionId", "RoomId", "Circuit" }, desc = "Doorway that needs ship power (contract/power gating)" },
	BarricadePoint = { attrs = { "ConnectionId", "Width", "Height" }, desc = "Doorway that can be barricaded (spec: any std door)" },
	HidePoint = { attrs = { "HideType", "SpecId", "RoomId" }, desc = "Hiding spot (spec hiding_spots) - prop built around it" },
	NoiseSurface = { attrs = { "NoiseMultiplier", "SurfaceKind" }, desc = "Volume whose footsteps/impacts are louder" },
	StalkerNode = { attrs = { "Links", "Deck" }, desc = "Navigation graph node for the stalker (Links = comma ids)" },
	StalkerZone = { attrs = { "Deck", "Priority" }, desc = "Volume the stalker patrols / searches" },
	PlayerSpawn = { attrs = { "SpawnGroup", "Index" }, desc = "Player spawn transform (harbor)" },
	HarborDeparture = { attrs = { "TenderId" }, desc = "Where players board the tender" },
	BoardingPoint = { attrs = { "Stage" }, desc = "Boarding sequence stages: LadderFoot, LadderTop, AftDeck, BoardDoor" },
	EarlyExtraction = { attrs = { "ExtractionId", "SpecId" }, desc = "Extraction usable when armed (spec lifeboats)" },
	FinalExtraction = { attrs = { "ExtractionId", "SpecId" }, desc = "Extraction opened by the final call (all lifeboats)" },
	CapturePoint = { attrs = { "Deck", "RoomId" }, desc = "Where a captured player is held for recovery" },
	ReviveSafeArea = { attrs = { "Deck", "Reason" }, desc = "Volume out of patrol sightlines, good for reviving" },
	MajorZone = { attrs = { "ZoneId", "DisplayName" }, desc = "Major navigation zone volume" },
	AudioZone = { attrs = { "Profile", "Reverb" }, desc = "Ambient audio zone volume" },
	StreamingRegion = { attrs = { "RegionId", "SpecId" }, desc = "Streaming chunk volume (one per deck + harbor + exterior)" },
}

-- Additional tags this build provides.
Tags.extra = {
	RotatingDetail = { attrs = { "SpinPeriod" }, desc = "Client-animated radar detail" },
	PlayableVolume = { attrs = { "VolumeId", "SpecExtension" }, desc = "Space a player may legitimately occupy (for bounds checks)" },
	ContractBriefing = { attrs = {}, desc = "Harbor briefing board" },
	OmenPoint = { attrs = { "OmenId" }, desc = "Optional harbor omen investigation spot" },
	HideoutAlcove = { attrs = {}, desc = "Harbor office alcove for the hideout display" },
	TenderPath = { attrs = { "Index" }, desc = "Ordered tender route nodes" },
	OptionalConnector = { attrs = { "ConnectionId", "Kind", "OpenProbMin", "OpenProbMax", "TraversableByAvatar" }, desc = "Spec optional vent/hatch" },
	DoorVisual = { attrs = { "ConnectionId" }, desc = "Presentation door leaf; swings with the Codex door anchor" },
	ShipLight = { attrs = { "Circuit", "Priority" }, desc = "Light managed by power state + quality tiers" },
	NavLight = { attrs = { "NavKind" }, desc = "Navigation / landmark light that stays on in every tier" },
	DetailHigh = { attrs = {}, desc = "Decorative part hidden on the Low tier" },
	SightTransparent = { attrs = {}, desc = "Glass: blocks movement, not sight. Include in LOS raycast exclusion" },
	PlayBoundary = { attrs = {}, desc = "Invisible containment wall" },
	FlareBracket = { attrs = {}, desc = "Suggested flare placement (kit flare_bracket)" },
	NoisemakerAnchor = { attrs = {}, desc = "Suggested noisemaker landing zone (kit noisemaker_anchor)" },
	PatrolWaypoint = { attrs = { "RouteId", "Index", "Loop" }, desc = "Spec patrol_routes waypoint (normalised to floor)" },
	EntitySpawn = { attrs = { "SpecId" }, desc = "Spec entity_spawns node (normalised to floor)" },
	Landmark = { attrs = { "ZoneId", "LandmarkId" }, desc = "Navigation landmark" },
	RoomVolume = { attrs = { "RoomId", "Theme", "Deck" }, desc = "Spec room box with its programme" },
	Clock = { attrs = { "ClockTime", "Behaviour" }, desc = "Clock prop (conflicting times)" },
}

-- Minimum counts per required tag in a complete build (tests assert these).
Tags.minimumCounts = {
	LootSpawn = 18, HeavyLootSpawn = 6, ContractSpawn = 6, EvidenceSpawn = 10, PoweredDoor = 2,
	BarricadePoint = 32, HidePoint = 12, NoiseSurface = 8, StalkerNode = 30, StalkerZone = 6,
	PlayerSpawn = 4, HarborDeparture = 1, BoardingPoint = 4, EarlyExtraction = 3, FinalExtraction = 3,
	CapturePoint = 3, ReviveSafeArea = 4, MajorZone = 9, AudioZone = 9, StreamingRegion = 6,
}

return Tags
