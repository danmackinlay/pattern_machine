//Check basic convergence on a toy problem
(
	~island = PSIsland.new((\initialChromosomeSize: 4));
	~island.params;
	// Solve sin(3wx\pi/2) = cos(yz\pi)
	~island.scoreEvaluator = [\phenosynth, \score_evals, \trigonometry];
	~island.scoreCooker = [\phenosynth, \score_cookers, \zero_peak];
	~island.play;
	~island.population;
	~arbitrary = ~island.population.asArray[0];
	//~island.init;
	~island.rawScoreMap;
	~island.rawScoreMap[~arbitrary];
	~island.cookedFitnessMap[~arbitrary];
	~island.cookedFitnessMap.values;
	~arbitrary.chromosome;
	# a, b, c, d = ~arbitrary.chromosome;
	(a*b*pi).cos;
	(c*d*pi*3/2).sin;
)
//calculating the delay in a convolution of a given window size, using impulses.
/*
The answer turns out to be non-simple:
[ delay for, 64, is, 1 ]
[ delay for, 128, is, 65 ]
[ delay for, 256, is, 193 ]
[ delay for, 512, is, 448 ]
[ delay for, 1024, is, 468 ]
[ delay for, 2048, is, 1472 ]
[ delay for, 4096, is, 1537 ]
So - framesize-64 up to 512,  3/4 framesize-64 for 2048.
1024 and 4096 are just a mystery.
Convolution source inspection is probably necessary.
*/
Server.default = s = Dan.serverboot(\internal, \builtin);
(
fork {
	~size=4096;
	~rec = Buffer.alloc(s,~size,2);
	~localrec = nil;
	~indexbus=Bus.control(s,1);
	s.sync;
	6.for(12, {|b|
		~framesize = 2.pow(b);
		~tester = {|t_trig=0|
			var pre, observedsig, templatesig, convolved, gate;
			templatesig = DC.ar(1);
			t_trig = Trig1.ar(K2A.ar(t_trig), SampleDur.ir);
			gate = Trig1.ar(t_trig, BufDur.ir(~rec));
			pre = t_trig;
			convolved = Convolution.ar(templatesig, pre, framesize: ~framesize);
			BufWr.ar(
				inputArray: [pre, convolved],
				bufnum: ~rec,
				phase: Phasor.ar(
					trig: t_trig,
					rate: BufRateScale.kr(~rec),
					start: 0,
					end:BufFrames.kr(~rec)
				) * gate + gate -1,//hope this stops recording when gate is over
				loop:0
			);
			IndexInBetween.kr(~rec, in: 0.5);
		}.play(target: s, outbus:~indexbus);
		s.sync;
		~tester.set(\t_trig, 1);
		s.sync;
		~rec.loadToFloatArray(action: {|a|
			~localrec = a.reshape(~size,2);
			//~indexbus.get;
			~presig=Signal.newFrom(~localrec.slice(nil,0));
			~postsig=Signal.newFrom(~localrec.slice(nil,1));
			{~presig.plot(\pre);}.defer;
			{~postsig.plot(\post);}.defer;
			["delay for", ~framesize, "is", ~postsig.indexOfGreaterThan(0)].postln;
		});
		1.wait;
		~tester.free;
		s.sync;
	});
};
)
