-- Walls with rectangular openings, door casings, glazing, windows and portholes.
--
-- A wall is described along one axis:
--   axis = "x" : wall runs along X; a = x, t = z (thickness direction)
--   axis = "z" : wall runs along Z; a = z, t = x
-- openings = { {a0, a1, y0, y1, glass = bool, name = string}, ... }
-- Pieces are emitted so that openings keep their full clear size (kit rule:
-- door cutouts are 4x8 and centred on connection.at).
local Walls = {}

local function boxAlong(ctx, parent, name, axis, a0, a1, y0, y1, t0, t1, style, opts)
	if axis == "x" then
		return ctx:box(parent, name, a0, y0, t0, a1, y1, t1, style, opts)
	end
	return ctx:box(parent, name, t0, y0, a0, t1, y1, a1, style, opts)
end
Walls.boxAlong = boxAlong

function Walls.slab(ctx, parent, w)
	local name = w.name or "Wall"
	local opts = w.opts
	-- clip openings to the wall and collect breakpoints along the wall axis
	local openings = {}
	local cuts = { w.a0, w.a1 }
	for _, o in ipairs(w.openings or {}) do
		local oa0, oa1 = math.max(o[1], w.a0), math.min(o[2], w.a1)
		if oa1 > oa0 + 0.01 then
			local c = { oa0, oa1, math.max(o[3], w.y0), math.min(o[4], w.y1), glass = o.glass, glassStyle = o.glassStyle, glassAttrs = o.glassAttrs }
			table.insert(openings, c)
			table.insert(cuts, oa0)
			table.insert(cuts, oa1)
		end
	end
	table.sort(cuts)
	local n = 0
	local runStart = nil -- start of a run of intervals with no openings (merged into one piece)
	local function flushRun(upTo)
		if runStart and upTo > runStart + 0.01 then
			n = n + 1
			boxAlong(ctx, parent, name .. "_" .. n, w.axis, runStart, upTo, w.y0, w.y1, w.t0, w.t1, w.style, opts)
		end
		runStart = nil
	end
	for i = 1, #cuts - 1 do
		local s0, s1 = cuts[i], cuts[i + 1]
		if s1 > s0 + 0.01 then
			local cover = {}
			for _, o in ipairs(openings) do
				if o[1] <= s0 + 1e-6 and o[2] >= s1 - 1e-6 then table.insert(cover, o) end
			end
			if #cover == 0 then
				if not runStart then runStart = s0 end
			else
				flushRun(s0)
				table.sort(cover, function(p, q) return p[3] < q[3] end)
				local y = w.y0
				for _, o in ipairs(cover) do
					if o[3] < y - 1e-6 then
						ctx:issue(name .. ": overlapping openings at " .. tostring(s0))
					end
					if o[3] > y + 0.01 then
						n = n + 1
						boxAlong(ctx, parent, name .. "_Seg" .. n, w.axis, s0, s1, y, o[3], w.t0, w.t1, w.style, opts)
					end
					y = math.max(y, o[4])
				end
				if w.y1 > y + 0.01 then
					n = n + 1
					boxAlong(ctx, parent, name .. "_Seg" .. n, w.axis, s0, s1, y, w.y1, w.t0, w.t1, w.style, opts)
				end
			end
		end
	end
	flushRun(w.a1)
	-- glass panes: one per opening (not per interval)
	for k, o in ipairs(openings) do
		if o.glass then
			local mid = (w.t0 + w.t1) / 2
			local pane = boxAlong(ctx, parent, name .. "_Glass" .. k, w.axis, o[1], o[2], o[3], o[4], mid - 0.1, mid + 0.1,
				o.glassStyle or "glass_smoked", { tags = { "SightTransparent" }, shadow = false })
			if pane and o.glassAttrs then ctx:attrs(pane, o.glassAttrs) end
		end
	end
end

-- Casing around an opening on one face (tFace = the face plane, dir = +1/-1 outward).
-- The casing sits OUTSIDE the clear opening so the 4-stud clear width is kept.
function Walls.casing(ctx, parent, axis, a0, a1, y0, y1, tFace, dir, style, name, depth)
	depth = depth or 0.25
	local w = 0.45
	local t0, t1 = tFace, tFace + dir * depth
	boxAlong(ctx, parent, name .. "_JambA", axis, a0 - w, a0, y0, y1 + w, t0, t1, style, { shadow = false })
	boxAlong(ctx, parent, name .. "_JambB", axis, a1, a1 + w, y0, y1 + w, t0, t1, style, { shadow = false })
	boxAlong(ctx, parent, name .. "_Head", axis, a0, a1, y1, y1 + w, t0, t1, style, { shadow = false })
end

-- Door leaf presentation (DoorVisual). Default pose: swung open 90 deg against
-- the wall on the `side` (+1/-1 across t) of the wall. CanCollide=false:
-- collision is owned by the Codex door anchor at the same doorway.
function Walls.doorLeaf(ctx, parent, axis, a0, a1, y0, tWall, side, style, connId, hingeAtA0)
	local width = a1 - a0 - 0.2
	local height = 7.85
	local thick = 0.3
	local hingeA = hingeAtA0 and (a0 + 0.1) or (a1 - 0.1)
	local sign = hingeAtA0 and 1 or -1
	local model = ctx:model(parent, "DoorLeaf_" .. connId)
	local cf
	if axis == "x" then
		-- closed leaf spans a0..a1 along X at z = tWall; open leaf lies along Z
		local hinge = Vector3.new(hingeA, y0 + height / 2, tWall + side * 0.2)
		cf = CFrame.new(hinge + Vector3.new(0, 0, side * width / 2)) * CFrame.new(sign * thick / 2, 0, 0)
		ctx:part(model, "Leaf", Vector3.new(thick, height, width), cf, style, { collide = false, query = false })
		ctx:part(model, "Handle", Vector3.new(0.5, 0.25, 0.25),
			cf * CFrame.new(-sign * 0.3, -0.2, side * (width / 2 - 0.6)), "brass", { collide = false, query = false, shadow = false })
	else
		local hinge = Vector3.new(tWall + side * 0.2, y0 + height / 2, hingeA)
		cf = CFrame.new(hinge + Vector3.new(side * width / 2, 0, 0)) * CFrame.new(0, 0, sign * thick / 2)
		ctx:part(model, "Leaf", Vector3.new(width, height, thick), cf, style, { collide = false, query = false })
		ctx:part(model, "Handle", Vector3.new(0.25, 0.25, 0.5),
			cf * CFrame.new(side * (width / 2 - 0.6), -0.2, -sign * 0.3), "brass", { collide = false, query = false, shadow = false })
	end
	ctx:attrs(model, {
		ConnectionId = connId, Axis = axis, HingeA = hingeA, OpenSide = side, Width = width,
		HingeAtA0 = hingeAtA0 == true, WallT = tWall,
	})
	ctx:tag(model, "DoorVisual")
	return model
end

-- Rectangular window with frame + glass set into a wall that has an opening.
function Walls.windowFrame(ctx, parent, axis, a0, a1, y0, y1, tFace, dir, frameStyle, name)
	local d = 0.3
	local t0, t1 = tFace, tFace + dir * d
	local f = 0.35
	boxAlong(ctx, parent, name .. "_FrameT", axis, a0 - f, a1 + f, y1, y1 + f, t0, t1, frameStyle, { shadow = false })
	boxAlong(ctx, parent, name .. "_FrameB", axis, a0 - f, a1 + f, y0 - f, y0, t0, t1, frameStyle, { shadow = false })
	boxAlong(ctx, parent, name .. "_FrameL", axis, a0 - f, a0, y0, y1, t0, t1, frameStyle, { shadow = false })
	boxAlong(ctx, parent, name .. "_FrameR", axis, a1, a1 + f, y0, y1, t0, t1, frameStyle, { shadow = false })
	if a1 - a0 > 5 then
		local m = (a0 + a1) / 2
		boxAlong(ctx, parent, name .. "_Mullion", axis, m - 0.15, m + 0.15, y0, y1, t0, t1, frameStyle, { shadow = false })
	end
end

-- Porthole: brass ring disk + glass disk, facing the +dir side of a wall face.
-- normal is the outward unit vector of the face.
function Walls.porthole(ctx, parent, center, normal, radius, glassStyle, name, ringStyle)
	local a = center
	local b = center + normal * 0.25
	ctx:cyl(parent, name .. "_Ring", a, b, radius + 0.35, ringStyle or "brass", { shadow = false, collide = false })
	local g = ctx:cyl(parent, name .. "_Glass", center + normal * 0.2, center + normal * 0.32, radius, glassStyle or "window_dark",
		{ shadow = false, collide = false })
	return g
end

return Walls
