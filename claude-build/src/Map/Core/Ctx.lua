-- Build context: the single factory through which every generated instance is
-- made. Centralising creation gives us deterministic naming, palette-only
-- styling, consistent performance defaults, keep-out reservations and the
-- statistics that PERFORMANCE_BUDGET.md reports.
local CollectionService = game:GetService("CollectionService")

local Map = script.Parent.Parent
local Palette = require(Map.Config.Palette)
local Budgets = require(Map.Config.Budgets)
local Rng = require(Map.Core.Rng)

local Ctx = {}
Ctx.__index = Ctx

local HALF_PI = math.pi / 2

function Ctx.new(opts)
	opts = opts or {}
	local self = setmetatable({}, Ctx)
	self.seed = opts.seed or "PastCurfew/Map/1"
	self.rng = Rng.new(self.seed)
	self.region = "UNASSIGNED"
	self.stats = {
		parts = 0, lights = 0, shadowLights = 0, transparent = 0, particles = 0, surfaceGuis = 0,
		violet = 0, neon = 0, byRegion = {}, serverOnlyParts = 0,
	}
	self.serverOnly = false -- true while building inactive variants
	self.reserved = {}
	self.issues = {}
	return self
end

---------------------------------------------------------------------------
-- bookkeeping
---------------------------------------------------------------------------
function Ctx:setRegion(id)
	self.region = id
	if not self.stats.byRegion[id] then
		self.stats.byRegion[id] = { parts = 0, lights = 0 }
	end
end

function Ctx:issue(msg)
	table.insert(self.issues, msg)
end

local function countPart(self, style)
	if self.serverOnly then
		self.stats.serverOnlyParts = self.stats.serverOnlyParts + 1
		return
	end
	self.stats.parts = self.stats.parts + 1
	local r = self.stats.byRegion[self.region]
	if r then r.parts = r.parts + 1 end
	if style and string.find(style, "violet", 1, true) then self.stats.violet = self.stats.violet + 1 end
end

function Ctx:attrs(inst, tbl)
	if not tbl then return inst end
	local keys = {}
	for k in pairs(tbl) do table.insert(keys, k) end
	table.sort(keys)
	for _, k in ipairs(keys) do inst:SetAttribute(k, tbl[k]) end
	return inst
end

function Ctx:tag(inst, ...)
	for _, t in ipairs({ ... }) do
		CollectionService:AddTag(inst, t)
	end
	return inst
end

---------------------------------------------------------------------------
-- containers
---------------------------------------------------------------------------
function Ctx:folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Ctx:model(parent, name, streamingMode)
	local m = Instance.new("Model")
	m.Name = name
	if streamingMode then
		m.ModelStreamingMode = Enum.ModelStreamingMode[streamingMode]
	end
	m.Parent = parent
	return m
end

---------------------------------------------------------------------------
-- parts
---------------------------------------------------------------------------
function Ctx:style(name)
	local s = Palette.styles[name]
	if not s then error("Unknown palette style '" .. tostring(name) .. "'", 3) end
	return s
end

-- opts: class, shape, collide(default true), query, touch, shadow, transparency,
--       tags{...}, attrs{...}, detail(bool -> DetailHigh tag)
function Ctx:part(parent, name, size, cframe, styleName, opts)
	opts = opts or {}
	local s = self:style(styleName)
	local p = Instance.new(opts.class or "Part")
	p.Name = name
	if opts.shape then p.Shape = Enum.PartType[opts.shape] end
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = s[1]
	p.Material = s[2]
	local transparency = opts.transparency or s[3] or 0
	p.Transparency = transparency
	if s[4] then p.Reflectance = s[4] end
	local collide = opts.collide
	if collide == nil then collide = true end
	p.CanCollide = collide
	local query = opts.query
	if query == nil then query = collide end
	p.CanQuery = query
	p.CanTouch = opts.touch == true
	local shadow = opts.shadow
	if shadow == nil then
		local m = math.max(size.X, size.Y, size.Z)
		shadow = m >= Budgets.rules.castShadowMinSize and transparency < 0.5
	end
	p.CastShadow = shadow
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if opts.attrs then self:attrs(p, opts.attrs) end
	if opts.tags then
		for _, t in ipairs(opts.tags) do CollectionService:AddTag(p, t) end
	end
	if opts.detail then CollectionService:AddTag(p, "DetailHigh") end
	if s[2] == Enum.Material.Neon and not self.serverOnly then self.stats.neon = self.stats.neon + 1 end
	if transparency > 0 and transparency < 1 and not self.serverOnly then
		self.stats.transparent = self.stats.transparent + 1
	end
	countPart(self, styleName)
	p.Parent = parent
	return p
end

-- Axis-aligned box from two corners. Returns nil for degenerate boxes.
function Ctx:box(parent, name, x0, y0, z0, x1, y1, z1, styleName, opts)
	local ax, bx = math.min(x0, x1), math.max(x0, x1)
	local ay, by = math.min(y0, y1), math.max(y0, y1)
	local az, bz = math.min(z0, z1), math.max(z0, z1)
	if bx - ax < 0.01 or by - ay < 0.01 or bz - az < 0.01 then return nil end
	return self:part(parent, name, Vector3.new(bx - ax, by - ay, bz - az),
		CFrame.new((ax + bx) / 2, (ay + by) / 2, (az + bz) / 2), styleName, opts)
end

-- CFrame whose X axis runs from a to b (used for bars, cylinders).
function Ctx.axisFrame(a, b)
	local mid = (a + b) / 2
	local d = b - a
	local len = d.Magnitude
	local dir = d / len
	if math.abs(dir.Y) > 0.999 then
		local s = dir.Y > 0 and 1 or -1
		return CFrame.new(mid) * CFrame.Angles(0, 0, s * HALF_PI), len
	end
	return CFrame.lookAt(mid, b) * CFrame.Angles(0, HALF_PI, 0), len
end

function Ctx:bar(parent, name, a, b, thick, styleName, opts)
	local cf, len = Ctx.axisFrame(a, b)
	local tw = type(thick) == "table" and thick or { thick, thick }
	return self:part(parent, name, Vector3.new(len, tw[1], tw[2]), cf, styleName, opts)
end

function Ctx:cyl(parent, name, a, b, radius, styleName, opts)
	opts = opts or {}
	opts.shape = "Cylinder"
	local cf, len = Ctx.axisFrame(a, b)
	return self:part(parent, name, Vector3.new(len, radius * 2, radius * 2), cf, styleName, opts)
end

function Ctx:ball(parent, name, center, radius, styleName, opts)
	opts = opts or {}
	opts.shape = "Ball"
	return self:part(parent, name, Vector3.new(radius * 2, radius * 2, radius * 2), CFrame.new(center), styleName, opts)
end

-- Invisible volume (zones, regions, boundaries). Never collides unless asked.
function Ctx:volume(parent, name, b, tags, attrs, opts)
	opts = opts or {}
	local p = self:box(parent, name, b[1], b[2], b[3], b[4], b[5], b[6], "volume", {
		collide = opts.collide == true, query = false, shadow = false, transparency = 1,
		tags = tags, attrs = attrs,
	})
	return p
end

---------------------------------------------------------------------------
-- lights
---------------------------------------------------------------------------
-- meta: circuit = Main|Emergency|Nav|Hero|Harbor, priority = Decor|Normal|Hero|Nav
function Ctx:light(part, kind, props, meta)
	meta = meta or {}
	local l = Instance.new(kind)
	local range = math.min(props.Range or 12, Budgets.rules.maxLightRange)
	l.Range = range
	l.Brightness = props.Brightness or 1
	local color = props.Color
	if type(color) == "string" then color = Palette.colors[color] end
	l.Color = color or Color3.new(1, 1, 1)
	if props.Angle then l.Angle = props.Angle end
	if props.Face then l.Face = Enum.NormalId[props.Face] end
	local priority = meta.priority or "Normal"
	local shadows = props.Shadows == true and priority == "Hero"
	l.Shadows = shadows
	l.Enabled = true
	self:attrs(l, {
		Circuit = meta.circuit or "Main",
		Priority = priority,
		BaseBrightness = l.Brightness,
		BaseRange = range,
		AuthoredShadows = shadows,
		Flicker = meta.flicker == true,
	})
	CollectionService:AddTag(l, "ShipLight")
	if meta.nav then
		l:SetAttribute("NavKind", meta.nav)
		CollectionService:AddTag(l, "NavLight")
	end
	if not self.serverOnly then
		self.stats.lights = self.stats.lights + 1
		if shadows then self.stats.shadowLights = self.stats.shadowLights + 1 end
		local r = self.stats.byRegion[self.region]
		if r then r.lights = r.lights + 1 end
	end
	l.Parent = part
	return l
end

---------------------------------------------------------------------------
-- surface text (signage, posters, paper). No image assets are used.
---------------------------------------------------------------------------
local FONT_FALLBACK = "SourceSans"
local function font(name)
	local ok, f = pcall(function() return Enum.Font[name] end)
	if ok and f then return f end
	return Enum.Font[FONT_FALLBACK]
end
Ctx.font = font

function Ctx:surfaceGui(part, face, opts)
	opts = opts or {}
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId[face or "Front"]
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = opts.pps or 40
	g.LightInfluence = opts.lightInfluence or 0.6
	g.Brightness = opts.brightness or 1.2
	g.MaxDistance = opts.maxDistance or 90
	g.ClipsDescendants = true
	if not self.serverOnly then self.stats.surfaceGuis = self.stats.surfaceGuis + 1 end
	g.Parent = part
	return g
end

function Ctx:label(parent, text, fontName, color, opts)
	opts = opts or {}
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = opts.size or UDim2.fromScale(1, 1)
	t.Position = opts.position or UDim2.fromScale(0, 0)
	t.Text = text
	t.Font = font(fontName)
	t.TextColor3 = color
	t.TextScaled = true
	t.TextWrapped = opts.wrap ~= false
	t.TextXAlignment = Enum.TextXAlignment[opts.align or "Center"]
	t.TextYAlignment = Enum.TextYAlignment[opts.valign or "Center"]
	if opts.rotation then t.Rotation = opts.rotation end
	if opts.stroke then
		t.TextStrokeTransparency = opts.stroke
	end
	t.Parent = parent
	return t
end

---------------------------------------------------------------------------
-- keep-out reservations (anchors, paths, door swings)
---------------------------------------------------------------------------
function Ctx:reserve(b, why)
	table.insert(self.reserved, { b[1], b[2], b[3], b[4], b[5], b[6], why = why })
end

function Ctx:isFree(b)
	for _, r in ipairs(self.reserved) do
		if b[1] < r[4] and b[4] > r[1] and b[2] < r[5] and b[5] > r[2] and b[3] < r[6] and b[6] > r[3] then
			return false, r.why
		end
	end
	return true
end

-- World AABB of an oriented footprint (for reservation tests).
function Ctx.aabb(cframe, size)
	local hx, hy, hz = size.X / 2, size.Y / 2, size.Z / 2
	local mn = Vector3.new(math.huge, math.huge, math.huge)
	local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local p = cframe * Vector3.new(sx * hx, sy * hy, sz * hz)
				mn = mn:Min(p)
				mx = mx:Max(p)
			end
		end
	end
	return { mn.X, mn.Y, mn.Z, mx.X, mx.Y, mx.Z }
end

return Ctx
