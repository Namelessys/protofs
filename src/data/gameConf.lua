local conf = {
	squareScaleX = 10,
	squareScaleY = 175,
	squareGab = 1,
	
	pressureOverlayColorMult = .3,
	minPressureColorMult = .00000000001, --to prevent dividing my 0 if pressureColorMult should be 0 at some point.
	
	debug = {
		textRender = {
			quantity = false,
			velocities = false
		}
	}
}

return conf