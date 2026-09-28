-- Room programme: gives every spec room slot (APPENDIX A) a purpose, zone,
-- materials, signage, lighting and story. Footprints and doors stay exactly as
-- specified; only the interior identity is defined here.
--
-- Adjacency logic (see README "Ship programme"):
--   Deck A  Promenade Deck  - passenger public rooms; galley beside dining room
--           (spec vent c_opt_A_L2_A_L3 becomes the service pass-through hatch);
--           ballroom stage trap (spec hatch c_hatch_AB) drops into the
--           entertainers' quarters on deck B. Lifeboat muster rooms on the port side.
--   Deck B  Cabin Deck      - staterooms, the named suite, security, infirmary,
--           luggage room; linen room chute (spec hatch c_hatch_BC) drops to the laundry.
--   Deck C  Service & Hold  - crew alleyway ("Burma Road"), stores and cargo
--           forward (deepest loot), crew spaces midships, machinery aft.
--
-- family: public | cabin | crew | service | hold | machinery
-- ceiling: finished ceiling height above the floor (studs); see Scale.CEILING
-- loot / hide rest props are placed from the spec nodes, not from this table.
local Rooms = {}

Rooms.byId = {
	-- DECK A ---------------------------------------------------------------
	A_L2 = {
		name = "Main Galley", sign = "GALLEY", signStyle = "crew", family = "service", zone = "PromenadeDeck",
		theme = "galley", ceiling = 12, floor = "tile_white", wall = "tile_white", trim = "steel_bare",
		story = "Pans still on the ranges; the pass-through hatch to the dining room is propped open.",
		noise = "crockery", audio = "galley",
	},
	A_L3 = {
		name = "The Coral Room", sign = "THE CORAL ROOM", subSign = "DINING", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "dining", ceiling = 12.5, floor = "carpet_coral", wall = "panel_cream",
		trim = "brass", hero = true,
		story = "Dinner service for Voyage 88-47, abandoned between courses. A birthday cake, uncut.",
		noise = "glass", audio = "public",
	},
	A_L4 = {
		name = "Compass Rose Bar", sign = "COMPASS ROSE BAR", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "bar", ceiling = 12, floor = "carpet_navy", wall = "panel_wood",
		trim = "brass", story = "Glasses still on the bar top; the piano lid is open.", audio = "public",
	},
	A_L5 = {
		name = "Meridian Boutique", sign = "BOUTIQUE", subSign = "DUTY FREE", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "boutique", ceiling = 11.5, floor = "marble", wall = "panel_cream",
		trim = "chrome", story = "Display cases half emptied, price tags in 1988 dollars.", audio = "public",
	},
	A_L6 = {
		name = "Purser's Office", sign = "PURSER", subSign = "RECEPTION", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "purser", ceiling = 11.5, floor = "marble", wall = "panel_wood_red",
		trim = "brass", hero = true, powered = true,
		story = "Every key hook is empty except one. The manifest is open to the last page.",
		audio = "public",
	},
	A_R1 = {
		name = "Observation Lounge", sign = "OBSERVATION LOUNGE", subSign = "MUSTER STATION A", signStyle = "public",
		family = "public", zone = "PromenadeDeck", theme = "lounge", ceiling = 12.5, floor = "carpet_teal",
		wall = "panel_cream", trim = "brass", muster = "A",
		story = "Armchairs turned to face the windows, as if everyone watched something outside.",
		audio = "public",
	},
	A_R2 = {
		name = "Radio Room", sign = "RADIO ROOM", subSign = "OFFICERS ONLY", signStyle = "crew", family = "crew",
		zone = "PromenadeDeck", theme = "radio", ceiling = 11, floor = "linoleum_teal", wall = "steel_paint",
		trim = "steel_dark", hero = true,
		story = "The log's last entry is timed 23:52. The receiver is still warm with a violet glow.",
		audio = "electrical",
	},
	A_R3 = {
		name = "Card Room & Library", sign = "CARD ROOM", subSign = "MUSTER STATION B", signStyle = "public",
		family = "public", zone = "PromenadeDeck", theme = "library", ceiling = 12, floor = "carpet_navy",
		wall = "panel_wood", trim = "brass", muster = "B",
		story = "A bridge game abandoned mid-trick; a library book overdue since 1988.", audio = "public",
	},
	A_R4 = {
		name = "Starlight Ballroom", sign = "STARLIGHT BALLROOM", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "ballroom", ceiling = 27, floor = "wood_teak", wall = "panel_cream",
		trim = "brass", hero = true, doubleHeight = true, glazedToCorridor = true,
		story = "Streamers, a stage set for the late show, one follow-spot still pointed at an empty mark.",
		noise = "stage", audio = "ballroom",
	},
	A_R5 = {
		name = "Coral Club Casino", sign = "CORAL CLUB", subSign = "CASINO", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "casino", ceiling = 11.5, floor = "carpet_coral", wall = "panel_wood",
		trim = "brass", hero = true, story = "Chips mid-bet on the roulette layout; the dealer's shoe half-dealt.",
		audio = "public",
	},
	A_R6 = {
		name = "Lido Café", sign = "LIDO CAFÉ", subSign = "MUSTER STATION C", signStyle = "public", family = "public",
		zone = "PromenadeDeck", theme = "cafe", ceiling = 11.5, floor = "linoleum", wall = "panel_cream",
		trim = "chrome", muster = "C",
		story = "Coffee cups by the lifeboat door. Condensation still beads on the glass.", audio = "public",
	},
	-- DECK B ---------------------------------------------------------------
	B_L2 = {
		name = "Staterooms 204-206", sign = "204  206", signStyle = "cabin", family = "cabin", zone = "CabinDeck",
		theme = "cabin_pair", ceiling = 10.5, floor = "carpet_teal", wall = "panel_cream", trim = "wood_dark",
		cabins = { { no = "204", guest = "MR & MRS R. OKONJO" }, { no = "206", guest = "MISS D. VALE" } },
		story = "Suitcases open on the beds; life jackets dragged out of the cupboard.", audio = "cabin",
	},
	B_L3 = {
		name = "Staterooms 208-210", sign = "208  210", signStyle = "cabin", family = "cabin", zone = "CabinDeck",
		theme = "cabin_pair", ceiling = 10.5, floor = "carpet_teal", wall = "panel_cream", trim = "wood_dark",
		cabins = { { no = "208", guest = "DR H. MARCHETTI" }, { no = "210", guest = "MR T. ASHWORTH" } },
		story = "Beds turned down for the night. One porthole is open and dripping.", audio = "cabin",
	},
	B_L4 = {
		name = "Housekeeping & Linen", sign = "HOUSEKEEPING", subSign = "CREW ONLY", signStyle = "crew",
		family = "crew", zone = "CabinDeck", theme = "linen", ceiling = 10.5, floor = "linoleum",
		wall = "steel_paint", trim = "steel_dark",
		story = "Linen carts abandoned; the laundry chute hatch in the floor is unlatched.", audio = "cabin",
	},
	B_L5 = {
		name = "Deluxe Stateroom 214", sign = "214", signStyle = "cabin", family = "cabin", zone = "CabinDeck",
		theme = "deluxe", ceiling = 10.5, floor = "carpet_coral", wall = "panel_cream", trim = "brass",
		cabins = { { no = "214", guest = "MR & MRS E. HALVORSEN" } },
		story = "Evening clothes laid out for a dinner no one reached.", audio = "cabin",
	},
	B_L6 = {
		name = "Ship's Hospital", sign = "HOSPITAL", subSign = "SURGERY 09:00-11:00", signStyle = "public",
		family = "crew", zone = "CabinDeck", theme = "hospital", ceiling = 10.5, floor = "linoleum_teal",
		wall = "tile_white", trim = "chrome",
		story = "Two cots, one used. The duty log records a passenger 'not on the manifest'.", audio = "cabin",
	},
	B_R1 = {
		name = "Security Office", sign = "SECURITY", subSign = "MASTER-AT-ARMS", signStyle = "crew",
		family = "crew", zone = "CabinDeck", theme = "security", ceiling = 10.5, floor = "linoleum",
		wall = "steel_paint", trim = "steel_dark",
		story = "Every monitor shows the same empty corridor. The key safe hangs open.", audio = "electrical",
	},
	B_R2 = {
		name = "Outside Staterooms 105-107", sign = "105  107", signStyle = "cabin", family = "cabin",
		zone = "CabinDeck", theme = "cabin_pair", ceiling = 10.5, floor = "carpet_teal", wall = "panel_cream",
		trim = "wood_dark",
		cabins = { { no = "105", guest = "MR P. LINDQVIST" }, { no = "107", guest = "MRS A. DEMIR" } },
		story = "Tickets for a shore excursion that never ran, pinned by a cold coffee cup.", audio = "cabin",
	},
	B_R3 = {
		name = "Luggage Room", sign = "LUGGAGE ROOM", subSign = "UNCLAIMED BAGGAGE", signStyle = "crew",
		family = "crew", zone = "CabinDeck", theme = "luggage", ceiling = 10.5, floor = "steel_floor",
		wall = "steel_paint", trim = "safety_yellow",
		story = "Unclaimed bags, labels for cabins that do not exist on this ship.", audio = "cabin",
	},
	B_R4 = {
		name = "Entertainers' Quarters", sign = "ARTISTES", subSign = "STAGE DOOR", signStyle = "crew",
		family = "crew", zone = "CabinDeck", theme = "dressing", ceiling = 10.5, floor = "linoleum",
		wall = "panel_cream_dirty", trim = "wood_dark",
		story = "Mirror bulbs still lit around one make-up station. The stage trap ladder hangs above.",
		audio = "cabin",
	},
	B_R5 = {
		name = "The Halvorsen Suite", sign = "SUITE 1", subSign = "THE HALVORSEN SUITE", signStyle = "public",
		family = "cabin", zone = "CabinDeck", theme = "suite", ceiling = 11, floor = "carpet_navy",
		wall = "panel_wood_red", trim = "brass", hero = true,
		cabins = { { no = "SUITE 1", guest = "MR & MRS E. HALVORSEN" } },
		story = "Packed trunks by the door. The carriage clock runs backwards. Two names, one of them twice.",
		audio = "suite",
	},
	-- DECK C ---------------------------------------------------------------
	C_L1 = {
		name = "Forward Cargo Hold", sign = "No.1 HOLD", subSign = "BONDED STORES", signStyle = "crew",
		family = "hold", zone = "ServiceDeck", theme = "cargo", ceiling = 15, floor = "steel_floor",
		wall = "steel_paint_green", trim = "safety_yellow", deepest = true,
		story = "Crates stencilled for Bermuda, seals intact, salt-rimed where the hull wept.",
		noise = "metal", audio = "hold",
	},
	C_L2 = {
		name = "Provision & Wine Store", sign = "PROVISIONS", subSign = "COLD STORE 2", signStyle = "crew",
		family = "hold", zone = "ServiceDeck", theme = "wine", ceiling = 13.5, floor = "steel_floor",
		wall = "steel_paint", trim = "safety_yellow", story = "Racks of 1980s vintages; the cold store is still cold.",
		audio = "hold",
	},
	C_L3 = {
		name = "Crew Mess", sign = "CREW MESS", signStyle = "crew", family = "crew", zone = "ServiceDeck",
		theme = "crewmess", ceiling = 12, floor = "linoleum", wall = "steel_paint", trim = "safety_yellow",
		story = "Breakfast trays for the 06:40 watch change. The roster is crossed out in one hand.",
		audio = "crew",
	},
	C_L4 = {
		name = "Laundry", sign = "LAUNDRY", signStyle = "crew", family = "service", zone = "ServiceDeck",
		theme = "laundry", ceiling = 12, floor = "steel_floor", wall = "tile_white", trim = "steel_dark",
		story = "A drum of whites still wet. The chute from housekeeping spills sheets onto the floor.",
		noise = "metal", audio = "service",
	},
	C_L5 = {
		name = "Main Switchboard", sign = "MAIN SWITCHBOARD", subSign = "DANGER 440 V", signStyle = "crew",
		family = "machinery", zone = "Machinery", theme = "switchboard", ceiling = 13, floor = "rubber",
		wall = "steel_paint_green", trim = "safety_yellow", hero = true, contractPower = true,
		story = "Breakers thrown by hand, one taped in the OFF position with a note: 'NOT AGAIN'.",
		audio = "electrical",
	},
	C_R1 = {
		name = "Strongroom", sign = "STRONGROOM", subSign = "AUTHORISED PERSONNEL", signStyle = "crew",
		family = "hold", zone = "ServiceDeck", theme = "strongroom", ceiling = 12, floor = "steel_floor",
		wall = "steel_dark", trim = "brass", powered = true, deepest = true,
		story = "Safe-deposit boxes for passenger valuables, a ledger signed at 23:40.", audio = "hold",
	},
	C_R2 = {
		name = "Baggage Hold", sign = "BAGGAGE HOLD", signStyle = "crew", family = "hold", zone = "ServiceDeck",
		theme = "baggage", ceiling = 15, floor = "steel_floor", wall = "steel_paint_green", trim = "safety_yellow",
		story = "Steamer trunks in wire cages, some cages opened from inside.", noise = "metal", audio = "hold",
	},
	C_R3 = {
		name = "Crew Quarters", sign = "CREW BERTHS", subSign = "C-DECK 301-306", signStyle = "crew",
		family = "crew", zone = "ServiceDeck", theme = "crewberths", ceiling = 10.5, floor = "linoleum_teal",
		wall = "steel_paint", trim = "safety_yellow",
		story = "Bunks with photos taped to the bulkhead; one bunk stripped to the frame.", audio = "crew",
	},
	C_R4 = {
		name = "Engineers' Workshop", sign = "WORKSHOP", signStyle = "crew", family = "machinery",
		zone = "Machinery", theme = "workshop", ceiling = 13, floor = "steel_floor", wall = "steel_paint_green",
		trim = "safety_yellow", story = "A lathe stopped mid-cut; the tool board has a gap shaped like a fire axe.",
		noise = "metal", audio = "machinery",
	},
	C_R5 = {
		name = "Generator Room", sign = "AUX GENERATORS", subSign = "HEARING PROTECTION", signStyle = "crew",
		family = "machinery", zone = "Machinery", theme = "generator", ceiling = 15, floor = "steel_grate",
		wall = "steel_paint_green", trim = "safety_yellow",
		story = "No.2 generator idles with no fuel in the day tank.", noise = "metal", audio = "machinery",
	},
	C_L6 = {
		name = "Engine Control Room", sign = "ENGINE CONTROL", signStyle = "crew", family = "machinery",
		zone = "Machinery", theme = "enginecontrol", ceiling = 13, floor = "linoleum", wall = "steel_paint",
		trim = "safety_yellow", hero = true,
		story = "The telegraph rings FULL ASTERN. The engine room below is dark and much too deep.",
		audio = "machinery",
	},
}

-- Stair towers (spec stairs footprints) get their own identity.
Rooms.stairs = {
	S_AB = {
		name = "Forward Grand Stair", sign = "FORWARD STAIR", family = "public", zone = "PromenadeDeck",
		wall = "panel_cream", floor = "carpet_navy", tread = "carpet_coral", rail = "brass",
		landingSign = { A = "PROMENADE DECK", B = "CABIN DECK" },
	},
	S_BC = {
		name = "Aft Service Stair", sign = "CREW STAIR", family = "crew", zone = "ServiceDeck",
		wall = "steel_paint", floor = "steel_floor", tread = "steel_grate", rail = "safety_yellow",
		landingSign = { B = "B DECK - CABINS", C = "C DECK - SERVICE" },
	},
}

-- Corridors (spec zones CORR_A/B/C).
Rooms.corridors = {
	CORR_A = {
		name = "Promenade Deck Concourse", deckName = "PROMENADE DECK", family = "public", zone = "PromenadeDeck",
		floor = "carpet_navy", runner = "carpet_coral", wall = "panel_cream", dado = "panel_wood",
		ceilingH = 11, ceiling = "ceiling_cream", trim = "brass", handrail = "brass",
		fireDoorsX = { 64, 128 }, lightEvery = 16,
	},
	CORR_B = {
		name = "Cabin Deck Passage", deckName = "CABIN DECK", family = "cabin", zone = "CabinDeck",
		floor = "carpet_teal", runner = "carpet_navy", wall = "panel_cream", dado = "panel_wood",
		ceilingH = 10, ceiling = "ceiling_panel", trim = "wood_dark", handrail = "wood_teak",
		fireDoorsX = { 64, 128 }, lightEvery = 16,
	},
	CORR_C = {
		name = "Crew Alleyway (\"Burma Road\")", deckName = "C DECK - SERVICE", family = "crew", zone = "ServiceDeck",
		floor = "steel_floor", runner = "safety_yellow", wall = "steel_paint", dado = "steel_paint_green",
		ceilingH = 13, ceiling = "steel_dark", trim = "safety_yellow", handrail = "safety_yellow",
		watertightDoorsX = { 48, 96, 144 }, lightEvery = 12,
	},
}

return Rooms
