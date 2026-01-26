local game = {}

debug.setFuncPrefix("[GAME]", nil, nil, 1)

function setPressure(x, y, pressure)
	global.fse.getCurrentCell(x, y):setPressure(pressure)
	global.fse.getNextCell(x, y):setPressure(pressure)
end
function setMass(x, y, mass)
	global.fse.getCurrentCell(x, y):setMass(mass)
	global.fse.getNextCell(x, y):setMass(mass)
end

function game.init(dt)
	--debug.setFuncPrefix("[INIT]")
	--debug.log("TEST")
	
	--global.fse.getCurrentCell(5, 5):setDebug(true)
	--global.fse.getNextCell(5, 5):setDebug(true)
	
	
	--setMass(2, 5, 1)
	--setPressure(4, 4, .5)
	
	
	
	
	for c = 1, 10 do
		--global.fse.matrices[1].matrix[c][1]:setPressure(c * .1)
		--global.fse.matrices[2].matrix[c][1]:setPressure(c * .1)
	end
end

function game.update(dt)
	
	
	if input.keyPressed("r") then
		loadfile("data/init.lua")({reload = true})
		isResetting = true
	end
	
	global.simulatePhysics = false
	if input.keyPressed("c") then
		print("Tick: " .. global.fse.currentMatrix)
		global.simulatePhysics = true
	end
	if input.keyDown("v") then
		print("Tick: " .. global.fse.currentMatrix)
		global.simulatePhysics = true
	end
	
	--global.fse.getCurrentCell(3, 3):setPressure(.01)
	--print(global.fse.getCurrentCell(3, 5):getPressure())
	
	
	
	--debug.log("game")
end

function game.draw(dt)
	
end

return game