--[[
	'noname' is the main table wich should contain all data relevant for things happening here.
	it is accesable from everywhere in the system using 'global.noname'.
]]
local noname = {
	--dynamically loaded files.
	dyn = {},
	
	firstTick = true,
}

function setQuantity(x, y, pressure)
	global.fse.getCurrentCell(x, y):setQuantity(pressure)
	global.fse.getNextCell(x, y):setQuantity(pressure)
end
function getQuantity(x, y)
	return global.fse.getCurrentCell(x, y):getQuantity()
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

	debug.log("##### noname INIT DONE #####")
end


function noname.update(dt)
	debug.setFuncPrefix("[noname][UPDATE]")
	if noname.firstTick then
		--noname.dyn.setWindowPos() --wayland

		setQuantity(1, 1, 1)
		setQuantity(2, 1, 1)
		
		global.fse.getCurrentMatrix().matrix[1][1]:setFlowVelocity(2, 1)
		
		noname.firstTick = false
	end
	
	setQuantity(2, 1, 1)
	
	

	if input.keyDown("f") then
		--setQuantity(3, 1, getQuantity(3, 1) + 1)
		setQuantity(1, 1, 1)
	end

	--print when the 'B' key is pressed or released
	if input.keyPressed("b") then
		debug.log("B key just got pressed")
	elseif input.keyReleased("b") then
		debug.log("B key just got released")
	end
end

function noname.draw(dt)
	debug.setFuncPrefix("[noname][DRAW]")
	
end

return noname