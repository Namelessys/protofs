--LÖVE main file 
local version = "v0.0.5d"

function love.load(args)
	loadfile("data/init.lua")()

	return 0
end