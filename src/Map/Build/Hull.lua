-- Hull: horizontal strakes following a plan-view curve (raked stem, counter
-- stern), main-deck plating outside the interior box, bulwarks, anchors,
-- waterline weathering and hull portholes aligned with the cabin decks.
local Map = script.Parent.Parent
local World = require(Map.Config.World)
local Signs = require(Map.Kit.Signs)
local Rails = require(Map.Kit.Rails)
local Maritime = require(Map.Kit.Maritime)
local Walls = require(Map.Kit.Walls)
local Palette = require(Map.Config.Palette)

local Hull = {}
local S = World.ship

-- half-width of a band at x (nil outside the band's length)
function Hull.halfWidth(band, x)
	local tip = S.bowX + band.rake
	local tail = S.sternX - band.sternRake
	if x < tip - 1e-6 or x > tail + 1e-6 then return nil end
	local H = S.halfBeam - band.inset
	local w = H
	if x < tip + S.bowLength then
		local s = math.max(0, (x - tip) / S.bowLength)
		w = H * (1 - (1 - s) ^ 2) ^ 0.55
	end
	if x > S.sternTaperStart then
		local s = (x - S.sternTaperStart) / (S.sternX - S.sternTaperStart)
		w = math.min(w, H - (S.halfBeam - S.transomHalf) * s * s)
	end
	return w
end

local function stations(band)
	local tip = S.bowX + band.rake
	local tail = S.sternX - band.sternRake
	local xs = {}
	local bowEnd = tip + S.bowLength
	local x = tip
	-- denser near the stem where curvature is highest
	local step = 3
	while x < bowEnd do
		table.insert(xs, x)
		x = x + step
		step = math.min(8, step + 0.6)
	end
	table.insert(xs, bowEnd)
	-- parallel body: split so no plate crosses a streaming chunk boundary badly
	for _, px in ipairs({ -40, 0, 96, 192 }) do
		if px > bowEnd and px < S.sternTaperStart then table.insert(xs, px) end
	end
	x = S.sternTaperStart
	while x < tail do
		table.insert(xs, x)
		x = x + 4
	end
	table.insert(xs, tail)
	table.sort(xs)
	local out = {}
	for _, v in ipairs(xs) do
		if #out == 0 or v - out[#out] > 0.4 then table.insert(out, v) end
	end
	return out
end
Hull.stations = stations

function Hull.build(ctx, root)
	ctx:setRegion("SHIP_EXT")
	local m = ctx:model(root, "Hull")
	local plates = ctx:folder(m, "Plating")
	local cz = S.centerZ
	for bi, band in ipairs(S.bands) do
		local xs = stations(band)
		local ym = (band.y0 + band.y1) / 2
		local h = band.y1 - band.y0
		for i = 1, #xs - 1 do
			local xa, xb = xs[i], xs[i + 1]
			local wa, wb = Hull.halfWidth(band, xa), Hull.halfWidth(band, xb)
			if wa and wb then
				for _, side in ipairs({ 1, -1 }) do
					local a = Vector3.new(xa - 0.3, ym, cz + side * wa)
					local b = Vector3.new(xb + 0.3, ym, cz + side * wb)
					ctx:bar(plates, "Strake" .. bi .. "_" .. (side > 0 and "P" or "S") .. i, a, b, { h, 1 }, band.style,
						{ shadow = band.y1 > 4 })
				end
			end
		end
		-- transom
		local tail = S.sternX - band.sternRake
		local wt = Hull.halfWidth(band, tail)
		if wt and wt > 0.5 then
			ctx:box(plates, "Transom" .. bi, tail - 0.5, band.y0, cz - wt, tail + 0.5, band.y1, cz + wt, band.style)
		end
	end
	-- stem bar (cutwater) following the rake
	local topBand, lowBand = S.bands[#S.bands], S.bands[1]
	ctx:bar(plates, "Stem", Vector3.new(S.bowX + lowBand.rake, lowBand.y0, cz), Vector3.new(S.bowX + topBand.rake - 0.5, S.sheerY + S.bowRise, cz),
		{ 1.4, 1.4 }, "hull_navy")

	-- main deck plating outside the interior box (forecastle + aft deck base)
	local deck = ctx:folder(m, "Deck")
	local xs = stations(topBand)
	for i = 1, #xs - 1 do
		local xa, xb = xs[i], xs[i + 1]
		if xb <= S.forecastleX + 2 then
			local w = math.min(Hull.halfWidth(topBand, xa), Hull.halfWidth(topBand, xb)) - 0.4
			if w > 0.5 then
				ctx:box(deck, "Forecastle" .. i, xa, S.sheerY - 1, cz - w, xb, S.sheerY, cz + w, "deck_paint")
			end
		end
	end
	-- deck plating under the non-playable forward superstructure + promenades is built by Exterior
	-- bulwark around the forecastle (solid plate, rising toward the stem)
	local bw = ctx:folder(m, "Bulwark")
	for _, side in ipairs({ 1, -1 }) do
		local pts = {}
		for _, x in ipairs(xs) do
			if x <= S.forecastleX + 4 then
				local w = Hull.halfWidth(topBand, x)
				if w then
					local rise = S.bowRise * math.max(0, 1 - (x - S.bowX) / 90)
					table.insert(pts, Vector3.new(x, S.sheerY + rise * 0.6, cz + side * (w - 0.25)))
				end
			end
		end
		Rails.bulwark(ctx, bw, pts, 3.6, "hull_navy", "rail_teak", "Bulwark" .. (side > 0 and "P" or "S"))
	end

	-- ship's name on both bows and the stern (Michroma, cream on navy)
	local names = ctx:folder(m, "Names")
	for _, side in ipairs({ 1, -1 }) do
		local x = S.bowX + 46
		local w = Hull.halfWidth(topBand, x)
		local p = Vector3.new(x, 27.5, cz + side * (w + 0.62))
		local look = Vector3.new(0, 0, side)
		-- follow the local hull angle
		local w2 = Hull.halfWidth(topBand, x + 4)
		local tangent = Vector3.new(4, 0, side * (w2 - w)).Unit
		local normal = Vector3.new(0, 1, 0):Cross(tangent) * side
		if normal:Dot(look) < 0 then normal = -normal end
		Signs.paint(ctx, names, CFrame.lookAt(p, p + normal), 38, 4.2, "CORAL MERIDIAN", Palette.fonts.display, Palette.colors.cream,
			{ name = "BowName" .. (side > 0 and "P" or "S"), pps = 10, lightInfluence = 0.5, brightness = 1.6 })
	end
	local tail = S.sternX - topBand.sternRake
	local sp = Vector3.new(tail + 0.62, 26.5, cz)
	Signs.paint(ctx, names, CFrame.lookAt(sp, sp + Vector3.new(1, 0, 0)), 34, 3.6, "CORAL MERIDIAN", Palette.fonts.display, Palette.colors.cream,
		{ name = "SternName", pps = 10, lightInfluence = 0.5, brightness = 1.6 })
	local sp2 = Vector3.new(tail + 0.62, 22.6, cz)
	Signs.paint(ctx, names, CFrame.lookAt(sp2, sp2 + Vector3.new(1, 0, 0)), 14, 2.2, S.registry, Palette.fonts.display, Palette.colors.cream,
		{ name = "SternPort", pps = 10, lightInfluence = 0.5, brightness = 1.4 })

	-- hull portholes aligned with the interior cabin/crew rows (exterior side)
	local ports = ctx:folder(m, "Portholes")
	local rng = ctx.rng:fork("hullports")
	for _, side in ipairs({ 1, -1 }) do
		local zHull = cz + side * (S.halfBeam + 0.5) -- outer face of the plating
		for x = -120, 212, 8 do
			for _, row in ipairs({ { y = 22.5, r = 0.95 }, { y = 9.5, r = 0.8 } }) do
				if not (row.y < 12 and (x < -60 or x > 200)) then
					local lit = rng:chance(0.05)
					local violet = (not lit) and x == 136 and side > 0 and row.y > 20
					local style = violet and "window_violet" or (lit and "window_lit" or "window_dark")
					Walls.porthole(ctx, ports, Vector3.new(x, row.y, zHull), Vector3.new(0, 0, side), row.r, style,
						"Port" .. (side > 0 and "P" or "S") .. "_" .. x .. "_" .. row.y, "hull_navy_worn")
				end
			end
		end
	end

	-- waterline weathering: algae band + rust weeping under scuppers
	local wx = ctx:folder(m, "Weathering")
	for _, side in ipairs({ 1, -1 }) do
		local z = cz + side * (S.halfBeam + 0.56)
		ctx:box(wx, "Algae" .. side, -80, 3.6, z - 0.03, 212, 4.8, z + 0.03, "hull_boottop", { collide = false, query = false, shadow = false })
		local r2 = ctx.rng:fork("rust" .. side)
		for x = -70, 200, 23 do
			local len = r2:range(4, 11)
			local xx = x + r2:range(-4, 4)
			ctx:box(wx, "Rust" .. side .. "_" .. x, xx - 0.35, 24 - len, z - 0.04, xx + 0.35, 24.2, z + 0.04, "rust_streak",
				{ collide = false, query = false, shadow = false, detail = true })
			ctx:box(wx, "Scupper" .. side .. "_" .. x, xx - 0.6, 24.2, z - 0.06, xx + 0.6, 25, z + 0.06, "black",
				{ collide = false, query = false, shadow = false, detail = true })
		end
		-- salt crust on the lower bow flare
		ctx:box(wx, "SaltBow" .. side, -200, 14, z - side * 12 - 0.05, -150, 16, z - side * 12 + 0.05, "salt_crust",
			{ collide = false, query = false, shadow = false, detail = true })
	end

	-- anchors: hawse pipes both bows; the port chain runs into the sea (anchored)
	local anc = ctx:folder(m, "Anchors")
	for _, side in ipairs({ 1, -1 }) do
		local x = S.bowX + 22
		local w = Hull.halfWidth(S.bands[#S.bands - 1], x) or 8
		local p = Vector3.new(x, 26, cz + side * (w + 0.4))
		ctx:cyl(anc, "Hawse" .. side, p, p + Vector3.new(0, 0, side * 0.6), 1.3, "black", { shadow = false })
		if side < 0 then
			ctx:box(anc, "AnchorStock", x - 0.6, 20.5, p.Z - 0.8, x + 0.6, 25.5, p.Z + 0.1, "steel_dark")
			ctx:box(anc, "AnchorFlukes", x - 2.2, 19.6, p.Z - 0.8, x + 2.2, 20.8, p.Z + 0.1, "steel_dark")
		end
	end
	local a = Vector3.new(S.bowX + 22, 25.5, cz + 11)
	local b = Vector3.new(S.bowX + 8, World.waterY - 2, cz + 26)
	ctx:bar(anc, "PortChain", a, b, { 0.7, 0.9 }, "steel_corroded", { collide = false, shadow = false })
	-- stern light (white) + draught marks at the stern
	local sl = ctx:ball(anc, "SternLight", Vector3.new(tail + 0.9, 30.6, cz), 0.45, "lamp_white", { collide = false, query = false, shadow = false })
	ctx:light(sl, "PointLight", { Range = 16, Brightness = 1.6, Color = "navWhite" }, { circuit = "Nav", priority = "Nav", nav = "SternLight" })
	for i, y in ipairs({ 6, 10, 14, 18 }) do
		Signs.paint(ctx, names, CFrame.lookAt(Vector3.new(tail + 0.62, y, cz + 18), Vector3.new(tail + 10, y, cz + 18)), 1.6, 1.2,
			tostring(2 + i * 1) .. "M", Palette.fonts.crew, Palette.colors.cream, { name = "Draught" .. i, pps = 20 })
	end
	return m
end

return Hull
