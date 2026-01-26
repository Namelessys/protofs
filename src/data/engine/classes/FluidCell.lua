local FluidCell = {}

local FACE_SIZE = 1
local FACE_COUNT = 2

local max = math.max
local min = math.min

local function getOpositeFace(face)
	if face == 1 then
		return 2
	elseif face == 2 then
		return 1
	end
end

function FluidCell.new(x, y)
	local self = setmetatable({}, {__index = FluidCell})

	_G.protofs.debugInfo.cellCount = _G.protofs.debugInfo.cellCount +1
	self.id = _G.protofs.debugInfo.cellCount
	self.color = {0, .3, .6}
	
	self.x = x
	self.y = y

	--those vars are getting dynamically generatet by the state of the cell later on
	self.mass = 100
	self.density = 1
	self.fluidity = .9
	
	--state vars
	self.temperature = 100
	self.quantity = 0
	
	self.flowVelocities = {}
	for i = 1, 2 do
		self.flowVelocities[i] = 0
	end
	
	
	self.lastForceTimestamp = love.timer.getTime()
	
	
	--debug vars
	self.changeSteps = .01

	return self
end

function FluidCell:update(dt, matrix)
	--print("fluidCell" .. tostring(self.id) .. ": update")
	
	local nextCell = global.fse.getNextCell(self.x, self.y)
	
	local currentNeighborCells = {}
	local nextNeighborCells = {}
	
	local flowForceDifferences = {}
	
	
	currentNeighborCells[1] = global.fse.getCurrentCell(self.x - 1, self.y)
	currentNeighborCells[2] = global.fse.getCurrentCell(self.x + 1, self.y)
	
	nextNeighborCells[1] = global.fse.getNextCell(self.x - 1, self.y)
	nextNeighborCells[2] = global.fse.getNextCell(self.x + 1, self.y)
	
	for face = 1, FACE_COUNT do
		local cnc = currentNeighborCells[face]
		if not cnc then break end
		
		local cncStaticForce = cnc:getStaticForce()
		local cncFlowForce = cnc:getFlowForce(getOpositeFace(face))
		
		local totalForceDiff = (self:getStaticForce() + self:getFlowForce(face)) - (cncStaticForce + cncFlowForce)
		
		nextCell:setFlowVelocitiy(face, totalForceDiff / (self:getMass() / FACE_COUNT))
		
		
		
		
	end
	
	
	self:log(self:getFlowVelocity(1))
end

function FluidCell:draw(posX, posY, offsetX, offsetY, scale, gab)
	local renderPosX = posX * scale + gab * posX + offsetX
	local renderPosY = posY * scale + gab * posY + offsetY
	
	do --pressure overlay
		local colorMult = math.max(global.conf.pressureOverlayColorMult, global.conf.pressureOverlayColorMult)
		if self:getQuantity() < 0 then
			self.color = {0, 0, 0, 1}
		elseif self:getQuantity() == 0 then
			self.color = {1, 1, 1, 1}
		elseif self:getQuantity() <= math.huge / colorMult then
			self.color = {self:getQuantity() * colorMult, 0, 1 - self:getQuantity() * colorMult, 1}
		else
			--self.color = {1, 2 - (self:getQuantity() * 2 - .1 / colorMult) * colorMult, 0}
		end
		
		love.graphics.setColor(self.color)
		love.graphics.rectangle("fill", 
			renderPosX, 
			renderPosY,
			scale, 
			scale
		)
		
		love.graphics.setColor({0, 0, 0, 1})
		love.graphics.print("Q " .. tostring(self:getQuantity()):sub(1, 5), renderPosX + scale / 10, renderPosY - 4 + scale / 10, 0, 1.3, 1.3)
	end
	
	do --flow overlay
		love.graphics.setColor({0, 0, 0, 1})
		love.graphics.print("V¹ " .. tostring(self:getFlowVelocity(1)):sub(1, 5), renderPosX + scale / 10, renderPosY + 15 + scale / 10, 0, 1.3, 1.3)
		love.graphics.print("V² " .. tostring(self:getFlowVelocity(2)):sub(1, 5), renderPosX + scale / 10, renderPosY + 30 + scale / 10, 0, 1.3, 1.3)
	end
end

--===== dynamicaly generatet values =====--
function FluidCell:setMass(value)
	self.mass = value
end
function FluidCell:getMass()
	return self.mass
end
function FluidCell:setDensity(density)
	self.density = density
end
function FluidCell:getDensity()
	return self.density
end

function FluidCell:getPressure()
	return self:getQuantity() / self:getDensity()
end

--===== state values =====--
function FluidCell:setQuantity(quantity)
	self.quantity = quantity
end
function FluidCell:getQuantity()
	return self.quantity
end

function FluidCell:setFlowVelocitiy(face, velocities)
	self.flowVelocities[face] = velocities
end
function FluidCell:getFlowVelocity(face)
	return self.flowVelocities[face]
end

function FluidCell:getStaticForce(face)
	return self:getPressure()
end

function FluidCell:getFlowForce(face)
	return self:getQuantity() / FACE_COUNT * self:getMass() * self:getFlowVelocity(face)
end

--===== debug =====--
function FluidCell:setDebug(active)
	self.debug = active
end
function FluidCell:getDebug()
	return self.debug
end

function FluidCell:log(...)
	global.debug.setFuncPrefix("[Cell_" .. self.x .. "]")
	if self.x == 3 then
		debug.log(...)
	end
end


return FluidCell