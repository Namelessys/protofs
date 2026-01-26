local main = {}
local love = love

global.tick = 0

function main.init()
	
end

function love.update(dt)
	if global.justInitialized then
		return 
	end
	global.tick = global.tick + 1
	
	if global.tick % 2 == 0 then
		--print("Tick:", global.tick)
	else
		--print("Tock:", global.tick)
	end
	
	global.game.update(dt)
	global.noname.update(dt)
	global.bladi.update(dt)
	if global.simulatePhysics then
		global.fse.update(dt)
	end
end

function love.draw()
	if global.justInitialized then
		global.justInitialized = false
		return 
	end
	
	global.renderer.preDraw()
	global.fse.draw(-50, -50, global.conf.squareScale, global.conf.squareGab)
	global.renderer.afterDraw()
	global.game.draw()
	global.noname.draw()
	global.bladi.draw()
end

return main