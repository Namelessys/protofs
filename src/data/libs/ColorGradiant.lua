local ColorGradiant = {}

--local ut = global.ut
local ut = require("UT")
local pa = ut.parseArgs

--===== helper functions =====--
local function clamp(low, high, value)
	return math.min(high, math.max(low, value))
end

local function interpol(valueA, valueB, pos)
	local low = math.min(valueA, valueB)
	--local high = math.max(valueA, valueB)
	local offset = -low
	local multiplier = math.abs(offset + valueA) + math.abs(offset + valueB)
	pos = clamp(0, 1, pos)
	if valueA < valueB then
		return pos * multiplier + low
	else
		return valueA - pos * multiplier
	end
end

--===== lib =====--
function ColorGradiant.new(args) 
	local self = setmetatable({}, {__index = ColorGradiant})
	
	self.lookup = pa(args.colors, args.colorGradiant, args.lt, args.lookup, args.lookup, {})
	self.clamp = pa(args.clamp, {low = 0, high = 1})
	
	return self
end

function ColorGradiant:clampSet(clampNew)
	self.clamp = clampNew
end
function ColorGradiant:clampGet()
	return self.clamp
end

function ColorGradiant:lookupSet(lookupNew)
	self.lookup = lookupNew
end
function ColorGradiant:lookupGet()
	return self.lookup
end

function ColorGradiant:colorGet(value)
	local offset = -self.clamp.low
	local divider = math.abs(offset + self.clamp.low) + math.abs(offset + self.clamp.high)
	local valueNorm = (clamp(self.clamp.low, self.clamp.high, value) + offset) * (#self.lookup - 1) / divider
	local valueNormTrunc = math.floor(valueNorm)
	local valueNormFrac = valueNorm - valueNormTrunc
	local tableA, tableB = self.lookup[valueNormTrunc + 1], self.lookup[valueNormTrunc + 2]
	if not tableB then tableB = tableA end
	local tableReturn = {}
	
	
	
	for i, v in pairs(tableA) do
		tableReturn[i] = interpol(v, tableB[i], valueNormFrac)
		
		--print(i, v, tableB[i], valueNormFrac)
	end
	
	
	return tableReturn
end

return ColorGradiant
