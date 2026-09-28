-- Room-local coordinates for dressing rooms independent of side and variant.
--
--   u : along the ship (X) from the room's clear fore edge
--   v : depth from the corridor-wall face toward the outer wall
--   h : height above the room floor
--
-- Walls sit inside room boxes (the corridor keeps its full 8-stud clear width):
--   corridor wall core occupies the 1 stud nearest the corridor,
--   outer wall 1 stud at the hull side, partitions straddle the 32-stud lines.
-- Variant "v2" mirrors u, giving a different layout on the same footprint and
-- door position (spec: "same footprint + door positions; interior differs").
local RoomFrame = {}
RoomFrame.__index = RoomFrame

local SHIP_X0, SHIP_X1 = 0, 192

function RoomFrame.new(room, variant, specDoor)
	local o, s = room.origin, room.size
	local self = setmetatable({}, RoomFrame)
	self.id = room.id
	self.room = room
	self.variant = variant or "v1"
	self.side = (o[3] < 24) and "L" or "R"
	self.y = o[2]
	self.x0 = o[1] + ((o[1] == SHIP_X0) and 1 or 0.5)
	self.x1 = o[1] + s[1] - ((o[1] + s[1] == SHIP_X1) and 1 or 0.5)
	self.W = self.x1 - self.x0
	if self.side == "L" then
		self.zCorr = o[3] + s[3] - 1 -- 19: room face of the corridor wall
		self.zOuter = o[3] + 1 -- 1: room face of the outer wall
		self.vDir = -1
	else
		self.zCorr = o[3] + 1 -- 29
		self.zOuter = o[3] + s[3] - 1 -- 47
		self.vDir = 1
	end
	self.D = math.abs(self.zOuter - self.zCorr) -- 18
	self.mirror = self.variant == "v2"
	if specDoor then
		self.doorU = specDoor[1] - self.x0
	else
		self.doorU = self.W / 2
	end
	return self
end

function RoomFrame:mu(u)
	if self.mirror then return self.W - u end
	return u
end

-- world position from room-local (u, v, h); mirrored for v2
function RoomFrame:pos(u, v, h)
	return Vector3.new(self.x0 + self:mu(u), self.y + (h or 0), self.zCorr + self.vDir * v)
end

-- unmirrored world position (for spec-fixed things like the door)
function RoomFrame:posRaw(u, v, h)
	return Vector3.new(self.x0 + u, self.y + (h or 0), self.zCorr + self.vDir * v)
end

local function dirFor(self, facing)
	if facing == "corridor" then return Vector3.new(0, 0, -self.vDir) end
	if facing == "outer" then return Vector3.new(0, 0, self.vDir) end
	local fore = Vector3.new(-1, 0, 0)
	if facing == "fore" then return self.mirror and -fore or fore end
	if facing == "aft" then return self.mirror and fore or -fore end
	error("bad facing " .. tostring(facing))
end
RoomFrame.dir = dirFor

-- CFrame at (u, v, h) whose LookVector (prop front) points `facing`
function RoomFrame:cf(u, v, facing, h)
	local p = self:pos(u, v, h)
	return CFrame.lookAt(p, p + dirFor(self, facing))
end

-- world AABB of a local rectangle (u0..u1, v0..v1) and height range
function RoomFrame:box(u0, u1, v0, v1, h0, h1)
	local a = self:pos(u0, v0, h0 or 0)
	local b = self:pos(u1, v1, h1 or 8)
	return { math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z), math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z) }
end

-- convert a world position into local (u, v) (unmirrored)
function RoomFrame:toLocal(p)
	return p.X - self.x0, (p.Z - self.zCorr) * self.vDir
end

-- local u of a world x taking the variant into account
function RoomFrame:uOfWorldX(x)
	local u = x - self.x0
	if self.mirror then return self.W - u end
	return u
end

return RoomFrame
