--[[
	'noname' is the main table wich should contain all data relevant for things happening here.
	it is accesable from everywhere in the system using 'global.noname'.
]]
local noname = {
	--dynamically loaded files.
	dyn = {},
	
	firstTick = true,
}

function densitySet(x, y, pressure)
	global.fse.currentCellGet(x, y):densitySet(pressure)
	global.fse.nextCellGet(x, y):densitySet(pressure)
	
	--global.fse.currentCellGet(x, y).energyTotal = 0
	--global.fse.nextCellGet(x, y).energyTotal = 0
	
end
function densityGet(x, y)
	return global.fse.currentCellGet(x, y):densityGet()
end

function noname.init()
	--set the logging prefix inside the 'noname.init' function.
	debug.setFuncPrefix("[noname][INIT]") 
	
	--do some logging
	debug.log("##### INIT START #####")
	
	--execute all files inside 'data/noname/init' in specific order.
	debug.log("Execute init dir")
	global.dl.executeDir("data/noname/init", "INIT_noname")
	
	--execute all files inside 'data/noname/dyn' and puts the return values into the 'noname.dyn' table.
	debug.log("Load dyn dir")
	global.dl.load({
		dir = "data/noname/dyn",
		target = noname.dyn,
		execute = true,
	})
	
	debug.log("### MISC ###")
	
	local cg = noname.dyn.ColorGradiant.new({
		lookup = {{0, 0, 0}, {0, 100, 0}}
	})
	
	debug.dlog(cg.colorGet(.5))

	debug.log("##### INIT DONE #####")
end


function noname.update(dt)
	debug.setFuncPrefix("[noname][UPDATE]")
	if noname.firstTick then
		--noname.dyn.setWindowPos() --wayland

		densitySet(1, 1, 100)
		--densitySet(2, 1, 0.1)
		
		
		--global.fse.currentMatrixGet().matrix[1][1]:flowVelocitySet(2, 1)
		
		noname.firstTick = false
	end
	
	
	--densitySet(global.conf.sizeX, 1, 1)

	if input.keyPressed("f") then
		--densitySet(3, 1, densityGet(3, 1) + 1)
		densitySet(1, 1, 100)
	end
	if input.keyPressed("g") then
		--densitySet(3, 1, densityGet(3, 1) + 1)
		densitySet(1, 1, 0.1)
	end

	--print when the 'B' key is pressed or released
	if input.keyDown("b") then
		debug.log("B key just got pressed")
	elseif input.keyUp("b") then
		debug.log("B key just got released")
	end
end

function noname.draw(dt)
	debug.setFuncPrefix("[noname][DRAW]")
	
end

return noname