local table = table
local math = math

function stringfromhex(str)
  return (str:gsub('..', function (cc)
      return string.char(tonumber(cc, 16))
  end))
end

function stringtohex(str)
  return (str:gsub('.', function (c)
      return string.format('%02X', string.byte(c))
  end))
end

vector = {}
vector.__index = vector

local function is_vector(t)
    return getmetatable(t) == vector
end

function vector.new(x, y)
    return setmetatable({ x = x or 0, y = y or 0 }, vector)
end

-- operator overloading
function vector.__add(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected.")
    return vector.new(lhs.x + rhs.x, lhs.y + rhs.y)
end

function vector.__sub(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected.")
    return vector.new(lhs.x - rhs.x, lhs.y - rhs.y)
end

function vector.__mul(lhs, rhs)
    local is_rhs_vector = is_vector(rhs)
    local is_lhs_vector = is_vector(lhs)
    if type(lhs) == "number" and is_rhs_vector then
        return vector.new(rhs.x * lhs, rhs.y * lhs)
    elseif type(rhs) == "number" and is_lhs_vector then
        return vector.new(lhs.x * rhs, lhs.y * rhs)
    elseif is_rhs_vector and is_lhs_vector then
        return vector.new(lhs.x * rhs.x, lhs.y * rhs.y)
    else
        error("Type mismatch: vector and/or number expected", 2)
    end
end
    

function vector.__unm(t)
    assert(is_vector(t), "Type mismatch: vector expected.")
    return vector.new(-t.x, -t.y)
end

function vector:__tostring()
    return "("..self.x..", "..self.y..")"
end

function vector.__eq(lhs, rhs)
    return lhs.x == rhs.x and lhs.y == rhs.y
end

function vector.__lt(lhs, rhs)
    return lhs.x < rhs.x or (not (rhs.x < lhs.x) and lhs.y < rhs.y)
end

function vector.__le(lhs, rhs)
    return lhs.x <= rhs.x or lhs.y <= rhs.y
end


-- actual functions
function vector:clone()
    return vector.new(self.x, self.y)
end

function vector:length()
    return math.sqrt(self.x * self.x + self.y * self.y)
end

function vector:length_squared()
    return self.x * self.x + self.y * self.y
end

function vector:is_unit()
    return self:length_squared() == 1
end

function vector:unpack()
    return self.x, self.y
end

function vector:normalize()
    local len = self:length()
    if len ~= 0 and len ~= 1 then
        self.x = self.x / len
        self.y = self.y / len
    end
end

function vector:normalized()
    return self:clone():normalize()
end

function vector.dot(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected")
    return lhs.x * rhs.x + lhs.y * rhs.y
end

function vector.distance(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected")
    local dx, dy = lhs.x - rhs.x, lhs.y - rhs.y
    return math.sqrt(dx * dx + dy * dy)
end

function vector.distance_squared(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected")
    local dx, dy = lhs.x - rhs.x, lhs.y - rhs.y
    return dx * dx + dy * dy
end

function vector.max(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected")
    local x = math.max(lhs.x, rhs.x)
    local y = math.max(lhs.y, rhs.y)
    return vector.new(x, y)
end

function vector.min(lhs, rhs)
    assert(is_vector(lhs) and is_vector(rhs), "Type mismatch: vector expected")
    local x = math.min(lhs.x, rhs.x)
    local y = math.min(lhs.y, rhs.y)
    return vector.new(x, y)
end
--[[
function vector.angle(from, to)
    assert(is_vector(from) and is_vector(to), "Type mismatch: vector expected")
		print(vector.dot(from, to))
    return math.acos(vector.dot(from, to) / (from:length() * to:length()))
end
]]
function vector.angle(from, to)
	assert(is_vector(from) and is_vector(to), "Type mismatch: vector expected")
	
	local dotProduct = vector.dot(from, to)
	local angle = math.acos(dotProduct / (from:length() * to:length()))

	local crossProduct = from.x * to.y - from.y * to.x
	if crossProduct < 0 then
			angle = 2 * math.pi - angle
	end

	return angle
end


function vector.direction(from, to)
    assert(is_vector(from) and is_vector(to), "Type mismatch: vector expected")
    return math.atan2(to.y - from.y, to.x - from.y)
end

function vector.lerp(from, to, t)
    assert(is_vector(from) and is_vector(to), "Type mismatch: vector expected")
    assert(type(t) == "number", "Type mismatch: number expected for t")
    return from * t + (to * (1 - t))
end

function table.dump(v, ores)
	local res = ores or {}
	local t = type(v)
	if t == "function" then 
		table.insert(res, "<function>")
		return res
	elseif t ~= "table" then 
		table.insert(res, string.format("%q",v))
		return res
	end
	table.insert(res, "{")
	for tk,tv in pairs(v) do
		table.insert(res, "[")
		table.dump(tk, res)
		table.insert(res, "]=")
		table.dump(tv, res)
		table.insert(res, ",")
	end
	table.insert(res, "}")
	return res
end

function table.indexof(t,q)
	for idx,v in ipairs(t) do
		if v == q then return idx end
	end
	return 0
end

function table.compact(t)
    local newTable = {}
    for _, v in pairs(t) do
        if v ~= nil then
            table.insert(newTable, v)
        end
    end
    return newTable
end

function Bounce(t)
		if (t < 1.0 / 2.75) then
			return 7.5625 * t * t;
		elseif (t < 2 / 2.75) then
			t = t - 1.5 / 2.75;
			return 7.5625 * t * t + 0.75;
		elseif (t < 2.5 / 2.75) then
			t = t - 2.25 / 2.75;
			return 7.5625 * t * t + 0.9375;
		end
		t = t -2.625 / 2.75;
		return 7.5625 * t * t + 0.984375;
end

function BounceIn(t)
    return 1.0 - Bounce(1.0 - t)
end

function BounceOut(t)
    return Bounce(t)
end

function BounceInOut(t)
    if t < 0.5 then
        return (1.0 - Bounce(1.0 - t * 2.0)) * 0.5
    else
        return Bounce(t * 2.0 - 1.0) * 0.5 + 0.5
    end
end

function ElasticIn(t, period)
    period = period or 0.4
    local s = period / 4.0
    t = t - 1.0
    return -(2.0)^(10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period)
end

function ElasticOut(t, period)
    period = period or 0.4
    local s = period / 4.0
    return (2.0)^(-10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period) + 1.0
end

function ElasticInOut(t, period)
    period = period or 0.4
    local s = period / 4.0
    t = 2.0 * t - 1.0
    if t < 0.0 then
        return -0.5 * (2.0)^(10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period)
    else
        return (2.0)^(-10.0 * t) * math.sin((t - s) * (math.pi * 2.0) / period) * 0.5 + 1.0
    end
end
