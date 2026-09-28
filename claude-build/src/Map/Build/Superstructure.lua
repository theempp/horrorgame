-- Superstructure: the non-playable forward deck-A block, tiers D/E/F with
-- window bands, bridge + wings, funnel, masts, lifeboats/davits and the
-- navigation lights. Silhouette first: this is the landmark seen from the
-- harbor and in thumbnails, so mass and profile matter more than detail.
--
-- Navigation-light storytelling (COLREGs): a vessel at anchor should show
-- anchor lights, not sidelights and masthead lights. The Coral Meridian lies
-- at anchor (chain in the water) yet shows underway lights - wrong in a way a
-- sailor would notice. See RESEARCH_LOG "Navigation lights".
local Map = script.Parent.Parent
local World = require(Map.Config.World)
local Rooms = require(Map.Config.Rooms)
local Maritime = require(Map.Kit.Maritime)
local Rails = require(Map.Kit.Rails)
local Signs = require(Map.Kit.Signs)
local Palette = require(Map.Config.Palette)

local Super = {}
local S = World.ship

local function frontX(tier, z)
	local zc = (tier.z0 + tier.z1) / 2
	local hz = (tier.z1 - tier.z0) / 2
	local t = (z - zc) / hz
	return tier.x0 - tier.frontBulge * (1 - t * t)
end

-- A tier: side walls with a window band, curved front, straight aft wall, roof.
local function tier(ctx, parent, t, opts)
	opts = opts or {}
	local m = ctx:model(parent, "Tier" .. t.id)
	local wallStyle = opts.wall or "super_cream"
	local y0, y1 = t.y0, t.y1
	local bandY0, bandY1 = y0 + (opts.bandLow or 4), y0 + (opts.bandHigh or 10)
	-- side walls: solid below/above the band, glass strip in the band
	for _, zSide in ipairs({ { t.z0, t.z0 + 1, -1 }, { t.z1 - 1, t.z1, 1 } }) do
		local za, zb, dir = zSide[1], zSide[2], zSide[3]
		local tag = dir > 0 and "P" or "S"
		ctx:box(m, "SideLow" .. tag, t.x0, y0, za, t.x1, bandY0, zb, wallStyle)
		ctx:box(m, "SideHigh" .. tag, t.x0, bandY1, za, t.x1, y1, zb, wallStyle)
		ctx:box(m, "SideGlass" .. tag, t.x0, bandY0, za + 0.2, t.x1, bandY1, zb - 0.2, "window_dark")
		local face = dir > 0 and zb or za
		for x = t.x0 + 8, t.x1 - 4, 8 do
			ctx:box(m, "Mullion" .. tag .. x, x - 0.25, bandY0, face - 0.1, x + 0.25, bandY1, face + 0.1, "window_frame",
				{ collide = false, shadow = false, detail = true })
		end
		-- lit window cells (sparse), plus designated glows
		local rng = ctx.rng:fork("lit" .. t.id .. tag)
		for x = t.x0 + 4, t.x1 - 8, 8 do
			local glow = false
			for _, g in ipairs(opts.glows or {}) do
				if g.side == dir and x >= g.x0 and x <= g.x1 then glow = true end
			end
			if glow or rng:chance(opts.litChance or 0.04) then
				ctx:box(m, "Lit" .. tag .. x, x + 0.4, bandY0 + 0.3, face - (dir > 0 and -0.12 or 0.12) - 0.05, x + 7.6, bandY1 - 0.3,
					face + (dir > 0 and 0.12 or -0.12) + 0.05, "window_lit", { collide = false, query = false, shadow = false })
			end
		end
		if opts.stripe then
			ctx:box(m, "Stripe" .. tag, t.x0, y1 - 1.2, face - 0.08, t.x1, y1 - 0.7, face + 0.08, opts.stripe,
				{ collide = false, shadow = false })
		end
	end
	-- curved front (8 segments), glass band continues around it
	local n = 8
	local prev
	for k = 0, n do
		local z = t.z0 + (t.z1 - t.z0) * k / n
		local p = Vector3.new(frontX(t, z), 0, z)
		if prev then
			local a0 = Vector3.new(prev.X, (y0 + bandY0) / 2, prev.Z)
			local b0 = Vector3.new(p.X, (y0 + bandY0) / 2, p.Z)
			ctx:bar(m, "FrontLow" .. k, a0, b0, { bandY0 - y0, 1 }, wallStyle)
			local a1 = Vector3.new(prev.X, (bandY1 + y1) / 2, prev.Z)
			local b1 = Vector3.new(p.X, (bandY1 + y1) / 2, p.Z)
			ctx:bar(m, "FrontHigh" .. k, a1, b1, { y1 - bandY1, 1 }, wallStyle)
			local ag = Vector3.new(prev.X, (bandY0 + bandY1) / 2, prev.Z)
			local bg = Vector3.new(p.X, (bandY0 + bandY1) / 2, p.Z)
			ctx:bar(m, "FrontGlass" .. k, ag, bg, { bandY1 - bandY0, 0.8 }, opts.frontGlass or "window_dark")
			-- roof infill over the bulge
			local xa = math.min(prev.X, p.X)
			ctx:box(m, "RoofBulge" .. k, xa, y1 - 0.6, math.min(prev.Z, p.Z), t.x0, y1, math.max(prev.Z, p.Z), "super_cream",
				{ shadow = false })
			ctx:box(m, "FloorBulge" .. k, xa, y0, math.min(prev.Z, p.Z), t.x0, y0 + 0.4, math.max(prev.Z, p.Z), "deck_paint",
				{ shadow = false })
		end
		prev = p
	end
	-- aft wall + roof
	ctx:box(m, "AftWall", t.x1 - 1, y0, t.z0, t.x1, y1, t.z1, wallStyle)
	local holes = opts.roofHoles or {}
	if #holes == 0 then
		ctx:box(m, "Roof", t.x0, y1 - 0.6, t.z0, t.x1, y1, t.z1, "super_cream")
	else
		local h = holes[1]
		ctx:box(m, "RoofA", t.x0, y1 - 0.6, t.z0, h[1], y1, t.z1, "super_cream")
		ctx:box(m, "RoofB", h[2], y1 - 0.6, t.z0, t.x1, y1, t.z1, "super_cream")
		ctx:box(m, "RoofC", h[1], y1 - 0.6, t.z0, h[2], y1, h[3], "super_cream")
		ctx:box(m, "RoofD", h[1], y1 - 0.6, h[4], h[2], y1, t.z1, "super_cream")
	end
	return m
end

local function doubleHeightHoles()
	local holes = {}
	local ShipSpec = require(Map.Data.ShipSpec)
	for _, r in ipairs(ShipSpec.rooms) do
		local cfg = Rooms.byId[r.id]
		if cfg and cfg.doubleHeight then
			table.insert(holes, { r.origin[1], r.origin[1] + r.size[1], r.origin[3], r.origin[3] + r.size[3] })
		end
	end
	return holes
end

local function funnel(ctx, parent)
	local F = S.funnel
	local m = ctx:model(parent, "Funnel")
	local zc = (F.z0 + F.z1) / 2
	for i = 0, F.layers - 1 do
		local y0 = F.y0 + i * F.layerH
		local y1 = y0 + F.layerH
		local shift = i * F.rakePerLayer
		local shrink = i * 0.35
		local hz = (F.z1 - F.z0) / 2 - shrink
		local x0, x1 = F.x0 + shift + hz, F.x1 + shift - hz
		local style = "funnel_navy"
		if i == 3 then style = "funnel_coral" elseif i == 4 then style = "funnel_navy" elseif i == F.layers - 1 then style = "funnel_cap" end
		ctx:box(m, "Body" .. i, x0, y0, zc - hz, x1, y1 + 0.02, zc + hz, style)
		for _, xe in ipairs({ x0, x1 }) do
			ctx:cyl(m, "Round" .. i .. "_" .. xe, Vector3.new(xe, y0, zc), Vector3.new(xe, y1 + 0.02, zc), hz, style, { shadow = i == 0 })
		end
		if i == 4 then
			-- faded yellow pin-stripe above the coral band
			ctx:box(m, "Pinstripe", x0 - hz * 0.2, y0 + 0.5, zc - hz - 0.05, x1 + hz * 0.2, y0 + 1.1, zc + hz + 0.05, "funnel_yellow",
				{ collide = false, shadow = false })
		end
	end
	-- smoke-deflecting top fins
	local top = F.y0 + F.layers * F.layerH
	local shift = F.layers * F.rakePerLayer
	for _, s in ipairs({ -1, 1 }) do
		local fin = ctx:box(m, "Fin" .. s, F.x0 + shift - 2, top - 1, zc + s * 12, F.x1 + shift + 6, top, zc + s * 12.8, "funnel_cap")
		fin.CFrame = fin.CFrame * CFrame.Angles(s * math.rad(-14), 0, 0)
	end
	-- line emblem: coral disc + cream compass diamond + "M" (both sides)
	local ey = F.y0 + 3.3 * F.layerH
	local ex = (F.x0 + F.x1) / 2 + 3.3 * F.rakePerLayer
	for _, s in ipairs({ -1, 1 }) do
		local hz = (F.z1 - F.z0) / 2 - 3 * 0.35
		local c = Vector3.new(ex, ey, zc + s * (hz + 0.1))
		local n = Vector3.new(0, 0, s)
		ctx:cyl(m, "EmblemDisc" .. s, c, c + n * 0.15, 4.4, "funnel_coral", { collide = false, shadow = false })
		local d = ctx:part(m, "EmblemDiamond" .. s, Vector3.new(4.2, 4.2, 0.2), CFrame.lookAt(c + n * 0.2, c + n) * CFrame.Angles(0, 0, math.rad(45)),
			"super_cream", { collide = false, shadow = false })
		local _ = d
		Signs.paint(ctx, m, CFrame.lookAt(c + n * 0.35, c + n * 2), 3.4, 3.4, "M", Palette.fonts.display, Palette.colors.navy,
			{ name = "EmblemLetter" .. s, pps = 20, lightInfluence = 0.4, brightness = 1.4 })
	end
	ctx:tag(m, "Landmark")
	m:SetAttribute("LandmarkId", "Funnel")
	m:SetAttribute("ZoneId", "ShipExterior")
	-- funnel floodlight: keeps the landmark legible at night in fog
	local flood = ctx:box(m, "Floodlight", ex - 16, F.y0 - 0.2, zc + 20, ex - 15, F.y0 + 0.6, zc + 21, "lamp_white", { collide = false, shadow = false })
	ctx:light(flood, "SpotLight", { Range = 40, Brightness = 1.6, Color = "cream", Angle = 60, Face = "Top" },
		{ circuit = "Nav", priority = "Nav", nav = "FunnelFlood" })
	return m
end

local function mast(ctx, parent, def)
	local m = ctx:model(parent, "Mast_" .. def.id)
	ctx:cyl(m, "Pole", Vector3.new(def.x, def.y0, def.z), Vector3.new(def.x, def.y1, def.z), 0.6, "rail_white", { shadow = false })
	ctx:bar(m, "Yard", Vector3.new(def.x, def.y1 - 8, def.z - 6), Vector3.new(def.x, def.y1 - 8, def.z + 6), 0.35, "rail_white",
		{ shadow = false, collide = false })
	local lamp = ctx:ball(m, "MastheadLight", Vector3.new(def.x, def.y1 + 0.6, def.z), 0.55, "lamp_white", { collide = false, shadow = false })
	ctx:light(lamp, "PointLight", { Range = 26, Brightness = 2.2, Color = "navWhite" }, { circuit = "Nav", priority = "Nav", nav = "Masthead" })
	if def.id == "foremast" then
		-- radar scanner (rotated by Runtime/Exterior)
		local r = ctx:box(m, "RadarScanner", def.x - 5, def.y1 - 13, def.z - 0.4, def.x + 5, def.y1 - 12.2, def.z + 0.4, "rail_white",
			{ collide = false, shadow = false })
		ctx:attrs(r, { Spin = true, SpinPeriod = 3.5 })
		ctx:tag(r, "RotatingDetail")
	end
	return m
end

function Super.build(ctx, root)
	ctx:setRegion("SHIP_EXT")
	local m = ctx:model(root, "Superstructure")

	-- deck D slab (roof over deck A + promenade overhangs), holed over double-height rooms
	local slabs = ctx:folder(m, "DeckDSlab")
	local d = S.deckDSlab
	local holes = doubleHeightHoles()
	local cuts = { d.x0 }
	for _, h in ipairs(holes) do
		table.insert(cuts, h[1])
		table.insert(cuts, h[2])
	end
	table.insert(cuts, d.x1)
	table.sort(cuts)
	for i = 1, #cuts - 1 do
		local xa, xb = cuts[i], cuts[i + 1]
		local hole
		for _, h in ipairs(holes) do
			if h[1] <= xa + 0.01 and h[2] >= xb - 0.01 then hole = h end
		end
		if not hole then
			-- split long spans for streaming granularity
			local x = xa
			while x < xb - 0.01 do
				local x2 = math.min(xb, x + 96)
				ctx:box(slabs, "Slab" .. i .. "_" .. x, x, d.y - 1, d.z0, x2, d.y, d.z1, "deck_paint")
				x = x2
			end
		else
			ctx:box(slabs, "Slab" .. i .. "_N", xa, d.y - 1, d.z0, xb, d.y, hole[3], "deck_paint")
			ctx:box(slabs, "Slab" .. i .. "_S", xa, d.y - 1, hole[4], xb, d.y, d.z1, "deck_paint")
		end
	end
	-- promenade ceiling finish (underside boards) + slab edge fascia
	for _, zz in ipairs({ { 48, 58 }, { -10, 0 } }) do
		ctx:box(slabs, "Soffit" .. zz[1], d.x0 + 2, d.y - 1.25, zz[1], 192, d.y - 1, zz[2], "deck_teak_grey", { collide = false, shadow = false })
	end
	ctx:box(slabs, "FasciaP", d.x0, d.y - 1.6, d.z1 - 0.3, d.x1, d.y + 0.3, d.z1 + 0.2, "super_cream", { shadow = false })
	ctx:box(slabs, "FasciaS", d.x0, d.y - 1.6, d.z0 - 0.2, d.x1, d.y + 0.3, d.z0 + 0.3, "super_cream", { shadow = false })

	-- forward deck-A block (x < 0): closed, windowed, not playable
	local fwd = { id = "A_Fwd", y0 = 32, y1 = 48, x0 = S.forecastleX, x1 = 0, z0 = 0, z1 = 48, frontBulge = 10 }
	tier(ctx, m, fwd, { bandLow = 3, bandHigh = 10, litChance = 0.03, wall = "super_cream_dirty" })
	-- tiers D, E, F
	local td, te, tf = S.tiers[1], S.tiers[2], S.tiers[3]
	tier(ctx, m, td, {
		bandLow = 4, bandHigh = 10, stripe = "hull_stripe_coral", litChance = 0.03,
		glows = { { side = 1, x0 = 96, x1 = 128 } }, -- ballroom clerestory
	})
	tier(ctx, m, te, { bandLow = 3.5, bandHigh = 10, litChance = 0.02, frontGlass = "window_dark" })
	tier(ctx, m, tf, { bandLow = 2, bandHigh = 6, litChance = 0 })

	-- bridge wings with sidelights (red to port, green to starboard)
	local bw = S.bridgeWing
	local wings = ctx:folder(m, "BridgeWings")
	ctx:box(wings, "WingDeck", bw.x0, bw.y, bw.z0, bw.x1, bw.y + 0.5, bw.z1, "deck_paint")
	for _, zz in ipairs({ { bw.z0, 4 }, { 44, bw.z1 } }) do
		ctx:box(wings, "Dodger" .. zz[1], bw.x0, bw.y + 0.5, zz[1], bw.x0 + 0.5, bw.y + 4, zz[2], "super_cream", { shadow = false })
	end
	for _, s in ipairs({ { bw.z1, "lamp_red", "navRed", "PortSidelight" }, { bw.z0, "lamp_green", "navGreen", "StbdSidelight" } }) do
		local box = ctx:box(wings, s[4] .. "Screen", bw.x0 + 3, bw.y + 3.6, s[1] - 0.6, bw.x0 + 6, bw.y + 5.4, s[1] + 0.6, "black", { shadow = false })
		local _ = box
		local lamp = ctx:box(wings, s[4], bw.x0 + 2.2, bw.y + 4, s[1] - 0.5, bw.x0 + 3, bw.y + 5, s[1] + 0.5, s[2], { collide = false, shadow = false })
		ctx:light(lamp, "PointLight", { Range = 22, Brightness = 2.4, Color = s[3] }, { circuit = "Nav", priority = "Nav", nav = s[4] })
		lamp:SetAttribute("Landmark", true)
	end

	funnel(ctx, m)
	for _, def in ipairs(S.masts) do mast(ctx, m, def) end

	-- ventilator cowls and deck clutter on the D roof (silhouette detail)
	local roof = ctx:folder(m, "RoofDetail")
	for i, x in ipairs({ -60, -20, 40, 80 }) do
		Maritime.ventilator(ctx, roof, CFrame.new(x, 64, 8 + (i % 2) * 32), 4 + (i % 2))
	end
	-- terraced aft sun deck rails
	Rails.run(ctx, roof, { Vector3.new(150, 64, -4), Vector3.new(200, 64, -4), Vector3.new(200, 64, 52), Vector3.new(150, 64, 52) },
		{ style = "rail_white", boundary = false, postEvery = 8, name = "SunDeckRail" })

	-- boat deck: davits both sides, boats present/missing per World config
	local boats = ctx:folder(m, "Lifeboats")
	local L = S.lifeboat
	for _, x in ipairs(S.davitX) do
		for _, side in ipairs({ 1, -1 }) do
			local present
			if side > 0 then present = S.boatsPort[x] else present = S.boatsStbd[x] end
			local footZ = side > 0 and 56 or -8
			local outward = Vector3.new(0, 0, side)
			local boatZ = footZ + side * 7.2
			Maritime.davits(ctx, boats, Vector3.new(x, 48, footZ), outward, 10, L.hangY + L.height, present ~= nil, World.waterY)
			if present then
				local id = (type(present) == "string") and present or ("STBD_" .. x)
				local cf = CFrame.lookAt(Vector3.new(x, L.hangY, boatZ), Vector3.new(x - 10, L.hangY, boatZ))
				local boat = Maritime.lifeboat(ctx, boats, cf, id, true)
				if type(present) == "string" then
					boat:SetAttribute("ExtractionId", present)
					-- boat number on the bow quarter
					local p = Vector3.new(x - 6, L.hangY + 3.6, boatZ + side * (L.beam / 2 + 0.25))
					Signs.paint(ctx, boats, CFrame.lookAt(p, p + outward), 3, 1.6, present == "LB_fore" and "1" or (present == "LB_mid" and "3" or "5"),
						Palette.fonts.crew, Palette.colors.black, { name = "BoatNo_" .. present, pps = 24 })
				end
			end
		end
	end
	return m
end

return Super
