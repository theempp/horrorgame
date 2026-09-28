-- Guard rails (>= 1.0 m, SOLAS/load-line) with an invisible anti-vault collider.
-- Roblox avatars can jump ~7 studs, so a 3.6-stud rail alone does not contain
-- players; every exterior drop edge gets a PlayBoundary strip up to +9 studs.
local Map = script.Parent.Parent
local Scale = require(Map.Config.Scale)

local Rails = {}

-- points: list of Vector3 at deck level. opts: style, height, postEvery,
-- boundary(bool, default true), gaps = { {i, t0, t1} } unused, name, mid(bool)
function Rails.run(ctx, parent, points, opts)
	opts = opts or {}
	local style = opts.style or "rail_white"
	local h = opts.height or Scale.RAIL_H
	local every = opts.postEvery or 6
	local name = opts.name or "Rail"
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local d = b - a
		local len = d.Magnitude
		if len > 0.05 then
			local up = Vector3.new(0, h, 0)
			ctx:bar(parent, name .. "_Top" .. i, a + up, b + up, { 0.35, 0.45 }, opts.topStyle or style, { shadow = false })
			if opts.mid ~= false then
				ctx:bar(parent, name .. "_Mid" .. i, a + up * 0.5, b + up * 0.5, 0.2, style, { shadow = false, detail = true })
			end
			local n = math.max(1, math.floor(len / every + 0.5))
			for k = 0, n - 1 do
				local p = a + d * (k / n)
				ctx:bar(parent, name .. "_Post" .. i .. "_" .. k, p, p + up, 0.3, style, { shadow = false })
			end
			if opts.boundary ~= false then
				local cf, l = ctx.axisFrame(a + Vector3.new(0, 4.5, 0), b + Vector3.new(0, 4.5, 0))
				ctx:part(parent, name .. "_Boundary" .. i, Vector3.new(l, 9, 0.4), cf, "volume",
					{ collide = true, query = false, shadow = false, transparency = 1, tags = { "PlayBoundary" } })
			end
		end
	end
	local last = points[#points]
	ctx:bar(parent, name .. "_PostEnd", last, last + Vector3.new(0, h, 0), 0.3, style, { shadow = false })
end

-- Solid bulwark plate (forecastle, bow) with a capping rail.
function Rails.bulwark(ctx, parent, points, h, style, capStyle, name)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local cf, l = ctx.axisFrame(a + Vector3.new(0, h / 2, 0), b + Vector3.new(0, h / 2, 0))
		ctx:part(parent, name .. "_Plate" .. i, Vector3.new(l + 0.3, h, 0.5), cf, style, { shadow = true })
		local cf2, l2 = ctx.axisFrame(a + Vector3.new(0, h + 0.2, 0), b + Vector3.new(0, h + 0.2, 0))
		ctx:part(parent, name .. "_Cap" .. i, Vector3.new(l2 + 0.3, 0.4, 0.9), cf2, capStyle or style, { shadow = false })
	end
end

return Rails
