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

	--placeholder vars wich get dynamically calculatet out of state values later on
	self.massPerQuantity = 100
	self.density = 1
	self.viscosity = 1
	
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
	
	local addedQuantity = 0
	
	for face = 1, FACE_COUNT do
		local cnc = currentNeighborCells[face]
		if not cnc then 
			nextCell:setFlowVelocity(face, 0)
		else
			--self:log("face: " .. face)
			
			local cncStaticForce = cnc:getStaticForce()
			local cncFlowForce = cnc:getFlowForce(getOpositeFace(face))
			
			local addedVelocity
			local newVelocity = self:getFlowVelocity(face)
			
			local totalForceDiff = (self:getStaticForce() + self:getFlowForce(face)) - (cncStaticForce + cncFlowForce)
			local staticForceDiff = self:getStaticForce() - cncStaticForce
			local flowForceDiff = self:getFlowForce(face) - cnc:getFlowForce(getOpositeFace(face))
			
			addedVelocity = staticForceDiff / (self:getMassPerQuantity() / FACE_COUNT)
			
			newVelocity = newVelocity + addedVelocity
			
			nextCell:setFlowVelocity(face, newVelocity)
			
			
			
			
			if self:getFlowVelocity(face) > 0 then
				local quantityDelta = self:getFlowVelocity(face) * (self:getQuantity() / FACE_COUNT)
				
				addedQuantity = addedQuantity - quantityDelta
				--[[
				if self:getQuantity() - quantityDelta < 0 then
					debug.warn("quantity would get negative on cell: " .. self.x .. ", quantity: " .. self:getQuantity())
					nextCell:setQuantity(0)	
				else
					nextCell:setQuantity(nextCell:getQuantity() - quantityDelta)
				end
				]]
			end
			
			if cnc:getFlowVelocity(getOpositeFace(face)) > 0 then
				local quantityDelta = cnc:getFlowVelocity(getOpositeFace(face)) * (cnc:getQuantity() / FACE_COUNT)

				addedQuantity = addedQuantity + quantityDelta
				--[[
				if cnc:getQuantity() - quantityDelta < 0 then
					debug.warn("quantity of neighbor cell would get negative: " .. self.x .. ", " .. cnc.x)
					nextCell:setQuantity(0)
				else
					self:log(self:getQuantity(), quantityDelta)
					nextCell:setQuantity(nextCell:getQuantity() + quantityDelta)
				end
				]]
			end
			
			
		end
	end
	
	--self:log(addedQuantity)
	
	if self:getQuantity() + addedQuantity < 0 then
		debug.warn("quantity would get negative on cell: " .. self.x .. ", quantity: " .. self:getQuantity())
		nextCell:setQuantity(0)	
	else
		nextCell:setQuantity(self:getQuantity() + addedQuantity)
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
			love.graphics.setColor({0, 0, 0, 1})
			love.graphics.print("Q " .. tostring(self:getQuantity()):sub(1, 5), renderPosX + scaleX / 10, renderPosY - 4 + scaleY / 10, 0, 1.3, 1.3)
		end
	end
	
	do --flow overlay
		if global.conf.debug.textRender.velocities then
			love.graphics.setColor({0, 0, 0, 1})
			love.graphics.print("V¹ " .. tostring(self:getFlowVelocity(1)):sub(1, 5), renderPosX + scaleX / 10, renderPosY + 15 + scaleY / 10, 0, 1.3, 1.3)
			love.graphics.print("V² " .. tostring(self:getFlowVelocity(2)):sub(1, 5), renderPosX + scaleX / 10, renderPosY + 30 + scaleY / 10, 0, 1.3, 1.3)
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


--===== state values =====--
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
	if self.x == 2 or self.x == 4 then
		debug.log(...)
	end
end


return FluidCell