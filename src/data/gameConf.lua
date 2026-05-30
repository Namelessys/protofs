local conf = {
	squareScaleX = 75,
	squareScaleY = 75,
	squareGab = 5,
	
	pressureOverlayColorMult = .3,
	minPressureColorMult = .00000000001, --to prevent dividing my 0 if pressureColorMult should be 0 at some point.
	
	debug = {
		textRender = {
			quantity = true,
			velocities = true
		}
	}
}

return conf