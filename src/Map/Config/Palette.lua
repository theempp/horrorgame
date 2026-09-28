-- Colour + material language. Principal palette (prompt): midnight navy, oxidized
-- teal, aged cream, coral, faded yellow. Supernatural violet is reserved for
-- uncanny signals and budgeted (see Budgets.violetParts).
--
-- Styles are {color, material, [transparency], [reflectance]}. Every part the
-- generator makes names a style from this table, which keeps the art direction
-- in one place and lets tests assert that no part uses an unlisted colour.
local Palette = {}

local rgb = Color3.fromRGB

Palette.colors = {
	navy = rgb(27, 42, 65),
	navyDeep = rgb(16, 24, 38),
	navyFaded = rgb(52, 66, 88),
	teal = rgb(63, 127, 122),
	tealOxide = rgb(92, 140, 128),
	tealDeep = rgb(34, 72, 72),
	cream = rgb(232, 220, 192),
	creamDirty = rgb(196, 184, 156),
	creamShadow = rgb(158, 146, 122),
	coral = rgb(224, 122, 95),
	coralFaded = rgb(186, 118, 100),
	yellow = rgb(227, 197, 103),
	yellowFaded = rgb(196, 172, 108),
	violet = rgb(142, 108, 255),
	brass = rgb(176, 141, 87),
	brassDark = rgb(122, 96, 58),
	teak = rgb(138, 106, 72),
	teakGrey = rgb(118, 104, 88),
	woodDark = rgb(84, 56, 40),
	woodRed = rgb(110, 58, 44),
	steel = rgb(110, 116, 121),
	steelDark = rgb(66, 70, 74),
	steelLight = rgb(150, 154, 152),
	paintGreen = rgb(96, 118, 104),
	paintGrey = rgb(128, 134, 128),
	rust = rgb(122, 74, 50),
	rustDark = rgb(82, 52, 38),
	antifouling = rgb(94, 47, 42),
	algae = rgb(66, 92, 74),
	black = rgb(22, 24, 28),
	white = rgb(214, 212, 204),
	glass = rgb(30, 42, 51),
	glassLit = rgb(255, 214, 150),
	rope = rgb(185, 162, 124),
	orange = rgb(214, 104, 50),
	red = rgb(160, 44, 38),
	green = rgb(52, 120, 70),
	felt = rgb(34, 84, 66),
	linen = rgb(222, 214, 198),
	stone = rgb(96, 98, 94),
	stoneDark = rgb(62, 64, 62),
	concrete = rgb(128, 126, 118),
	tarmac = rgb(58, 60, 62),
	sodium = rgb(255, 184, 108),
	emergency = rgb(255, 214, 150),
	cold = rgb(180, 210, 230),
	exitGreen = rgb(90, 200, 120),
	navRed = rgb(255, 60, 50),
	navGreen = rgb(60, 255, 120),
	navWhite = rgb(255, 244, 220),
}

local C = Palette.colors
local M = Enum.Material

-- name = { color, material, transparency, reflectance }
Palette.styles = {
	-- hull and exterior
	hull_navy = { C.navy, M.Metal },
	hull_navy_worn = { C.navyFaded, M.Metal },
	hull_antifouling = { C.antifouling, M.CorrodedMetal },
	hull_boottop = { C.algae, M.Slate },
	hull_stripe_coral = { C.coral, M.SmoothPlastic },
	hull_stripe_yellow = { C.yellowFaded, M.SmoothPlastic },
	super_cream = { C.cream, M.SmoothPlastic },
	super_cream_dirty = { C.creamDirty, M.SmoothPlastic },
	super_shadow = { C.creamShadow, M.SmoothPlastic },
	deck_teak = { C.teak, M.WoodPlanks },
	deck_teak_grey = { C.teakGrey, M.WoodPlanks },
	deck_steel = { C.paintGreen, M.DiamondPlate },
	deck_paint = { C.paintGrey, M.Concrete },
	rail_white = { C.white, M.SmoothPlastic },
	rail_teak = { C.teak, M.Wood },
	funnel_navy = { C.navyDeep, M.SmoothPlastic },
	funnel_coral = { C.coral, M.SmoothPlastic },
	funnel_yellow = { C.yellow, M.SmoothPlastic },
	funnel_cap = { C.black, M.Metal },
	window_dark = { C.glass, M.Glass, 0.15, 0.25 },
	window_frame = { C.steelDark, M.Metal },
	window_lit = { C.glassLit, M.Neon, 0.35 },
	window_violet = { C.violet, M.Neon, 0.45 },
	rust_streak = { C.rust, M.CorrodedMetal },
	salt_crust = { C.linen, M.Salt },
	lifeboat_hull = { C.orange, M.SmoothPlastic },
	lifeboat_canopy = { C.white, M.SmoothPlastic },
	davit = { C.white, M.Metal },
	machinery = { C.tealDeep, M.Metal },
	machinery_green = { C.paintGreen, M.Metal },
	-- interior: public (passenger) — aged cream, coral, brass, navy carpet
	carpet_navy = { C.navy, M.Carpet },
	carpet_coral = { C.coralFaded, M.Carpet },
	carpet_teal = { C.tealDeep, M.Carpet },
	carpet_worn = { C.navyFaded, M.Carpet },
	panel_cream = { C.cream, M.SmoothPlastic },
	panel_cream_dirty = { C.creamDirty, M.SmoothPlastic },
	panel_wood = { C.woodDark, M.Wood },
	panel_wood_red = { C.woodRed, M.Wood },
	ceiling_cream = { C.creamDirty, M.SmoothPlastic },
	ceiling_panel = { C.creamShadow, M.SmoothPlastic },
	brass = { C.brass, M.Metal },
	brass_dark = { C.brassDark, M.Metal },
	marble = { C.cream, M.Marble },
	marble_dark = { C.stoneDark, M.Marble },
	fabric_coral = { C.coral, M.Fabric },
	fabric_teal = { C.teal, M.Fabric },
	fabric_navy = { C.navy, M.Fabric },
	fabric_cream = { C.linen, M.Fabric },
	fabric_yellow = { C.yellowFaded, M.Fabric },
	felt = { C.felt, M.Fabric },
	linen = { C.linen, M.Fabric },
	wood_dark = { C.woodDark, M.Wood },
	wood_teak = { C.teak, M.Wood },
	chrome = { C.steelLight, M.Metal },
	mirror = { C.steelLight, M.Glass, 0, 0.35 },
	glass_clear = { C.cold, M.Glass, 0.55, 0.1 },
	glass_smoked = { C.glass, M.Glass, 0.35, 0.15 },
	-- interior: crew/service — painted steel, faded yellow safety, teal machinery
	steel_paint = { C.paintGrey, M.Metal },
	steel_paint_green = { C.paintGreen, M.Metal },
	steel_floor = { C.steelDark, M.DiamondPlate },
	steel_grate = { C.steel, M.DiamondPlate },
	steel_bare = { C.steel, M.Metal },
	steel_dark = { C.steelDark, M.Metal },
	steel_corroded = { C.rust, M.CorrodedMetal },
	safety_yellow = { C.yellow, M.SmoothPlastic },
	safety_coral = { C.coral, M.SmoothPlastic },
	pipe_teal = { C.teal, M.Metal },
	pipe_cream = { C.creamDirty, M.Metal },
	pipe_red = { C.red, M.Metal },
	tile_white = { C.linen, M.Slate },
	tile_teal = { C.tealOxide, M.Slate },
	linoleum = { C.creamShadow, M.SmoothPlastic },
	linoleum_teal = { C.tealOxide, M.SmoothPlastic },
	cardboard = { C.yellowFaded, M.Fabric },
	crate_wood = { C.teakGrey, M.WoodPlanks },
	paper = { C.linen, M.SmoothPlastic },
	rubber = { C.black, M.Fabric },
	black = { C.black, M.SmoothPlastic },
	plastic_cream = { C.cream, M.Plastic },
	screen_dark = { C.glass, M.Glass, 0, 0.2 },
	-- light-emitting fixtures (Neon glows without a Light instance; budgeted)
	lamp_warm = { C.emergency, M.Neon },
	lamp_sodium = { C.sodium, M.Neon },
	lamp_cold = { C.cold, M.Neon },
	lamp_exit = { C.exitGreen, M.Neon },
	lamp_violet = { C.violet, M.Neon },
	lamp_red = { C.navRed, M.Neon },
	lamp_green = { C.navGreen, M.Neon },
	lamp_white = { C.navWhite, M.Neon },
	-- harbor
	quay_concrete = { C.concrete, M.Concrete },
	quay_stone = { C.stone, M.Cobblestone },
	tarmac = { C.tarmac, M.Asphalt },
	timber = { C.teakGrey, M.WoodPlanks },
	timber_dark = { C.woodDark, M.Wood },
	shed_teal = { C.tealOxide, M.CorrodedMetal },
	shed_cream = { C.creamDirty, M.Brick },
	shed_roof = { C.steelDark, M.CorrodedMetal },
	lighthouse_white = { C.white, M.Concrete },
	lighthouse_band = { C.navy, M.Concrete },
	rock = { C.stoneDark, M.Rock },
	buoy_red = { C.red, M.SmoothPlastic },
	buoy_green = { C.green, M.SmoothPlastic },
	buoy_yellow = { C.yellow, M.SmoothPlastic },
	rope = { C.rope, M.Fabric },
	lifering = { C.orange, M.SmoothPlastic },
	-- review overlays (client-only, never built by the server)
	debug = { C.yellow, M.Neon, 0.5 },
	-- invisible volumes (zones, regions, blockers)
	volume = { C.teal, M.SmoothPlastic, 1 },
}

Palette.fonts = {
	public = "Merriweather", -- 1980s brochure serif
	display = "Michroma", -- wide display face for deck names / funnel
	crew = "Oswald", -- stencilled crew signage
	paper = "SpecialElite", -- typewritten notices, logs, manifests
	mono = "RobotoMono", -- instrument readouts
}

-- Zone palettes: identity colours used by signs, carpets and light tints.
Palette.zones = {
	Harbor = { primary = C.sodium, secondary = C.tealOxide, accent = C.yellow },
	ShipExterior = { primary = C.navy, secondary = C.cream, accent = C.coral },
	PromenadeDeck = { primary = C.cream, secondary = C.coral, accent = C.brass },
	CabinDeck = { primary = C.teal, secondary = C.cream, accent = C.brass },
	ServiceDeck = { primary = C.paintGreen, secondary = C.yellow, accent = C.navy },
	Machinery = { primary = C.tealDeep, secondary = C.yellow, accent = C.coral },
}

return Palette
