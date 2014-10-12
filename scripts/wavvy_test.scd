p= Pspawner({|spawner|
		spawner.seq((degree: 5));
});
r=p.play;

p=PSWavvyseq.new(nBars:1,timePoints:[0.0, 0.3, 0.9,3.5]);
p.pat.trace.play