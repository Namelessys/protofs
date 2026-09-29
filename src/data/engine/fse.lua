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

function fse.currentMatrixGet()
	return fse.matrices[fse.currentMatrix]
end
function fse.nextMatrixGet()
	return fse.matrices[fse.nextMatrix]
end
function fse.currentCellGet(x, y)
	local matrixSizeX, matrixSizeY = fse.currentMatrixGet():sizeGet()
	if x < 1 or y < 1 or x > matrixSizeX or y > matrixSizeY then
		return false
	end
	return fse.currentMatrixGet().matrix[x][y]
end
function fse.nextCellGet(x, y)
	local matrixSizeX, matrixSizeY = fse.currentMatrixGet():sizeGet()
	if x < 1 or y < 1 or x > matrixSizeX or y > matrixSizeY then
		return false
	end
	return fse.nextMatrixGet().matrix[x][y]
end

function fse.pressureSet(x, y, pressure)
	fse.nextCellGet(x, y):pressureSet(pressure)
end
function fse.pressureGet(x, y, pressure)
	fse.currentCellGet(x, y):pressureSet(pressure)
end

return fse