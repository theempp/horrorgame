-- Deterministic PRNG (Park-Miller minimal standard, 16807 mod 2^31-1).
-- Chosen over Random.new because it produces identical sequences in Roblox
-- Luau and in the headless Lua 5.1 test harness: every intermediate value is an
-- integer below 2^53, so double arithmetic is exact in both.
local Rng = {}
Rng.__index = Rng

local MOD = 2147483647
local MUL = 16807

function Rng.hash(s)
	local h = 7
	for i = 1, #s do
		h = (h * 31 + string.byte(s, i)) % MOD
	end
	if h == 0 then h = 1 end
	return h
end

function Rng.new(seed)
	if type(seed) == "string" then seed = Rng.hash(seed) end
	seed = math.floor(seed or 1) % MOD
	if seed <= 0 then seed = seed + MOD - 1 end
	return setmetatable({ state = seed }, Rng)
end

-- Independent stream derived from this one's seed and a label, so adding a
-- random call in one room never reshuffles every other room.
function Rng:fork(label)
	return Rng.new((self.state + Rng.hash(label)) % MOD)
end

function Rng:next()
	self.state = (self.state * MUL) % MOD
	return self.state / MOD
end

function Rng:range(a, b)
	return a + (b - a) * self:next()
end

function Rng:int(a, b)
	return a + math.floor(self:next() * (b - a + 1))
end

function Rng:chance(p)
	return self:next() < p
end

function Rng:pick(list)
	return list[self:int(1, #list)]
end

-- Snap to the prop grid (horrorgame.md: prop snap 0.5).
function Rng:snap(a, b, step)
	step = step or 0.5
	return math.floor(self:range(a, b) / step + 0.5) * step
end

return Rng
