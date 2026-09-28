-- Audio zones and emitter hooks. No audio assets are embedded or uploaded by
-- this build (no verified licences). Every layer has an empty `asset` slot; the
-- client AudioZones runtime only creates AudioPlayer/AudioEmitter instances for
-- layers whose asset id has been filled in with a verified Roblox-licensed or
-- original sound. Until then the zones still exist, are tagged AudioZone, show
-- in review mode and drive room-tone/reverb metadata.
local Audio = {}

-- Zone profiles: `bed` = looping ambience, `spot` = positional one-shots/loops.
Audio.profiles = {
	harbor = { reverb = "Outdoor", bed = { "water_lap", "wind_low", "dock_cables" }, spot = { "foghorn_distant", "bell_buoy" } },
	sea = { reverb = "Outdoor", bed = { "open_water", "wind_high", "tender_engine" }, spot = { "foghorn_distant", "bell_buoy" } },
	ship_exterior = { reverb = "Outdoor", bed = { "wind_rigging", "hull_slap" }, spot = { "halyard_clank", "davit_creak", "foghorn_distant" } },
	public_interior = { reverb = "LargeRoom", bed = { "room_tone_public", "ventilation_soft" }, spot = { "pa_crackle", "music_box" } },
	cabin_interior = { reverb = "SmallRoom", bed = { "room_tone_cabin", "hull_creak" }, spot = { "pipe_knock", "distant_impact" } },
	service_interior = { reverb = "Hallway", bed = { "room_tone_steel", "water_in_bilge" }, spot = { "drip", "distant_impact" } },
	machinery = { reverb = "Hangar", bed = { "generator_drone", "electrical_hum" }, spot = { "telegraph_bell", "steam_hiss" } },
	stair_public = { reverb = "Stairwell", bed = { "room_tone_public" }, spot = { "pa_crackle" } },
	stair_crew = { reverb = "Stairwell", bed = { "ventilation_roar" }, spot = { "metal_tick" } },
}

-- Layer catalogue: description is the brief for sourcing/recording the sound.
Audio.layers = {
	water_lap = { asset = "", volume = 0.5, desc = "Small waves against stone quay and timber piles" },
	wind_low = { asset = "", volume = 0.35, desc = "Low onshore wind, no gusts" },
	wind_high = { asset = "", volume = 0.45, desc = "Open-water wind with spray" },
	wind_rigging = { asset = "", volume = 0.45, desc = "Wind through rails, stays and davit falls" },
	dock_cables = { asset = "", volume = 0.3, desc = "Mooring lines and steel cables creaking under load" },
	foghorn_distant = { asset = "", volume = 0.6, desc = "Distant two-tone foghorn, long decay" },
	bell_buoy = { asset = "", volume = 0.35, desc = "Irregular bell buoy clang" },
	open_water = { asset = "", volume = 0.5, desc = "Open sea swell" },
	tender_engine = { asset = "", volume = 0.45, desc = "Small diesel launch engine, idle to cruise" },
	hull_slap = { asset = "", volume = 0.45, desc = "Water slapping a large steel hull" },
	halyard_clank = { asset = "", volume = 0.3, desc = "Flag halyard against a mast" },
	davit_creak = { asset = "", volume = 0.3, desc = "Lifeboat davit arm creaking" },
	room_tone_public = { asset = "", volume = 0.25, desc = "Carpeted large room tone" },
	room_tone_cabin = { asset = "", volume = 0.2, desc = "Small furnished room tone" },
	room_tone_steel = { asset = "", volume = 0.25, desc = "Bare steel corridor tone" },
	ventilation_soft = { asset = "", volume = 0.2, desc = "Distant air-conditioning" },
	ventilation_roar = { asset = "", volume = 0.35, desc = "Close ventilation trunk" },
	pa_crackle = { asset = "", volume = 0.35, desc = "Public-address system switching on, no voice" },
	music_box = { asset = "", volume = 0.2, desc = "Original music-box motif, detuned" },
	hull_creak = { asset = "", volume = 0.3, desc = "Hull working in a swell" },
	pipe_knock = { asset = "", volume = 0.3, desc = "Water hammer in pipes" },
	distant_impact = { asset = "", volume = 0.45, desc = "Heavy impact far away in the ship" },
	water_in_bilge = { asset = "", volume = 0.3, desc = "Water sloshing in a bilge" },
	drip = { asset = "", volume = 0.25, desc = "Single drips into a puddle" },
	generator_drone = { asset = "", volume = 0.55, desc = "Diesel generator running" },
	electrical_hum = { asset = "", volume = 0.3, desc = "50/60 Hz switchboard hum" },
	telegraph_bell = { asset = "", volume = 0.4, desc = "Engine-order telegraph bell" },
	steam_hiss = { asset = "", volume = 0.3, desc = "Pressure release hiss" },
	metal_tick = { asset = "", volume = 0.2, desc = "Metal contracting in the cold" },
	threat_low = { asset = "", volume = 0.3, desc = "Threat escalation bed: sub-bass swell" },
	threat_high = { asset = "", volume = 0.45, desc = "Threat escalation bed: dissonant string cluster" },
}

-- Threat escalation layers are global (not positional); the client fades them
-- by Workspace.PastCurfewStalker.State (Codex contract) or MapThreat attribute.
Audio.threat = { Roam = 0, Investigate = 0.35, LoseTrack = 0.35, Hunt = 1, Stunned = 0.2 }

-- Emitter budget per client (see PERFORMANCE_BUDGET.md)
Audio.maxActiveEmitters = 8

return Audio
