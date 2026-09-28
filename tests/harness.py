"""Headless harness: runs the real Luau map generator inside a strict Roblox
API mock (tests/mock/roblox.lua) on Lua 5.1 via lupa, then exports the
generated instance tree for validation.

lupa discovery order:
  1. the current interpreter (pip install lupa==2.6+)
  2. PC_PYTHON env var / ../codex-build/.venv (read-only use; nothing is written there)
Run tests through tools/run_tests.sh, which picks an interpreter automatically.
"""
import json
import math
import os
import re

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SRC = os.path.join(ROOT, "src")

from lupa import lua51  # noqa: E402

# Rojo mapping (mirrors default.project.json)
MOUNTS = [
    ("ReplicatedStorage/PastCurfew/Map", os.path.join(SRC, "Map")),
    ("ServerScriptService/PastCurfewMap", os.path.join(SRC, "Server")),
    ("StarterPlayer/StarterPlayerScripts/PastCurfewMap", os.path.join(SRC, "Client")),
]


def _entries():
    out = []
    for inst_root, fs_root in MOUNTS:
        for dirpath, dirnames, filenames in os.walk(fs_root):
            dirnames.sort()
            rel = os.path.relpath(dirpath, fs_root)
            base = inst_root if rel == "." else inst_root + "/" + rel.replace(os.sep, "/")
            out.append((base, "Folder", ""))
            for fn in sorted(filenames):
                path = os.path.join(dirpath, fn)
                if fn.endswith(".server.lua"):
                    out.append((base + "/" + fn[: -len(".server.lua")], "Script", path))
                elif fn.endswith(".client.lua"):
                    out.append((base + "/" + fn[: -len(".client.lua")], "LocalScript", path))
                elif fn.endswith(".lua"):
                    out.append((base + "/" + fn[: -len(".lua")], "ModuleScript", path))
    return out


BOOT = r"""
local M, entries, readFile = ...
M.reset()
local sources = {}
local cache = {}
local function ensure(path, className)
	local node = game
	local parts = string.split(path, "/")
	for i, name in ipairs(parts) do
		local child
		if i == 1 then
			child = M.services[name]
		else
			child = node:FindFirstChild(name)
		end
		if not child then
			local cls = (i == #parts) and className or "Folder"
			child = M.newInstance(cls, name)
			child.Parent = node
		end
		node = child
	end
	return node
end
for i = 1, #entries do
	local e = entries[i]
	local inst = ensure(e[1], e[2])
	if e[3] ~= "" then sources[inst] = e[3] end
end
local realRequire = require
function require(target)
	if typeof(target) ~= "Instance" then return realRequire(target) end
	if cache[target] ~= nil then return cache[target] end
	local path = sources[target]
	if not path then error("require: no source for " .. target:GetFullName(), 2) end
	local fn, err = loadstring(readFile(path), "@" .. path)
	if not fn then error(err, 0) end
	local env = setmetatable({ script = target }, { __index = _G })
	setfenv(fn, env)
	local result = fn()
	cache[target] = result
	return result
end
return true
"""

EXPORT = r"""
local M, rootPaths = ...
local out = {}
local function num(v) return string.format("%.4f", v) end
local function encAttr(v)
	local t = typeof(v)
	if t == "string" then return "s:" .. string.gsub(v, "[|;=\n]", "_") end
	if t == "number" then return "n:" .. num(v) end
	if t == "boolean" then return "b:" .. tostring(v) end
	if t == "Vector3" then return "v:" .. num(v.X) .. "," .. num(v.Y) .. "," .. num(v.Z) end
	if t == "Color3" then return "c:" .. num(v.R) .. "," .. num(v.G) .. "," .. num(v.B) end
	return "o:" .. t
end
local function attrs(inst)
	local keys = {}
	for k in pairs(inst.__attrs) do table.insert(keys, k) end
	table.sort(keys)
	local parts = {}
	for _, k in ipairs(keys) do table.insert(parts, k .. "=" .. encAttr(inst.__attrs[k])) end
	return table.concat(parts, ";")
end
local function tags(inst)
	return table.concat(inst:GetTags(), ",")
end
local function emit(inst, path)
	local p = inst.__props
	local cls = inst.__class
	local line
	if inst:IsA("BasePart") then
		local cf = p.CFrame
		local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
		local s = p.Size
		local shape = cls == "Part" and p.Shape.Name or cls
		line = table.concat({
			"P", path, shape,
			num(s.X) .. "," .. num(s.Y) .. "," .. num(s.Z),
			table.concat({ num(x), num(y), num(z), num(r00), num(r01), num(r02), num(r10), num(r11), num(r12), num(r20), num(r21), num(r22) }, ","),
			p.Material.Name,
			num(p.Color.R) .. "," .. num(p.Color.G) .. "," .. num(p.Color.B),
			num(p.Transparency),
			tostring(p.CanCollide), tostring(p.CanQuery), tostring(p.CastShadow), tostring(p.Anchored),
			tags(inst), attrs(inst),
		}, "|")
	elseif inst:IsA("Light") then
		line = table.concat({ "L", path, cls, num(p.Range), num(p.Brightness), tostring(p.Shadows), tostring(p.Enabled), tags(inst), attrs(inst) }, "|")
	else
		local extra = ""
		if cls == "TextLabel" then extra = string.gsub(p.Text or "", "[|\n]", " ") end
		line = table.concat({ "I", path, cls, tags(inst), attrs(inst), extra }, "|")
	end
	table.insert(out, line)
end
local function walk(inst, path)
	for _, c in ipairs(inst.__children) do
		local cp = path .. "/" .. c.__props.Name
		emit(c, cp)
		walk(c, cp)
	end
end
for i = 1, #rootPaths do
	local root = game
	for _, name in ipairs(string.split(rootPaths[i], "/")) do
		if root == game then root = M.services[name] else root = root:FindFirstChild(name) end
		if not root then break end
	end
	if root then walk(root, rootPaths[i]) end
end
-- terrain operations
for _, op in ipairs(M.terrainOps) do
	local pos, size = "", ""
	if op.cf then
		pos = num(op.cf.Position.X) .. "," .. num(op.cf.Position.Y) .. "," .. num(op.cf.Position.Z)
	end
	if op.size then size = num(op.size.X) .. "," .. num(op.size.Y) .. "," .. num(op.size.Z) end
	if op.center then pos = num(op.center.X) .. "," .. num(op.center.Y) .. "," .. num(op.center.Z); size = num(op.radius) end
	table.insert(out, table.concat({ "T", op.op, op.mat, pos, size }, "|"))
end
return table.concat(out, "\n")
"""


class Part:
    __slots__ = ("path", "shape", "size", "pos", "rot", "material", "color", "transparency", "collide", "query",
                 "shadow", "anchored", "tags", "attrs", "name")

    def aabb(self):
        hx, hy, hz = self.size[0] / 2, self.size[1] / 2, self.size[2] / 2
        r = self.rot
        ex = abs(r[0]) * hx + abs(r[1]) * hy + abs(r[2]) * hz
        ey = abs(r[3]) * hx + abs(r[4]) * hy + abs(r[5]) * hz
        ez = abs(r[6]) * hx + abs(r[7]) * hy + abs(r[8]) * hz
        x, y, z = self.pos
        return (x - ex, y - ey, z - ez, x + ex, y + ey, z + ez)

    def axis_aligned(self):
        r = self.rot
        # each column has exactly one +-1 entry
        for c in range(3):
            col = (abs(r[c]), abs(r[3 + c]), abs(r[6 + c]))
            if max(col) < 0.999:
                return False
        return True


def _decode_attr(v):
    kind, _, val = v.partition(":")
    if kind == "s":
        return val
    if kind == "n":
        return float(val)
    if kind == "b":
        return val == "true"
    if kind in ("v", "c"):
        return tuple(float(x) for x in val.split(","))
    return val


def _attrs(s):
    out = {}
    if not s:
        return out
    for kv in s.split(";"):
        k, _, v = kv.partition("=")
        out[k] = _decode_attr(v)
    return out


class Build:
    def __init__(self, text, report):
        self.parts = []
        self.lights = []
        self.instances = []
        self.terrain = []
        self.report = report
        for line in text.split("\n"):
            if not line:
                continue
            f = line.split("|")
            if f[0] == "P":
                p = Part()
                p.path = f[1]
                p.name = f[1].rsplit("/", 1)[-1]
                p.shape = f[2]
                p.size = tuple(float(x) for x in f[3].split(","))
                c = [float(x) for x in f[4].split(",")]
                p.pos = tuple(c[:3])
                p.rot = tuple(c[3:])
                p.material = f[5]
                p.color = tuple(float(x) for x in f[6].split(","))
                p.transparency = float(f[7])
                p.collide = f[8] == "true"
                p.query = f[9] == "true"
                p.shadow = f[10] == "true"
                p.anchored = f[11] == "true"
                p.tags = set(t for t in f[12].split(",") if t)
                p.attrs = _attrs(f[13])
                self.parts.append(p)
            elif f[0] == "L":
                self.lights.append({
                    "path": f[1], "class": f[2], "range": float(f[3]), "brightness": float(f[4]),
                    "shadows": f[5] == "true", "enabled": f[6] == "true",
                    "tags": set(t for t in f[7].split(",") if t), "attrs": _attrs(f[8]),
                })
            elif f[0] == "I":
                self.instances.append({
                    "path": f[1], "class": f[2], "tags": set(t for t in f[3].split(",") if t),
                    "attrs": _attrs(f[4]), "text": f[5] if len(f) > 5 else "",
                })
            elif f[0] == "T":
                self.terrain.append({"op": f[1], "mat": f[2], "pos": f[3], "size": f[4]})
        self.text = text

    def tagged(self, tag):
        out = [p for p in self.parts if tag in p.tags]
        out += [i for i in self.instances if tag in i["tags"]]
        out += [l for l in self.lights if tag in l["tags"]]
        return out


def _read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def new_runtime():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    with open(os.path.join(HERE, "mock", "roblox.lua"), "r", encoding="utf-8") as f:
        mock = lua.execute(f.read())
    entries = lua.table_from([lua.table_from(list(e)) for e in _entries()])
    boot = lua.eval("function(...) " + BOOT + " end")
    boot(mock, entries, _read_file)
    return lua, mock


def run_build(seed="PastCurfew/Map/1", roots=("Workspace/PastCurfewMap", "ServerStorage/PastCurfewMapVariants", "Lighting"), variant="v1"):
    lua, mock = new_runtime()
    runner = lua.eval("""function(seed, variant)
        local MB = require(game:GetService("ReplicatedStorage").PastCurfew.Map.MapBuilder)
        local report = MB.build({ seed = seed, variant = variant })
        return report
    end""")
    report = runner(seed, variant)
    exporter = lua.eval("function(...) " + EXPORT + " end")
    text = exporter(mock, lua.table_from(list(roots)))
    rep = _lua_to_py(report)
    return Build(text, rep), lua, mock


def _lua_to_py(v):
    if v is None or isinstance(v, (int, float, str, bool)):
        return v
    try:
        keys = list(v.keys())
    except AttributeError:
        return v
    if keys and all(isinstance(k, int) for k in keys) and sorted(keys) == list(range(1, len(keys) + 1)):
        return [_lua_to_py(v[k]) for k in sorted(keys)]
    return {str(k): _lua_to_py(v[k]) for k in keys}


if __name__ == "__main__":
    import sys
    import time
    t = time.time()
    b, _, _ = run_build(sys.argv[1] if len(sys.argv) > 1 else "PastCurfew/Map/1")
    print("parts", len(b.parts), "lights", len(b.lights), "instances", len(b.instances), "terrain ops", len(b.terrain))
    print("report", json.dumps(b.report, indent=1)[:3000])
    print("seconds", round(time.time() - t, 2))
