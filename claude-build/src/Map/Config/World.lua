-- World layout. The ship interior box (X 0..192, Y 0..48, Z 0..48) is fixed by
-- horrorgame.md APPENDIX A and is never moved; everything else is placed around it.
--
-- Axis conventions (spec): X = ship long axis, Y = up, Z = width.
--   * Bow (fore) is -X, stern (aft) is +X (stairs S_AB "fore" at x=0, S_BC "aft").
--   * Facing the bow, starboard (right) is -Z and port (left) is +Z.
--     So spec "L" rooms (z 0..20) are starboard and "R" rooms (z 28..48) are port.
--   * Lifeboat extractions sit on the port side (z = 48), which faces the harbor.
local World = {}

World.waterY = 4 -- sea level (top of terrain water); multiple of the 4-stud voxel grid

World.sea = {
	min = { -1400, -28, -1100 },
	max = { 1400, 4, 1560 },
	-- Terrain water visual properties (Terrain.Water*). Waves are visual; gameplay
	-- never depends on them (RESEARCH_LOG: terrain water).
	waterColor = { 18, 38, 46 },
	waterTransparency = 0.12,
	waterReflectance = 0.55,
	waveSize = 0.18,
	waveSpeed = 9,
}

---------------------------------------------------------------------------
-- Ship
---------------------------------------------------------------------------
World.ship = {
	name = "MV Coral Meridian",
	line = "Meridian Blue Line",
	registry = "NASSAU",
	voyage = "88-47",
	lastSeen = "14 NOV 1988",
	bowX = -236,
	sternX = 244,
	centerZ = 24,
	halfBeam = 34, -- 68 studs = 19.0 m beam
	keelY = -15,
	sheerY = 32, -- main hull top = promenade deck (deck A floor)
	bowRise = 5, -- forecastle bulwark rises toward the stem
	bowLength = 150, -- stem to start of parallel mid-body
	sternTaperStart = 216,
	transomHalf = 26,
	-- Horizontal hull strakes. rake = how far aft the band's stem/stern sit
	-- (gives a raked bow and a counter stern); inset narrows the bilge.
	bands = {
		{ y0 = -15, y1 = -5, style = "hull_antifouling", rake = 34, sternRake = 22, inset = 6 },
		{ y0 = -5, y1 = 3, style = "hull_antifouling", rake = 24, sternRake = 12, inset = 2 },
		{ y0 = 3, y1 = 5.5, style = "hull_boottop", rake = 18, sternRake = 8, inset = 0.6 },
		{ y0 = 5.5, y1 = 23, style = "hull_navy", rake = 9, sternRake = 3, inset = 0 },
		{ y0 = 23, y1 = 24.5, style = "hull_stripe_coral", rake = 3, sternRake = 1, inset = 0 },
		{ y0 = 24.5, y1 = 25.5, style = "hull_stripe_yellow", rake = 2.5, sternRake = 0.5, inset = 0 },
		{ y0 = 25.5, y1 = 32, style = "hull_navy", rake = 0, sternRake = 0, inset = 0 },
	},
	-- Walkable exterior (outside the spec interior box). These require the
	-- gameplay bounds check to be extended — see PRESENTATION_API.md.
	aftDeck = { x0 = 192, x1 = 240, y = 32 },
	promenadePort = { x0 = -140, x1 = 192, z0 = 48, z1 = 58, y = 32 },
	promenadeStbd = { x0 = -140, x1 = 192, z0 = -10, z1 = 0, y = 32 }, -- visual only; no doors reach it
	forecastleX = -150, -- forward end of the deck A superstructure
	-- Superstructure tiers (visual shell, not walkable)
	tiers = {
		{ id = "D", y0 = 48, y1 = 64, x0 = -138, x1 = 200, z0 = -4, z1 = 52, frontBulge = 9 },
		{ id = "E", y0 = 64, y1 = 80, x0 = -122, x1 = 150, z0 = 4, z1 = 44, frontBulge = 7, bridge = true },
		{ id = "F", y0 = 80, y1 = 88, x0 = -112, x1 = -72, z0 = 12, z1 = 36, frontBulge = 3 },
	},
	deckDSlab = { x0 = -142, x1 = 204, z0 = -10, z1 = 58, y = 48 },
	funnel = { x0 = 108, x1 = 144, z0 = 12, z1 = 36, y0 = 80, layers = 7, layerH = 5.5, rakePerLayer = 2.6 },
	masts = {
		{ id = "foremast", x = -96, z = 24, y0 = 88, y1 = 118, light = "masthead" },
		{ id = "mainmast", x = 172, z = 24, y0 = 64, y1 = 124, light = "masthead" },
	},
	bridgeWing = { x0 = -112, x1 = -100, y = 64, z0 = -12, z1 = 60 },
	-- Davit stations (x centre). Boats present / missing tell the story: two
	-- boats per side were launched before the ship vanished.
	-- LB_mid: spec door is x=80 but its marker is x=96; the boat is centred at
	-- x=88 so its 28-stud hull spans both spec points.
	davitX = { 24, 56, 88, 136, 176 },
	boatsPort = { [24] = "LB_fore", [88] = "LB_mid", [176] = "LB_aft" },
	boatsStbd = { [24] = true, [88] = true, [136] = true },
	lifeboat = { length = 28, beam = 9, height = 8, hangY = 35, outboard = 6 },
	-- Anchor chain runs from the port hawse pipe into the water: the ship is anchored.
	anchorPort = { x = -214, y = 26, z = 51 },
	-- Accommodation ladder (boarding): rises aft along the port side, <= 55 deg.
	ladder = {
		footX0 = 194, footX1 = 204, footY = 7, z0 = 60, z1 = 65,
		flightX0 = 204, rise = 25, tread = 1, width = 4,
		topX0 = 229, topX1 = 236, topZ0 = 55, topZ1 = 65,
	},
}

---------------------------------------------------------------------------
-- Boarding + spawn (spec APPENDIX A "spawn")
--   outside_pos [224,40,24] and approach waypoints lie on the aft deck.
--   board_door [192,40,24] is the aft entrance to the deck A corridor.
---------------------------------------------------------------------------
World.boarding = {
	ladderFoot = { 199, 7, 62.5 },
	ladderTop = { 232.5, 32, 60 },
	aftDeckArrival = { 224, 32, 24 },
	boardDoor = { 192, 32, 24 },
}

---------------------------------------------------------------------------
-- Tender (harbor launch) and its route. 20-30 s approach (spec §1).
---------------------------------------------------------------------------
World.tender = {
	name = "CALDER BELLE",
	length = 40,
	beam = 12,
	deckY = 6,
	speed = 22, -- studs/s for review playback; ~24 s along the route below
	route = {
		{ 162, 4, 568 },
		{ 170, 4, 540 },
		{ 200, 4, 440 },
		{ 236, 4, 300 },
		{ 250, 4, 170 },
		{ 236, 4, 100 },
		{ 208, 4, 71 },
	},
	mooredCenter = { 162, 4, 568 },
	alongsideCenter = { 208, 4, 71 },
}

---------------------------------------------------------------------------
-- Harbor ("Calder Harbour"): compact prelude north of the ship (+Z).
---------------------------------------------------------------------------
World.harbor = {
	name = "Calder Harbour",
	quayY = 10,
	quayFrontZ = 700,
	land = { x0 = -460, x1 = 700, z0 = 700, z1 = 1120 },
	quay = { x0 = -40, x1 = 360, z0 = 700, z1 = 744 },
	pier = { x0 = 150, x1 = 166, z0 = 612, z1 = 700 },
	pierHead = { x0 = 136, x1 = 180, z0 = 598, z1 = 612 },
	pontoon = { x0 = 146, x1 = 172, z0 = 588, z1 = 598, y = 6.5 },
	gangway = { x0 = 156, x1 = 160, zTop = 598, zBottom = 591 },
	office = { x0 = 96, x1 = 132, z0 = 708, z1 = 734, h = 15 },
	briefing = { 138, 10, 720 },
	departure = { 162, 6.5, 594 },
	spawns = { { 146, 10, 724 }, { 151, 10, 724 }, { 146, 10, 730 }, { 151, 10, 730 } },
	spawnFacing = { 0, 0, -1 }, -- look south: pier, channel, then the liner in the fog
	omen = { 70, 6, 690 },
	slipway = { x0 = 60, x1 = 80, zTop = 726, zBottom = 676, yTop = 10, yBottom = 1 },
	boathouse = { x0 = 50, x1 = 90, z0 = 726, z1 = 752, h = 14 },
	warehouses = {
		{ id = "Warehouse3", x0 = 196, x1 = 256, z0 = 718, z1 = 770, h = 22, label = "3", style = "shed_teal" },
		{ id = "ColdStore", x0 = 272, x1 = 322, z0 = 716, z1 = 758, h = 18, label = "COLD STORE", style = "shed_cream" },
		{ id = "Customs", x0 = 6, x1 = 44, z0 = 730, z1 = 760, h = 14, label = "H.M. CUSTOMS", style = "shed_cream" },
	},
	fuelTanks = { { -24, 10, 770 }, { -8, 10, 782 } },
	crane = { 234, 10, 706 },
	lampX = { -16, 16, 48, 80, 112, 144, 176, 208, 240, 272, 304, 336 },
	lampZ = 704,
	lighthouse = { x = -160, z = 600, baseY = 16, height = 58, radius = 7 },
	westBreakwater = { { -150, 620 }, { -60, 628 }, { 40, 632 } },
	eastBreakwater = { { 560, 700 }, { 500, 640 }, { 440, 590 }, { 400, 552 } },
	eastBeacon = { 400, 14, 552 },
	buoys = {
		{ kind = "port", pos = { 252, 4, 500 } },
		{ kind = "starboard", pos = { 150, 4, 505 } },
		{ kind = "port", pos = { 290, 4, 390 } },
		{ kind = "starboard", pos = { 186, 4, 380 } },
		{ kind = "special", pos = { 330, 4, 250 } },
	},
	boundary = {
		-- invisible walls: keep the harbor compact (players can still swim near the pier)
		{ -44, -10, 560, -40, 60, 800 },
		{ 360, -10, 560, 364, 60, 800 },
		{ -44, -10, 796, 364, 60, 800 },
		{ -44, -10, 556, 364, 60, 560 },
	},
	ladderX = { 40, 120, 200, 280 },
}

---------------------------------------------------------------------------
-- Review camera path for the harbor-to-ship reveal (review mode only)
---------------------------------------------------------------------------
World.revealPath = {
	{ pos = { 149, 16, 736 }, look = { 150, 12, 600 }, t = 0 },
	{ pos = { 158, 14, 640 }, look = { 60, 30, 24 }, t = 5 },
	{ pos = { 190, 9, 470 }, look = { 20, 50, 24 }, t = 11 },
	{ pos = { 250, 10, 250 }, look = { 60, 60, 24 }, t = 17 },
	{ pos = { 236, 12, 110 }, look = { 150, 60, 30 }, t = 23 },
	{ pos = { 214, 14, 76 }, look = { 232, 34, 58 }, t = 27 },
}

return World
