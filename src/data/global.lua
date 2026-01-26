local global = {
	org = {}
}

local pleal = require("plealTranspilerAPI")

function global.loadfile(path)
	local transSuc, transErr, transCode = pleal.transpileFile(path)
	local func, err
	
	if not transSuc then
		print("Could not transpile code")
		error(transErr)
	end
	
	func, err = load(transCode)
	--local func, err = loadfile(path)
	if func == nil then
		print("Could not load file")
		error(err)
	end
	return func
end

return global