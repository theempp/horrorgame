-- Exterior and harbor kit: mooring gear, lights, buoys, lifeboats, tender,
-- lighthouse. Local-space convention as in Props (base = ground contact point,
-- -Z local = front).
local Map = script.Parent.Parent
local Props = require(Map.Kit.Props)

local Maritime = {}

local P, VC = Props.P, Props.VC
local DECOR = { collide = false, query = false, shadow = false, detail = true }
local SOFT = { collide = false, query = false, shadow = false }

local function M(ctx, parent, name)
	return ctx:model(parent, name)
end

function Maritime.bollard(ctx, parent, base, style)
	local m = M(ctx, parent, "Bollard")
	VC(ctx, m, base, "Post", 0.8, 0, 2.2, 0, 0, style or "steel_dark")
	VC(ctx, m, base, "Cap", 1.1, 2.2, 2.6, 0, 0, style or "steel_dark", { shadow = false })
	return m
end

function Maritime.bitts(ctx, parent, base, style)
	local m = M(ctx, parent, "Bitts")
	P(ctx, m, base, "Base", 4.2, 0.4, 1.6, 0, 0.2, 0, style or "steel_dark", { shadow = false })
	VC(ctx, m, base, "PostA", 0.65, 0.4, 2.6, -1.3, 0, style or "steel_dark")
	VC(ctx, m, base, "PostB", 0.65, 0.4, 2.6, 1.3, 0, style or "steel_dark")
	return m
end

function Maritime.cleat(ctx, parent, base)
	local m = M(ctx, parent, "Cleat")
	P(ctx, m, base, "Horn", 2, 0.35, 0.5, 0, 0.6, 0, "steel_dark", DECOR)
	P(ctx, m, base, "Foot", 0.6, 0.5, 0.5, 0, 0.25, 0, "steel_dark", DECOR)
	return m
end

-- lifebuoy ring on a wall/rail: cf = centre, LookVector = outward
function Maritime.lifebuoy(ctx, parent, cf, backStyle)
	local m = M(ctx, parent, "Lifebuoy")
	local n = cf.LookVector
	ctx:cyl(m, "Ring", cf.Position, cf.Position + n * 0.35, 1.2, "lifering", SOFT)
	ctx:cyl(m, "Hole", cf.Position + n * 0.05, cf.Position + n * 0.4, 0.6, backStyle or "super_cream", SOFT)
	return m
end

function Maritime.ropeCoil(ctx, parent, base, r)
	local m = M(ctx, parent, "RopeCoil")
	VC(ctx, m, base, "Coil", r or 1.2, 0, 0.45, 0, 0, "rope", DECOR)
	return m
end

function Maritime.ropeLine(ctx, parent, a, b, sag)
	local m = M(ctx, parent, "Rope")
	local mid = (a + b) / 2 - Vector3.new(0, sag or 0.6, 0)
	ctx:bar(m, "RopeA", a, mid, 0.18, "rope", DECOR)
	ctx:bar(m, "RopeB", mid, b, 0.18, "rope", DECOR)
	return m
end

function Maritime.fender(ctx, parent, a, b)
	local m = M(ctx, parent, "Fender")
	ctx:cyl(m, "Fender", a, b, 0.8, "rubber", { shadow = false })
	return m
end

function Maritime.lampPost(ctx, parent, base, lit, circuit)
	local m = M(ctx, parent, "LampPost")
	VC(ctx, m, base, "Pole", 0.25, 0, 14, 0, 0, "steel_dark", { shadow = false })
	P(ctx, m, base, "Arm", 0.25, 0.25, 2.6, 0, 13.9, -1.2, "steel_dark", DECOR)
	local head = P(ctx, m, base, "Head", 1.2, 0.5, 1.6, 0, 13.6, -2.4, lit and "lamp_sodium" or "steel_dark", { collide = false, shadow = false })
	if lit then
		local l = ctx:light(head, "SpotLight", { Range = 34, Brightness = 2.2, Color = "sodium", Angle = 110, Face = "Bottom" },
			{ circuit = circuit or "Harbor", priority = "Normal" })
		l:SetAttribute("Landmark", true)
	end
	return m
end

-- IALA region A lateral buoys: port = red can, starboard = green cone.
function Maritime.buoy(ctx, parent, base, kind, index)
	local m = M(ctx, parent, "Buoy_" .. kind .. "_" .. tostring(index))
	local style = kind == "port" and "buoy_red" or (kind == "starboard" and "buoy_green" or "buoy_yellow")
	VC(ctx, m, base, "Float", 2.2, -1.5, 1.5, 0, 0, style)
	VC(ctx, m, base, "Tower", 0.9, 1.5, 6, 0, 0, style, { shadow = false })
	if kind == "port" then
		P(ctx, m, base, "TopmarkCan", 1.2, 1.2, 1.2, 0, 6.8, 0, style, DECOR)
	else
		ctx:ball(m, "TopmarkCone", (base * CFrame.new(0, 6.9, 0)).Position, 0.75, style, DECOR)
	end
	local lampStyle = kind == "port" and "lamp_red" or (kind == "starboard" and "lamp_green" or "buoy_yellow")
	local lamp = ctx:ball(m, "Lamp", (base * CFrame.new(0, 7.9, 0)).Position, 0.4, lampStyle, SOFT)
	local col = kind == "port" and "navRed" or (kind == "starboard" and "navGreen" or "yellow")
	ctx:light(lamp, "PointLight", { Range = 14, Brightness = 2, Color = col }, { circuit = "Nav", priority = "Nav", nav = "Buoy_" .. kind })
	ctx:attrs(m, { BuoyKind = kind, FlashPeriod = kind == "special" and 5 or 4 })
	return m
end

function Maritime.capstan(ctx, parent, base)
	local m = M(ctx, parent, "Capstan")
	VC(ctx, m, base, "Base", 1.8, 0, 0.5, 0, 0, "steel_dark", { shadow = false })
	VC(ctx, m, base, "Drum", 1.2, 0.5, 2.8, 0, 0, "steel_dark")
	VC(ctx, m, base, "Cap", 1.5, 2.8, 3.2, 0, 0, "steel_dark", DECOR)
	return m
end

function Maritime.windlass(ctx, parent, base)
	local m = M(ctx, parent, "Windlass")
	P(ctx, m, base, "Bed", 7, 1, 4, 0, 0.5, 0, "machinery_green")
	ctx:cyl(m, "Gypsy", (base * CFrame.new(-2.4, 2.2, 0)).Position, (base * CFrame.new(2.4, 2.2, 0)).Position, 1.3, "steel_dark")
	P(ctx, m, base, "Motor", 2, 2, 2.4, 0, 2, 1.8, "machinery_green", { shadow = false })
	return m
end

function Maritime.ventilator(ctx, parent, base, h)
	local m = M(ctx, parent, "Ventilator")
	h = h or 5
	VC(ctx, m, base, "Trunk", 0.9, 0, h, 0, 0, "super_cream")
	ctx:ball(m, "Cowl", (base * CFrame.new(0, h + 0.4, -0.3)).Position, 1.4, "super_cream", { shadow = false })
	ctx:cyl(m, "Mouth", (base * CFrame.new(0, h + 0.5, -1.2)).Position, (base * CFrame.new(0, h + 0.5, -1.6)).Position, 0.9, "black", DECOR)
	return m
end

function Maritime.deckChairStack(ctx, parent, base, n)
	local m = M(ctx, parent, "DeckChairs")
	for i = 1, n do
		P(ctx, m, base, "Chair" .. i, 2.2, 0.35, 5.2, (i % 2) * 0.2, 0.2 + i * 0.4, 0, i % 3 == 0 and "fabric_coral" or "rail_teak", { shadow = i == n })
	end
	return m
end

function Maritime.flagstaff(ctx, parent, base, h)
	local m = M(ctx, parent, "Flagstaff")
	VC(ctx, m, base, "Staff", 0.2, 0, h, 0, 0, "rail_white", { shadow = false })
	P(ctx, m, base, "Flag", 0.08, 2.2, 3.6, 0, h - 1.4, 1.9, "fabric_navy", SOFT)
	P(ctx, m, base, "FlagTear", 0.09, 1.2, 1.2, 0, h - 1.9, 3.2, "fabric_coral", SOFT)
	return m
end

function Maritime.netPile(ctx, parent, base, style)
	local m = M(ctx, parent, "Nets")
	P(ctx, m, base, "Pile", 4, 1.4, 3, 0, 0.7, 0, style or "fabric_teal", { shadow = false })
	P(ctx, m, base, "Floats", 3.4, 0.5, 0.5, 0.2, 1.5, -0.8, "safety_coral", DECOR)
	return m
end

function Maritime.fuelTank(ctx, parent, base, r, h)
	local m = M(ctx, parent, "FuelTank")
	VC(ctx, m, base, "Tank", r, 0, h, 0, 0, "super_cream_dirty")
	VC(ctx, m, base, "Band", r + 0.1, h * 0.8, h * 0.85, 0, 0, "safety_coral", DECOR)
	VC(ctx, m, base, "Roof", r - 0.4, h, h + 0.6, 0, 0, "steel_dark", DECOR)
	return m
end

-- Dockside crane: lattice approximated by a few heavy members (silhouette first).
function Maritime.crane(ctx, parent, base)
	local m = M(ctx, parent, "Crane")
	P(ctx, m, base, "Portal", 10, 3, 10, 0, 1.5, 0, "steel_dark")
	P(ctx, m, base, "Tower", 4, 26, 4, 0, 16, 0, "safety_yellow")
	P(ctx, m, base, "Cab", 6, 5, 6, 0, 31.5, 0, "safety_yellow")
	ctx:bar(m, "Jib", (base * CFrame.new(0, 33, 0)).Position, (base * CFrame.new(0, 48, -34)).Position, { 1.4, 1.4 }, "safety_yellow")
	ctx:bar(m, "Stay", (base * CFrame.new(0, 38, 2)).Position, (base * CFrame.new(0, 48, -34)).Position, 0.3, "steel_dark", DECOR)
	ctx:bar(m, "Hook", (base * CFrame.new(0, 48, -34)).Position, (base * CFrame.new(0, 26, -34)).Position, 0.15, "steel_dark", DECOR)
	P(ctx, m, base, "Block", 1, 1.5, 1, 0, 25, -34, "steel_dark", DECOR)
	return m
end

-- 1980s partially enclosed lifeboat (FRP), ~28 x 9 studs (7.8 x 2.5 m).
-- cf: centre of the keel line, LookVector = bow direction.
function Maritime.lifeboat(ctx, parent, cf, id, weathered)
	local m = M(ctx, parent, "Lifeboat_" .. id)
	local L, B, H = 28, 9, 8
	local hull = weathered and "lifeboat_hull" or "lifeboat_hull"
	P(ctx, m, cf, "Hull", B - 1.5, 2.2, L - 6, 0, 1.1, 0, hull)
	P(ctx, m, cf, "Topside", B, 2.6, L - 4, 0, 3.4, 0, hull)
	P(ctx, m, cf, "Gunwale", B + 0.3, 0.4, L - 3.6, 0, 4.8, 0, "lifeboat_canopy", { shadow = false })
	-- tapered ends: two rotated blocks each
	for _, s in ipairs({ -1, 1 }) do
		local end1 = P(ctx, m, cf, "End" .. s, B * 0.72, 3.6, 5, 0, 2.6, s * (L / 2 - 2.6), hull)
		end1.CFrame = cf * CFrame.new(0, 2.6, s * (L / 2 - 2.8)) * CFrame.Angles(s * math.rad(-12), 0, 0)
	end
	P(ctx, m, cf, "CanopyFore", B - 0.8, 3, 8, 0, 6.3, -L / 2 + 6.5, "lifeboat_canopy")
	P(ctx, m, cf, "CanopyAft", B - 0.8, 3, 7, 0, 6.3, L / 2 - 6, "lifeboat_canopy")
	P(ctx, m, cf, "Stripe", B + 0.35, 0.5, L - 4.2, 0, 3.8, 0, "safety_yellow", DECOR)
	P(ctx, m, cf, "WindowA", 0.1, 0.8, 3, B / 2 - 0.35, 6.5, -L / 2 + 6.5, "window_dark", DECOR)
	P(ctx, m, cf, "WindowB", 0.1, 0.8, 3, -B / 2 + 0.35, 6.5, -L / 2 + 6.5, "window_dark", DECOR)
	ctx:attrs(m, { LifeboatId = id })
	return m
end

-- Gravity davit pair with falls. topCf: davit head line centre (inboard end on
-- the deck edge), outward = direction toward the sea. boatPresent draws falls
-- to the boat; otherwise the falls hang slack to the water (launched boat).
function Maritime.davits(ctx, parent, deckEdge, outward, halfSpan, boatTopY, boatPresent, waterY)
	local m = M(ctx, parent, "Davits")
	local along = Vector3.new(1, 0, 0)
	for _, s in ipairs({ -1, 1 }) do
		local foot = deckEdge + along * (s * halfSpan)
		local elbow = foot + Vector3.new(0, 6, 0) + outward * 1.5
		local head = foot + Vector3.new(0, 7.5, 0) + outward * 7.2
		ctx:bar(m, "Arm" .. s, foot, elbow, { 1.1, 1.1 }, "davit")
		ctx:bar(m, "Jib" .. s, elbow, head, { 0.9, 0.9 }, "davit")
		local lowY = boatPresent and boatTopY or (waterY + 0.5)
		ctx:bar(m, "Fall" .. s, head, Vector3.new(head.X, lowY, head.Z), 0.15, "rope", DECOR)
		if not boatPresent then
			ctx:bar(m, "Block" .. s, Vector3.new(head.X, lowY + 1.2, head.Z), Vector3.new(head.X, lowY, head.Z), 0.6, "steel_dark", DECOR)
		end
	end
	return m
end

-- Harbor launch (tender). cf = centre at the waterline, LookVector = bow.
function Maritime.tender(ctx, parent, cf, name)
	local m = M(ctx, parent, "Tender")
	local L, B = 40, 12
	P(ctx, m, cf, "Hull", B - 1, 3, L - 6, 0, 0.5, 0, "hull_navy")
	P(ctx, m, cf, "Topside", B, 2, L - 4, 0, 2.4, 0, "super_cream")
	local bow = P(ctx, m, cf, "Bow", B * 0.7, 4, 7, 0, 1.4, -L / 2 + 3, "hull_navy")
	bow.CFrame = cf * CFrame.new(0, 1.4, -L / 2 + 3.2) * CFrame.Angles(math.rad(14), 0, 0)
	P(ctx, m, cf, "Deck", B - 1.2, 0.3, L - 5, 0, 2.15, 0, "deck_teak")
	P(ctx, m, cf, "Cabin", B - 3, 5.2, 12, 0, 4.9, -3, "super_cream")
	P(ctx, m, cf, "CabinRoof", B - 2.4, 0.5, 13, 0, 7.7, -3, "hull_navy", { shadow = false })
	P(ctx, m, cf, "Windscreen", B - 3.2, 1.8, 0.2, 0, 6.2, -9.1, "window_dark", { shadow = false })
	local lamp = P(ctx, m, cf, "CabinLamp", 1.2, 0.3, 1.2, 0, 7.4, -3, "lamp_warm", { collide = false, shadow = false })
	ctx:light(lamp, "PointLight", { Range = 14, Brightness = 1.4, Color = "emergency" }, { circuit = "Harbor", priority = "Normal" })
	-- gunwale rails with a boarding gap on the port side (+X local is starboard when bow is -Z)
	P(ctx, m, cf, "RailStbd", 0.3, 1.6, L - 8, B / 2 - 0.2, 3.2, 1, "rail_white", { shadow = false })
	P(ctx, m, cf, "RailPortAft", 0.3, 1.6, 10, -B / 2 + 0.2, 3.2, 10, "rail_white", { shadow = false })
	P(ctx, m, cf, "RailPortFwd", 0.3, 1.6, 10, -B / 2 + 0.2, 3.2, -8, "rail_white", { shadow = false })
	P(ctx, m, cf, "Transom", B, 3, 0.4, 0, 2.2, L / 2 - 2, "hull_navy", { shadow = false })
	-- navigation lights
	local red = ctx:ball(m, "PortLight", (cf * CFrame.new(-B / 2 + 0.6, 7.6, -7)).Position, 0.3, "lamp_red", SOFT)
	ctx:light(red, "PointLight", { Range = 8, Brightness = 1.5, Color = "navRed" }, { circuit = "Nav", priority = "Nav", nav = "TenderPort" })
	ctx:ball(m, "StbdLight", (cf * CFrame.new(B / 2 - 0.6, 7.6, -7)).Position, 0.3, "lamp_green", SOFT)
	ctx:ball(m, "MastLight", (cf * CFrame.new(0, 11, -4)).Position, 0.3, "lamp_white", SOFT)
	P(ctx, m, cf, "Mast", 0.2, 3.2, 0.2, 0, 9.3, -4, "rail_white", DECOR)
	ctx:attrs(m, { TenderName = name })
	return m
end

-- Lighthouse: tapering tower (stacked drums), gallery, lantern, rotating beam.
function Maritime.lighthouse(ctx, parent, baseCf, height, radius)
	local m = M(ctx, parent, "Lighthouse")
	local segs = 6
	for i = 1, segs do
		local y0 = (i - 1) * height / segs
		local y1 = i * height / segs
		local r = radius * (1 - 0.28 * (i - 0.5) / segs)
		VC(ctx, m, baseCf, "Tower" .. i, r, y0, y1, 0, 0, (i == 3 or i == 5) and "lighthouse_band" or "lighthouse_white")
	end
	VC(ctx, m, baseCf, "Gallery", radius * 0.95, height, height + 0.8, 0, 0, "steel_dark", { shadow = false })
	local lantern = VC(ctx, m, baseCf, "Lantern", radius * 0.5, height + 0.8, height + 5, 0, 0, "lamp_white", { collide = false, shadow = false, transparency = 0.2 })
	VC(ctx, m, baseCf, "Roof", radius * 0.6, height + 5, height + 6.4, 0, 0, "lighthouse_band", { shadow = false })
	ctx:light(lantern, "PointLight", { Range = 30, Brightness = 2.5, Color = "navWhite" }, { circuit = "Nav", priority = "Nav", nav = "Lighthouse" })
	-- beam: long thin neon blades, rotated on the client (Runtime/Lighthouse)
	local beam = M(ctx, m, "Beam")
	local c = (baseCf * CFrame.new(0, height + 3, 0)).Position
	for _, s in ipairs({ -1, 1 }) do
		ctx:part(beam, "Blade" .. s, Vector3.new(120, 1.6, 4), CFrame.new(c + Vector3.new(s * 62, 0, 0)), "lamp_white",
			{ collide = false, query = false, shadow = false, transparency = 0.82 })
	end
	ctx:attrs(beam, { RotationPeriod = 10, PivotY = c.Y, PivotX = c.X, PivotZ = c.Z, SkipBeatEvery = 7 })
	ctx:tag(beam, "Landmark")
	beam:SetAttribute("LandmarkId", "LighthouseBeam")
	beam:SetAttribute("ZoneId", "Harbor")
	return m
end

return Maritime
