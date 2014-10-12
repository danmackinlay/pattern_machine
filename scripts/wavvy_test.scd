p= Pspawner({|spawner|
		spawner.seq((degree: 5));
});
r=p.play;

p=PSWavvyseq.new(nBars:1,timePoints:[0.0, 1.0, 2.0, 3.0]);
p.pat.trace.play
