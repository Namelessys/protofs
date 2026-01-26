--LÖVE main file 
local version = "v0.0.2d"



function love.load(args)
	loadfile("data/init.lua")()

	return 0
end