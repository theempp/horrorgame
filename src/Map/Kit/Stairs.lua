-- Stair flights, landings and the accommodation ladder.
-- Steps are solid stacked boxes (no gaps under stairs to hide in or snag on).
local Map = script.Parent.Parent
local Scale = require(Map.Config.Scale)

local Stairs = {}

-- flight{ axis="x"|"z", start (coordinate along axis where the first riser is),
--         dir=+1/-1 (direction of travel while climbing), c0,c1 (across range),
--         baseY, rise (studs), riser, tread, style, nosing=style|nil, name }
-- Returns the far edge coordinate (top of the flight along axis).
function Stairs.flight(ctx, parent, f)
	local riser = f.riser or Scale.STAIR.riser
	local tread = f.tread or Scale.STAIR.tread
	local steps = math.floor(f.rise / riser + 0.5)
	local name = f.name or "Flight"
	for i = 1, steps do
		local s0 = f.start + (i - 1) * tread * f.dir
		local s1 = f.start + i * tread * f.dir
		local top = f.baseY + i * riser
		if f.axis == "x" then
			ctx:box(parent, name .. "_Step" .. i, s0, f.baseY - 0.5, f.c0, s1, top, f.c1, f.style, { shadow = i % 4 == 0 })
		else
			ctx:box(parent, name .. "_Step" .. i, f.c0, f.baseY - 0.5, s0, f.c1, top, s1, f.style, { shadow = i % 4 == 0 })
		end
		if f.nosing and i % 2 == 0 then
			local n0 = s0
			local n1 = s0 + 0.25 * f.dir
			if f.axis == "x" then
				ctx:box(parent, name .. "_Nose" .. i, n0, top - 0.02, f.c0 + 0.2, n1, top + 0.04, f.c1 - 0.2, f.nosing,
					{ collide = false, shadow = false, detail = true })
			else
				ctx:box(parent, name .. "_Nose" .. i, f.c0 + 0.2, top - 0.02, n0, f.c1 - 0.2, top + 0.04, n1, f.nosing,
					{ collide = false, shadow = false, detail = true })
			end
		end
	end
	return f.start + steps * tread * f.dir, f.baseY + steps * riser
end

-- Handrail following a flight on one side (c = across coordinate of the rail).
function Stairs.handrail(ctx, parent, f, c, style, name)
	local riser = f.riser or Scale.STAIR.riser
	local tread = f.tread or Scale.STAIR.tread
	local steps = math.floor(f.rise / riser + 0.5)
	local h = Scale.HANDRAIL_H
	local a0 = f.start
	local a1 = f.start + steps * tread * f.dir
	local y0 = f.baseY + riser + h
	local y1 = f.baseY + steps * riser + h
	local p0, p1
	if f.axis == "x" then
		p0, p1 = Vector3.new(a0, y0, c), Vector3.new(a1, y1, c)
	else
		p0, p1 = Vector3.new(c, y0, a0), Vector3.new(c, y1, a1)
	end
	ctx:bar(parent, name, p0, p1, 0.3, style, { shadow = false })
	-- balusters every 3 steps
	for i = 1, steps, 3 do
		local a = f.start + (i - 0.5) * tread * f.dir
		local top = f.baseY + i * riser
		local b0, b1
		if f.axis == "x" then
			b0, b1 = Vector3.new(a, top, c), Vector3.new(a, top + h - 0.1 + riser * 0.5, c)
		else
			b0, b1 = Vector3.new(c, top, a), Vector3.new(c, top + h - 0.1 + riser * 0.5, a)
		end
		ctx:bar(parent, name .. "_Baluster" .. i, b0, b1, 0.18, style, { shadow = false, detail = true })
	end
end

return Stairs
