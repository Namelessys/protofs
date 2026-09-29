local FluidCell = {}

local FACE_SIZE = 1

local function getOpositeSide(side)
	side = side + 4
	if side > 8 then
		side = side - 8
	end
	return side
end

function FluidCell.new(x, y)
	local self = setmetatable({}, {__index = FluidCell})

	_G.protofs.debugInfo.cellCount = _G.protofs.debugInfo.cellCount +1
	self.id = _G.protofs.debugInfo.cellCount
	self.color = {0, .3, .6}
	
	self.x = x
	self.y = y
	
	self.pressure = 0
	self.mass = 0
	
	self.density = 1
	self.fluidity = .9
	self.weight = 10
	
	self.flowForces = {}
	self.flowVelocities = {}
	for i = 1, 8 do
		self.flowForces[i] = 0
		self.flowVelocities[i] = 0
	end
	--self.totalFlowForceDifference = 0
	self.totalVelocityFactor = 0
	
	self.lastForceTimestamp = love.timer.getTime()
	

	return self
end

function FluidCell:update(dt, matrix)
	--print("fluidCell" .. tostring(self.id) .. ": update")
	
	local nextCell = global.fse.nextCellGet(self.x, self.y)
	
	local currentNeighborCells = {}
	local nextNeighborCells = {}
	
	local flowForceDifferences = {}
	
	
	
	currentNeighborCells[1] = global.fse.currentCellGet(self.x - 1, self.y - 1)
	currentNeighborCells[2] = global.fse.currentCellGet(self.x, self.y - 1)
	currentNeighborCells[3] = global.fse.currentCellGet(self.x + 1, self.y - 1)
	currentNeighborCells[4] = global.fse.currentCellGet(self.x + 1, self.y)
	currentNeighborCells[5] = global.fse.currentCellGet(self.x + 1, self.y + 1)
	currentNeighborCells[6] = global.fse.currentCellGet(self.x, self.y + 1)
	currentNeighborCells[7] = global.fse.currentCellGet(self.x - 1, self.y + 1)
	currentNeighborCells[8] = global.fse.currentCellGet(self.x - 1, self.y)
	
	nextNeighborCells[1] = global.fse.nextCellGet(self.x - 1, self.y - 1)
	nextNeighborCells[2] = global.fse.nextCellGet(self.x, self.y - 1)
	nextNeighborCells[3] = global.fse.nextCellGet(self.x + 1, self.y - 1)
	nextNeighborCells[4] = global.fse.nextCellGet(self.x + 1, self.y)
	nextNeighborCells[5] = global.fse.nextCellGet(self.x + 1, self.y + 1)
	nextNeighborCells[6] = global.fse.nextCellGet(self.x, self.y + 1)
	nextNeighborCells[7] = global.fse.nextCellGet(self.x - 1, self.y + 1)
	nextNeighborCells[8] = global.fse.nextCellGet(self.x - 1, self.y)
	
	
	
	--collect flow force differences
	local totalFlowForceDifference = 0
	local totalFlowForceFactor = 0
	for i = 1, 8 do
		if currentNeighborCells[i] then
			flowForceDifferences[i] = self:getFlowForce(i) - currentNeighborCells[i]:getFlowForce(getOpositeSide(i))
		else
			flowForceDifferences[i] = 0
		end
		totalFlowForceDifference = totalFlowForceDifference + flowForceDifferences[i]
	end
	totalFlowForceFactor = 1 / totalFlowForceDifference
	
	
	--process flow velocities
	--process mass
	nextCell.mass = self.mass
	for i = 1, 8 do
		if currentNeighborCells[i] then
			if flowForceDifferences[i] > 0 or true then
				local acceleration = flowForceDifferences[i] * (1 / self.weight)
				local massDelta = 0
				
				nextCell.flowVelocities[i] = (self.flowVelocities[i] + acceleration) * self.fluidity
				
				massDelta = self.flowVelocities[i] * self.density * FACE_SIZE
				nextCell.mass = nextCell.mass - massDelta * self.totalVelocityFactor
			else
				
			end
		end
	end
	
	self:log("Mass: " .. self.mass)
	
	
	
	--process pressure
	--process flow forces
	local velocitySum = 0
	for i = 1, 8 do
		velocitySum = velocitySum + nextCell.flowVelocities[i]
		nextCell.pressure = nextCell.mass
		
		nextCell.flowForces[i] = nextCell:pressureGet() + nextCell.flowVelocities[i] * self.weight
		
		self:log("Flow force difference: " .. flowForceDifferences[i])
		self:log("Flow force: " .. self.flowForces[i])
		self:log("Flow velocity: " .. self.flowVelocities[i])
	end
	nextCell.totalVelocityFactor = velocitySum / 8
	
	
	
	if self.mass < 0 then
		debug.warn("Mass below 0 on cell: " .. self.x .. ", " .. self.y)
	end
	
	
	--[[
	-- gravity
	if self.y < 10 and self:pressureGet() > 0 then 
		local otherCell = global.fse.matrices[global.fse.nextMatrix].matrix[self.x][self.y + 1]
		local flowRate = .01
		
		otherCell:pressureSet(otherCell:pressureGet() + math.min(self:pressureGet(), flowRate))
		self:pressureSet(math.max(self:pressureGet() - flowRate, 0))
	end
	
	
	
	
	-- spread (lulz)
	if self.y == 11 and false then 
		local leftCell
		local rightCell
		
		if global.fse.matrices[global.fse.nextMatrix].matrix[self.x - 1] ~= nil then
			leftCell = global.fse.matrices[global.fse.nextMatrix].matrix[self.x - 1][self.y]
		end
		if global.fse.matrices[global.fse.nextMatrix].matrix[self.x + 1] ~= nil then
			rightCell = global.fse.matrices[global.fse.nextMatrix].matrix[self.x + 1][self.y]
		end
		
		if leftCell ~= nil and self:pressureGet() > leftCell:pressureGet() then
			local diff = self:pressureGet() - leftCell:pressureGet()
			leftCell:pressureSet(leftCell:pressureGet() + diff / 2)
			self:pressureSet(self:pressureGet() - diff / 2)
		end
		if rightCell ~= nil and self:pressureGet() > rightCell:pressureGet() then
			local diff = self:pressureGet() - rightCell:pressureGet()
			rightCell:pressureSet(rightCell:pressureGet() + diff / 2)
			self:pressureSet(self:pressureGet() - diff / 2)
		end
			
	end
	]]
end

function FluidCell:draw(posX, posY, offsetX, offsetY, scale, gab)
	local renderPosX = posX * scale + gab * posX + offsetX
	local renderPosY = posY * scale + gab * posY + offsetY
	
	do --pressure overlay
		local colorMult = math.max(global.conf.pressureOverlayColorMult, global.conf.pressureOverlayColorMult)
		if self:pressureGet() == 0 then
			self.color = {1, 1, 1, 0}
		elseif self:pressureGet() <= 0.5 / colorMult then
			self.color = {self:pressureGet() * 2 * colorMult, 1, 0}
		else
			self.color = {1, 2 - (self:pressureGet() * 2 - .1 / colorMult) * colorMult, 0}
		end
	end
	
	love.graphics.setColor(self.color)
	love.graphics.rectangle("fill", 
		renderPosX, 
		renderPosY,
		scale, 
		scale
	)
end

function FluidCell:getMass()
	return self.mass
end
function FluidCell:setMass(value)
	self.mass = value
end
function FluidCell:pressureGet()
	return self.pressure
end
function FluidCell:pressureSet(value)
	self.pressure = value
end

function FluidCell:setVelocity(newVelocity)
	self.velocity = newVelocity
end

function FluidCell:getFlowForce(side)
	return self.flowForces[side]
end
function FluidCell:setFlowForce(side, force)
	self.flowForces[side] = force
end

function FluidCell:debugGet()
	return self.debug
end
function FluidCell:debugSet(active)
	self.debug = active
end

function FluidCell:log(...)
	if self.debug then
		debug.log(...)
	end
end


return FluidCell