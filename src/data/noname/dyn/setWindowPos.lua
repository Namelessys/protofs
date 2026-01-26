local conf = {
	displayServer = "wayland",
}

return function()
	debug.setFuncPrefix("[setWindowPos]")
	debug.log("Set pos")

	if conf.displayServer == "wayland" then
		os.execute([[
		swaymsg split v
		swaymsg resize set height 40
		swaymsg focus up
		]])
	end
end