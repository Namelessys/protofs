local input = {
	pressedKeys = {},
	releasedKeys = {}
}

function input.keyPressed(key)
	if input.pressedKeys[key] then
		return true
	else
		return false
	end
end
function input.keyDown(key)
	if input.pressedKeys[key] == global.tick then
		return true
	else
		return false
	end
end
function input.keyUp(key)
	if input.releasedKeys[key] == global.tick then
		return true
	else
		return false
	end
end

function love.keypressed(key, scancode, isrepeat)
	input.pressedKeys[key] = global.tick + 1
end
function love.keyreleased(key, scancode, isrepeat)
	input.pressedKeys[key] = nil
	input.releasedKeys[key] = global.tick + 1
end

return input