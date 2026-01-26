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
	
	local totalQuantity = 0
	local totalEnergy = 0

	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			matrix[x][y]:update(dt, self)
			
			totalQuantity = totalQuantity + matrix[x][y]:getQuantity()
			totalEnergy = totalEnergy + matrix[x][y]:getPressure()
			for fv in ipairs(matrix[x][y]:getFlowVelocities()) do
				totalEnergy = totalEnergy + fv
			end
		end
	end
	
	debug.dlog("total: quantity: " .. tostring(totalQuantity) .. ", energy: " .. tostring(totalEnergy))
end

function FluidMatrix:draw(offsetX, offsetY, scaleX, scaleY, gab)
	local matrix = self.matrix

	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			matrix[x][y]:draw(x, y, offsetX, offsetY, scaleX, scaleY, gab)
		end
	end
end

function FluidMatrix:getSize()
	return self.sizeX, self.sizeY
end

return FluidMatrix