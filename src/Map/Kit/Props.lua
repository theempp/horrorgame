-- Interior prop library. Each prop is built in local space from primitives:
--   base CFrame = floor contact point at the prop's footprint centre,
--   local +Y up, local -Z = the prop's front (Roblox LookVector).
-- Props stay under ~10 parts each; small decorative bits are non-colliding and
-- tagged DetailHigh so the Low tier can hide them.
local Map = script.Parent.Parent
local Palette = require(Map.Config.Palette)

local Props = {}

local function M(ctx, parent, name)
	return ctx:model(parent, name)
end

local function P(ctx, m, base, name, sx, sy, sz, ox, oy, oz, style, opts)
	return ctx:part(m, name, Vector3.new(sx, sy, sz), base * CFrame.new(ox, oy, oz), style, opts)
end
Props.P = P

local DECOR = { collide = false, query = false, shadow = false, detail = true }
local SOFT = { collide = false, query = false, shadow = false }

-- vertical cylinder in local space
local function VC(ctx, m, base, name, r, y0, y1, ox, oz, style, opts)
	return ctx:cyl(m, name, (base * CFrame.new(ox, y0, oz)).Position, (base * CFrame.new(ox, y1, oz)).Position, r, style, opts)
end
Props.VC = VC

---------------------------------------------------------------------------
-- seating and tables
---------------------------------------------------------------------------
function Props.chair(ctx, parent, base, seatStyle, frameStyle)
	local m = M(ctx, parent, "Chair")
	P(ctx, m, base, "Seat", 1.8, 0.45, 1.8, 0, 1.55, 0, seatStyle or "fabric_coral")
	P(ctx, m, base, "Back", 1.8, 2.1, 0.3, 0, 2.8, 0.8, seatStyle or "fabric_coral", { shadow = false })
	P(ctx, m, base, "SideL", 0.2, 1.4, 1.7, -0.8, 0.7, 0, frameStyle or "wood_dark", DECOR)
	P(ctx, m, base, "SideR", 0.2, 1.4, 1.7, 0.8, 0.7, 0, frameStyle or "wood_dark", DECOR)
	return m
end

function Props.armchair(ctx, parent, base, style)
	local m = M(ctx, parent, "Armchair")
	P(ctx, m, base, "Base", 3, 1.6, 3, 0, 0.8, 0, style or "fabric_teal")
	P(ctx, m, base, "Back", 3, 2.2, 0.8, 0, 2.7, 1.1, style or "fabric_teal", { shadow = false })
	P(ctx, m, base, "ArmL", 0.6, 1, 3, -1.2, 2.1, 0, style or "fabric_teal", DECOR)
	P(ctx, m, base, "ArmR", 0.6, 1, 3, 1.2, 2.1, 0, style or "fabric_teal", DECOR)
	return m
end

function Props.sofa(ctx, parent, base, len, style)
	local m = M(ctx, parent, "Sofa")
	P(ctx, m, base, "Base", len, 1.6, 3, 0, 0.8, 0, style or "fabric_navy")
	P(ctx, m, base, "Back", len, 2.2, 0.8, 0, 2.7, 1.1, style or "fabric_navy", { shadow = false })
	P(ctx, m, base, "ArmL", 0.7, 1.1, 3, -len / 2 + 0.35, 2.15, 0, style or "fabric_navy", DECOR)
	P(ctx, m, base, "ArmR", 0.7, 1.1, 3, len / 2 - 0.35, 2.15, 0, style or "fabric_navy", DECOR)
	return m
end

function Props.tableRound(ctx, parent, base, r, h, topStyle, clothStyle)
	local m = M(ctx, parent, "RoundTable")
	h = h or 2.8
	VC(ctx, m, base, "Top", r, h - 0.2, h, 0, 0, clothStyle or topStyle or "wood_dark")
	if clothStyle then
		VC(ctx, m, base, "Drape", r + 0.05, h - 1.1, h - 0.2, 0, 0, clothStyle, DECOR)
	end
	VC(ctx, m, base, "Pedestal", 0.35, 0, h - 0.2, 0, 0, "brass_dark", { shadow = false })
	return m
end

function Props.tableRect(ctx, parent, base, w, d, h, topStyle, legStyle)
	local m = M(ctx, parent, "Table")
	h = h or 2.8
	P(ctx, m, base, "Top", w, 0.25, d, 0, h - 0.125, 0, topStyle or "wood_dark")
	P(ctx, m, base, "LegA", 0.35, h - 0.25, d - 0.4, -w / 2 + 0.4, (h - 0.25) / 2, 0, legStyle or "wood_dark", { shadow = false })
	P(ctx, m, base, "LegB", 0.35, h - 0.25, d - 0.4, w / 2 - 0.4, (h - 0.25) / 2, 0, legStyle or "wood_dark", { shadow = false })
	return m
end

-- plates / glasses / cutlery hint on a table top (dining storytelling)
function Props.placeSetting(ctx, parent, base, h, eaten)
	local m = M(ctx, parent, "Setting")
	VC(ctx, m, base, "Plate", 0.55, h, h + 0.06, 0, 0, "plastic_cream", DECOR)
	if eaten then
		P(ctx, m, base, "Food", 0.5, 0.18, 0.35, 0.1, h + 0.14, 0.05, "wood_dark", DECOR)
	end
	VC(ctx, m, base, "Glass", 0.14, h, h + 0.55, 0.55, -0.35, "glass_clear", DECOR)
	return m
end

function Props.stool(ctx, parent, base, style)
	local m = M(ctx, parent, "Stool")
	VC(ctx, m, base, "Seat", 0.7, 2.6, 2.95, 0, 0, style or "fabric_coral", { shadow = false })
	VC(ctx, m, base, "Post", 0.15, 0, 2.6, 0, 0, "chrome", DECOR)
	VC(ctx, m, base, "Foot", 0.6, 0, 0.12, 0, 0, "chrome", DECOR)
	return m
end

---------------------------------------------------------------------------
-- sleeping, storage
---------------------------------------------------------------------------
function Props.bed(ctx, parent, base, w, blanketStyle, made)
	-- base at the foot centre? No: footprint centre. Head at local +Z.
	local m = M(ctx, parent, "Bed")
	local len = 7.4
	P(ctx, m, base, "Frame", w, 1.1, len, 0, 0.55, 0, "wood_dark")
	P(ctx, m, base, "Mattress", w - 0.3, 0.7, len - 0.3, 0, 1.45, 0, "linen", { shadow = false })
	P(ctx, m, base, "Headboard", w + 0.2, 3.2, 0.35, 0, 1.6, len / 2 + 0.1, "panel_wood", { shadow = false })
	local blanketLen = made and 4.8 or 3.2
	P(ctx, m, base, "Blanket", w - 0.1, 0.25, blanketLen, 0, 1.9, -len / 2 + blanketLen / 2 + 0.3, blanketStyle or "fabric_teal", SOFT)
	if w > 4.5 then
		P(ctx, m, base, "PillowL", w / 2 - 0.5, 0.45, 1.3, -w / 4, 2.0, len / 2 - 1, "linen", DECOR)
		P(ctx, m, base, "PillowR", w / 2 - 0.5, 0.45, 1.3, w / 4, 2.0, len / 2 - 1, "linen", DECOR)
	else
		P(ctx, m, base, "Pillow", w - 0.8, 0.45, 1.3, 0, 2.0, len / 2 - 1, "linen", DECOR)
	end
	return m
end

function Props.bunk(ctx, parent, base, stripped)
	local m = M(ctx, parent, "Bunk")
	local w, len = 3.2, 7.2
	P(ctx, m, base, "PostHead", w, 7.4, 0.3, 0, 3.7, len / 2, "steel_paint")
	P(ctx, m, base, "PostFoot", w, 7.4, 0.3, 0, 3.7, -len / 2, "steel_paint", { shadow = false })
	P(ctx, m, base, "Lower", w, 0.9, len, 0, 1.3, 0, stripped and "steel_dark" or "fabric_navy")
	P(ctx, m, base, "Upper", w, 0.9, len, 0, 4.9, 0, "fabric_navy", { shadow = false })
	P(ctx, m, base, "Curtain", 0.15, 2.2, len - 0.4, -w / 2 - 0.05, 2.6, 0, "fabric_teal", SOFT)
	return m
end

function Props.wardrobe(ctx, parent, base, w, h, d, style, openDoor)
	local m = M(ctx, parent, "Wardrobe")
	P(ctx, m, base, "Body", w, h, d, 0, h / 2, 0, style or "panel_wood")
	P(ctx, m, base, "Split", 0.12, h - 0.8, 0.1, 0, h / 2, -d / 2 - 0.05, "wood_dark", DECOR)
	P(ctx, m, base, "HandleL", 0.15, 0.8, 0.2, -0.3, h * 0.55, -d / 2 - 0.1, "brass", DECOR)
	P(ctx, m, base, "HandleR", 0.15, 0.8, 0.2, 0.3, h * 0.55, -d / 2 - 0.1, "brass", DECOR)
	if openDoor then
		P(ctx, m, base, "DoorOpen", 0.2, h - 0.4, w / 2, -w / 2 - 0.1, h / 2, -d / 2 - w / 4, style or "panel_wood", SOFT)
	end
	return m
end

function Props.locker(ctx, parent, base, style, dented)
	local m = M(ctx, parent, "Locker")
	local w, h, d = 2.6, 7.4, 2.4
	P(ctx, m, base, "Body", w, h, d, 0, h / 2, 0, style or "steel_paint_green")
	for i = 1, 3 do
		P(ctx, m, base, "Vent" .. i, w - 1, 0.12, 0.08, 0, h - 1 - i * 0.35, -d / 2 - 0.04, "steel_dark", DECOR)
	end
	P(ctx, m, base, "Handle", 0.18, 0.9, 0.2, w / 2 - 0.4, h * 0.5, -d / 2 - 0.1, "chrome", DECOR)
	if dented then
		P(ctx, m, base, "Dent", 0.9, 1.1, 0.1, -0.4, h * 0.62, -d / 2 - 0.02, "steel_dark", DECOR)
	end
	return m
end

function Props.lockerBank(ctx, parent, base, n, style)
	local m = M(ctx, parent, "LockerBank")
	for i = 1, n do
		local x = (i - (n + 1) / 2) * 2.6
		P(ctx, m, base, "Locker" .. i, 2.5, 7.4, 2.4, x, 3.7, 0, style or "steel_paint_green", { shadow = i == 1 })
		P(ctx, m, base, "Handle" .. i, 0.18, 0.9, 0.2, x + 0.8, 3.7, -1.25, "chrome", DECOR)
	end
	return m
end

function Props.bookshelf(ctx, parent, base, w, h, rng)
	local m = M(ctx, parent, "Bookshelf")
	local d = 1.6
	P(ctx, m, base, "Case", w, h, d, 0, h / 2, 0.2, "wood_dark")
	local rows = math.floor((h - 0.6) / 1.6)
	local fabrics = { "fabric_coral", "fabric_teal", "fabric_navy", "fabric_cream", "fabric_yellow" }
	for i = 1, rows do
		local y = 0.4 + (i - 1) * 1.6
		local fill = rng and rng:range(0.45, 0.95) or 0.8
		P(ctx, m, base, "Books" .. i, (w - 0.6) * fill, 1.2, 1.0, -(w - 0.6) * (1 - fill) / 2, y + 0.6, -0.15,
			rng and rng:pick(fabrics) or "fabric_coral", DECOR)
	end
	return m
end

function Props.cabinet(ctx, parent, base, w, h, d, style, topStyle)
	local m = M(ctx, parent, "Cabinet")
	P(ctx, m, base, "Body", w, h, d, 0, h / 2, 0, style or "panel_wood")
	if topStyle then
		P(ctx, m, base, "Top", w + 0.2, 0.2, d + 0.2, 0, h + 0.1, 0, topStyle, { shadow = false })
	end
	P(ctx, m, base, "Line", w - 0.4, 0.1, 0.08, 0, h * 0.5, -d / 2 - 0.04, "wood_dark", DECOR)
	return m
end

function Props.counter(ctx, parent, base, len, h, d, bodyStyle, topStyle)
	local m = M(ctx, parent, "Counter")
	h, d = h or 3.6, d or 2.4
	P(ctx, m, base, "Body", len, h - 0.25, d, 0, (h - 0.25) / 2, 0, bodyStyle or "panel_wood")
	P(ctx, m, base, "Top", len + 0.3, 0.25, d + 0.4, 0, h - 0.125, 0.1, topStyle or "marble")
	P(ctx, m, base, "Kick", len, 0.4, 0.2, 0, 0.35, -d / 2 - 0.1, "brass", DECOR)
	return m
end

---------------------------------------------------------------------------
-- entertainment
---------------------------------------------------------------------------
function Props.grandPiano(ctx, parent, base)
	local m = M(ctx, parent, "GrandPiano")
	P(ctx, m, base, "Body", 5, 1.3, 6.2, 0, 2.6, 0, "black")
	P(ctx, m, base, "Legs", 4.2, 1.95, 5, 0, 0.98, 0.3, "black", { shadow = false })
	P(ctx, m, base, "Keys", 4.4, 0.25, 0.9, 0, 3.1, -3.4, "plastic_cream", DECOR)
	P(ctx, m, base, "Lid", 4.8, 0.12, 6, 0, 5.1, 0.3, "black", { collide = false, shadow = false })
	local lid = m:FindFirstChild("Lid")
	lid.CFrame = base * CFrame.new(-0.8, 4.2, 0.3) * CFrame.Angles(0, 0, math.rad(35))
	P(ctx, m, base, "Stool", 2.2, 1.8, 1.2, 0, 0.9, -4.6, "black")
	return m
end

function Props.slotMachine(ctx, parent, base, lit)
	local m = M(ctx, parent, "SlotMachine")
	P(ctx, m, base, "Cabinet", 2.2, 4.4, 2, 0, 2.2, 0, "panel_wood_red")
	P(ctx, m, base, "Screen", 1.6, 1.1, 0.1, 0, 3.4, -1.02, lit and "window_lit" or "screen_dark", { collide = false, shadow = false })
	P(ctx, m, base, "Topper", 2.2, 1, 1.6, 0, 4.9, 0.2, "brass", { shadow = false })
	P(ctx, m, base, "Tray", 1.6, 0.3, 0.6, 0, 1.4, -1.2, "chrome", DECOR)
	return m
end

function Props.roulette(ctx, parent, base)
	local m = M(ctx, parent, "Roulette")
	P(ctx, m, base, "Table", 9, 2.6, 4.4, 0, 1.3, 0, "panel_wood")
	P(ctx, m, base, "Layout", 6, 0.1, 3.8, 1.2, 2.65, 0, "felt", { shadow = false })
	VC(ctx, m, base, "Wheel", 1.6, 2.6, 3.1, -3.2, 0, "wood_dark", { shadow = false })
	VC(ctx, m, base, "WheelHub", 0.5, 3.1, 3.4, -3.2, 0, "brass", DECOR)
	for i = 1, 4 do
		VC(ctx, m, base, "Chips" .. i, 0.3, 2.7, 2.7 + 0.12 * i, 0.4 + i * 0.9, -0.8 + (i % 2) * 1.4, i % 2 == 0 and "safety_coral" or "safety_yellow", DECOR)
	end
	return m
end

function Props.cardTable(ctx, parent, base, dealt)
	local m = Props.tableRound(ctx, parent, base, 2.6, 2.8, "felt")
	if dealt then
		for i = 1, 4 do
			local a = i * math.pi / 2
			P(ctx, m, base, "Cards" .. i, 0.7, 0.05, 0.5, math.cos(a) * 1.6, 2.83, math.sin(a) * 1.6, "paper", DECOR)
		end
	end
	return m
end

function Props.displayCase(ctx, parent, base, w, items, rng)
	local m = M(ctx, parent, "DisplayCase")
	P(ctx, m, base, "Base", w, 2.6, 2, 0, 1.3, 0, "panel_cream")
	P(ctx, m, base, "Glass", w - 0.2, 1.6, 1.8, 0, 3.4, 0, "glass_clear", { tags = { "SightTransparent" }, shadow = false })
	P(ctx, m, base, "Rim", w, 0.15, 2, 0, 4.25, 0, "chrome", DECOR)
	for i = 1, (items or 0) do
		local x = -w / 2 + (i - 0.5) * (w / items)
		P(ctx, m, base, "Item" .. i, 0.5, rng and rng:range(0.3, 0.9) or 0.6, 0.5, x, 2.9, 0, rng and rng:pick({ "brass", "glass_clear", "fabric_coral", "chrome" }) or "brass", DECOR)
	end
	return m
end

function Props.mannequin(ctx, parent, base, shrouded)
	local m = M(ctx, parent, "Mannequin")
	VC(ctx, m, base, "Stand", 0.15, 0, 3, 0, 0, "chrome", { shadow = false })
	P(ctx, m, base, "Torso", 1.8, 2.4, 1, 0, 4.1, 0, shrouded and "linen" or "fabric_coral")
	ctx:ball(m, "Head", (base * CFrame.new(0, 5.8, 0)).Position, 0.6, shrouded and "linen" or "plastic_cream", { shadow = false })
	if shrouded then
		P(ctx, m, base, "Shroud", 2.2, 3.4, 1.4, 0, 4.3, 0, "linen", SOFT)
	end
	return m
end

---------------------------------------------------------------------------
-- luggage, cargo
---------------------------------------------------------------------------
function Props.suitcase(ctx, parent, base, style, upright)
	local m = M(ctx, parent, "Suitcase")
	if upright then
		P(ctx, m, base, "Body", 2.2, 3, 0.9, 0, 1.5, 0, style or "fabric_navy")
		P(ctx, m, base, "Handle", 0.8, 0.25, 0.2, 0, 3.12, 0, "black", DECOR)
	else
		P(ctx, m, base, "Body", 2.2, 0.9, 3, 0, 0.45, 0, style or "fabric_navy")
		P(ctx, m, base, "Handle", 0.8, 0.2, 0.25, 0, 0.45, -1.55, "black", DECOR)
	end
	P(ctx, m, base, "Label", 0.5, 0.35, 0.05, 0.6, upright and 2.3 or 0.6, upright and -0.48 or -1.52, "safety_coral", DECOR)
	return m
end

function Props.trunk(ctx, parent, base, style)
	local m = M(ctx, parent, "Trunk")
	P(ctx, m, base, "Body", 3.4, 2, 2, 0, 1, 0, style or "fabric_teal")
	P(ctx, m, base, "BandA", 0.25, 2.06, 2.06, -1.1, 1, 0, "brass_dark", DECOR)
	P(ctx, m, base, "BandB", 0.25, 2.06, 2.06, 1.1, 1, 0, "brass_dark", DECOR)
	P(ctx, m, base, "Lid", 3.44, 0.12, 2.06, 0, 1.6, 0, "wood_dark", DECOR)
	return m
end

function Props.crate(ctx, parent, base, s, style)
	local m = M(ctx, parent, "Crate")
	s = s or 3
	P(ctx, m, base, "Body", s, s, s, 0, s / 2, 0, style or "crate_wood")
	P(ctx, m, base, "SlatA", s + 0.1, 0.35, s + 0.1, 0, s * 0.25, 0, "timber_dark", DECOR)
	P(ctx, m, base, "SlatB", s + 0.1, 0.35, s + 0.1, 0, s * 0.75, 0, "timber_dark", DECOR)
	return m
end

function Props.pallet(ctx, parent, base, w, d)
	local m = M(ctx, parent, "Pallet")
	P(ctx, m, base, "Deck", w, 0.3, d, 0, 0.55, 0, "crate_wood", { shadow = false })
	P(ctx, m, base, "RunnerA", w, 0.4, 0.5, 0, 0.2, -d / 2 + 0.3, "timber_dark", DECOR)
	P(ctx, m, base, "RunnerB", w, 0.4, 0.5, 0, 0.2, d / 2 - 0.3, "timber_dark", DECOR)
	return m
end

function Props.drum(ctx, parent, base, style)
	local m = M(ctx, parent, "Drum")
	VC(ctx, m, base, "Body", 1.1, 0, 3.2, 0, 0, style or "pipe_teal")
	VC(ctx, m, base, "Band", 1.14, 1.5, 1.7, 0, 0, "steel_dark", DECOR)
	return m
end

function Props.trolley(ctx, parent, base, style, loadStyle)
	local m = M(ctx, parent, "Trolley")
	P(ctx, m, base, "Bed", 3, 0.3, 5, 0, 1.2, 0, style or "chrome")
	P(ctx, m, base, "Handle", 3, 2.6, 0.2, 0, 2.5, 2.4, style or "chrome", { shadow = false })
	P(ctx, m, base, "Wheels", 2.6, 1, 4.4, 0, 0.5, 0, "black", DECOR)
	if loadStyle then
		P(ctx, m, base, "Load", 2.6, 1.8, 4, 0, 2.3, 0, loadStyle, { shadow = false })
	end
	return m
end

function Props.shelving(ctx, parent, base, w, h, d, loadStyle, rng)
	local m = M(ctx, parent, "Shelving")
	P(ctx, m, base, "UprightL", 0.3, h, d, -w / 2 + 0.15, h / 2, 0, "steel_bare", { shadow = false })
	P(ctx, m, base, "UprightR", 0.3, h, d, w / 2 - 0.15, h / 2, 0, "steel_bare", { shadow = false })
	local n = math.floor(h / 2.2)
	for i = 1, n do
		local y = 0.3 + (i - 1) * 2.2
		P(ctx, m, base, "Shelf" .. i, w, 0.2, d, 0, y, 0, "steel_bare", { shadow = false })
		if loadStyle and (not rng or rng:chance(0.8)) then
			local fill = rng and rng:range(0.4, 0.95) or 0.8
			P(ctx, m, base, "Load" .. i, (w - 0.6) * fill, 1.4, d - 0.4, 0, y + 0.8, 0, loadStyle, DECOR)
		end
	end
	return m
end

---------------------------------------------------------------------------
-- service + medical + crew
---------------------------------------------------------------------------
function Props.cot(ctx, parent, base, used)
	local m = M(ctx, parent, "Cot")
	P(ctx, m, base, "Frame", 3.2, 2, 7, 0, 1, 0, "chrome")
	P(ctx, m, base, "Mattress", 3, 0.5, 6.8, 0, 2.25, 0, "linen", { shadow = false })
	P(ctx, m, base, "Sheet", 3.1, 0.2, used and 3 or 5, 0, 2.55, used and -1.5 or -0.8, "fabric_cream", SOFT)
	P(ctx, m, base, "Rail", 0.15, 1, 5, -1.6, 3, 0, "chrome", DECOR)
	return m
end

function Props.curtainScreen(ctx, parent, base, len)
	local m = M(ctx, parent, "Screen")
	P(ctx, m, base, "Rail", len, 0.2, 0.2, 0, 7.6, 0, "chrome", DECOR)
	P(ctx, m, base, "Curtain", len - 0.6, 6.2, 0.15, -0.3, 4.2, 0, "fabric_teal", SOFT)
	return m
end

function Props.wheelchair(ctx, parent, base)
	local m = M(ctx, parent, "Wheelchair")
	P(ctx, m, base, "Seat", 1.8, 0.3, 1.8, 0, 1.8, 0, "fabric_navy")
	P(ctx, m, base, "Back", 1.8, 1.8, 0.2, 0, 2.8, 0.9, "fabric_navy", SOFT)
	ctx:cyl(m, "WheelL", (base * CFrame.new(-1.05, 1.3, 0.2)).Position, (base * CFrame.new(-1.2, 1.3, 0.2)).Position, 1.3, "chrome", DECOR)
	ctx:cyl(m, "WheelR", (base * CFrame.new(1.05, 1.3, 0.2)).Position, (base * CFrame.new(1.2, 1.3, 0.2)).Position, 1.3, "chrome", DECOR)
	return m
end

function Props.washer(ctx, parent, base, open)
	local m = M(ctx, parent, "Washer")
	P(ctx, m, base, "Body", 3.6, 4.4, 3.4, 0, 2.2, 0, "steel_bare")
	local c = base * CFrame.new(0, 2.3, -1.7)
	ctx:cyl(m, "Door", c.Position, (c * CFrame.new(0, 0, -0.25)).Position, 1.1, open and "steel_dark" or "glass_smoked", { shadow = false, collide = false })
	P(ctx, m, base, "Panel", 3.6, 0.8, 0.2, 0, 4.0, -1.75, "steel_dark", DECOR)
	return m
end

function Props.galleyRange(ctx, parent, base, len)
	local m = M(ctx, parent, "Range")
	P(ctx, m, base, "Body", len, 3.4, 3.2, 0, 1.7, 0, "steel_bare")
	P(ctx, m, base, "Top", len, 0.2, 3.2, 0, 3.5, 0, "steel_dark", { shadow = false })
	local n = math.floor(len / 2.4)
	for i = 1, n do
		local x = -len / 2 + (i - 0.5) * (len / n)
		VC(ctx, m, base, "Plate" .. i, 0.8, 3.6, 3.65, x, -0.3, "black", DECOR)
		if i % 2 == 1 then
			VC(ctx, m, base, "Pan" .. i, 0.75, 3.65, 4.4, x, -0.3, "chrome", DECOR)
		end
	end
	P(ctx, m, base, "Hood", len + 0.4, 1.4, 3.6, 0, 8.6, 0.4, "steel_bare", { collide = false, shadow = false })
	return m
end

function Props.prepTable(ctx, parent, base, len, loaded, rng)
	local m = Props.tableRect(ctx, parent, base, len, 2.6, 3.2, "chrome", "steel_bare")
	P(ctx, m, base, "Shelf", len - 0.8, 0.15, 2.2, 0, 1, 0, "steel_bare", DECOR)
	if loaded then
		for i = 1, 3 do
			local x = -len / 2 + i * len / 4
			P(ctx, m, base, "Tray" .. i, 1.6, 0.15, 1.1, x, 3.3, rng and rng:range(-0.5, 0.5) or 0, "chrome", DECOR)
		end
	end
	return m
end

function Props.messTable(ctx, parent, base, len)
	local m = Props.tableRect(ctx, parent, base, len, 3, 2.8, "linoleum", "steel_bare")
	P(ctx, m, base, "BenchA", len, 1.6, 1.1, 0, 0.8, -2.3, "fabric_navy", { shadow = false })
	P(ctx, m, base, "BenchB", len, 1.6, 1.1, 0, 0.8, 2.3, "fabric_navy", { shadow = false })
	return m
end

function Props.workbench(ctx, parent, base, len)
	local m = Props.tableRect(ctx, parent, base, len, 2.8, 3.2, "wood_teak", "steel_paint_green")
	P(ctx, m, base, "Vice", 0.9, 0.9, 1.2, len / 2 - 1, 3.65, -0.4, "steel_dark", DECOR)
	P(ctx, m, base, "Board", len, 4, 0.2, 0, 6, 1.5, "timber", { collide = false, shadow = false })
	for i = 1, 4 do
		P(ctx, m, base, "Tool" .. i, 0.25, 1.2 + (i % 2) * 0.5, 0.2, -len / 2 + i * len / 5, 6, 1.35, i == 3 and "volume" or "steel_dark",
			{ collide = false, query = false, shadow = false, detail = true, transparency = i == 3 and 1 or nil })
	end
	return m
end

function Props.lathe(ctx, parent, base)
	local m = M(ctx, parent, "Lathe")
	P(ctx, m, base, "Bed", 7, 0.9, 1.6, 0, 3.2, 0, "machinery_green")
	P(ctx, m, base, "Stand", 6, 2.8, 1.4, 0, 1.4, 0, "machinery_green", { shadow = false })
	P(ctx, m, base, "Headstock", 1.8, 2, 1.8, -2.6, 4.6, 0, "machinery_green")
	ctx:cyl(m, "Work", (base * CFrame.new(-1.7, 4.4, 0)).Position, (base * CFrame.new(1.8, 4.4, 0)).Position, 0.35, "chrome", DECOR)
	return m
end

---------------------------------------------------------------------------
-- electrical, radio, machinery
---------------------------------------------------------------------------
function Props.radioRack(ctx, parent, base, violetDial)
	local m = M(ctx, parent, "RadioRack")
	P(ctx, m, base, "Rack", 4, 7, 2, 0, 3.5, 0, "steel_paint_green")
	for i = 1, 4 do
		P(ctx, m, base, "Panel" .. i, 3.6, 1.4, 0.1, 0, 1.2 + i * 1.45, -1.02, "steel_dark", { collide = false, shadow = false })
	end
	for i = 1, 3 do
		ctx:cyl(m, "Dial" .. i, (base * CFrame.new(-1.2 + i * 0.8, 4.1, -1.05)).Position,
			(base * CFrame.new(-1.2 + i * 0.8, 4.1, -1.2)).Position, 0.3, (violetDial and i == 2) and "lamp_violet" or "chrome", DECOR)
	end
	return m
end

function Props.monitorBank(ctx, parent, base, n, staticIndex)
	local m = M(ctx, parent, "MonitorBank")
	P(ctx, m, base, "Desk", n * 2.4 + 0.6, 2.8, 2.6, 0, 1.4, 0, "steel_paint")
	for i = 1, n do
		local x = (i - (n + 1) / 2) * 2.4
		P(ctx, m, base, "CRT" .. i, 2, 1.8, 1.8, x, 5.2, 0.3, "black", { shadow = false })
		P(ctx, m, base, "Screen" .. i, 1.6, 1.3, 0.05, x, 5.2, -0.62, i == staticIndex and "lamp_cold" or "screen_dark",
			{ collide = false, shadow = false, transparency = i == staticIndex and 0.55 or nil })
	end
	P(ctx, m, base, "Shelf", n * 2.4 + 0.6, 0.2, 2.2, 0, 4.2, 0.3, "steel_paint", { shadow = false })
	return m
end

function Props.switchboard(ctx, parent, base, len, rng)
	local m = M(ctx, parent, "Switchboard")
	P(ctx, m, base, "Cabinet", len, 8, 2.4, 0, 4, 0, "machinery_green")
	P(ctx, m, base, "Plinth", len, 0.6, 3, 0, 0.3, -0.2, "steel_dark", { shadow = false })
	local sections = math.floor(len / 3)
	for i = 1, sections do
		local x = -len / 2 + (i - 0.5) * (len / sections)
		P(ctx, m, base, "Seam" .. i, 0.1, 7.6, 0.08, x + len / sections / 2, 4, -1.22, "steel_dark", DECOR)
		ctx:cyl(m, "Gauge" .. i, (base * CFrame.new(x, 6.4, -1.2)).Position, (base * CFrame.new(x, 6.4, -1.35)).Position, 0.45, "plastic_cream", DECOR)
		local off = rng and rng:chance(0.35)
		P(ctx, m, base, "Breaker" .. i, 0.4, 1, 0.5, x, off and 3.6 or 4.2, -1.45, off and "safety_coral" or "black", DECOR)
	end
	return m
end

function Props.generator(ctx, parent, base, running)
	local m = M(ctx, parent, "Generator")
	P(ctx, m, base, "Skid", 12, 0.8, 4.4, 0, 0.4, 0, "steel_dark")
	P(ctx, m, base, "Engine", 7, 4.2, 3.6, -2, 2.9, 0, "machinery")
	P(ctx, m, base, "Head", 6.4, 1, 3, -2, 5.5, 0, "machinery_green", { shadow = false })
	ctx:cyl(m, "Alternator", (base * CFrame.new(1.6, 2.9, 0)).Position, (base * CFrame.new(5.6, 2.9, 0)).Position, 1.9, "machinery_green")
	ctx:cyl(m, "Exhaust", (base * CFrame.new(-3, 6, 0.6)).Position, (base * CFrame.new(-3, 14.5, 0.6)).Position, 0.6, "steel_corroded", { shadow = false })
	P(ctx, m, base, "Placard", 1.4, 0.8, 0.05, 3.6, 3.2, -1.95, running and "lamp_green" or "lamp_red", { collide = false, shadow = false })
	return m
end

function Props.console(ctx, parent, base, len)
	local m = M(ctx, parent, "Console")
	P(ctx, m, base, "Base", len, 3, 2.4, 0, 1.5, 0, "steel_paint_green")
	local slope = P(ctx, m, base, "Slope", len, 0.3, 2.2, 0, 3.4, 0.1, "steel_dark", { shadow = false })
	slope.CFrame = base * CFrame.new(0, 3.4, 0.1) * CFrame.Angles(math.rad(-25), 0, 0)
	local n = math.floor(len / 1.6)
	for i = 1, n do
		local x = -len / 2 + (i - 0.5) * (len / n)
		ctx:cyl(m, "Gauge" .. i, (base * CFrame.new(x, 3.75, 0.1)).Position, (base * CFrame.new(x, 3.95, -0.05)).Position, 0.35, "plastic_cream", DECOR)
	end
	return m
end

function Props.telegraph(ctx, parent, base)
	local m = M(ctx, parent, "Telegraph")
	VC(ctx, m, base, "Pedestal", 0.45, 0, 3.6, 0, 0, "brass_dark", { shadow = false })
	ctx:cyl(m, "Dial", (base * CFrame.new(0, 4.2, 0.25)).Position, (base * CFrame.new(0, 4.2, -0.25)).Position, 0.9, "brass")
	P(ctx, m, base, "Face", 1.4, 1.4, 0.05, 0, 4.2, -0.28, "plastic_cream", DECOR)
	P(ctx, m, base, "Lever", 0.2, 1.4, 0.2, 0.3, 4.3, -0.45, "safety_coral", DECOR)
	return m
end

---------------------------------------------------------------------------
-- clocks (conflicting times are part of the story)
---------------------------------------------------------------------------
local function clockHands(ctx, m, center, normal, right, up, r, hh, mm)
	local minuteA = (mm / 60) * 2 * math.pi
	local hourA = ((hh % 12) / 12 + mm / 720) * 2 * math.pi
	local function hand(name, angle, len, thick)
		local dir = up * math.cos(angle) + right * math.sin(angle)
		local a = center + normal * 0.08
		local b = a + dir * len
		ctx:bar(m, name, a, b, thick, "black", { collide = false, query = false, shadow = false })
	end
	hand("HourHand", hourA, r * 0.5, 0.12)
	hand("MinuteHand", minuteA, r * 0.8, 0.08)
end

-- wall clock: cf = centre of the face, LookVector = outward normal
function Props.wallClock(ctx, parent, cf, r, hh, mm, behaviour)
	local m = M(ctx, parent, "Clock")
	local n = cf.LookVector
	ctx:cyl(m, "Rim", cf.Position - n * 0.05, cf.Position + n * 0.2, r + 0.2, "brass", SOFT)
	ctx:cyl(m, "Face", cf.Position + n * 0.2, cf.Position + n * 0.25, r, "plastic_cream", SOFT)
	clockHands(ctx, m, cf.Position + n * 0.25, n, cf.RightVector, cf.UpVector, r, hh, mm)
	ctx:attrs(m, { ClockTime = string.format("%02d:%02d", hh, mm), Behaviour = behaviour or "Stopped" })
	ctx:tag(m, "Clock")
	return m
end

function Props.grandfatherClock(ctx, parent, base, hh, mm, behaviour)
	local m = M(ctx, parent, "GrandfatherClock")
	P(ctx, m, base, "Case", 2.4, 7.8, 1.6, 0, 3.9, 0, "panel_wood_red")
	P(ctx, m, base, "Hood", 2.8, 1.2, 1.9, 0, 8.4, 0, "wood_dark", { shadow = false })
	P(ctx, m, base, "Window", 1.2, 3, 0.05, 0, 3.6, -0.82, "glass_smoked", { collide = false, shadow = false })
	local faceCf = base * CFrame.new(0, 6.6, -0.82) * CFrame.Angles(0, math.pi, 0)
	-- faceCf LookVector must point to the front (-Z local of base): rotate 180 about Y
	faceCf = CFrame.lookAt(faceCf.Position, faceCf.Position + (base.LookVector))
	ctx:cyl(m, "Face", faceCf.Position, faceCf.Position + base.LookVector * 0.06, 0.95, "plastic_cream", SOFT)
	clockHands(ctx, m, faceCf.Position + base.LookVector * 0.06, base.LookVector, faceCf.RightVector, faceCf.UpVector, 0.95, hh, mm)
	ctx:attrs(m, { ClockTime = string.format("%02d:%02d", hh, mm), Behaviour = behaviour or "Stopped" })
	ctx:tag(m, "Clock")
	return m
end

---------------------------------------------------------------------------
-- small dressing
---------------------------------------------------------------------------
function Props.plantDead(ctx, parent, base)
	local m = M(ctx, parent, "Planter")
	VC(ctx, m, base, "Pot", 0.9, 0, 1.8, 0, 0, "brass_dark", { shadow = false })
	P(ctx, m, base, "StemA", 0.12, 2.4, 0.12, 0.2, 2.9, 0, "wood_dark", DECOR)
	P(ctx, m, base, "StemB", 0.12, 1.8, 0.12, -0.3, 2.6, 0.2, "wood_dark", DECOR)
	return m
end

function Props.rug(ctx, parent, base, w, d, style)
	local m = M(ctx, parent, "Rug")
	P(ctx, m, base, "Rug", w, 0.06, d, 0, 0.03, 0, style or "carpet_coral", { collide = false, query = false, shadow = false })
	return m
end

function Props.lampStanding(ctx, parent, base, lit, ctxLight)
	local m = M(ctx, parent, "FloorLamp")
	VC(ctx, m, base, "Pole", 0.12, 0, 5.2, 0, 0, "brass", DECOR)
	local shade = VC(ctx, m, base, "Shade", 0.8, 5, 6.2, 0, 0, lit and "lamp_warm" or "fabric_cream", SOFT)
	if lit and ctxLight then
		ctx:light(shade, "PointLight", { Range = 12, Brightness = 0.8, Color = "emergency" }, { circuit = "Emergency", priority = "Decor" })
	end
	return m
end

function Props.lifejackets(ctx, parent, base, spilled)
	local m = M(ctx, parent, "LifejacketLocker")
	P(ctx, m, base, "Box", 4, 2.4, 2, 0, 1.2, 0, "safety_coral")
	if spilled then
		P(ctx, m, base, "JacketA", 1.6, 0.5, 2, -0.8, 0.25, -2.2, "lifering", SOFT)
		P(ctx, m, base, "JacketB", 1.6, 0.5, 2, 1.2, 0.25, -3.4, "lifering", SOFT)
	end
	return m
end

function Props.fireReel(ctx, parent, cf)
	local m = M(ctx, parent, "FireReel")
	local n = cf.LookVector
	P(ctx, m, cf, "Box", 2.4, 2.8, 0.8, 0, 0, 0.4, "pipe_red", { shadow = false })
	ctx:cyl(m, "Reel", cf.Position + n * 0.05, cf.Position - n * 0.05 + n * 0.45, 0.9, "pipe_red", DECOR)
	return m
end

function Props.mirrorBulbs(ctx, parent, base, lit)
	local m = M(ctx, parent, "MakeupStation")
	P(ctx, m, base, "Desk", 4.4, 0.25, 2, 0, 3, 0, "wood_dark")
	P(ctx, m, base, "Cabinet", 4.4, 2.8, 1.8, 0, 1.4, 0.1, "panel_wood", { shadow = false })
	P(ctx, m, base, "Mirror", 3.6, 2.6, 0.1, 0, 5, 0.9, "mirror", { collide = false, shadow = false })
	for i = 1, 5 do
		local x = -1.9 + (i - 1) * 0.95
		ctx:ball(m, "Bulb" .. i, (base * CFrame.new(x, 6.5, 0.8)).Position, 0.2, lit and "lamp_warm" or "plastic_cream", DECOR)
	end
	return m
end

function Props.costumeRack(ctx, parent, base, len, rng)
	local m = M(ctx, parent, "CostumeRack")
	P(ctx, m, base, "Bar", len, 0.15, 0.15, 0, 5.6, 0, "chrome", DECOR)
	P(ctx, m, base, "LegA", 0.15, 5.6, 1.4, -len / 2, 2.8, 0, "chrome", { shadow = false })
	P(ctx, m, base, "LegB", 0.15, 5.6, 1.4, len / 2, 2.8, 0, "chrome", { shadow = false })
	local styles = { "fabric_coral", "fabric_yellow", "fabric_navy", "fabric_teal", "brass" }
	local n = math.floor(len / 1.2)
	for i = 1, n do
		P(ctx, m, base, "Costume" .. i, 0.5, 3.4, 1.4, -len / 2 + i * len / (n + 1), 3.8, 0, rng and rng:pick(styles) or "fabric_coral", SOFT)
	end
	return m
end

function Props.wineRack(ctx, parent, base, w, h)
	local m = M(ctx, parent, "WineRack")
	P(ctx, m, base, "Frame", w, h, 1.6, 0, h / 2, 0.2, "wood_dark")
	local rows = math.floor(h / 1.2)
	for i = 1, rows do
		P(ctx, m, base, "Bottles" .. i, w - 0.6, 0.7, 0.6, 0, 0.6 + (i - 1) * 1.2, -0.45, i % 3 == 0 and "glass_smoked" or "felt", DECOR)
	end
	return m
end

function Props.cage(ctx, parent, base, w, d, h, openFront)
	local m = M(ctx, parent, "Cage")
	local st = "window_frame"
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			P(ctx, m, base, "Post", 0.25, h, 0.25, sx * w / 2, h / 2, sz * d / 2, st, { shadow = false })
		end
	end
	P(ctx, m, base, "TopA", w, 0.2, 0.2, 0, h, -d / 2, st, { shadow = false })
	P(ctx, m, base, "TopB", w, 0.2, 0.2, 0, h, d / 2, st, { shadow = false })
	P(ctx, m, base, "TopC", 0.2, 0.2, d, -w / 2, h, 0, st, { shadow = false })
	P(ctx, m, base, "TopD", 0.2, 0.2, d, w / 2, h, 0, st, { shadow = false })
	-- mesh panels: see-through, collidable, tagged SightTransparent
	local mesh = { collide = true, shadow = false, transparency = 0.7, tags = { "SightTransparent" } }
	P(ctx, m, base, "MeshBack", w, h, 0.1, 0, h / 2, d / 2, "steel_grate", mesh)
	P(ctx, m, base, "MeshL", 0.1, h, d, -w / 2, h / 2, 0, "steel_grate", mesh)
	P(ctx, m, base, "MeshR", 0.1, h, d, w / 2, h / 2, 0, "steel_grate", mesh)
	if not openFront then
		P(ctx, m, base, "MeshFront", w, h, 0.1, 0, h / 2, -d / 2, "steel_grate", mesh)
	else
		local door = P(ctx, m, base, "DoorOpen", w * 0.5, h, 0.1, 0, h / 2, 0, "steel_grate", { collide = false, query = false, shadow = false, transparency = 0.7 })
		door.CFrame = base * CFrame.new(-w / 2, h / 2, -d / 2) * CFrame.Angles(0, math.rad(-110), 0) * CFrame.new(w * 0.25, 0, 0)
	end
	return m
end

function Props.vaultDoor(ctx, parent, cf, r, open)
	local m = M(ctx, parent, "VaultDoor")
	local n = cf.LookVector
	ctx:cyl(m, "Frame", cf.Position - n * 0.2, cf.Position + n * 0.35, r + 0.8, "steel_dark", { collide = false })
	if open then
		-- door disk swung 90 degrees: its axis now runs along the wall
		local hinge = cf.Position + cf.RightVector * (r + 0.4) + n * (r + 0.6)
		ctx:cyl(m, "Door", hinge, hinge + cf.RightVector * 1.2, r, "steel_bare", { collide = false })
	else
		ctx:cyl(m, "Door", cf.Position + n * 0.3, cf.Position + n * 1.5, r, "steel_bare", { collide = false })
		ctx:cyl(m, "Wheel", cf.Position + n * 1.5, cf.Position + n * 1.8, r * 0.35, "brass", DECOR)
	end
	return m
end

return Props
