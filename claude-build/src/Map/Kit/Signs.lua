-- Signage and printed ephemera rendered with SurfaceGui text + frames only
-- (no uploaded images). Styles follow late-1980s cruise brochures and
-- maritime practice: brass-and-navy public plaques, stencilled crew signs,
-- green exit signs, typewritten notices, gradient brochure posters.
local Map = script.Parent.Parent
local Palette = require(Map.Config.Palette)

local C = Palette.colors
local F = Palette.fonts

local Signs = {}

-- board part styles and text treatment
local STYLES = {
	public = { board = "brass_dark", bg = C.navy, fg = C.cream, font = F.public, stroke = C.brass },
	deck = { board = "brass_dark", bg = C.navyDeep, fg = C.yellow, font = F.display, stroke = C.brass },
	cabin = { board = "brass", bg = C.brass, fg = C.navyDeep, font = F.public },
	crew = { board = "steel_paint", bg = C.yellowFaded, fg = C.black, font = F.crew },
	danger = { board = "steel_paint", bg = C.yellow, fg = C.black, font = F.crew, header = C.red },
	exit = { board = "black", bg = C.black, fg = C.exitGreen, font = F.crew, emissive = true },
	paper = { board = "paper", bg = C.linen, fg = C.navyDeep, font = F.paper },
	poster = { board = "paper", bg = C.navy, fg = C.cream, font = F.display, gradient = { C.coral, C.yellow } },
	harbor = { board = "timber_dark", bg = C.tealDeep, fg = C.cream, font = F.crew, stroke = C.yellowFaded },
	hull = { board = "hull_navy", bg = C.navy, fg = C.cream, font = F.display, noBoard = true },
	violet = { board = "black", bg = C.black, fg = C.violet, font = F.paper, emissive = true },
}
Signs.STYLES = STYLES

-- cf: CFrame of the sign face centre; the text reads on the part's Front face
-- (LookVector points toward the reader). w, h in studs.
-- lines: string or { main, sub }.
function Signs.make(ctx, parent, cf, w, h, lines, styleName, opts)
	opts = opts or {}
	local st = STYLES[styleName] or STYLES.public
	local depth = opts.depth or 0.15
	local part = ctx:part(parent, opts.name or "Sign", Vector3.new(w, h, depth), cf * CFrame.new(0, 0, depth / 2), st.board,
		{ collide = false, query = false, shadow = false, transparency = st.noBoard and 1 or nil })
	local gui = ctx:surfaceGui(part, "Front", {
		pps = opts.pps or 36,
		lightInfluence = st.emissive and 0 or (opts.lightInfluence or 0.55),
		brightness = st.emissive and 2.2 or (opts.brightness or 1.25),
		maxDistance = opts.maxDistance or 80,
	})
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = st.bg
	frame.BackgroundTransparency = st.noBoard and 1 or 0
	frame.BorderSizePixel = 0
	frame.Parent = gui
	if st.stroke then
		local s = Instance.new("UIStroke")
		s.Color = st.stroke
		s.Thickness = 3
		s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		s.Parent = frame
	end
	if st.gradient then
		local band = Instance.new("Frame")
		band.Size = UDim2.fromScale(1, 0.28)
		band.Position = UDim2.fromScale(0, 0.72)
		band.BorderSizePixel = 0
		band.BackgroundColor3 = Color3.new(1, 1, 1)
		band.Parent = frame
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(st.gradient[1], st.gradient[2])
		g.Parent = band
	end
	if st.header then
		local hd = Instance.new("Frame")
		hd.Size = UDim2.fromScale(1, 0.3)
		hd.BorderSizePixel = 0
		hd.BackgroundColor3 = st.header
		hd.Parent = frame
	end
	local main, sub = lines, nil
	if type(lines) == "table" then main, sub = lines[1], lines[2] end
	if sub then
		ctx:label(frame, main, st.font, st.fg, { size = UDim2.fromScale(0.92, 0.56), position = UDim2.fromScale(0.04, 0.06) })
		ctx:label(frame, sub, st.font, st.fg, { size = UDim2.fromScale(0.86, 0.3), position = UDim2.fromScale(0.07, 0.62) })
	else
		local top = st.header and 0.32 or 0.1
		ctx:label(frame, main, st.font, st.fg, { size = UDim2.fromScale(0.9, 0.9 - top), position = UDim2.fromScale(0.05, top) })
	end
	return part
end

-- Multi-line paper document (manifest page, log, notice). Text is short by design.
function Signs.paper(ctx, parent, cf, w, h, title, body, opts)
	opts = opts or {}
	local part = ctx:part(parent, opts.name or "Paper", Vector3.new(w, h, 0.05), cf * CFrame.new(0, 0, 0.025), "paper",
		{ collide = false, query = false, shadow = false })
	local gui = ctx:surfaceGui(part, "Front", { pps = opts.pps or 60, lightInfluence = 0.7, brightness = 1.1, maxDistance = 24 })
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = C.linen
	frame.BorderSizePixel = 0
	frame.Parent = gui
	ctx:label(frame, title, F.paper, C.navyDeep, { size = UDim2.fromScale(0.9, 0.18), position = UDim2.fromScale(0.05, 0.04) })
	ctx:label(frame, body, F.paper, C.black, {
		size = UDim2.fromScale(0.9, 0.72), position = UDim2.fromScale(0.05, 0.24), align = "Left", valign = "Top",
	})
	return part
end

-- Painted lettering directly on a surface (hull names, frame numbers, deck
-- stencils). The carrier part is invisible.
function Signs.paint(ctx, parent, cf, w, h, text, fontName, color, opts)
	opts = opts or {}
	local part = ctx:part(parent, opts.name or "Paint", Vector3.new(w, h, 0.05), cf * CFrame.new(0, 0, 0.03), "volume",
		{ collide = false, query = false, shadow = false, transparency = 1 })
	local gui = ctx:surfaceGui(part, "Front", {
		pps = opts.pps or 12, lightInfluence = opts.lightInfluence or 1, brightness = opts.brightness or 1,
		maxDistance = opts.maxDistance or 0,
	})
	ctx:label(gui, text, fontName, color, { wrap = false })
	return part
end

return Signs
