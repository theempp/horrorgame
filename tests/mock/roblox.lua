-- Headless Roblox API mock used by the Python test harness (lupa, Lua 5.1).
--
-- Purpose: execute the real Luau map generator outside Studio so its output can
-- be counted, measured and validated. The mock is deliberately STRICT:
--   * unknown classes, properties, enum items and attribute types raise errors,
--   * a few engine limits (light Range <= 60, Transparency 0..1) are enforced.
-- That turns the mock into a lint for API misuse that would otherwise only
-- surface in Studio. It is NOT a physics or rendering emulator.
--
-- The generator source is written in the Lua 5.1-compatible subset of Luau
-- (no type annotations, compound assignment, continue, or string interpolation)
-- so the same files run here and in Roblox unchanged.

local M = {}

---------------------------------------------------------------------------
-- Luau built-in polyfills (present in Roblox, absent in Lua 5.1)
---------------------------------------------------------------------------
table.unpack = table.unpack or unpack
function table.find(t, v, init)
	for i = init or 1, #t do
		if t[i] == v then return i end
	end
	return nil
end
function table.clone(t)
	local c = {}
	for k, v in pairs(t) do c[k] = v end
	return c
end
function table.create(n, v)
	local t = {}
	for i = 1, n do t[i] = v end
	return t
end
function table.clear(t)
	for k in pairs(t) do t[k] = nil end
end
function table.freeze(t) return t end
function math.clamp(x, a, b)
	assert(a <= b, "math.clamp: min > max")
	if x < a then return a elseif x > b then return b end
	return x
end
function math.round(x)
	if x >= 0 then return math.floor(x + 0.5) end
	return -math.floor(-x + 0.5)
end
function math.sign(x)
	if x > 0 then return 1 elseif x < 0 then return -1 end
	return 0
end
function string.split(s, sep)
	sep = sep or ","
	local out, i = {}, 1
	while true do
		local a, b = string.find(s, sep, i, true)
		if not a then
			table.insert(out, string.sub(s, i))
			break
		end
		table.insert(out, string.sub(s, i, a - 1))
		i = b + 1
	end
	return out
end

---------------------------------------------------------------------------
-- typeof
---------------------------------------------------------------------------
local TYPE_KEY = {}
local function tagged(mt, name)
	mt[TYPE_KEY] = name
	return mt
end
function typeof(v)
	local t = type(v)
	if t == "table" then
		local mt = getmetatable(v)
		if mt and mt[TYPE_KEY] then return mt[TYPE_KEY] end
	end
	return t
end

---------------------------------------------------------------------------
-- Vector3 / Vector2
---------------------------------------------------------------------------
local V3 = tagged({}, "Vector3")
Vector3 = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3)
end
Vector3.new = function(x, y, z)
	assert(x == nil or type(x) == "number", "Vector3.new expects numbers")
	return v3(x, y, z)
end
Vector3.zero = v3(0, 0, 0)
Vector3.one = v3(1, 1, 1)
Vector3.xAxis = v3(1, 0, 0)
Vector3.yAxis = v3(0, 1, 0)
Vector3.zAxis = v3(0, 0, 1)
local V3methods = {}
function V3methods.Dot(a, b) return a.X * b.X + a.Y * b.Y + a.Z * b.Z end
function V3methods.Cross(a, b)
	return v3(a.Y * b.Z - a.Z * b.Y, a.Z * b.X - a.X * b.Z, a.X * b.Y - a.Y * b.X)
end
function V3methods.Lerp(a, b, t) return a + (b - a) * t end
function V3methods.Abs(a) return v3(math.abs(a.X), math.abs(a.Y), math.abs(a.Z)) end
function V3methods.Min(a, b) return v3(math.min(a.X, b.X), math.min(a.Y, b.Y), math.min(a.Z, b.Z)) end
function V3methods.Max(a, b) return v3(math.max(a.X, b.X), math.max(a.Y, b.Y), math.max(a.Z, b.Z)) end
function V3methods.FuzzyEq(a, b, eps)
	eps = eps or 1e-5
	return math.abs(a.X - b.X) <= eps and math.abs(a.Y - b.Y) <= eps and math.abs(a.Z - b.Z) <= eps
end
V3.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z) end
	if k == "Unit" then
		local m = math.sqrt(v.X * v.X + v.Y * v.Y + v.Z * v.Z)
		if m == 0 then return v3(0 / 0, 0 / 0, 0 / 0) end
		return v3(v.X / m, v.Y / m, v.Z / m)
	end
	local f = V3methods[k]
	if f then return f end
	error("Vector3 has no member " .. tostring(k), 2)
end
V3.__newindex = function() error("Vector3 is immutable", 2) end
V3.__add = function(a, b) return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z) end
V3.__sub = function(a, b) return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z) end
V3.__unm = function(a) return v3(-a.X, -a.Y, -a.Z) end
V3.__mul = function(a, b)
	if type(a) == "number" then return v3(a * b.X, a * b.Y, a * b.Z) end
	if type(b) == "number" then return v3(a.X * b, a.Y * b, a.Z * b) end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3.__div = function(a, b)
	if type(b) == "number" then return v3(a.X / b, a.Y / b, a.Z / b) end
	return v3(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
V3.__eq = function(a, b) return a.X == b.X and a.Y == b.Y and a.Z == b.Z end
V3.__tostring = function(v) return string.format("%g, %g, %g", v.X, v.Y, v.Z) end

local V2 = tagged({}, "Vector2")
Vector2 = {}
local function v2(x, y) return setmetatable({ X = x or 0, Y = y or 0 }, V2) end
Vector2.new = v2
Vector2.zero = v2(0, 0)
V2.__index = function(v, k)
	if k == "Magnitude" then return math.sqrt(v.X * v.X + v.Y * v.Y) end
	error("Vector2 has no member " .. tostring(k), 2)
end
V2.__add = function(a, b) return v2(a.X + b.X, a.Y + b.Y) end
V2.__sub = function(a, b) return v2(a.X - b.X, a.Y - b.Y) end
V2.__mul = function(a, b)
	if type(b) == "number" then return v2(a.X * b, a.Y * b) end
	return v2(a.X * b.X, a.Y * b.Y)
end

---------------------------------------------------------------------------
-- CFrame (position + row-major rotation matrix)
---------------------------------------------------------------------------
local CF = tagged({}, "CFrame")
CFrame = {}
local function cf(px, py, pz, r)
	return setmetatable({ _p = v3(px, py, pz), _r = r }, CF)
end
local IDR = { 1, 0, 0, 0, 1, 0, 0, 0, 1 }
local function matmul(a, b)
	local r = {}
	for i = 0, 2 do
		for j = 0, 2 do
			local s = 0
			for k = 0, 2 do s = s + a[i * 3 + k + 1] * b[k * 3 + j + 1] end
			r[i * 3 + j + 1] = s
		end
	end
	return r
end
local function rotv(r, v)
	return v3(
		r[1] * v.X + r[2] * v.Y + r[3] * v.Z,
		r[4] * v.X + r[5] * v.Y + r[6] * v.Z,
		r[7] * v.X + r[8] * v.Y + r[9] * v.Z
	)
end
local function transpose(r)
	return { r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }
end
local function rx(a)
	local c, s = math.cos(a), math.sin(a)
	return { 1, 0, 0, 0, c, -s, 0, s, c }
end
local function ry(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, 0, s, 0, 1, 0, -s, 0, c }
end
local function rz(a)
	local c, s = math.cos(a), math.sin(a)
	return { c, -s, 0, s, c, 0, 0, 0, 1 }
end
local function fromMatrix(pos, vx, vy, vz)
	if not vz then vz = vx:Cross(vy).Unit end
	return cf(pos.X, pos.Y, pos.Z, { vx.X, vy.X, vz.X, vx.Y, vy.Y, vz.Y, vx.Z, vy.Z, vz.Z })
end
local function lookAt(at, target, up)
	up = up or Vector3.yAxis
	local look = (target - at).Unit
	local right = look:Cross(up)
	if right.Magnitude < 1e-6 then right = look:Cross(Vector3.zAxis) end
	right = right.Unit
	local up2 = right:Cross(look).Unit
	return fromMatrix(at, right, up2, -look)
end
CFrame.new = function(a, b, c, ...)
	if a == nil then return cf(0, 0, 0, IDR) end
	if typeof(a) == "Vector3" then
		if b ~= nil then return lookAt(a, b) end
		return cf(a.X, a.Y, a.Z, IDR)
	end
	local rest = { ... }
	if #rest == 9 then return cf(a, b, c, rest) end
	assert(#rest == 0, "CFrame.new: unsupported arity")
	assert(type(a) == "number" and type(b) == "number" and type(c) == "number", "CFrame.new expects numbers")
	return cf(a, b, c, IDR)
end
CFrame.identity = cf(0, 0, 0, IDR)
CFrame.Angles = function(x, y, z) return cf(0, 0, 0, matmul(matmul(rx(x), ry(y)), rz(z))) end
CFrame.fromEulerAnglesXYZ = CFrame.Angles
CFrame.fromEulerAnglesYXZ = function(x, y, z) return cf(0, 0, 0, matmul(matmul(ry(y), rx(x)), rz(z))) end
CFrame.fromOrientation = CFrame.fromEulerAnglesYXZ
CFrame.fromAxisAngle = function(axis, a)
	local u = axis.Unit
	local c, s, t = math.cos(a), math.sin(a), 1 - math.cos(a)
	return cf(0, 0, 0, {
		t * u.X * u.X + c, t * u.X * u.Y - s * u.Z, t * u.X * u.Z + s * u.Y,
		t * u.X * u.Y + s * u.Z, t * u.Y * u.Y + c, t * u.Y * u.Z - s * u.X,
		t * u.X * u.Z - s * u.Y, t * u.Y * u.Z + s * u.X, t * u.Z * u.Z + c,
	})
end
CFrame.lookAt = lookAt
CFrame.fromMatrix = fromMatrix
local CFmethods = {}
function CFmethods.Inverse(c)
	local rt = transpose(c._r)
	local p = rotv(rt, c._p)
	return cf(-p.X, -p.Y, -p.Z, rt)
end
function CFmethods.ToWorldSpace(c, o) return c * o end
function CFmethods.ToObjectSpace(c, o) return c:Inverse() * o end
function CFmethods.PointToWorldSpace(c, v) return c * v end
function CFmethods.PointToObjectSpace(c, v) return c:Inverse() * v end
function CFmethods.VectorToWorldSpace(c, v) return rotv(c._r, v) end
function CFmethods.VectorToObjectSpace(c, v) return rotv(transpose(c._r), v) end
function CFmethods.GetComponents(c)
	local r = c._r
	return c._p.X, c._p.Y, c._p.Z, r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9]
end
CFmethods.components = CFmethods.GetComponents
function CFmethods.Lerp(a, b, t)
	-- position-only lerp is sufficient for the generator (it never lerps rotations)
	local p = a._p:Lerp(b._p, t)
	return cf(p.X, p.Y, p.Z, a._r)
end
CF.__index = function(c, k)
	if k == "Position" or k == "p" then return c._p end
	if k == "X" then return c._p.X end
	if k == "Y" then return c._p.Y end
	if k == "Z" then return c._p.Z end
	local r = c._r
	if k == "RightVector" or k == "XVector" then return v3(r[1], r[4], r[7]) end
	if k == "UpVector" or k == "YVector" then return v3(r[2], r[5], r[8]) end
	if k == "LookVector" then return v3(-r[3], -r[6], -r[9]) end
	if k == "ZVector" then return v3(r[3], r[6], r[9]) end
	if k == "Rotation" then return cf(0, 0, 0, r) end
	local f = CFmethods[k]
	if f then return f end
	error("CFrame has no member " .. tostring(k), 2)
end
CF.__newindex = function() error("CFrame is immutable", 2) end
CF.__mul = function(a, b)
	if typeof(b) == "Vector3" then return rotv(a._r, b) + a._p end
	assert(typeof(b) == "CFrame", "CFrame * expects CFrame or Vector3")
	local p = rotv(a._r, b._p) + a._p
	return cf(p.X, p.Y, p.Z, matmul(a._r, b._r))
end
CF.__add = function(a, b)
	local p = a._p + b
	return cf(p.X, p.Y, p.Z, a._r)
end
CF.__sub = function(a, b)
	local p = a._p - b
	return cf(p.X, p.Y, p.Z, a._r)
end
CF.__eq = function(a, b)
	if not (a._p == b._p) then return false end
	for i = 1, 9 do
		if a._r[i] ~= b._r[i] then return false end
	end
	return true
end

---------------------------------------------------------------------------
-- Color3, BrickColor, UDim/UDim2, ranges and sequences, Font, misc
---------------------------------------------------------------------------
local C3 = tagged({}, "Color3")
Color3 = {}
local function c3(r, g, b)
	assert(type(r) == "number" and type(g) == "number" and type(b) == "number", "Color3 expects numbers")
	return setmetatable({ R = r, G = g, B = b }, C3)
end
Color3.new = function(r, g, b) return c3(r or 0, g or 0, b or 0) end
Color3.fromRGB = function(r, g, b)
	assert(r >= 0 and r <= 255 and g >= 0 and g <= 255 and b >= 0 and b <= 255, "Color3.fromRGB out of range")
	return c3(r / 255, g / 255, b / 255)
end
Color3.fromHex = function(h)
	h = string.gsub(h, "#", "")
	return Color3.fromRGB(tonumber(string.sub(h, 1, 2), 16), tonumber(string.sub(h, 3, 4), 16), tonumber(string.sub(h, 5, 6), 16))
end
Color3.fromHSV = function(h, s, v)
	local i = math.floor(h * 6)
	local f = h * 6 - i
	local p, q, t = v * (1 - s), v * (1 - f * s), v * (1 - (1 - f) * s)
	i = i % 6
	if i == 0 then return c3(v, t, p) elseif i == 1 then return c3(q, v, p) elseif i == 2 then return c3(p, v, t)
	elseif i == 3 then return c3(p, q, v) elseif i == 4 then return c3(t, p, v) end
	return c3(v, p, q)
end
C3.__index = function(c, k)
	if k == "Lerp" then
		return function(a, b, t) return c3(a.R + (b.R - a.R) * t, a.G + (b.G - a.G) * t, a.B + (b.B - a.B) * t) end
	end
	if k == "ToHex" then
		return function(a)
			return string.format("%02x%02x%02x", math.floor(a.R * 255 + 0.5), math.floor(a.G * 255 + 0.5), math.floor(a.B * 255 + 0.5))
		end
	end
	if k == "ToHSV" then
		return function(a)
			local mx, mn = math.max(a.R, a.G, a.B), math.min(a.R, a.G, a.B)
			return 0, (mx == 0) and 0 or (mx - mn) / mx, mx
		end
	end
	error("Color3 has no member " .. tostring(k), 2)
end
C3.__eq = function(a, b) return a.R == b.R and a.G == b.G and a.B == b.B end

local UD = tagged({}, "UDim")
UDim = { new = function(s, o) return setmetatable({ Scale = s or 0, Offset = o or 0 }, UD) end }
local UD2 = tagged({}, "UDim2")
UDim2 = {
	new = function(xs, xo, ys, yo)
		return setmetatable({ X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }, UD2)
	end,
}
UDim2.fromScale = function(x, y) return UDim2.new(x, 0, y, 0) end
UDim2.fromOffset = function(x, y) return UDim2.new(0, x, 0, y) end

local NR = tagged({}, "NumberRange")
NumberRange = { new = function(a, b) return setmetatable({ Min = a, Max = b or a }, NR) end }
local NSK = tagged({}, "NumberSequenceKeypoint")
NumberSequenceKeypoint = { new = function(t, v, e) return setmetatable({ Time = t, Value = v, Envelope = e or 0 }, NSK) end }
local NS = tagged({}, "NumberSequence")
NumberSequence = {
	new = function(a, b)
		if type(a) == "table" then return setmetatable({ Keypoints = a }, NS) end
		return setmetatable({ Keypoints = { NumberSequenceKeypoint.new(0, a), NumberSequenceKeypoint.new(1, b or a) } }, NS)
	end,
}
local CSK = tagged({}, "ColorSequenceKeypoint")
ColorSequenceKeypoint = { new = function(t, c) return setmetatable({ Time = t, Value = c }, CSK) end }
local CS = tagged({}, "ColorSequence")
ColorSequence = {
	new = function(a, b)
		if typeof(a) == "Color3" then
			return setmetatable({ Keypoints = { ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(1, b or a) } }, CS)
		end
		return setmetatable({ Keypoints = a }, CS)
	end,
}
local FONT = tagged({}, "Font")
Font = {
	new = function(family, weight, style) return setmetatable({ Family = family, Weight = weight, Style = style }, FONT) end,
	fromEnum = function(e) return setmetatable({ Family = e.Name }, FONT) end,
	fromName = function(n) return setmetatable({ Family = n }, FONT) end,
}
local TI = tagged({}, "TweenInfo")
TweenInfo = { new = function(...) return setmetatable({ args = { ... } }, TI) end }
local RECT = tagged({}, "Rect")
Rect = { new = function(...) return setmetatable({ args = { ... } }, RECT) end }
local PP = tagged({}, "PhysicalProperties")
PhysicalProperties = { new = function(...) return setmetatable({ args = { ... } }, PP) end }
local BC = tagged({}, "BrickColor")
BrickColor = { new = function(n) return setmetatable({ Name = n }, BC) end }

---------------------------------------------------------------------------
-- Enum (strict: unknown enum types or items error)
---------------------------------------------------------------------------
local ENUMS = {
	Material = {
		"Plastic", "SmoothPlastic", "Neon", "Wood", "WoodPlanks", "Marble", "Slate", "Concrete",
		"Granite", "Brick", "Pebble", "Cobblestone", "CorrodedMetal", "DiamondPlate", "Foil", "Metal",
		"Grass", "Sand", "Fabric", "Ice", "Glass", "ForceField", "Rock", "Basalt", "Asphalt",
		"LeafyGrass", "Limestone", "Pavement", "Salt", "Sandstone", "Snow", "Mud", "Ground",
		"CrackedLava", "Glacier", "Water", "Air", "Carpet",
		-- Newer materials (Plaster, Leather, Rubber, ...) are deliberately absent: they were not
		-- confirmed in the fetched Creator docs, so the generator must not depend on them.
	},
	PartType = { "Ball", "Block", "Cylinder", "Wedge", "CornerWedge" },
	NormalId = { "Right", "Top", "Back", "Left", "Bottom", "Front" },
	SurfaceType = { "Smooth", "Glue", "Weld", "Studs", "Inlet", "Universal", "Hinge", "Motor", "SteppingMotor", "SmoothNoOutlines" },
	Font = {
		"Legacy", "Arial", "ArialBold", "SourceSans", "SourceSansBold", "SourceSansSemibold", "SourceSansLight",
		"SourceSansItalic", "Bodoni", "Garamond", "Cartoon", "Code", "Highway", "SciFi", "Arcade", "Fantasy",
		"Antique", "Gotham", "GothamMedium", "GothamBold", "GothamBlack", "AmaticSC", "Bangers", "Creepster",
		"DenkOne", "Fondamento", "FredokaOne", "GrenzeGotisch", "IndieFlower", "JosefinSans", "Jura", "Kalam",
		"LuckiestGuy", "Merriweather", "Michroma", "Nunito", "Oswald", "PatrickHand", "PermanentMarker",
		"Roboto", "RobotoCondensed", "RobotoMono", "Sarpanch", "SpecialElite", "TitilliumWeb", "Ubuntu",
		"BuilderSans", "BuilderSansMedium", "BuilderSansBold", "BuilderSansExtraBold", "Arimo", "ArimoBold",
	},
	SurfaceGuiSizingMode = { "FixedSize", "PixelsPerStud" },
	TextXAlignment = { "Left", "Center", "Right" },
	TextYAlignment = { "Top", "Center", "Bottom" },
	ModelStreamingMode = { "Default", "Atomic", "Persistent", "PersistentPerPlayer", "Nonatomic" },
	ModelLevelOfDetail = { "Automatic", "StreamingMesh", "Disabled", "SLIM" },
	LightingStyle = { "Realistic", "Soft" },
	SortOrder = { "Name", "Custom", "LayoutOrder" },
	FillDirection = { "Horizontal", "Vertical" },
	HorizontalAlignment = { "Center", "Left", "Right" },
	VerticalAlignment = { "Center", "Top", "Bottom" },
	AutomaticSize = { "None", "X", "Y", "XY" },
	ZIndexBehavior = { "Global", "Sibling" },
	EasingStyle = { "Linear", "Sine", "Back", "Quad", "Quart", "Quint", "Bounce", "Elastic", "Exponential", "Circular", "Cubic" },
	EasingDirection = { "In", "Out", "InOut" },
	KeyCode = { "M", "F", "G", "H", "J", "K", "L", "N", "R", "T", "V", "X", "Z", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Zero", "Tab", "Escape", "LeftShift", "Q", "E", "B", "C", "P", "Semicolon", "Quote", "LeftBracket", "RightBracket" },
	UserInputType = { "MouseButton1", "Touch", "Keyboard", "Gamepad1" },
	UserInputState = { "Begin", "Change", "End", "Cancel", "None" },
	CollisionFidelity = { "Default", "Hull", "Box", "PreciseConvexDecomposition" },
	RenderFidelity = { "Automatic", "Precise", "Performance" },
	ApplyStrokeMode = { "Contextual", "Border" },
	SavedQualitySetting = { "Automatic", "QualityLevel1", "QualityLevel2", "QualityLevel3", "QualityLevel4", "QualityLevel5", "QualityLevel6", "QualityLevel7", "QualityLevel8", "QualityLevel9", "QualityLevel10" },
	HumanoidStateType = { "Running", "Jumping", "Freefall", "Landed", "Seated", "Dead" },
	CameraType = { "Custom", "Scriptable", "Fixed", "Follow", "Track", "Watch", "Attach", "Orbital" },
	ScaleType = { "Stretch", "Slice", "Tile", "Fit", "Crop" },
	BorderMode = { "Outline", "Middle", "Inset" },
	ParticleOrientation = { "FacingCamera", "FacingCameraWorldUp", "VelocityParallel", "VelocityPerpendicular" },
	ResamplerMode = { "Default", "Pixelated" },
	TextTruncate = { "None", "AtEnd", "SplitWord" },
	AspectType = { "FitWithinMaxSize", "ScaleWithParentSize" },
	DominantAxis = { "Width", "Height" },
	ContextActionPriority = { "Low", "Medium", "Default", "High" },
}
local enumTypes = {}
local ENUMITEM = tagged({}, "EnumItem")
ENUMITEM.__tostring = function(e) return "Enum." .. e.EnumType .. "." .. e.Name end
local function makeEnumType(tname, items)
	local t = { __items = {} }
	for i, n in ipairs(items) do
		t.__items[n] = setmetatable({ Name = n, Value = i - 1, EnumType = tname }, ENUMITEM)
	end
	t.GetEnumItems = function()
		local out = {}
		for _, n in ipairs(items) do table.insert(out, t.__items[n]) end
		return out
	end
	return setmetatable(t, {
		__index = function(_, k)
			local it = rawget(t, "__items")[k]
			if not it then error("Enum." .. tname .. " has no item " .. tostring(k), 2) end
			return it
		end,
	})
end
for tname, items in pairs(ENUMS) do enumTypes[tname] = makeEnumType(tname, items) end
Enum = setmetatable({}, {
	__index = function(_, k)
		local t = enumTypes[k]
		if not t then error("Unknown enum type Enum." .. tostring(k), 2) end
		return t
	end,
})

---------------------------------------------------------------------------
-- Signals
---------------------------------------------------------------------------
local SIGNAL = tagged({}, "RBXScriptSignal")
SIGNAL.__index = SIGNAL
function SIGNAL:Connect(fn)
	table.insert(self._fns, fn)
	return { Disconnect = function() end, Connected = true }
end
SIGNAL.Once = SIGNAL.Connect
function SIGNAL:Wait() return nil end
function SIGNAL:Fire(...)
	for _, fn in ipairs(self._fns) do fn(...) end
end
local function newSignal() return setmetatable({ _fns = {} }, SIGNAL) end
M.newSignal = newSignal

---------------------------------------------------------------------------
-- Class schema. Only properties listed here may be read/written.
-- Value "check" names: n=number b=boolean s=string v3 cf c3 enum:<Type>
-- udim udim2 v2 nr ns cs font inst any
---------------------------------------------------------------------------
local CLASSES = {}
local function class(name, parent, props, opts)
	CLASSES[name] = { parent = parent, props = props or {}, opts = opts or {} }
end

class("Instance", nil, { Name = "s", Parent = "inst", Archivable = "b" })
class("Folder", "Instance")
class("Configuration", "Instance")
class("PVInstance", "Instance")
class("Model", "PVInstance", {
	PrimaryPart = "inst", WorldPivot = "cf", ModelStreamingMode = "enum:ModelStreamingMode",
	LevelOfDetail = "enum:ModelLevelOfDetail",
})
class("WorldRoot", "Model")
class("Workspace", "WorldRoot", {
	Gravity = "n", CurrentCamera = "inst",
})
local BASEPART = {
	Size = "v3", CFrame = "cf", Position = "v3", Anchored = "b", CanCollide = "b", CanTouch = "b",
	CanQuery = "b", CastShadow = "b", Material = "enum:Material", MaterialVariant = "s", Color = "c3",
	Transparency = "n", Reflectance = "n", Locked = "b", Massless = "b", TopSurface = "enum:SurfaceType",
	BottomSurface = "enum:SurfaceType", LeftSurface = "enum:SurfaceType", RightSurface = "enum:SurfaceType",
	FrontSurface = "enum:SurfaceType", BackSurface = "enum:SurfaceType", CollisionGroup = "s",
	AssemblyLinearVelocity = "v3", BrickColor = "any",
}
class("BasePart", "PVInstance", BASEPART)
class("FormFactorPart", "BasePart")
class("Part", "FormFactorPart", { Shape = "enum:PartType" })
class("WedgePart", "FormFactorPart")
class("CornerWedgePart", "BasePart")
class("TrussPart", "BasePart")
class("Terrain", "BasePart", {
	WaterColor = "c3", WaterReflectance = "n", WaterTransparency = "n", WaterWaveSize = "n",
	WaterWaveSpeed = "n", Decoration = "b",
})
class("SpecialMesh", "Instance", { MeshType = "any", Scale = "v3", Offset = "v3" })
class("Light", "Instance", { Brightness = "n", Color = "c3", Enabled = "b", Range = "n", Shadows = "b" })
class("PointLight", "Light")
class("SpotLight", "Light", { Angle = "n", Face = "enum:NormalId" })
class("SurfaceLight", "Light", { Angle = "n", Face = "enum:NormalId" })
class("Attachment", "Instance", { CFrame = "cf", Position = "v3", Visible = "b", WorldPosition = "v3" })
class("Beam", "Instance", {
	Attachment0 = "inst", Attachment1 = "inst", Color = "cs", Transparency = "ns", Width0 = "n", Width1 = "n",
	LightEmission = "n", LightInfluence = "n", FaceCamera = "b", Segments = "n", Enabled = "b", Brightness = "n",
	Texture = "s", TextureLength = "n", TextureSpeed = "n", CurveSize0 = "n", CurveSize1 = "n", ZOffset = "n",
})
class("ParticleEmitter", "Instance", {
	Rate = "n", Lifetime = "nr", Speed = "nr", Size = "ns", Transparency = "ns", Color = "cs",
	LightEmission = "n", LightInfluence = "n", SpreadAngle = "v2", Acceleration = "v3", Texture = "s",
	Enabled = "b", Drag = "n", Rotation = "nr", RotSpeed = "nr", EmissionDirection = "enum:NormalId",
	Orientation = "enum:ParticleOrientation", Brightness = "n", ZOffset = "n", LockedToPart = "b",
	VelocityInheritance = "n", Squash = "ns", TimeScale = "n",
})
class("GuiBase", "Instance")
class("LayerCollector", "GuiBase", { Enabled = "b", ResetOnSpawn = "b", ZIndexBehavior = "enum:ZIndexBehavior" })
class("SurfaceGuiBase", "LayerCollector", { Adornee = "inst", Face = "enum:NormalId", Active = "b" })
class("SurfaceGui", "SurfaceGuiBase", {
	CanvasSize = "v2", SizingMode = "enum:SurfaceGuiSizingMode", PixelsPerStud = "n", LightInfluence = "n",
	Brightness = "n", AlwaysOnTop = "b", MaxDistance = "n", ClipsDescendants = "b", ZOffset = "n",
})
class("BillboardGui", "LayerCollector", {
	Adornee = "inst", Size = "udim2", StudsOffset = "v3", StudsOffsetWorldSpace = "v3", AlwaysOnTop = "b",
	MaxDistance = "n", LightInfluence = "n", Brightness = "n", ClipsDescendants = "b", ExtentsOffset = "v3",
})
class("ScreenGui", "LayerCollector", { IgnoreGuiInset = "b", DisplayOrder = "n", ScreenInsets = "any" })
local GUIOBJ = {
	Size = "udim2", Position = "udim2", AnchorPoint = "v2", BackgroundColor3 = "c3", BackgroundTransparency = "n",
	BorderSizePixel = "n", BorderColor3 = "c3", Visible = "b", ZIndex = "n", LayoutOrder = "n", Rotation = "n",
	ClipsDescendants = "b", AutomaticSize = "enum:AutomaticSize", Active = "b", Selectable = "b",
}
class("GuiObject", "GuiBase", GUIOBJ)
class("Frame", "GuiObject")
class("ScrollingFrame", "GuiObject", { CanvasSize = "udim2", ScrollBarThickness = "n", AutomaticCanvasSize = "enum:AutomaticSize", ScrollingDirection = "any" })
local TEXT = {
	Text = "s", TextColor3 = "c3", TextScaled = "b", TextSize = "n", Font = "enum:Font", FontFace = "font",
	TextWrapped = "b", TextXAlignment = "enum:TextXAlignment", TextYAlignment = "enum:TextYAlignment",
	TextStrokeTransparency = "n", TextStrokeColor3 = "c3", TextTransparency = "n", RichText = "b",
	LineHeight = "n", TextTruncate = "enum:TextTruncate", MaxVisibleGraphemes = "n",
}
class("TextLabel", "GuiObject", TEXT)
class("TextButton", "GuiObject", TEXT)
CLASSES.TextButton.props.AutoButtonColor = "b"
class("TextBox", "GuiObject", TEXT)
class("ImageLabel", "GuiObject", { Image = "s", ImageColor3 = "c3", ImageTransparency = "n", ScaleType = "enum:ScaleType" })
class("UIComponent", "Instance")
class("UIGradient", "UIComponent", { Color = "cs", Rotation = "n", Transparency = "ns", Offset = "v2", Enabled = "b" })
class("UICorner", "UIComponent", { CornerRadius = "udim" })
class("UIStroke", "UIComponent", { Color = "c3", Thickness = "n", Transparency = "n", ApplyStrokeMode = "enum:ApplyStrokeMode", Enabled = "b" })
class("UIPadding", "UIComponent", { PaddingTop = "udim", PaddingBottom = "udim", PaddingLeft = "udim", PaddingRight = "udim" })
class("UIListLayout", "UIComponent", {
	FillDirection = "enum:FillDirection", Padding = "udim", SortOrder = "enum:SortOrder",
	HorizontalAlignment = "enum:HorizontalAlignment", VerticalAlignment = "enum:VerticalAlignment", Wraps = "b",
})
class("UIGridLayout", "UIComponent", { CellSize = "udim2", CellPadding = "udim2", SortOrder = "enum:SortOrder", FillDirection = "enum:FillDirection" })
class("UIAspectRatioConstraint", "UIComponent", { AspectRatio = "n", AspectType = "enum:AspectType", DominantAxis = "enum:DominantAxis" })
class("UISizeConstraint", "UIComponent", { MinSize = "v2", MaxSize = "v2" })
class("UITextSizeConstraint", "UIComponent", { MinTextSize = "n", MaxTextSize = "n" })
class("UIScale", "UIComponent", { Scale = "n" })
class("Atmosphere", "Instance", { Density = "n", Offset = "n", Color = "c3", Decay = "c3", Glare = "n", Haze = "n" })
class("Sky", "Instance", {
	StarCount = "n", CelestialBodiesShown = "b", MoonAngularSize = "n", SunAngularSize = "n",
	SkyboxBk = "s", SkyboxDn = "s", SkyboxFt = "s", SkyboxLf = "s", SkyboxRt = "s", SkyboxUp = "s",
	MoonTextureId = "s", SunTextureId = "s",
})
class("Clouds", "Instance", { Cover = "n", Density = "n", Color = "c3", Enabled = "b" })
class("PostEffect", "Instance", { Enabled = "b" })
class("ColorCorrectionEffect", "PostEffect", { Brightness = "n", Contrast = "n", Saturation = "n", TintColor = "c3" })
class("BloomEffect", "PostEffect", { Intensity = "n", Size = "n", Threshold = "n" })
class("DepthOfFieldEffect", "PostEffect", { FarIntensity = "n", FocusDistance = "n", InFocusRadius = "n", NearIntensity = "n" })
class("SunRaysEffect", "PostEffect", { Intensity = "n", Spread = "n" })
class("BlurEffect", "PostEffect", { Size = "n" })
class("PathfindingModifier", "Instance", { Label = "s", PassThrough = "b" })
class("ValueBase", "Instance")
class("StringValue", "ValueBase", { Value = "s" })
class("NumberValue", "ValueBase", { Value = "n" })
class("IntValue", "ValueBase", { Value = "n" })
class("BoolValue", "ValueBase", { Value = "b" })
class("ObjectValue", "ValueBase", { Value = "inst" })
class("Vector3Value", "ValueBase", { Value = "v3" })
class("Highlight", "Instance", {
	Adornee = "inst", FillColor = "c3", FillTransparency = "n", OutlineColor = "c3", OutlineTransparency = "n",
	DepthMode = "any", Enabled = "b",
})
class("SelectionBox", "Instance", { Adornee = "inst", Color3 = "c3", LineThickness = "n", SurfaceColor3 = "c3", SurfaceTransparency = "n", Transparency = "n", Visible = "b" })
class("LuaSourceContainer", "Instance", { Disabled = "b", Enabled = "b" })
class("ModuleScript", "LuaSourceContainer")
class("Script", "LuaSourceContainer")
class("LocalScript", "Script")
class("RemoteEvent", "Instance")
class("BindableEvent", "Instance")
class("Camera", "Instance", { CFrame = "cf", FieldOfView = "n", CameraType = "enum:CameraType", CameraSubject = "inst", Focus = "cf" })
class("Lighting", "Instance", {
	Ambient = "c3", OutdoorAmbient = "c3", Brightness = "n", ClockTime = "n", GeographicLatitude = "n",
	ColorShift_Top = "c3", ColorShift_Bottom = "c3", EnvironmentDiffuseScale = "n", EnvironmentSpecularScale = "n",
	ExposureCompensation = "n", GlobalShadows = "b", ShadowSoftness = "n", FogColor = "c3", FogStart = "n",
	FogEnd = "n", LightingStyle = "enum:LightingStyle", PrioritizeLightingQuality = "b", TimeOfDay = "s",
})
class("ServiceProvider", "Instance")
class("DataModel", "ServiceProvider")
class("ReplicatedStorage", "Instance")
class("ServerStorage", "Instance")
class("ServerScriptService", "Instance")
class("StarterPlayer", "Instance")
class("StarterPlayerScripts", "Instance")
class("CollectionService", "Instance")
class("MaterialService", "Instance")

local ABSTRACT = { Instance = true, PVInstance = true, BasePart = true, FormFactorPart = true, Light = true,
	GuiBase = true, LayerCollector = true, SurfaceGuiBase = true, GuiObject = true, UIComponent = true,
	PostEffect = true, ValueBase = true, LuaSourceContainer = true, WorldRoot = true, ServiceProvider = true }

local function propCheck(className, prop)
	local c = CLASSES[className]
	while c do
		local p = c.props[prop]
		if p then return p end
		c = c.parent and CLASSES[c.parent]
	end
	return nil
end
local function isA(className, target)
	local n = className
	while n do
		if n == target then return true end
		n = CLASSES[n] and CLASSES[n].parent
	end
	return false
end

local function checkValue(kind, v, where)
	if kind == "any" then return end
	local t = typeof(v)
	if kind == "n" then
		assert(t == "number" and v == v, where .. " expects number, got " .. t)
	elseif kind == "b" then
		assert(t == "boolean", where .. " expects boolean, got " .. t)
	elseif kind == "s" then
		assert(t == "string", where .. " expects string, got " .. t)
	elseif kind == "v3" then
		assert(t == "Vector3", where .. " expects Vector3, got " .. t)
		assert(v.X == v.X and v.Y == v.Y and v.Z == v.Z, where .. " got NaN Vector3")
	elseif kind == "cf" then
		assert(t == "CFrame", where .. " expects CFrame, got " .. t)
		local p = v.Position
		assert(p.X == p.X and p.Y == p.Y and p.Z == p.Z, where .. " got NaN CFrame")
	elseif kind == "c3" then
		assert(t == "Color3", where .. " expects Color3, got " .. t)
	elseif kind == "inst" then
		assert(v == nil or t == "Instance", where .. " expects Instance, got " .. t)
	elseif kind == "udim" then
		assert(t == "UDim", where .. " expects UDim")
	elseif kind == "udim2" then
		assert(t == "UDim2", where .. " expects UDim2")
	elseif kind == "v2" then
		assert(t == "Vector2", where .. " expects Vector2")
	elseif kind == "nr" then
		assert(t == "NumberRange", where .. " expects NumberRange")
	elseif kind == "ns" then
		assert(t == "NumberSequence", where .. " expects NumberSequence")
	elseif kind == "cs" then
		assert(t == "ColorSequence", where .. " expects ColorSequence")
	elseif kind == "font" then
		assert(t == "Font", where .. " expects Font")
	elseif string.sub(kind, 1, 5) == "enum:" then
		assert(t == "EnumItem", where .. " expects EnumItem, got " .. t)
		assert(v.EnumType == string.sub(kind, 6), where .. " expects Enum." .. string.sub(kind, 6) .. ", got Enum." .. tostring(v.EnumType))
	end
end

local ATTR_TYPES = { string = true, number = true, boolean = true, Vector3 = true, Color3 = true, CFrame = true,
	Vector2 = true, UDim = true, UDim2 = true, NumberRange = true, NumberSequence = true, ColorSequence = true,
	BrickColor = true, Rect = true, EnumItem = true, Font = true }

---------------------------------------------------------------------------
-- Instances
---------------------------------------------------------------------------
local INST = tagged({}, "Instance")
local tagIndex = {} -- tag -> set of instances
M.tagIndex = tagIndex
M.created = 0

local function defaultsFor(className)
	local d = { Archivable = true }
	if isA(className, "BasePart") then
		d.Size = Vector3.new(4, 1, 2)
		d.CFrame = CFrame.new()
		d.Anchored = false
		d.CanCollide = true
		d.CanTouch = true
		d.CanQuery = true
		d.CastShadow = true
		d.Material = Enum.Material.Plastic
		d.Color = Color3.fromRGB(163, 162, 165)
		d.Transparency = 0
		d.Reflectance = 0
		d.Locked = false
		d.Massless = false
		d.MaterialVariant = ""
		d.CollisionGroup = "Default"
		d.TopSurface = Enum.SurfaceType.Smooth
		d.BottomSurface = Enum.SurfaceType.Smooth
		if className == "Part" then d.Shape = Enum.PartType.Block end
	end
	if isA(className, "Light") then
		d.Brightness = 1; d.Color = Color3.new(1, 1, 1); d.Enabled = true; d.Range = 8; d.Shadows = false
	end
	if className == "SpotLight" or className == "SurfaceLight" then d.Angle = 90; d.Face = Enum.NormalId.Front end
	if className == "SurfaceGui" then
		d.Face = Enum.NormalId.Front; d.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize; d.PixelsPerStud = 50
		d.CanvasSize = Vector2.new(800, 600); d.LightInfluence = 1; d.Enabled = true; d.AlwaysOnTop = false
		d.Brightness = 1; d.MaxDistance = 0
	end
	if className == "ParticleEmitter" then d.Rate = 20; d.Enabled = true end
	if className == "Model" or className == "Workspace" then
		d.ModelStreamingMode = Enum.ModelStreamingMode.Default
		d.WorldPivot = CFrame.new()
	end
	if isA(className, "GuiObject") then
		d.Visible = true; d.BackgroundTransparency = 0; d.ZIndex = 1; d.LayoutOrder = 0
		d.Size = UDim2.new(0, 100, 0, 100); d.Position = UDim2.new(0, 0, 0, 0)
	end
	if isA(className, "LayerCollector") then d.Enabled = true end
	if className == "TextLabel" or className == "TextButton" or className == "TextBox" then d.Text = "Label" end
	if className == "Atmosphere" then
		d.Density = 0.3; d.Offset = 0.25; d.Color = Color3.fromRGB(199, 199, 199); d.Decay = Color3.fromRGB(106, 112, 125); d.Glare = 0; d.Haze = 0
	end
	return d
end

local function newInstance(className, name)
	local def = CLASSES[className]
	if not def or ABSTRACT[className] then error("Instance.new: unknown or abstract class '" .. tostring(className) .. "'", 3) end
	M.created = M.created + 1
	local self = setmetatable({
		__class = className,
		__props = defaultsFor(className),
		__children = {},
		__attrs = {},
		__tags = {},
		__signals = {},
		__destroyed = false,
		__id = M.created,
	}, INST)
	self.__props.Name = name or className
	return self
end
M.newInstance = newInstance

local Imethods = {}
function Imethods:IsA(c) return isA(self.__class, c) end
function Imethods:GetChildren()
	local out = {}
	for i, c in ipairs(self.__children) do out[i] = c end
	return out
end
function Imethods:GetDescendants()
	local out = {}
	local function walk(n)
		for _, c in ipairs(n.__children) do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Imethods:FindFirstChild(name, recursive)
	for _, c in ipairs(self.__children) do
		if c.__props.Name == name then return c end
	end
	if recursive then
		for _, c in ipairs(self.__children) do
			local f = c:FindFirstChild(name, true)
			if f then return f end
		end
	end
	return nil
end
function Imethods:FindFirstChildOfClass(cn)
	for _, c in ipairs(self.__children) do
		if c.__class == cn then return c end
	end
	return nil
end
function Imethods:FindFirstChildWhichIsA(cn, recursive)
	for _, c in ipairs(self.__children) do
		if isA(c.__class, cn) then return c end
	end
	if recursive then
		for _, c in ipairs(self.__children) do
			local f = c:FindFirstChildWhichIsA(cn, true)
			if f then return f end
		end
	end
	return nil
end
function Imethods:FindFirstAncestorWhichIsA(cn)
	local p = self.__props.Parent
	while p do
		if isA(p.__class, cn) then return p end
		p = p.__props.Parent
	end
	return nil
end
function Imethods:WaitForChild(name)
	local c = self:FindFirstChild(name)
	if not c then error("WaitForChild would yield forever in mock: " .. self:GetFullName() .. "." .. name, 2) end
	return c
end
function Imethods:IsDescendantOf(anc)
	local p = self.__props.Parent
	while p do
		if p == anc then return true end
		p = p.__props.Parent
	end
	return false
end
function Imethods:GetFullName()
	local parts = {}
	local n = self
	while n and n.__class ~= "DataModel" do
		table.insert(parts, 1, n.__props.Name)
		n = n.__props.Parent
	end
	return table.concat(parts, ".")
end
function Imethods:SetAttribute(k, v)
	assert(type(k) == "string" and #k > 0 and #k <= 100, "SetAttribute: bad name")
	assert(string.match(k, "^[%w_]+$"), "SetAttribute: attribute names must be alphanumeric/underscore: " .. k)
	if v ~= nil then
		assert(ATTR_TYPES[typeof(v)], "SetAttribute(" .. k .. "): unsupported type " .. typeof(v))
		if type(v) == "number" then assert(v == v, "SetAttribute(" .. k .. "): NaN") end
	end
	self.__attrs[k] = v
end
function Imethods:GetAttribute(k) return self.__attrs[k] end
function Imethods:GetAttributes() return table.clone(self.__attrs) end
function Imethods:GetAttributeChangedSignal(k)
	local key = "attr:" .. k
	self.__signals[key] = self.__signals[key] or newSignal()
	return self.__signals[key]
end
function Imethods:GetPropertyChangedSignal(k)
	local key = "prop:" .. k
	self.__signals[key] = self.__signals[key] or newSignal()
	return self.__signals[key]
end
function Imethods:AddTag(t)
	assert(type(t) == "string" and #t > 0, "AddTag: bad tag")
	self.__tags[t] = true
	tagIndex[t] = tagIndex[t] or {}
	tagIndex[t][self] = true
end
function Imethods:RemoveTag(t)
	self.__tags[t] = nil
	if tagIndex[t] then tagIndex[t][self] = nil end
end
function Imethods:HasTag(t) return self.__tags[t] == true end
function Imethods:GetTags()
	local out = {}
	for t in pairs(self.__tags) do table.insert(out, t) end
	table.sort(out)
	return out
end
function Imethods:ClearAllChildren()
	local kids = self:GetChildren()
	for _, c in ipairs(kids) do c:Destroy() end
end
function Imethods:Destroy()
	for _, c in ipairs(self:GetChildren()) do c:Destroy() end
	for t in pairs(self.__tags) do
		if tagIndex[t] then tagIndex[t][self] = nil end
	end
	self.Parent = nil
	self.__destroyed = true
end
function Imethods:Clone()
	local c = newInstance(self.__class, self.__props.Name)
	for k, v in pairs(self.__props) do
		if k ~= "Parent" then c.__props[k] = v end
	end
	for k, v in pairs(self.__attrs) do c.__attrs[k] = v end
	for t in pairs(self.__tags) do c:AddTag(t) end
	for _, ch in ipairs(self.__children) do
		local cc = ch:Clone()
		cc.Parent = c
	end
	return c
end
function Imethods:GetPivot()
	if isA(self.__class, "BasePart") then return self.__props.CFrame end
	return self.__props.WorldPivot or CFrame.new()
end
function Imethods:PivotTo(target)
	local cur = self:GetPivot()
	local delta = target * cur:Inverse()
	if isA(self.__class, "BasePart") then
		self.CFrame = target
		return
	end
	for _, d in ipairs(self:GetDescendants()) do
		if isA(d.__class, "BasePart") then d.CFrame = delta * d.__props.CFrame end
	end
	self.__props.WorldPivot = target
end
function Imethods:GetBoundingBox()
	local mn, mx
	for _, d in ipairs(self:GetDescendants()) do
		if isA(d.__class, "BasePart") then
			local p, s = d.__props.CFrame.Position, d.__props.Size
			local a, b = p - s / 2, p + s / 2
			mn = mn and mn:Min(a) or a
			mx = mx and mx:Max(b) or b
		end
	end
	if not mn then return CFrame.new(), Vector3.zero end
	return CFrame.new((mn + mx) / 2), mx - mn
end
function Imethods:GetService(name) return M.services[name] or error("mock: unknown service " .. name) end
Imethods.FindService = Imethods.GetService

-- Terrain API: records operations for the tests.
M.terrainOps = {}
local TerrainMethods = {}
function TerrainMethods:FillBlock(cframe, size, material)
	checkValue("cf", cframe, "FillBlock cframe"); checkValue("v3", size, "FillBlock size"); checkValue("enum:Material", material, "FillBlock material")
	table.insert(M.terrainOps, { op = "Block", cf = cframe, size = size, mat = material.Name })
end
function TerrainMethods:FillBall(center, radius, material)
	checkValue("v3", center, "FillBall center"); checkValue("n", radius, "FillBall radius"); checkValue("enum:Material", material, "FillBall material")
	table.insert(M.terrainOps, { op = "Ball", center = center, radius = radius, mat = material.Name })
end
function TerrainMethods:FillWedge(cframe, size, material)
	checkValue("cf", cframe, "FillWedge cframe"); checkValue("v3", size, "FillWedge size")
	table.insert(M.terrainOps, { op = "Wedge", cf = cframe, size = size, mat = material.Name })
end
function TerrainMethods:FillCylinder(cframe, height, radius, material)
	checkValue("cf", cframe, "FillCylinder cframe")
	table.insert(M.terrainOps, { op = "Cylinder", cf = cframe, height = height, radius = radius, mat = material.Name })
end
function TerrainMethods:Clear() M.terrainOps = {} end

local SIGNAL_NAMES = { ChildAdded = true, ChildRemoved = true, DescendantAdded = true, DescendantRemoving = true,
	Changed = true, AncestryChanged = true, Destroying = true, Touched = true, MouseButton1Click = true, Activated = true }

INST.__index = function(self, k)
	local m = Imethods[k]
	if m then return m end
	if self.__class == "Terrain" and TerrainMethods[k] then return TerrainMethods[k] end
	if SIGNAL_NAMES[k] then
		self.__signals[k] = self.__signals[k] or newSignal()
		return self.__signals[k]
	end
	if k == "ClassName" then return self.__class end
	local kind = propCheck(self.__class, k)
	if kind then
		if k == "Position" and isA(self.__class, "BasePart") then return self.__props.CFrame.Position end
		return self.__props[k]
	end
	-- child lookup by name (Roblox allows instance.ChildName)
	local child = Imethods.FindFirstChild(self, k)
	if child then return child end
	error(self.__class .. " '" .. tostring(self.__props.Name) .. "' has no property or child '" .. tostring(k) .. "'", 2)
end

INST.__newindex = function(self, k, v)
	assert(not self.__destroyed or k == "Parent", "write to destroyed instance")
	local kind = propCheck(self.__class, k)
	if not kind then error("Cannot set unknown property " .. self.__class .. "." .. tostring(k), 2) end
	checkValue(kind, v, self.__class .. "." .. k)
	if k == "Parent" then
		local old = self.__props.Parent
		if old == v then return end
		if v ~= nil then
			assert(v ~= self and not v:IsDescendantOf(self), "cyclic parent")
		end
		if old then
			for i, c in ipairs(old.__children) do
				if c == self then table.remove(old.__children, i) break end
			end
		end
		self.__props.Parent = v
		if v then table.insert(v.__children, self) end
		return
	end
	if k == "Position" and isA(self.__class, "BasePart") then
		local r = self.__props.CFrame
		self.__props.CFrame = CFrame.new(v) * r.Rotation
		return
	end
	if k == "Transparency" or k == "Reflectance" or k == "BackgroundTransparency" or k == "TextTransparency" then
		assert(v >= 0 and v <= 1, self.__class .. "." .. k .. " must be within 0..1, got " .. tostring(v))
	end
	if k == "Size" and isA(self.__class, "BasePart") then
		assert(v.X >= 0.001 and v.Y >= 0.001 and v.Z >= 0.001, "Part size below engine minimum: " .. tostring(v) .. " on " .. tostring(self.__props.Name))
		assert(v.X <= 2048 and v.Y <= 2048 and v.Z <= 2048, "Part size above engine maximum: " .. tostring(v))
	end
	if k == "Range" and isA(self.__class, "Light") then
		assert(v >= 0 and v <= 60, "Light.Range must be within 0..60 (engine clamps), got " .. tostring(v))
	end
	if k == "Angle" and (self.__class == "SpotLight" or self.__class == "SurfaceLight") then
		assert(v >= 0 and v <= 180, "Light.Angle must be within 0..180")
	end
	self.__props[k] = v
	local sig = self.__signals["prop:" .. k]
	if sig then sig:Fire() end
end
INST.__tostring = function(self) return self.__props.Name end

Instance = {
	new = function(className, parent)
		local inst = newInstance(className)
		if parent then inst.Parent = parent end
		return inst
	end,
}

---------------------------------------------------------------------------
-- DataModel + services
---------------------------------------------------------------------------
function M.reset()
	for k in pairs(tagIndex) do tagIndex[k] = nil end
	M.terrainOps = {}
	M.created = 0
	local dm = newInstance("DataModel", "game")
	local services = {}
	local function svc(cls, name)
		local s = newInstance(cls, name or cls)
		s.Parent = dm
		services[name or cls] = s
		return s
	end
	local ws = svc("Workspace")
	local terrain = newInstance("Terrain", "Terrain")
	terrain.Parent = ws
	terrain.Anchored = true
	svc("Lighting")
	svc("ReplicatedStorage")
	svc("ServerStorage")
	svc("ServerScriptService")
	svc("StarterPlayer")
	local sps = newInstance("StarterPlayerScripts", "StarterPlayerScripts")
	sps.Parent = services.StarterPlayer
	svc("CollectionService")
	svc("MaterialService")
	local cs = services.CollectionService
	rawset(cs, "__cs", true)
	services.CollectionService = setmetatable({}, {
		__index = function(_, k)
			if k == "AddTag" then return function(_, inst, t) inst:AddTag(t) end end
			if k == "RemoveTag" then return function(_, inst, t) inst:RemoveTag(t) end end
			if k == "HasTag" then return function(_, inst, t) return inst:HasTag(t) end end
			if k == "GetTags" then return function(_, inst) return inst:GetTags() end end
			if k == "GetTagged" then
				return function(_, t)
					local out = {}
					for inst in pairs(tagIndex[t] or {}) do
						if not inst.__destroyed then table.insert(out, inst) end
					end
					table.sort(out, function(a, b) return a.__id < b.__id end)
					return out
				end
			end
			if k == "GetInstanceAddedSignal" or k == "GetInstanceRemovedSignal" then
				return function() return newSignal() end
			end
			error("CollectionService has no member " .. k)
		end,
	})
	services.RunService = {
		IsStudio = function() return true end,
		IsServer = function() return M.isServer ~= false end,
		IsClient = function() return M.isServer == false end,
		IsRunning = function() return false end,
		Heartbeat = newSignal(), RenderStepped = newSignal(), Stepped = newSignal(),
	}
	services.Players = { LocalPlayer = nil, PlayerAdded = newSignal(), GetPlayers = function() return {} end }
	services.TweenService = {
		Create = function(_, inst, info, goal)
			return { Play = function() for k, v in pairs(goal) do inst[k] = v end end, Cancel = function() end, Completed = newSignal() }
		end,
	}
	services.HttpService = { GenerateGUID = function() return "00000000-0000-0000-0000-000000000000" end }
	services.UserInputService = { TouchEnabled = false, KeyboardEnabled = true, InputBegan = newSignal() }
	M.services = services
	game = dm
	workspace = ws
	return dm
end

task = {
	wait = function() return 0 end,
	spawn = function(fn, ...) fn(...) end,
	defer = function(fn, ...) fn(...) end,
	delay = function(_, fn, ...) fn(...) end,
}
tick = function() return 0 end
warn = function(...) M.warnings = (M.warnings or 0) + 1 end

return M
