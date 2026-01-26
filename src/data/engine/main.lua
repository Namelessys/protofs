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
	
	global.fse.update(dt)
end

function love.draw()
	if global.justInitialized then
		global.justInitialized = false
		return 
	end
	
	global.renderer.preDraw()
	global.fse.draw(0, 0, global.conf.squareScaleX, global.conf.squareScaleY, global.conf.squareGab)
	global.renderer.afterDraw()
	
	global.game.draw()
	global.noname.draw()
	global.bladi.draw()
end

return main