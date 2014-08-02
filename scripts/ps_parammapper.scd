/*
PSParammapper {
	metaparams = FloatArray.fill(7,0.5);
	params = FloatArray.fill(32,0.5);
	pitchrollyawaccel = FloatArray.fill(4,0.5);

	paramUpdaters = List.new;
		paramWatcher = Routine({|newinval|
		var lastposttime=0.0, delta=0.0;
		inf.do({|ix|
			state.paramDirty.if({
				state.paramDirty = false;
				(delta>10.0).if({
					[\wii_updating,state.metaparams, newinval, delta].postln;
					lastposttime = newinval;
				});
				state.params = state.paramMap.value(state.metaparams);
				state.paramUpdaters.do({|fn, i|
					fn.value(state.params[i]);
				});
			});
			newinval = 0.02.yield;
			delta = newinval-lastposttime;
		});
	}).play;
	CmdPeriod.doOnce { paramWatcher.free };

}
*/
~mapbulkPRNG={|x=0.1, nvals=10, abase=3.117111, astep=0.77733, cbase=0.23335, cstep=0.3347|
	var as=Array.series(n,abase,astep);
	var cs=Array.series(n,cbase,cstep);
	((x+cs)*as).fold(0.0,1.0);
};
~mapbulkPRNG.value(x=0.23,n=10);
~mapPRNGfactory={|abase=3.117111, astep=0.77733, cbase=0.23335, cstep=0.3347|
	Routine({|x=0.1|
		var a=abase;
		var c=cbase;
		inf.do({
			x = ((x+c)*a).fold(0.0,1.0).yield;
			a=a+astep;
			c=c+cstep;
		});
	});
};
~mapbulkPRNG=~mapPRNGfactory.value;
~mapbulkPRNG.value(x=0.23);
~mapbulkPRNG.reset;
~genMap={|prng, x, inDims|
	var coefs = inDims.collect({(prng.next(x)-0.5)*pi.atan});
	coefs = coefs - (coefs.mean);
	coefs = coefs / ((coefs**2).sum.sqrt);
	{|inVec|
		(inVec * coefs).sum;
	};
};
~genMap.value(~mapbulkPRNG,0.10,3).value([1,0,-1]);
