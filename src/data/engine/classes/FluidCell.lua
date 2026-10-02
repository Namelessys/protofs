-- FluidCell.lua — 1D density-based CFD cell (Rusanov flux, mirrored-wall boundaries)
-- Love2D cell framework integration.

local FluidCell = {}

local SIZE_CELL = global.conf.SIZE_CELL
local FACES = 2
local DEPTH = 1

local UNIVERSAL_GAS_CONSTANT = 8.31446261815324

local MOLAR_MASS = 0.02897 -- average of dry air
local R_GAS = UNIVERSAL_GAS_CONSTANT / MOLAR_MASS
local GAMMA = 1.4
local CV = R_GAS / (GAMMA - 1)   -- ≈ 718 J/(kg·K)

local RHO_FLOOR        = 1e-8    -- getter floor
local RHO_FLOOR_UPDATE = 1e-6    -- update floor
local T_MIN = 1.0                -- K, floor for pathological states
local T_MAX = 1e4                -- K, cap for pathological states

local DEBUG = false   -- set true to re-enable the per-call prints

local max = math.max
local min = math.min
local sqrt = math.sqrt
local abs = math.abs

local function getOpositeFace(face)
	if face == 1 then
		return 2
	elseif face == 2 then
		return 1
	end
end

--====================================================================
-- construction
--====================================================================

function FluidCell.new(x, y)
	local self = setmetatable({}, {__index = FluidCell})

	--===== debug =====--
	_G.protofs.debugInfo.cellCount = _G.protofs.debugInfo.cellCount + 1
	self.id = _G.protofs.debugInfo.cellCount
	self.color = {0, .3, .6}

	--===== metadata =====--
	self.x = x
	self.y = y
	self.size = 1

	--===== dynamic vars (conserved state) =====--
	local T_INIT = 293.0
	self.density = 1.1
	self.momentum = 0
	-- self-consistent start: E = rho*cv*T  (NOT 0, NOT .1)
	self.energyTotal = self.density * CV * T_INIT

	self.lastForceTimestamp = love.timer.getTime()

	--===== debug vars =====--
	self.changeSteps = .01

	return self
end

--====================================================================
-- rusanovFlux: one flux per face
-- mirrorL / mirrorR: ghost wall on the left / right side
--   (mirrorL flips the LEFT state — for a LEFT wall;
--    mirrorR flips the RIGHT state — for a RIGHT wall)
--====================================================================

function rusanovFlux(cellL, cellR)

	-- 1. conserved state
	local rhoL  = cellL:densityGet()
	local rhoR  = cellR:densityGet()
	local rhouL = cellL:momentumGet()
	local rhouR = cellR:momentumGet()
	local EL    = cellL:energyTotalGet()
	local ER    = cellR:energyTotalGet()

	-- 2. primitive + thermodynamic state (derived)
	local uL = rhouL / max(rhoL, RHO_FLOOR)
	local uR = rhouR / max(rhoR, RHO_FLOOR)
	local pL = cellL:pressureStaticGet()
	local pR = cellR:pressureStaticGet()
	local cL = cellL:soundSpeedGet()
	local cR = cellR:soundSpeedGet()

	-- 3. largest signal speed: max(|u| + c) of both sides
	local s_max
	if global.conf.USE_PRECONDITIONED_DT then
		local machL = abs(uL) / max(cL, 1e-6)
		local machR = abs(uR) / max(cR, 1e-6)
		local machFace = max(machL, machR)
		
		-- effective speed: blend c -> |u| as Ma -> 0
		local cEffFloor = 0.02 * max(cL, cR)   -- keep ≥ 2% of real sound speed
		local cEffL = max(cL * machFace / (1 + machFace), cEffFloor)
		local cEffR = max(cR * machFace / (1 + machFace), cEffFloor)
		
		s_max = max(abs(uL) + cEffL, abs(uR) + cEffR)
	else
		s_max = max(abs(uL) + cL, abs(uR) + cR)
	end
	
	
	-- 4. physical fluxes
	local FL_rho  = rhoL  * uL
	local FL_mom  = rhouL * uL + pL
	local FL_engy = uL * (EL + pL)

	local FR_rho  = rhoR  * uR
	local FR_mom  = rhouR * uR + pR
	local FR_engy = uR * (ER + pR)

	if DEBUG then
		print("rho", rhoL, rhoR)
		print("rhou", rhouL, rhouR)
		print("u", uL, uR)
		print("p", pL, pR)
		print("smax", s_max)
		print("F_rho", FL_rho, FR_rho)
		print("F_mom", FL_mom, FR_mom)
	end

	-- 5. Rusanov: average minus dissipation, per component
	local flux = {}
	flux.rho    = 0.5 * (FL_rho  + FR_rho)  - 0.5 * s_max * (rhoR  - rhoL)
	flux.mom    = 0.5 * (FL_mom  + FR_mom)  - 0.5 * s_max * (rhouR - rhouL)
	flux.energy = 0.5 * (FL_engy + FR_engy) - 0.5 * s_max * (ER     - EL)
	flux.sMax = s_max
		
	return flux
end

--====================================================================
-- update (per cell; reads current state, writes next state)
--====================================================================

function FluidCell:update(dt)
	local nextCell = global.fse.nextCellGet(self.x, self.y)

	local nL = global.fse.currentCellGet(self.x - 1, self.y)
	local nR = global.fse.currentCellGet(self.x + 1, self.y)

	local fluxLeft, fluxRight

	if nL then
		fluxLeft = rusanovFlux(nL, self)
	else
		fluxLeft = {
			rho = 0,
			mom = self:pressureStaticGet(),
			energy = 0,
			sMax = self:waveSpeedGet()
		}
	end

	if nR then
		fluxRight = rusanovFlux(self, nR)
	else
		fluxRight = {
			rho = 0,
			mom = self:pressureStaticGet(),
			energy = 0,
			sMax = self:waveSpeedGet()
		}
	end

	-- conserved update: gains (left face) minus losses (right face)
	local dtdx = dt / SIZE_CELL

	nextCell.momentum = self.momentum - dtdx * (fluxRight.mom - fluxLeft.mom)
	nextCell.density = max(
		self.density - dtdx * (fluxRight.rho - fluxLeft.rho),
		RHO_FLOOR_UPDATE
	)
	nextCell.energyTotal = self.energyTotal - dtdx * (fluxRight.energy - fluxLeft.energy)
end

--====================================================================
-- state values / setters
--====================================================================

function FluidCell:stateGet()
	return {
		momentum = self.momentum,
		energyTotal = self.energyTotal,
		density = self.density
	}
end

function FluidCell:momentumGet()
	return self.momentum
end

function FluidCell:energyTotalGet()
	return self.energyTotal
end

function FluidCell:densityGet()
	return max(self.density, RHO_FLOOR)
end

function FluidCell:densitySet(newDensity)
	newDensity = max(newDensity, RHO_FLOOR_UPDATE)

	local rhoOld = self.density
	local rhou   = self.momentum

	-- specific internal energy per kg: e = (E - K_old) / rho_old
	local eInt = (self.energyTotal - (rhou * rhou) / (2 * max(rhoOld, RHO_FLOOR)))
	             / max(rhoOld, RHO_FLOOR)

	self.density = newDensity

	-- rebuild energy with the NEW density:
	-- kinetic from conserved momentum, internal from preserved e
	local K_new = (rhou * rhou) / (2 * newDensity)
	self.energyTotal = eInt * newDensity + K_new
end

-- atomic, self-consistent initialization (rho, T, u together)
function FluidCell:initState(rho, T, u)
	self.density  = max(rho, RHO_FLOOR_UPDATE)
	self.momentum = (u or 0) * self.density
	self.energyTotal = self.density * CV * T
	   + (self.momentum * self.momentum) / (2 * self.density)
end

--====================================================================
-- derived values
--====================================================================

function FluidCell:kineticFromMomentum()
	-- K = (rhou)^2 / (2*rho), guarded
	local rho = self:densityGet()
	local rhou = self:momentumGet()
	return (rhou * rhou) / (2 * rho)
end

function FluidCell:velocityGet()
	return self:momentumGet() / self:densityGet()
end

function FluidCell:temperatureGet()
	-- e (per kg) = (E - K) / rho;  T = e / cv
	local e = (self:energyTotalGet() - self:kineticFromMomentum()) / self:densityGet()
	local T = e / CV
	if T ~= T then return T_MIN end          -- NaN guard
	return min(max(T, T_MIN), T_MAX)
end

function FluidCell:pressureStaticGet()
	-- EOS: p = (gamma - 1) * (E - K)   [both per volume]
	return (GAMMA - 1) * (self:energyTotalGet() - self:kineticFromMomentum())
end

function FluidCell:pressureDynamicGet(face)
	local velocity = self:velocityGet()
	if face == 1 then
		return -(0.5 * self:densityGet() * velocity * velocity)
	elseif face == 2 then
		return 0.5 * self:densityGet() * velocity * velocity
	end
end

function FluidCell:soundSpeedGet()
	return sqrt(GAMMA * R_GAS * self:temperatureGet())
end

function FluidCell:waveSpeedGet()
	return abs(self:velocityGet()) + self:soundSpeedGet()
end

function FluidCell:volumeGet()
	return self.size * DEPTH / FACES
end

--====================================================================
-- draw (unchanged except floor-consistent getters)
--====================================================================

function FluidCell:draw(posX, posY, offsetX, offsetY, scaleX, scaleY, gab)
	local renderPosX = posX * scaleX + gab * posX + offsetX
	local renderPosY = posY * scaleY + gab * posY + offsetY

	do --pressure overlay
		local colorMult = global.conf.pressureOverlayColorMult
		local rho = self:densityGet()   -- floored: never < 0, never == 0
		
		self.color = {min(rho * colorMult, 1), 0, 1 - min(rho * colorMult, 1), 1}

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
			--love.graphics.print("M " .. tostring(rho):sub(1, 5), renderPosX + scaleX / 10, renderPosY - 4 + scaleY / 10, 0, 1.3, 1.3)
		end
	end

	do --flow overlay
		if global.conf.debug.textRender.velocities then
			local colorMult = global.conf.velocityOverlayColorMult
			
			local uh = self:velocityGet() 
			if uh < 0 then
				self.color = {min(math.abs(uh) * colorMult, 1), 0, 0, 1}
			else
				self.color = {0, min(uh* colorMult, 1), 0, 1}
			end

			love.graphics.setColor(self.color)
			love.graphics.rectangle("fill",
				renderPosX,
				renderPosY + scaleY + gab,
				scaleX,
				scaleY
			)	
			

			love.graphics.setColor({0, 0, 0, 1})
			--love.graphics.print("V¹ " .. tostring(self:velocityGet()), renderPosX + scaleX / 10, renderPosY + 15 + scaleY / 10, 0, 1.3, 1.3)
		end
	end
end

--====================================================================
-- debug
--====================================================================

function FluidCell:debugSet(active)
	self.debug = active
end

function FluidCell:debugGet()
	return self.debug
end

function FluidCell:log(...)
	global.debug.setFuncPrefix("[Cell_" .. self.x .. "]")
	if self.x == 1 or self.x == 2 then
		debug.log(...)
	end
end

return FluidCell
