Phenosynth {
	/* This root class does nearly nothing at all, except  that I need somewhere to stash library-wide initialisation (since I can't rely on library wide initialisation to work since Startup.add never seems to get called for the internal server */
	*reInit{
		[PSMCCore, PSBasicPlaySynths, PSBasicJudgeSynths].do(
			{|class|
			 class.classInit;}
		);
	}
}