PSSynth {
	var <pstrip;
	
	//must be called by pstrip
	initPSSynth {arg str;
		pstrip=str;
		this.setup;
	}

	//override in subclasses
	setup {
	
	}
	
	free {
	
	}

}