(
var patt, ps = PSProductionSystem(PostLogger.new, trace:true);
~clock=TempoClock.new(108/60);
ps.putOp(\doubleSpeed, Pop(\stretch, Affine1(1/2)));
ps.putOp(\halfSpeed, Pop(\stretch, Affine1(2)));
ps.putAtom(\tresillo, Pbind(\note, 0, \legato, 0.5, \dur, Pseq([3/4,3/4,2/4])));
ps.putAtom(\fourtothefloor, Pbind(\note, -17,  \sustain, 1, \dur, Pseq([1,1,1,1])));
ps.putAtom(\onebarrest, PoRest(4));
ps.putRule(\bar, PSBranch([\tresillo, \tresillo],[\fourtothefloor]), \onebarrest);
ps.putRule(\root, PSStarN(8, \bar));
patt = ps.root;
~steps = TestPS.expressPattern(patt);
~patt=patt;
~patt.play(~clock);
)
Pbind(\note, 1, \dur, Pseq([3/4,3/4,2/4])).play(~clock);