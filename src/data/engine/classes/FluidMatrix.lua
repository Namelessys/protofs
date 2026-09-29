local FluidMatrix = {}

function FluidMatrix.new(sizeX, sizeY, FluidCell)
	local self = setmetatable({}, {__index = FluidMatrix})

	self.matrix = {}
	self.sizeX, self.sizeY = sizeX, sizeY

	for x = 1, sizeX do
		self.matrix[x] = {}
		for y = 1, sizeY do
			self.matrix[x][y] = FluidCell.new(x, y)
		end
	end

	return self
end

function FluidMatrix:update(dt)
	local matrix = self.matrix
	
	local totalQuantity, totalEnergy, totalStaticForce, totalTemperature = 0, 0, 0, 0
	
	local waveSpeedMax = 1
	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			if global.conf.USE_PRECONDITIONED_DT then
				local s = 0
				if matrix[x-1] and matrix[x-1][y] then
					s = rusanovFlux(matrix[x-1][y], matrix[x][y]).sMax
				else
					s = rusanovFlux(matrix[x][y], matrix[x][y], true, false).sMax
				end
				if matrix[x+1] and matrix[x+1][y] then
					s = rusanovFlux(matrix[x][y], matrix[x+1][y]).sMax
				else
					s = rusanovFlux(matrix[x][y], matrix[x][y], false, true).sMax
				end
				waveSpeedMax = math.max(waveSpeedMax, s)
			else
				waveSpeedMax = math.max(waveSpeedMax, matrix[x][y]:waveSpeedGet())
			end
		end
	end
	local SAFETY_FACTOR = .4
	local SIZE_CELL = global.conf.SIZE_CELL
	local dtSafe = SAFETY_FACTOR * SIZE_CELL / waveSpeedMax
	dt = math.min(dtSafe, dt)

	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			matrix[x][y]:update(dt, self)
			
			totalQuantity = totalQuantity + matrix[x][y]:densityGet()
			--totalStaticForce = totalStaticForce + matrix[x][y]:getStaticForce()
			
			totalTemperature = totalTemperature + matrix[x][y]:temperatureGet()
			--totalEnergy = totalEnergy + math.abs(matrix[x][y]:getFlowForce(1))
			--totalEnergy = totalEnergy + math.abs(matrix[x][y]:getFlowForce(2))
		end
	end
	
	--debug.dlog("total: quantity: " .. tostring(totalQuantity) .. ", staticForce: " .. tostring(totalStaticForce))
	--debug.dlog("total: temperature: " .. tostring(totalTemperature) .. ", energy: " .. tostring(totalEnergy))
end

function FluidMatrix:draw(offsetX, offsetY, scaleX, scaleY, gab)
	local matrix = self.matrix

	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			matrix[x][y]:draw(x, y, offsetX, offsetY, scaleX, scaleY, gab)
		end
	end
end

function FluidMatrix:sizeGet()
	return self.sizeX, self.sizeY
end

return FluidMatrix