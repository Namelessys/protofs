--LÖVE main file 
local version = "v0.0.3d"

function love.load(args)
	loadfile("data/init.lua")()

	return 0
end