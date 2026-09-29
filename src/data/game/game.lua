local game = {}

debug.setFuncPrefix("[GAME]", nil, nil, 1)

function densitySet(x, y, pressure)
	global.fse.currentCellGet(x, y):densitySet(pressure)
	global.fse.nextCellGet(x, y):densitySet(pressure)
end

function game.init(dt)
	--debug.setFuncPrefix("[INIT]")
	--debug.log("TEST")
	
	--global.fse.currentCellGet(5, 5):debugSet(true)
	--global.fse.nextCellGet(5, 5):debugSet(true)
	
	
	--setMass(2, 5, 1)
	--densitySet(4, 4, .5)
	
	
	
	
	for c = 1, 10 do
		--global.fse.matrices[1].matrix[c][1]:densitySet(c * .1)
		--global.fse.matrices[2].matrix[c][1]:densitySet(c * .1)
	end
end

function game.update(dt)
	
	if input.keyDown("r") then
		loadfile("data/init.lua")({reload = true})
		isResetting = true
	end
	
	if input.keyDown("p") then
		global.simulationPaused = !global.simulationPaused
	end
	
	global.simulatePhysics = !global.simulationPaused
		
	if input.keyDown("c") then
		print("Tick: " .. global.fse.currentMatrix)
		global.simulatePhysics = true
	end
	if input.keyPressed("v") then
		print("Tick: " .. global.fse.currentMatrix)
		global.simulatePhysics = true
	end
	if input.keyDown("m") then
		if global.fse.currentMatrixRender == 1 then
			global.fse.currentMatrixRender = 2
		else
			global.fse.currentMatrixRender = 1
		end
	end
	
	--global.fse.currentCellGet(3, 3):densitySet(.01)
	--print(global.fse.currentCellGet(3, 5):pressureGet())
	
	
	
	--debug.log("game")
end

function game.draw(dt)
	
end

return game