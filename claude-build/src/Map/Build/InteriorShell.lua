-- Interior shell: floors, layered walls, spec doorways, ceilings, corridors and
-- stair towers for decks A/B/C. Collision geometry follows horrorgame.md
-- APPENDIX A exactly:
--   * rooms/corridors/stairs keep their spec boxes; walls sit inside room boxes
--     so every corridor keeps its full 8-stud clear width,
--   * every spec door/stair connection is a 4x8 clear opening centred on
--     connection.at; nothing else connects rooms to corridors,
--   * optional vents/hatches are built closed and tagged for runtime toggling.
local Map = script.Parent.Parent
local Rooms = require(Map.Config.Rooms)
local World = require(Map.Config.World)
local Walls = require(Map.Kit.Walls)
local Stairs = require(Map.Kit.Stairs)
local Signs = require(Map.Kit.Signs)
local Props = require(Map.Kit.Props)
local Maritime = require(Map.Kit.Maritime)
local Palette = require(Map.Config.Palette)

local Shell = {}

local DECK_TOP = 15 -- walls run from the floor to the underside of the next slab
local SLOT = 32

---------------------------------------------------------------------------
-- spec indexing
---------------------------------------------------------------------------
function Shell.index(spec)
	local S = { levels = {}, rooms = {}, stairsAt = {}, conns = spec.connections, spec = spec }
	for _, l in ipairs(spec.levels) do
		S.levels[l.id] = l
	end
	for _, r in ipairs(spec.rooms) do
		S.rooms[r.id] = r
	end
	-- slot lookup: level -> side -> x0 -> {kind="room"/"stair", id}
	S.slots = {}
	for _, l in ipairs(spec.levels) do
		S.slots[l.id] = { L = {}, R = {} }
	end
	for _, r in ipairs(spec.rooms) do
		local side = r.origin[3] < 24 and "L" or "R"
		S.slots[r.level][side][r.origin[1]] = { kind = "room", id = r.id, room = r }
	end
	for _, st in ipairs(spec.stairs) do
		local lowest, highest = nil, nil
		for _, fp in ipairs(st.footprints) do
			if not lowest or fp.origin[2] < lowest.origin[2] then lowest = fp end
			if not highest or fp.origin[2] > highest.origin[2] then highest = fp end
		end
		for _, fp in ipairs(st.footprints) do
			local side = fp.origin[3] < 24 and "L" or "R"
			S.slots[fp.level][side][fp.origin[1]] = { kind = "stair", id = st.id, fp = fp, stair = st }
		end
		S.stairsAt[st.id] = { stair = st, lowest = lowest, highest = highest }
	end
	-- doors on corridors
	S.corridorDoors = { A = {}, B = {}, C = {} }
	S.vents, S.hatches, S.lifeboatDoors = {}, {}, {}
	for _, c in ipairs(spec.connections) do
		if (c.kind == "door" or c.kind == "stair") and string.sub(c.b, 1, 5) == "CORR_" and c.a ~= "EXT_ship" then
			local lvl = string.sub(c.b, 6, 6)
			table.insert(S.corridorDoors[lvl], c)
		elseif c.kind == "vent" then
			table.insert(S.vents, c)
		elseif c.kind == "hatch" then
			table.insert(S.hatches, c)
		elseif c.kind == "door" and string.sub(c.a, 1, 3) == "LB_" then
			table.insert(S.lifeboatDoors, c)
		elseif c.a == "EXT_ship" then
			S.boardDoor = c
		end
	end
	return S
end

local function slotStyle(slot, which)
	if not slot then return "steel_paint" end
	if slot.kind == "stair" then
		local cfg = Rooms.stairs[slot.id]
		return (which == "floor") and cfg.floor or cfg.wall
	end
	local cfg = Rooms.byId[slot.id]
	return (which == "floor") and cfg.floor or cfg.wall
end
Shell.slotStyle = slotStyle

local function exteriorStyle(level)
	if level == "A" then return "super_cream_dirty" end
	return "steel_paint"
end

---------------------------------------------------------------------------
-- floors (+ spec hatches)
---------------------------------------------------------------------------
local function floorWithHole(ctx, parent, name, x0, z0, x1, z1, y, style, hole)
	if not hole then
		return ctx:box(parent, name, x0, y - 1, z0, x1, y, z1, style)
	end
	local hx0, hx1, hz0, hz1 = hole[1], hole[2], hole[3], hole[4]
	ctx:box(parent, name .. "_A", x0, y - 1, z0, hx0, y, z1, style)
	ctx:box(parent, name .. "_B", hx1, y - 1, z0, x1, y, z1, style)
	ctx:box(parent, name .. "_C", hx0, y - 1, z0, hx1, y, hz0, style)
	ctx:box(parent, name .. "_D", hx0, y - 1, hz1, hx1, y, z1, style)
end

local function buildFloors(ctx, f, S, level)
	local y = S.levels[level].floorY
	for _, r in ipairs(S.spec.rooms) do
		if r.level == level then
			local cfg = Rooms.byId[r.id]
			local hole
			for _, h in ipairs(S.hatches) do
				-- a hatch opens in the floor of the UPPER room of the pair
				local ra, rb = S.rooms[h.a], S.rooms[h.b]
				local upper = (ra.origin[2] > rb.origin[2]) and ra or rb
				if upper.id == r.id then
					hole = { h.at[1] - 1.2, h.at[1] + 1.2, h.at[3] - 1.2, h.at[3] + 1.2, conn = h }
				end
			end
			floorWithHole(ctx, f.Floors, r.id .. "_Floor", r.origin[1], r.origin[3], r.origin[1] + r.size[1], r.origin[3] + r.size[3], y, cfg.floor, hole)
			if hole then
				local h = hole.conn
				-- frame + closed hatch cover (spec size 2x2 clear; see STATUS: not avatar-traversable)
				ctx:box(f.Floors, h.id .. "_Coaming", hole[1] - 0.3, y, hole[3] - 0.3, hole[2] + 0.3, y + 0.12, hole[4] + 0.3, "steel_dark",
					{ collide = false, query = false, shadow = false })
				local cover = ctx:box(f.Floors, h.id .. "_Cover", h.at[1] - 1.15, y - 0.6, h.at[3] - 1.15, h.at[1] + 1.15, y + 0.1, h.at[3] + 1.15, "steel_grate",
					{ tags = { "OptionalConnector" } })
				ctx:attrs(cover, {
					ConnectionId = h.id, Kind = "hatch", RoomA = h.a, RoomB = h.b,
					OpenProbMin = h.opened_prob[1], OpenProbMax = h.opened_prob[2],
					ClearWidth = h.w, ClearHeight = h.h, TraversableByAvatar = false,
					ProposedClear = "4x4", Open = false,
				})
			end
		end
	end
	local corr = nil
	for _, z in ipairs(S.spec.zones) do
		if z.level == level then corr = z end
	end
	local ccfg = Rooms.corridors[corr.id]
	ctx:box(f.Floors, corr.id .. "_Floor", corr.origin[1], y - 1, corr.origin[3], corr.origin[1] + corr.size[1], y, corr.origin[3] + corr.size[3], ccfg.floor)
	-- runner / walkway stripes (visual only)
	if level == "C" then
		ctx:box(f.Floors, "Walkway_N", 0.5, y, 20.5, 191.5, y + 0.04, 20.9, "safety_yellow", { collide = false, query = false, shadow = false })
		ctx:box(f.Floors, "Walkway_S", 0.5, y, 27.1, 191.5, y + 0.04, 27.5, "safety_yellow", { collide = false, query = false, shadow = false })
	else
		ctx:box(f.Floors, "Runner", 1, y, 22.2, 191, y + 0.04, 25.8, ccfg.runner, { collide = false, query = false, shadow = false })
		ctx:box(f.Floors, "RunnerEdgeN", 1, y, 21.9, 191, y + 0.05, 22.2, "brass_dark", { collide = false, query = false, shadow = false, detail = true })
		ctx:box(f.Floors, "RunnerEdgeS", 1, y, 25.8, 191, y + 0.05, 26.1, "brass_dark", { collide = false, query = false, shadow = false, detail = true })
	end
end

---------------------------------------------------------------------------
-- walls
---------------------------------------------------------------------------
local function doorOpeningsForSlot(S, level, side, x0)
	local ops = {}
	local zWall = side == "L" and 20 or 28
	local y = S.levels[level].floorY
	for _, c in ipairs(S.corridorDoors[level]) do
		if math.abs(c.at[3] - zWall) < 0.01 and c.at[1] >= x0 and c.at[1] <= x0 + SLOT then
			table.insert(ops, { c.at[1] - c.w / 2, c.at[1] + c.w / 2, y, y + c.h, conn = c })
		end
	end
	return ops
end
Shell.doorOpeningsForSlot = doorOpeningsForSlot

local function buildCorridorWalls(ctx, f, S, level)
	local y = S.levels[level].floorY
	local corr = Rooms.corridors["CORR_" .. level]
	local ceil = y + corr.ceilingH
	for _, side in ipairs({ "L", "R" }) do
		-- core: z [19,19.8] (L) / [28.2,29] (R); lining: [19.8,20] / [28,28.2]
		local coreT0, coreT1, linT0, linT1
		if side == "L" then
			coreT0, coreT1, linT0, linT1 = 19, 19.8, 19.8, 20
		else
			coreT0, coreT1, linT0, linT1 = 28.2, 29, 28, 28.2
		end
		for x0 = 0, 160, SLOT do
			local slot = S.slots[level][side][x0]
			local ops = doorOpeningsForSlot(S, level, side, x0)
			local cfg = slot and slot.kind == "room" and Rooms.byId[slot.id]
			local wallTop = y + DECK_TOP
			if cfg and cfg.doubleHeight then wallTop = y + cfg.ceiling + 0.5 end
			local glazing = {}
			for _, o in ipairs(ops) do table.insert(glazing, o) end
			if cfg and cfg.glazedToCorridor then
				-- glazed screen either side of the ballroom doors: sight line, no passage
				table.insert(glazing, { x0 + 2.5, x0 + 12.5, y + 1.5, y + 9.5, glass = true, glassStyle = "glass_smoked", glassAttrs = { RoomId = slot.id } })
				table.insert(glazing, { x0 + 19.5, x0 + 29.5, y + 1.5, y + 9.5, glass = true, glassStyle = "glass_smoked", glassAttrs = { RoomId = slot.id } })
			end
			local name = "CorrWall" .. side .. "_" .. tostring(x0)
			Walls.slab(ctx, f.Walls, {
				axis = "x", a0 = x0 + (x0 == 0 and 0 or 0), a1 = x0 + SLOT, y0 = y, y1 = wallTop,
				t0 = coreT0, t1 = coreT1, openings = glazing, style = slotStyle(slot, "wall"), name = name .. "_Core",
			})
			-- corridor lining up to the corridor ceiling: dado + upper panel
			local dado = {}
			for _, o in ipairs(glazing) do table.insert(dado, { o[1], o[2], o[3], math.min(o[4], y + 3), glass = false }) end
			Walls.slab(ctx, f.Walls, { axis = "x", a0 = x0, a1 = x0 + SLOT, y0 = y, y1 = y + 3, t0 = linT0, t1 = linT1,
				openings = dado, style = corr.dado, name = name .. "_Dado", opts = { shadow = false } })
			local upper = {}
			for _, o in ipairs(glazing) do
				if o[4] > y + 3 then table.insert(upper, { o[1], o[2], y + 3, o[4] }) end
			end
			Walls.slab(ctx, f.Walls, { axis = "x", a0 = x0, a1 = x0 + SLOT, y0 = y + 3, y1 = ceil, t0 = linT0, t1 = linT1,
				openings = upper, style = corr.wall, name = name .. "_Panel", opts = { shadow = false } })
			-- dado rail
			local tRail = side == "L" and 20.1 or 27.9
			local lastA = x0
			local railSegs = {}
			for _, o in ipairs(glazing) do
				if o[3] <= y + 3.1 then
					table.insert(railSegs, { lastA, o[1] - 0.5 })
					lastA = o[2] + 0.5
				end
			end
			table.insert(railSegs, { lastA, x0 + SLOT })
			for i, seg in ipairs(railSegs) do
				if seg[2] - seg[1] > 0.5 then
					ctx:box(f.Trim, name .. "_Handrail" .. i, seg[1], y + 3.05, tRail - 0.15, seg[2], y + 3.35, tRail + 0.15, corr.handrail,
						{ collide = false, query = false, shadow = false })
				end
			end
			-- casings on both faces of each door
			for _, o in ipairs(ops) do
				local faceCorr = side == "L" and 20 or 28
				local dirCorr = side == "L" and 1 or -1
				local faceRoom = side == "L" and 19 or 29
				Walls.casing(ctx, f.Trim, "x", o[1], o[2], y, o[4], faceCorr, dirCorr, corr.trim, o.conn.id .. "_CasingCorr")
				local roomTrim = (cfg and cfg.trim) or (slot and slot.kind == "stair" and Rooms.stairs[slot.id].rail) or "steel_dark"
				Walls.casing(ctx, f.Trim, "x", o[1], o[2], y, o[4], faceRoom, -dirCorr, roomTrim, o.conn.id .. "_CasingRoom")
			end
		end
	end
end

local function buildPartitions(ctx, f, S, level)
	local y = S.levels[level].floorY
	for _, side in ipairs({ "L", "R" }) do
		local z0, z1 = (side == "L") and 1 or 29, (side == "L") and 19 or 47
		for xb = 0, 192, SLOT do
			local west = S.slots[level][side][xb - SLOT]
			local east = S.slots[level][side][xb]
			if west or east then
				local ops = {}
				for _, v in ipairs(S.vents) do
					local ra = S.rooms[v.a]
					if ra.level == level and math.abs(v.at[1] - xb) < 0.01 and ((side == "L") == (v.at[3] < 24)) then
						table.insert(ops, { v.at[3] - v.w / 2, v.at[3] + v.w / 2, y + 1, y + 1 + v.h, conn = v })
					end
				end
				local top = y + DECK_TOP
				for _, s in ipairs({ west, east }) do
					local c = s and s.kind == "room" and Rooms.byId[s.id]
					if c and c.doubleHeight then top = math.max(top, y + c.ceiling + 0.5) end
				end
				local name = "Partition" .. side .. "_" .. tostring(xb)
				if xb == 0 or xb == 192 then
					-- ship-end walls of the interior box: single 1-stud wall inside the slot
					local slot = east or west
					local tx0, tx1 = (xb == 0) and 0 or 191, (xb == 0) and 1 or 192
					local ext = xb == 192 and level == "A"
					local windows = {}
					if ext then
						-- aft facade over the embarkation deck
						for _, zc in ipairs(side == "L" and { 6, 14 } or { 34, 42 }) do
							table.insert(windows, { zc - 2.5, zc + 2.5, y + 3, y + 9, glass = true, glassStyle = "glass_smoked" })
						end
					end
					Walls.slab(ctx, f.Walls, { axis = "z", a0 = z0 - 1, a1 = z1 + 1, y0 = y, y1 = top, t0 = tx0, t1 = tx1,
						openings = windows, style = ext and "super_cream_dirty" or slotStyle(slot, "wall"), name = name })
					if ext then
						local tl0, tl1 = 190.8, 191
						Walls.slab(ctx, f.Walls, { axis = "z", a0 = z0, a1 = z1, y0 = y, y1 = y + 12, t0 = tl0, t1 = tl1,
							openings = windows, style = slotStyle(slot, "wall"), name = name .. "_Lining", opts = { shadow = false } })
						for i, w in ipairs(windows) do
							Walls.windowFrame(ctx, f.Trim, "z", w[1], w[2], w[3], w[4], 192, 1, "window_frame", name .. "_Win" .. i)
						end
					end
				else
					Walls.slab(ctx, f.Walls, { axis = "z", a0 = z0, a1 = z1, y0 = y, y1 = top, t0 = xb - 0.5, t1 = xb + 0.3,
						openings = ops, style = slotStyle(west, "wall"), name = name .. "_W" })
					Walls.slab(ctx, f.Walls, { axis = "z", a0 = z0, a1 = z1, y0 = y, y1 = top, t0 = xb + 0.3, t1 = xb + 0.5,
						openings = ops, style = slotStyle(east, "wall"), name = name .. "_E", opts = { shadow = false } })
					for _, o in ipairs(ops) do
						local v = o.conn
						local grille = ctx:box(f.Walls, v.id .. "_Grille", xb - 0.15, o[3], o[1], xb + 0.15, o[4], o[2], "steel_grate",
							{ tags = { "OptionalConnector" } })
						ctx:attrs(grille, {
							ConnectionId = v.id, Kind = "vent", RoomA = v.a, RoomB = v.b,
							OpenProbMin = v.opened_prob[1], OpenProbMax = v.opened_prob[2],
							ClearWidth = v.w, ClearHeight = v.h, TraversableByAvatar = false,
							ProposedClear = "4x6", Open = false, NormalisedBottomY = o[3],
						})
						Walls.casing(ctx, f.Trim, "z", o[1], o[2], o[3], o[4], xb - 0.5, -1, "steel_dark", v.id .. "_FrameW")
						Walls.casing(ctx, f.Trim, "z", o[1], o[2], o[3], o[4], xb + 0.5, 1, "steel_dark", v.id .. "_FrameE")
					end
				end
			end
		end
	end
end

-- outer (hull-side) walls at z 0..1 (L) and 47..48 (R)
local function buildOuterWalls(ctx, f, S, level)
	local y = S.levels[level].floorY
	for _, side in ipairs({ "L", "R" }) do
		local ext0, ext1, lin0, lin1, face, dir
		if side == "L" then
			ext0, ext1, lin0, lin1, face, dir = 0, 0.8, 0.8, 1, 0, -1
		else
			ext0, ext1, lin0, lin1, face, dir = 47.2, 48, 47, 47.2, 48, 1
		end
		for x0 = 0, 160, SLOT do
			local slot = S.slots[level][side][x0]
			local cfg = slot and slot.kind == "room" and Rooms.byId[slot.id]
			local top = y + DECK_TOP
			if cfg and cfg.doubleHeight then top = y + cfg.ceiling + 0.5 end
			local ops = {}
			local lbDoor
			for _, c in ipairs(S.lifeboatDoors) do
				local rb = S.rooms[c.b]
				if rb and rb.level == level and c.at[1] >= x0 and c.at[1] <= x0 + SLOT and ((side == "R") == (c.at[3] > 24)) then
					lbDoor = c
					table.insert(ops, { c.at[1] - c.w / 2, c.at[1] + c.w / 2, y, y + c.h, conn = c })
				end
			end
			if level == "A" then
				-- promenade windows: two per slot, clear of any lifeboat door
				for _, wc in ipairs({ 8, 24 }) do
					local a0, a1 = x0 + wc - 3.5, x0 + wc + 3.5
					local clash = false
					for _, o in ipairs(ops) do
						if a0 < o[2] + 1 and a1 > o[1] - 1 then clash = true end
					end
					if not clash then
						table.insert(ops, { a0, a1, y + 3, y + 10, glass = true, glassStyle = "glass_smoked" })
					end
				end
				if cfg and cfg.doubleHeight then
					for _, wc in ipairs({ 8, 16, 24 }) do
						table.insert(ops, { x0 + wc - 2.5, x0 + wc + 2.5, y + 17, y + 24, glass = true, glassStyle = "window_lit",
							glassAttrs = { Clerestory = true } })
					end
				end
			end
			local name = "Outer" .. side .. "_" .. tostring(x0)
			Walls.slab(ctx, f.Walls, { axis = "x", a0 = x0, a1 = x0 + SLOT, y0 = y, y1 = top, t0 = ext0, t1 = ext1,
				openings = ops, style = exteriorStyle(level), name = name .. "_Ext" })
			local liningTop = (cfg and cfg.ceiling and cfg.ceiling < DECK_TOP) and (y + cfg.ceiling) or top
			local linOps = {}
			for _, o in ipairs(ops) do
				if o[3] < liningTop then table.insert(linOps, { o[1], o[2], o[3], math.min(o[4], liningTop) }) end
			end
			Walls.slab(ctx, f.Walls, { axis = "x", a0 = x0 + 0.5, a1 = x0 + SLOT - 0.5, y0 = y, y1 = liningTop, t0 = lin0, t1 = lin1,
				openings = linOps, style = slotStyle(slot, "wall"), name = name .. "_Lining", opts = { shadow = false } })
			for i, o in ipairs(ops) do
				if o.glass then
					Walls.windowFrame(ctx, f.Trim, "x", o[1], o[2], o[3], o[4], face, dir, "window_frame", name .. "_Win" .. i)
				end
			end
			if lbDoor then
				local o = ops[1]
				Walls.casing(ctx, f.Trim, "x", o[1], o[2], y, y + 8, face, dir, "steel_dark", lbDoor.id .. "_CasingOut", 0.4)
				Walls.casing(ctx, f.Trim, "x", o[1], o[2], y, y + 8, (side == "R") and 47 or 1, -dir, "steel_dark", lbDoor.id .. "_CasingIn", 0.3)
				-- weathertight door leaf, held open against the outer face
				Walls.doorLeaf(ctx, f.Doors, "x", o[1], o[2], y, face, dir, "steel_paint", lbDoor.id, true)
			end
			-- portholes on cabin/service decks (fake: lining-face props; the hull carries matching exterior portholes)
			if level ~= "A" and slot and slot.kind == "room" then
				local fam = cfg.family
				local count = (fam == "cabin") and 2 or ((fam == "crew" or fam == "service") and 1 or 0)
				if level == "C" and fam == "hold" then count = 0 end
				for k = 1, count do
					local px = x0 + (count == 1 and 16 or (k == 1 and 9 or 23))
					local pz = (side == "L") and 1 or 47
					local n = Vector3.new(0, 0, -dir)
					Walls.porthole(ctx, f.Trim, Vector3.new(px, y + (level == "C" and 9 or 6.5), pz), n, 0.95, "window_dark", name .. "_Port" .. k)
				end
			end
		end
	end
end

local function buildCorridorEnds(ctx, f, S, level)
	local y = S.levels[level].floorY
	local corr = Rooms.corridors["CORR_" .. level]
	-- fore end (x 0..1)
	Walls.slab(ctx, f.Walls, { axis = "z", a0 = 20, a1 = 28, y0 = y, y1 = y + DECK_TOP, t0 = 0, t1 = 1, openings = {},
		style = corr.wall, name = "CorrForeEnd" })
	-- aft end (x 191..192): board door on A, crew watertight door visuals on B/C
	local ops = {}
	if level == "A" and S.boardDoor then
		local c = S.boardDoor
		ops = { { c.at[3] - c.w / 2, c.at[3] + c.w / 2, y, y + c.h, conn = c } }
	end
	Walls.slab(ctx, f.Walls, { axis = "z", a0 = 20, a1 = 28, y0 = y, y1 = y + DECK_TOP, t0 = 191, t1 = 192, openings = ops,
		style = level == "A" and "super_cream_dirty" or corr.wall, name = "CorrAftEnd" })
	if level == "A" and S.boardDoor then
		local o = ops[1]
		Walls.casing(ctx, f.Trim, "z", o[1], o[2], y, y + 8, 192, 1, "brass", "BoardDoor_CasingOut", 0.35)
		Walls.casing(ctx, f.Trim, "z", o[1], o[2], y, y + 8, 191, -1, "brass", "BoardDoor_CasingIn", 0.3)
		-- glazed double doors, both held open (visual)
		for i, s in ipairs({ -1, 1 }) do
			local z = s < 0 and o[1] or o[2]
			ctx:box(f.Doors, "BoardDoorLeaf" .. i, 191.2, y + 0.1, z - s * 0.1, 191.2 - 2, y + 7.9, z - s * 0.35, "glass_smoked",
				{ collide = false, query = false, shadow = false, tags = { "SightTransparent" } })
		end
		Signs.make(ctx, f.Signs, CFrame.lookAt(Vector3.new(192.3, y + 10.2, 24), Vector3.new(200, y + 10.2, 24)), 9, 1.8,
			{ "PROMENADE DECK", "PURSER  ·  LIDO CAFÉ  ·  BALLROOM" }, "public", { name = "BoardDoorSign", maxDistance = 140 })
	elseif level ~= "A" then
		-- painted watertight door (sealed) at the corridor aft end
		ctx:box(f.Doors, "SealedWTD_" .. level, 190.6, y + 0.4, 21.5, 191, y + 8.4, 26.5, "steel_paint_green")
		Signs.make(ctx, f.Signs, CFrame.lookAt(Vector3.new(190.5, y + 9.4, 24), Vector3.new(180, y + 9.4, 24)), 5, 1,
			{ "WTD " .. (level == "B" and "6" or "7") .. " — SEALED" }, "danger", { name = "SealedSign" })
	end
end

local function buildCeilings(ctx, f, S, level)
	local y = S.levels[level].floorY
	for _, r in ipairs(S.spec.rooms) do
		if r.level == level then
			local cfg = Rooms.byId[r.id]
			local h = cfg.ceiling
			local x0, x1 = r.origin[1] + 0.5, r.origin[1] + r.size[1] - 0.5
			local z0, z1
			if r.origin[3] < 24 then z0, z1 = 1, 19 else z0, z1 = 29, 47 end
			if cfg.doubleHeight then
				ctx:box(f.Ceilings, r.id .. "_Ceiling", x0, y + h, z0, x1, y + h + 0.5, z1, "ceiling_cream")
				-- coffers
				for i = 1, 3 do
					local cx = x0 + (x1 - x0) * i / 4
					ctx:box(f.Ceilings, r.id .. "_Beam" .. i, cx - 0.4, y + h - 1.2, z0, cx + 0.4, y + h, z1, "panel_cream", { collide = false, shadow = false })
				end
			elseif h < DECK_TOP then
				local style = (cfg.family == "public") and "ceiling_cream" or ((cfg.family == "cabin") and "ceiling_panel" or "steel_paint")
				ctx:box(f.Ceilings, r.id .. "_Ceiling", x0, y + h, z0, x1, y + h + 0.4, z1, style, { shadow = false })
				if cfg.family == "public" then
					-- cove trim around the ceiling edge
					ctx:box(f.Ceilings, r.id .. "_CoveA", x0, y + h - 0.5, z0, x1, y + h, z0 + 0.4, cfg.trim, { collide = false, shadow = false, detail = true })
					ctx:box(f.Ceilings, r.id .. "_CoveB", x0, y + h - 0.5, z1 - 0.4, x1, y + h, z1, cfg.trim, { collide = false, shadow = false, detail = true })
				end
			else
				-- exposed deckhead: transverse web frames every 8 studs
				for fx = r.origin[1] + 8, r.origin[1] + r.size[1] - 8, 8 do
					ctx:box(f.Ceilings, r.id .. "_Web" .. fx, fx - 0.3, y + DECK_TOP - 1.4, z0, fx + 0.3, y + DECK_TOP, z1, "steel_paint", { shadow = false })
				end
			end
		end
	end
	local corr = Rooms.corridors["CORR_" .. level]
	if level == "C" then
		-- crew alley: exposed frames + ring-main pipes instead of a finished ceiling
		ctx:box(f.Ceilings, "CorrC_Ceiling", 0, y + DECK_TOP - 0.2, 20, 192, y + DECK_TOP, 28, "steel_dark", { shadow = false })
		for fx = 8, 184, 8 do
			ctx:box(f.Ceilings, "CorrC_Web" .. fx, fx - 0.3, y + 13.6, 20, fx + 0.3, y + DECK_TOP, 28, "steel_paint", { collide = false, shadow = false })
		end
		ctx:cyl(f.Ceilings, "RingMain_Teal", Vector3.new(0.5, y + 12.6, 21.2), Vector3.new(191.5, y + 12.6, 21.2), 0.55, "pipe_teal", { collide = false, shadow = false })
		ctx:cyl(f.Ceilings, "RingMain_Cream", Vector3.new(0.5, y + 12.8, 22.6), Vector3.new(191.5, y + 12.8, 22.6), 0.4, "pipe_cream", { collide = false, shadow = false })
		ctx:cyl(f.Ceilings, "FireMain_Red", Vector3.new(0.5, y + 12.7, 26.8), Vector3.new(191.5, y + 12.7, 26.8), 0.45, "pipe_red", { collide = false, shadow = false })
		ctx:box(f.Ceilings, "CableTray", 0.5, y + 13.2, 24.2, 191.5, y + 13.4, 25.8, "steel_bare", { collide = false, shadow = false, detail = true })
	else
		ctx:box(f.Ceilings, "Corr" .. level .. "_Ceiling", 0, y + corr.ceilingH, 20, 192, y + corr.ceilingH + 0.4, 28, corr.ceiling, { shadow = false })
	end
end

---------------------------------------------------------------------------
-- corridor dressing: lights, fire screens / watertight doors, landmarks
---------------------------------------------------------------------------
local function corridorLight(ctx, f, level, x, y, ceilH, i, corrId)
	local crew = level == "C"
	local fixture
	if crew then
		fixture = ctx:box(f.Lights, corrId .. "_Bulkhead" .. i, x - 0.8, y + ceilH - 1.9, 23.4, x + 0.8, y + ceilH - 1.3, 24.6, "lamp_cold",
			{ collide = false, query = false, shadow = false })
	else
		fixture = ctx:box(f.Lights, corrId .. "_Fixture" .. i, x - 1.4, y + ceilH - 0.15, 23, x + 1.4, y + ceilH, 25, "lamp_warm",
			{ collide = false, query = false, shadow = false })
	end
	fixture:SetAttribute("Glow", true)
	local emergency = (i % 2 == 1)
	fixture:SetAttribute("Circuit", emergency and "Emergency" or "Main")
	ctx:light(fixture, "PointLight", {
		Range = crew and 16 or 18, Brightness = emergency and 0.9 or 1.2,
		Color = crew and "cold" or "emergency",
	}, { circuit = emergency and "Emergency" or "Main", priority = "Normal", flicker = (i == 5 and level == "B") or (i == 9 and level == "C") })
end

local function buildCorridorDressing(ctx, f, S, level)
	local y = S.levels[level].floorY
	local corr = Rooms.corridors["CORR_" .. level]
	local id = "CORR_" .. level
	local i = 0
	for x = corr.lightEvery / 2, 192 - corr.lightEvery / 2, corr.lightEvery do
		i = i + 1
		corridorLight(ctx, f, level, x, y, level == "C" and 13 or corr.ceilingH, i, id)
	end
	-- fire screens (A/B): recessed jambs + header, leaves painted flat on the walls
	for _, fx in ipairs(corr.fireDoorsX or {}) do
		ctx:box(f.Trim, id .. "_FireHeader" .. fx, fx - 0.6, y + 9, 20, fx + 0.6, y + corr.ceilingH, 28, corr.trim, { shadow = false })
		for _, zz in ipairs({ { 20, 20.12 }, { 27.88, 28 } }) do
			ctx:box(f.Trim, id .. "_FireJamb" .. fx .. "_" .. zz[1], fx - 0.6, y, zz[1], fx + 0.6, y + 9, zz[2], corr.trim, { collide = false, shadow = false })
			local s = zz[1] < 24 and 1 or -1
			local zf = zz[1] < 24 and 20.12 or 27.88
			ctx:box(f.Trim, id .. "_FireLeaf" .. fx .. "_" .. zz[1], fx + 0.6, y + 0.2, zf, fx + 4.4, y + 8.8, zf + s * 0.12, "panel_wood",
				{ collide = false, query = false, shadow = false })
		end
		Signs.make(ctx, f.Signs, CFrame.lookAt(Vector3.new(fx - 0.61, y + 9.8, 24), Vector3.new(fx - 10, y + 9.8, 24)), 5, 0.8,
			"FIRE SCREEN DOOR — KEEP CLEAR", "crew", { name = "FireSign" .. fx, maxDistance = 60 })
	end
	-- watertight doors (C): heavy frames with hazard stripes and status lamps
	for n, wx in ipairs(corr.watertightDoorsX or {}) do
		ctx:box(f.Trim, id .. "_WTDHeader" .. wx, wx - 0.8, y + 9.5, 20, wx + 0.8, y + 13, 28, "steel_paint_green")
		for _, zz in ipairs({ { 20, 20.2 }, { 27.8, 28 } }) do
			ctx:box(f.Trim, id .. "_WTDJamb" .. wx .. "_" .. zz[1], wx - 0.8, y, zz[1], wx + 0.8, y + 9.5, zz[2], "steel_paint_green", { collide = false, shadow = false })
			for k = 0, 3 do
				ctx:box(f.Trim, id .. "_Hazard" .. wx .. "_" .. zz[1] .. "_" .. k, wx - 0.82, y + 0.6 + k * 2.2, zz[1] - 0.01, wx + 0.82, y + 1.6 + k * 2.2, zz[2] + 0.01,
					"safety_yellow", { collide = false, query = false, shadow = false, detail = true })
			end
		end
		-- retracted leaf in its pocket on the port wall
		ctx:box(f.Trim, id .. "_WTDLeaf" .. wx, wx + 0.8, y + 0.3, 27.85, wx + 7.4, y + 9.2, 28, "steel_paint_green", { collide = false, query = false, shadow = false })
		local lamp = ctx:box(f.Lights, id .. "_WTDLamp" .. wx, wx - 1.4, y + 10.1, 23.6, wx - 0.8, y + 10.7, 24.4, n == 2 and "lamp_red" or "lamp_green",
			{ collide = false, query = false, shadow = false })
		lamp:SetAttribute("Landmark", true)
		Signs.make(ctx, f.Signs, CFrame.lookAt(Vector3.new(wx - 0.81, y + 11.6, 24), Vector3.new(wx - 10, y + 11.6, 24)), 6, 1,
			{ "WTD " .. n .. " — DO NOT OBSTRUCT" }, "danger", { name = "WTDSign" .. wx, maxDistance = 70 })
	end
	-- frame numbers stencilled along the crew alley (navigation)
	if level == "C" then
		for fx = 16, 176, 16 do
			local frameNo = 20 + math.floor(fx / 16) * 4
			Signs.paint(ctx, f.Signs, CFrame.lookAt(Vector3.new(fx, y + 7.5, 20.25), Vector3.new(fx, y + 7.5, 30)), 2.6, 0.9,
				"FR " .. frameNo, Palette.fonts.crew, Palette.colors.navyDeep, { name = "Frame" .. frameNo, pps = 40, maxDistance = 60 })
		end
	end
	-- deck name at both ends (visible down the full corridor)
	Signs.make(ctx, f.Signs, CFrame.lookAt(Vector3.new(1.05, y + 8.5, 24), Vector3.new(10, y + 8.5, 24)), 6.5, 1.3, corr.deckName, "deck",
		{ name = "DeckNameFore", maxDistance = 220 })
	if level ~= "A" then
		Signs.make(ctx, f.Signs, CFrame.lookAt(Vector3.new(190.4, y + 11, 24), Vector3.new(180, y + 11, 24)), 6.5, 1.3, corr.deckName, "deck",
			{ name = "DeckNameAft", maxDistance = 220 })
	end
end

---------------------------------------------------------------------------
-- stair towers (see MAP_SCALE.md "Stairs": U-shaped, two 8-stud flights,
-- half landing; FSS <= 3.5 m rise per flight)
---------------------------------------------------------------------------
local function buildStair(ctx, parent, S, stairId)
	local info = S.stairsAt[stairId]
	local cfg = Rooms.stairs[stairId]
	local low, high = info.lowest, info.highest
	local ox, oz = low.origin[1], low.origin[3]
	local lowY, highY = low.origin[2], high.origin[2]
	local doorSideZ = (oz < 24) and (oz + low.size[3]) or oz -- the corridor wall
	local dsign = (oz < 24) and -1 or 1 -- d grows away from the corridor
	local function Z(d) return doorSideZ + dsign * d end
	local function box(name, a0, a1, d0, d1, y0, y1, style, opts)
		local za, zb = Z(d0), Z(d1)
		return ctx:box(parent, stairId .. "_" .. name, ox + a0, y0, math.min(za, zb), ox + a1, y1, math.max(za, zb), style, opts)
	end
	-- base slab (lower level floor) over the whole footprint
	box("Base", 0, 32, 0, 20, lowY - 1, lowY, cfg.floor)
	-- mid landing M: solid from the lower floor
	local midY = lowY + 8
	box("MidLanding", 1, 14, 7, 19, lowY, midY, cfg.floor)
	-- fill under flight 2 and under the top pad (no voids)
	box("UnderF2", 14, 26, 13, 19, lowY, midY - 0.5, cfg.wall)
	box("UnderTop", 26, 31, 13, 19, lowY, highY - 1, cfg.wall)
	-- upper landing L2 + top pad T (upper level floor)
	box("UpperLanding", 1, 31, 1, 7, highY - 1, highY, cfg.floor)
	box("TopPad", 26, 31, 7, 19, highY - 1, highY, cfg.floor)
	-- flights: F1 climbs toward the fore end of the tower, F2 back
	local function flight(name, startA, dir, d0, d1, baseY)
		local za, zb = Z(d0), Z(d1)
		local f = { axis = "x", start = ox + startA, dir = dir, c0 = math.min(za, zb), c1 = math.max(za, zb), baseY = baseY,
			rise = 8, style = cfg.tread, nosing = cfg.rail, name = stairId .. "_" .. name }
		Stairs.flight(ctx, parent, f)
		return f
	end
	local f1 = flight("F1", 26, -1, 7, 13, lowY)
	local f2 = flight("F2", 14, 1, 13, 19, midY)
	-- balustrades (guarding the drops) + handrails
	local railH = 3.6
	box("GuardL2", 1, 26, 6.8, 7.2, highY, highY + railH, cfg.rail, { shadow = false })
	box("GuardTop", 25.8, 26.2, 7, 13, highY, highY + railH, cfg.rail, { shadow = false })
	box("GuardMid", 14, 26, 12.8, 13.2, midY, midY + railH, cfg.rail, { shadow = false })
	Stairs.handrail(ctx, parent, f1, Z(7.4), cfg.rail, stairId .. "_RailF1")
	Stairs.handrail(ctx, parent, f2, Z(18.6), cfg.rail, stairId .. "_RailF2")
	-- landing lamp (emergency circuit): the warm landmark seen through both doors
	local lamp = box("LandingLamp", 5, 9, 18.6, 19, midY + 5, midY + 6.2, "lamp_warm", { collide = false, query = false, shadow = false })
	lamp:SetAttribute("Glow", true)
	lamp:SetAttribute("Circuit", "Emergency")
	ctx:light(lamp, "PointLight", { Range = 22, Brightness = 1.1, Color = "emergency" }, { circuit = "Emergency", priority = "Nav", nav = "StairLanding" })
	-- landing bench + porthole mural on the far wall
	box("Bench", 2, 8, 17, 18.8, midY, midY + 1.6, cfg.family == "public" and "fabric_coral" or "steel_paint", { shadow = false })
	-- deck plaques beside each door
	local lvls = {}
	for lvl in pairs(cfg.landingSign) do table.insert(lvls, lvl) end
	table.sort(lvls)
	for _, lvl in ipairs(lvls) do
		local text = cfg.landingSign[lvl]
		local ly = S.levels[lvl].floorY
		local p = Vector3.new(ox + 21.5, ly + 5.2, Z(1.05))
		Signs.make(ctx, parent, CFrame.lookAt(p, p + Vector3.new(0, 0, dsign)), 4.2, 1.1, text, cfg.family == "public" and "public" or "crew",
			{ name = stairId .. "_Plaque" .. lvl })
		local p2 = Vector3.new(ox + 16, ly + 9.4, Z(-0.05))
		Signs.make(ctx, parent, CFrame.lookAt(p2, p2 - Vector3.new(0, 0, dsign)), 4.4, 1, cfg.sign, cfg.family == "public" and "public" or "crew",
			{ name = stairId .. "_DoorSign" .. lvl })
	end
	if cfg.family ~= "public" then
		local p = Vector3.new(ox + 1.05, midY + 2, Z(10))
		Props.fireReel(ctx, parent, CFrame.lookAt(p, p + Vector3.new(1, 0, 0)))
	end
	return { f1 = f1, f2 = f2, midY = midY }
end

---------------------------------------------------------------------------
-- entry point
---------------------------------------------------------------------------
function Shell.build(ctx, decks, spec)
	local S = Shell.index(spec)
	for _, level in ipairs({ "A", "B", "C" }) do
		ctx:setRegion("REG_" .. level)
		local deck = decks[level]
		local f = {}
		for _, n in ipairs({ "Floors", "Walls", "Trim", "Doors", "Ceilings", "Lights", "Signs" }) do
			f[n] = ctx:folder(deck, n)
		end
		buildFloors(ctx, f, S, level)
		buildCorridorWalls(ctx, f, S, level)
		buildPartitions(ctx, f, S, level)
		buildOuterWalls(ctx, f, S, level)
		buildCorridorEnds(ctx, f, S, level)
		buildCeilings(ctx, f, S, level)
		buildCorridorDressing(ctx, f, S, level)
	end
	local stairs = {}
	for _, st in ipairs(spec.stairs) do
		local lvl = S.stairsAt[st.id].lowest.level
		ctx:setRegion("REG_" .. lvl)
		local folder = ctx:folder(decks[lvl], "Stair_" .. st.id)
		stairs[st.id] = buildStair(ctx, folder, S, st.id)
	end
	return S, stairs
end

return Shell
