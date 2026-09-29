local conf = {
	dtFixed = 1,
	
	squareScaleX = 7,
	squareScaleY = 75,
	squareGab = 1,
	
	pressureOverlayColorMult = .3,
	minPressureColorMult = .00000000001, --to prevent dividing my 0 if pressureColorMult should be 0 at some point.
	
	debug = {
		textRender = {
			quantity = true,
			velocities = true
		}
	},
	
	SIZE_CELL = .01,
	USE_PRECONDITIONED_DT = false,
}

return conf