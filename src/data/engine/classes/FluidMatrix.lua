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

	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			matrix[x][y]:update(dt, self)
		end
	end
end

function FluidMatrix:draw(offsetX, offsetY, scale, gab)
	local matrix = self.matrix

	for x = 1, self.sizeX do
		for y = 1, self.sizeY do
			matrix[x][y]:draw(x, y, offsetX, offsetY, scale, gab)
		end
	end
end

function FluidMatrix:getSize()
	return self.sizeX, self.sizeY
end

return FluidMatrix