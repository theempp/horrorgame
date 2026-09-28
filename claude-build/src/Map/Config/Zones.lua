-- Major zones: each has a recognisable palette, a landmark, unique signage, a
-- prop family, a sound identity and at least one navigation anchor visible from
-- several positions (prompt requirement; asserted by tests/test_map.py).
-- Bounds are world-space AABBs {x0,y0,z0,x1,y1,z1}; lookups use first match in order.
local Zones = {}

Zones.list = {
	{
		id = "ForwardStair", displayName = "Forward Grand Stair", deck = "A/B",
		bounds = { 0, 16, 0, 32, 48, 20 },
		palette = "PromenadeDeck", lighting = "PassengerInterior", audio = "stair_public",
		landmark = "Brass deck-name plaques and a coral runner climbing past a porthole mural",
		signage = "Merriweather brass plaques: PROMENADE DECK / CABIN DECK",
		props = "Carpeted treads, brass balustrade, landing bench",
		sound = "Stairwell reverb, distant PA hiss",
		anchor = "Warm landing lamp visible from both corridor doors",
		spawn = { 16, 33, 16 },
	},
	{
		id = "AftStair", displayName = "Aft Service Stair", deck = "B/C",
		bounds = { 160, 0, 28, 192, 32, 48 },
		palette = "ServiceDeck", lighting = "ServiceInterior", audio = "stair_crew",
		landmark = "Yellow-striped steel stair with CREW ONLY stencil",
		signage = "Oswald stencils: B DECK - CABINS / C DECK - SERVICE",
		props = "Grating treads, safety-yellow rails, fire hose reel",
		sound = "Metallic footsteps, ventilation roar from below",
		anchor = "Red fire-point lamp at each landing",
		spawn = { 176, 17, 32 },
	},
	{
		id = "PromenadeDeck", displayName = "Promenade Deck (A)", deck = "A",
		bounds = { 0, 32, 0, 192, 48, 48 },
		palette = "PromenadeDeck", lighting = "PassengerInterior", audio = "public_interior",
		landmark = "Starlight Ballroom chandelier glowing through the glazed screen midships; ship mural at the fore end",
		signage = "Brass-and-cream brochure signs (Merriweather), deck directory",
		props = "Upholstered furniture, brass fittings, dining sets, casino tables",
		sound = "Soft room tone, faint big-band music box, PA crackle",
		anchor = "Chandelier (x=112) and the lit mural (x=0) both visible along the concourse",
		spawn = { 184, 33, 24 },
	},
	{
		id = "CabinDeck", displayName = "Cabin Deck (B)", deck = "B",
		bounds = { 0, 16, 0, 192, 32, 48 },
		palette = "CabinDeck", lighting = "PassengerInterior", audio = "cabin_interior",
		landmark = "Brass deck directory and grandfather clock at the midships fire screen (x=96)",
		signage = "Cabin numbers and passenger nameplates",
		props = "Beds, wardrobes, luggage, life-jacket lockers",
		sound = "Ventilation hush, hull creaks, water in pipes",
		anchor = "Grandfather clock face lit at x=96; fire-screen doors frame it from both ends",
		spawn = { 96, 17, 24 },
	},
	{
		id = "ServiceDeck", displayName = "Service & Hold (C)", deck = "C",
		bounds = { 0, 0, 0, 128, 16, 48 },
		palette = "ServiceDeck", lighting = "ServiceInterior", audio = "service_interior",
		landmark = "Yellow-lined crew alleyway with three open watertight doors and numbered frames",
		signage = "Stencilled frame numbers (FR 20..FR 68), WTD warnings",
		props = "Crates, cages, trolleys, lockers, ring-main pipes",
		sound = "Water against the hull, dripping, low machinery hum from aft",
		anchor = "Watertight door frames with red status lamps (x=48, 96)",
		spawn = { 64, 1, 24 },
	},
	{
		id = "Machinery", displayName = "Machinery Spaces (C aft)", deck = "C",
		bounds = { 128, 0, 0, 192, 16, 48 },
		palette = "Machinery", lighting = "Machinery", audio = "machinery",
		landmark = "Engine control windows over the dark engine room pit",
		signage = "DANGER 440 V, hearing-protection pictograms",
		props = "Switchboards, generators, gauges, workbenches",
		sound = "Generator drone, electrical hum, telegraph bell",
		anchor = "Orange rotating warning beacon over the switchboard door (x=144)",
		spawn = { 150, 1, 24 },
	},
	{
		id = "ShipExterior", displayName = "Ship Exterior", deck = "Exterior",
		bounds = { -260, -20, -20, 250, 130, 80 },
		palette = "ShipExterior", lighting = "ShipExterior", audio = "ship_exterior",
		landmark = "Raked navy funnel with coral and yellow bands; red port sidelight on the bridge wing",
		signage = "Ship name on bow and stern (Michroma), muster station boards",
		props = "Lifeboats, davits, bollards, mooring winches, deck chairs",
		sound = "Wind, halyards, hull slap, distant foghorn",
		anchor = "Funnel silhouette and masthead lights visible from the harbor and aft deck",
		spawn = { 224, 33, 24 },
	},
	{
		id = "SeaApproach", displayName = "Tender Approach", deck = "Sea",
		bounds = { 100, -20, 80, 400, 60, 590 },
		palette = "Harbor", lighting = "BoatApproach", audio = "sea",
		landmark = "Channel buoys and the liner's lights growing out of the fog",
		signage = "Buoy numbers",
		props = "Lateral buoys, tender",
		sound = "Tender engine, bell buoy, open-water wind",
		anchor = "Port-hand red and starboard-hand green buoy lights",
		spawn = { 200, 8, 440 },
	},
	{
		id = "Harbor", displayName = "Calder Harbour", deck = "Harbor",
		bounds = { -480, -30, 540, 720, 140, 1140 },
		palette = "Harbor", lighting = "HarborExterior", audio = "harbor",
		landmark = "Lighthouse on the west breakwater; harbor office clock",
		signage = "Harbour board signs, missing-ship posters, warehouse numerals",
		props = "Bollards, lamp posts, crates, nets, buoys, crane",
		sound = "Water lapping, dock cables, gulls absent, distant foghorn",
		anchor = "Lighthouse beam sweeping over the harbor; sodium lamps along the quay",
		spawn = { 148, 11, 727 },
	},
}

function Zones.at(pos)
	for _, z in ipairs(Zones.list) do
		local b = z.bounds
		if pos.X >= b[1] and pos.X <= b[4] and pos.Y >= b[2] and pos.Y <= b[5] and pos.Z >= b[3] and pos.Z <= b[6] then
			return z
		end
	end
	return nil
end

function Zones.get(id)
	for _, z in ipairs(Zones.list) do
		if z.id == id then return z end
	end
	return nil
end

return Zones
