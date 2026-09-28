-- Scale contract. Every number here is documented in MAP_SCALE.md with its source.
-- 1 stud = 0.28 m comes from horrorgame.md (meta.stud_to_m) and is not negotiable.
local Scale = {}

Scale.STUD_M = 0.28
Scale.GRID = 4
Scale.PROP_SNAP = 0.5

-- Baseline (spec) values: horrorgame.md §10 + kit_pieces.json
Scale.DECK_HEIGHT = 16 -- deck-to-deck, 4.48 m (spec; real accommodation decks ~2.8-3.0 m)
Scale.WALL = 1 -- wall thickness
Scale.DOOR_W = 4 -- clear width 1.12 m
Scale.DOOR_H = 8 -- clear height 2.24 m
Scale.CORRIDOR_W = 8 -- clear width 2.24 m (spec minimum)

-- Presentation values chosen by this build (see MAP_SCALE.md for reasoning)
Scale.CEILING = {
	corridorPublic = 11, -- 3.08 m finished ceiling under a 4.48 m deck: plenum hides services
	corridorCabin = 10, -- 2.80 m
	corridorCrew = 13, -- exposed deckhead with pipes, 3.64 m to the plating
	cabin = 10.5, -- 2.94 m
	publicRoom = 12.5, -- 3.50 m
	service = 13.5,
	machinery = 15,
}
Scale.RAIL_H = 3.6 -- 1.01 m: SOLAS/load-line guard rail minimum is 1.0 m
Scale.HANDRAIL_H = 3.2 -- 0.9 m wall handrail
Scale.STAIR = {
	width = 6, -- 1.68 m clear (FSS Code ch.13 minimum 0.90 m)
	riser = 1, -- 0.28 m (Roblox auto-step friendly; real 0.17-0.19 m)
	tread = 1.5, -- 0.42 m
	flightRise = 8, -- 2.24 m between landings (FSS: <= 3.5 m rise without a landing)
}
Scale.LADDER = { width = 4, riser = 1, tread = 1.1, maxAngleDeg = 55 } -- accommodation ladder <= 55 deg
Scale.AVATAR = { height = 5.2, width = 2.2, eyeHeight = 4.5, pathRadius = 1.5, pathHeight = 5 }
Scale.MIN_HEADROOM = 7 -- clear height required over any walkable surface
Scale.MIN_CLEAR_PATH = 3 -- clear width required on any required route (door leafs, furniture)

-- Ship (see MAP_SCALE.md: modelled on a late-1980s ~134 m small luxury liner)
Scale.SHIP = {
	length = 480, -- 134.4 m overall
	beam = 68, -- 19.0 m
	keelY = -15, -- draught 19 studs = 5.3 m below the 4-stud waterline
	waterY = 4,
}

function Scale.toMeters(studs)
	return studs * Scale.STUD_M
end

return Scale
