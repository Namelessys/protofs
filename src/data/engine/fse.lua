local fse = {
	currentMatrix = 1,
	currentMatrixRender = 1,
	
	nextMatrix = 2,
	
	matrices = {},
	
	test = "T",
	
}

function fse.init(sizeX, sizeY)
	fse.matrices = {
		loadfile("data/engine/classes/FluidMatrix.lua")().new(
			sizeX, sizeY, global.loadfile("data/engine/classes/FluidCell.lua")()
		),
		loadfile("data/engine/classes/FluidMatrix.lua")().new(
			sizeX, sizeY, global.loadfile("data/engine/classes/FluidCell.lua")()
		)
	}
end

function fse.update(dt)	
	debug.setFuncPrefix("[FSE_UPDATE]")
	
	if global.simulatePhysics then
		fse.matrices[fse.currentMatrix]:update(1)
		
		if fse.currentMatrix + 1 > #fse.matrices then
			fse.currentMatrix = 1
		else
			fse.currentMatrix = fse.currentMatrix + 1
		end
		if fse.currentMatrix + 1 > #fse.matrices then
			fse.nextMatrix = 1
		else
			fse.nextMatrix = fse.currentMatrix + 1
		end
	end
end

function fse.draw(offsetX, offsetY, scaleX, scaleY, gab)
	debug.setFuncPrefix("[FSE_DRAW]")
	fse.matrices[fse.currentMatrixRender]:draw(offsetX, offsetY, scaleX, scaleY, gab)
	
	if global.simulatePhysics then
		if fse.currentMatrixRender + 1 > #fse.matrices then
			fse.currentMatrixRender = 1
		else
			fse.currentMatrixRender = fse.currentMatrixRender + 1
		end
	end
end

function fse.getCurrentMatrix()
	return fse.matrices[fse.currentMatrix]
end
function fse.getNextMatrix()
	return fse.matrices[fse.nextMatrix]
end
function fse.getCurrentCell(x, y)
	local matrixSizeX, matrixSizeY = fse.getCurrentMatrix():getSize()
	if x < 1 or y < 1 or x > matrixSizeX or y > matrixSizeY then
		return false
	end
	return fse.getCurrentMatrix().matrix[x][y]
end
function fse.getNextCell(x, y)
	local matrixSizeX, matrixSizeY = fse.getCurrentMatrix():getSize()
	if x < 1 or y < 1 or x > matrixSizeX or y > matrixSizeY then
		return false
	end
	return fse.getNextMatrix().matrix[x][y]
end

function fse.setPressure(x, y, pressure)
	fse.getNextCell(x, y):setPressure(pressure)
end
function fse.getPressure(x, y, pressure)
	fse.getCurrentCell(x, y):setPressure(pressure)
end

return fse