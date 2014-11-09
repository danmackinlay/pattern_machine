//short lived patterns that I like

//Manufacture short toy FSMs
//should length be preordained, or geometric?
//should it be one machine per dimension, or just n random vectors?
PSPseudoAutomata {
	*new {
		arg ndims, nstates, surprisal, length, seed;
		var stateArrays = Array.new;
		//Do stuff
		
	}
	
}
//turns some metaparams into a larger number of event lookup params, possibly by random copulae,
// or random convex combinations
// Side queston: what are the distributions of random simplicial combinations? or even random general convex combinations?
PSMetaparamCombine {
	*new {
		arg ndimsin, ndimsout, seed;
		var coefs;
		//Do stuff
		
	}
}
//map these lookup params into real event values
//it would be nice if they were pure vector patterns until this point
PSMetaparamEvent {
	*new {
		arg map, seed;
		//Do stuff
		
	}
}