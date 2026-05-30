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
	
	self.size = 1

	--placeholder vars wich get dynamically calculatet out of state values later on
	self.massPerQuantity = 10
	self.density = 1
	self.viscosity = .1
	
	--state vars
	self.temperature = 0
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
	
	local addedQuantity = 0
	
	for face = 1, FACE_COUNT do
		local cnc = currentNeighborCells[face]
		if not cnc then 
			nextCell:setFlowVelocity(face, 0)
		else
			--self:log("face: " .. face)
			
			local addedVelocityForce, addedMomentum = 0, 0
			local momentumLoss, addedTempretature
			local newVelocity = self:getFlowVelocity(face)
			local newMomentum = self:getMomentum(face)
			
			local staticForceDiff = self:getStaticForce() - cnc:getStaticForce()
			local flowForceDiff = self:getFlowForce(face) - cnc:getFlowForce(getOpositeFace(face))
			local momentumDiff = self:getMomentum(face) - cnc:getMomentum(getOpositeFace(face))
			local velocityDiff = self:getFlowVelocity(face) - cnc:getFlowVelocity(getOpositeFace(face))
			
			--self:log(self:getMomentum(face), cnc:getMomentum(getOpositeFace(face)))
			
			local faceMass = self:getMass() / FACE_COUNT
			
			if faceMass <= 0 or staticForceDiff <= 0 then
				--addedMomentum = 0
			else
				--addedMomentum = staticForceDiff / faceMass
			end
			--newVelocity = newVelocity + addedMomentum
			
			
			
			local viscosityFactor = 1 --= self:getViscosity() * velocityDiff
			
			self:log(velocityDiff, viscosityFactor)
			
			
			addedMomentum = addedMomentum - self:getMomentum(face) / (2 * viscosityFactor)
			addedMomentum = addedMomentum - cnc:getMomentum(getOpositeFace(face)) / (2 * viscosityFactor)
			newMomentum = newMomentum + addedMomentum
			
			self:log(addedMomentum, newMomentum)
			
			
			
			
			
			if self:getFlowVelocity(face) > 0 then
				local quantityDelta = self:getFlowVelocity(face) * (self:getQuantity() / FACE_COUNT)
				
				addedQuantity = addedQuantity - quantityDelta
			end
			
			if cnc:getFlowVelocity(getOpositeFace(face)) > 0 then
				local quantityDelta = cnc:getFlowVelocity(getOpositeFace(face)) * (cnc:getQuantity() / FACE_COUNT)

				addedQuantity = addedQuantity + quantityDelta
			end
			
			
			newVelocity = newVelocity + newMomentum / (self:getMass() / FACE_COUNT)
			
			--newVelocity = newVelocity + addedVelocity
			nextCell:setFlowVelocity(face, newVelocity)
			
		end
	end
	
	if self:getQuantity() + addedQuantity < 0 then
		debug.warn("quantity would get negative on cell: " .. self.x .. ", quantity: " .. self:getQuantity() + addedQuantity)
		nextCell:setQuantity(0)	
		nextCell:setTemperature(0)
	else
		nextCell:setQuantity(self:getQuantity() + addedQuantity)
		nextCell:setTemperature(self:getTemperature() - addedQuantity)
	end
	
	
	--self:log(self:getFlowVelocity(1))
end

function FluidCell:draw(posX, posY, offsetX, offsetY, scaleX, scaleY, gab)
	local renderPosX = posX * scaleX + gab * posX + offsetX
	local renderPosY = posY * scaleY + gab * posY + offsetY
	
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
			scaleX, 
			scaleY
		)
		
		if global.conf.debug.textRender.quantity then
			local renderPosY = renderPosY + 75
			
			love.graphics.setColor({0, 0, 0, 1})
			love.graphics.print("Q " .. tostring(self:getQuantity()):sub(1, 5), renderPosX + scaleX / 10, renderPosY - 4 + scaleY / 10, 0, 1.3, 1.3)
		end
	end
	
	do --flow overlay
		if global.conf.debug.textRender.velocities then
			local renderPosY = renderPosY + 75
			
			love.graphics.setColor({0, 0, 0, 1})
			love.graphics.print("V¹ " .. tostring(self:getFlowVelocity(1)):sub(1, 5), renderPosX + scaleX / 10, renderPosY + 15 + scaleY / 10, 0, 1.3, 1.3)
			love.graphics.print("V² " .. tostring(self:getFlowVelocity(2)):sub(1, 5), renderPosX + scaleX / 10, renderPosY + 30 + scaleY / 10, 0, 1.3, 1.3)
			
			love.graphics.print("M¹ " .. tostring(self:getMomentum(1)):sub(1, 5), renderPosX + scaleX / 10, renderPosY + 45 + scaleY / 10, 0, 1.3, 1.3)
			love.graphics.print("M² " .. tostring(self:getMomentum(2)):sub(1, 5), renderPosX + scaleX / 10, renderPosY + 60 + scaleY / 10, 0, 1.3, 1.3)
		end
	end
end

--===== dynamicaly generatet values =====--
function FluidCell:setMassPerQuantity(mass)
	self.massPerQuantity = mass
end
function FluidCell:getMassPerQuantity()
	return self.massPerQuantity
end
function FluidCell:setDensity(density)
	self.density = density
end
function FluidCell:getDensity()
	return self.density
end
function FluidCell:setViscosity(viscosity)
	self.viscosity = viscosity
end
function FluidCell:getViscosity()
	return self.viscosity
end

function FluidCell:getPressure()
	return self:getQuantity() / self:getDensity()
end
function FluidCell:getMass()
	return self:getQuantity() * self:getMassPerQuantity()
end

function FluidCell:getStaticForce(face)
	return self:getPressure()
end
function FluidCell:getFlowForce(face)
	return .5 * (self:getFlowVelocity(face) ^ 2) * (self:getMass() / FACE_COUNT )
end
function FluidCell:getMomentum(face)
	return self:getFlowVelocity(face) * (self:getMass() / FACE_COUNT)
end


--===== state values =====--
function FluidCell:setSize(size)
	self.size = size
end
function FluidCell:getSize()
	return self.size
end
function FluidCell:setQuantity(quantity)
	self.quantity = quantity
end
function FluidCell:getQuantity()
	return self.quantity
end
function FluidCell:setFlowVelocity(face, velocities)
	self.flowVelocities[face] = velocities
end
function FluidCell:getFlowVelocity(face)
	return self.flowVelocities[face]
end
function FluidCell:setFlowVelocities(velocities)
	self.flowVelocities = velocities
end
function FluidCell:getFlowVelocities()
	return self.flowVelocities
end

function FluidCell:setTemperature(temperature)
	self.temperature = temperature
end
function FluidCell:getTemperature()
	return self.temperature
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
	if self.x == 1 or self.x == 2 then
		debug.log(...)
	end
end


return FluidCell