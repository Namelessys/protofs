local ColorGradiant = {}

local ut = global.ut
local pa = ut.parseArgs

function ColorGradiant.new(args) 
	local self = setmetatable({}, {__index = ColorGradiant})
	
	self.lookup = pa(args.colors, args.colorGradiant, args.lt, args.lookup, args.lookup, {})
	self.clamp = pa(args.clamp, {min = 0, max = 1})
	
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
	return 1
end

return ColorGradiant