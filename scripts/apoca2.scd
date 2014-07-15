(
~state=(
	lambda:2,
	quant:1/4,
	strength: 1,
);
~patt=Pbind(
	\delta, PexpR(Pfunc({~state.lambda})),
	\degree, Prand([0,3,5,7,10], inf),
	\strength, Pfunc({~state.strength})
);
)
~str=Pquantize(~patt, quant: Pfunc({~state.quant}), debug:true).trace.play;
~state.quant=1/16;
~state.lambda=4;
Pquantize(~patt, quant: 1/4, debug:true).quant;
~state.lambda=1/4;
PlazyEnvir
