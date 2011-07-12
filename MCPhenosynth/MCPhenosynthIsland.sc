MCPhenosynthIsland : GAIsland {
	var evolvetask, postfx;
	
	*new { |genomeLength=40, server, target, addAction=\addToTail, 
						numinds=20, channels=2|
		// "groupsize" is not used by this class - all individuals play at once.
		// Hence the reworking of the constructor args.
		["groupsize", numinds, "genomeLength", genomeLength, "server", server, "target", target, "addAction", addAction, "numinds", numinds, "channels", channels].postln; 
		^super.new(numinds, genomeLength, server, target, addAction, numinds, channels:channels);
	}
	postinit {
		evolvetask = Task({
			loop({
				21.0.wait;
				this.cullAndMate;
				this.resetFitnesses;
				// Refresh the proxys where deaths-and-rebirths have occurred
				indproxys.do{|indproxy, index|
					if(inds[index].age==0, {
						indproxy.source_(this.class.phenomeToGraphFunc(inds[index].phenome));
						// Also reset the newbie fitnesses from the class default of zero
						inds[index].fitness = 1.0;
					});
				};
			});
		}, AppClock);
		{ |amp = 0.5|
			var son;
			son = In.ar(numChannels:channels) * amp * 0.7;
			son = LPF.ar(son, 4000);
			son = FreeVerb.ar(son);
			ReplaceOut.ar(0, son);
		}.play(server, addAction:\addToTail);
	}
	createJudgeSynth { |testbus, out, judgeindex|
		^Synth(\_ga_judge_targetpitch, //\_ga_judge_ampenv
						[	\testbus, testbus,
							\out, out,
							\targetpitch, 500
						], judgesgroup, \addToTail);
	}
	*yearLogFilePath {
		^"/Users/dan/supercollogs/_auto_logs_";
	}
	*individualClass {
		^MCPhenosynthIndividual;
	}
	*phenomeToGraphFunc{ |p, trig=1|
		// The phenome may be used in different
		// contexts, so the island here performs the standard final wrap-up.
		var textdef;
		textdef = "{|t_trig="++trig++"| "++p++"}";
		^textdef.interpret;
	}
	start {
		// Start the audio output and the evolutionary process
		this.resetFitnesses;
		indproxys.do{|indproxy, index|
			indproxy.fadeTime_(0.5).source_(
				this.class.phenomeToGraphFunc(inds[index].phenome)
			);
		};
		evolvetask.reset;
		evolvetask.start;
/*		volumestask.reset;
		volumestask.start;*/
	}
	resetFitnesses {
		inds.do{|ind| ind.fitness = 1.0};
	}
}
