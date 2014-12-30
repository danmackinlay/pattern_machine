~state = (a:1);
~str =Pbind(\delta, PContext(~state, \a)).trace.play;
~state[\a]=2
p=PMarkovChain(probs:[[0.5,0.5],[0.5,0.5]], initState:1, halt:0).asStream.nextN(10);
p.asStream.nextN(10);
p=PMarkovChain.random(disorder:0.1, initState:\rand, nstates:5, halt:nil, ordertype: \inc).asStream.nextN(10);
p=PMarkovChain.random(disorder:0.1, initState:0, halt:nil, ordertype: \inc, expressions:[\a, \b, \c]).asStream.nextN(10);
p=PMarkovChain.random(disorder:0.1, initState:\rand, halt:nil, ordertype: \static, expressions:[\a, \b, \c]).asStream.nextN(10);
p=PMarkovChain.random(disorder:0.1, nstates:5, initState:\rand, halt:nil, ordertype: \static, expressions:\unit).asStream.nextN(10);

Pbind(\delta, 1/2, \degree, PMarkovChain(probs:[[0,1],[1,0]])).play;
Pbind(\delta, 1/2, \degree, Prand([1,2],inf).trace).play;
(
var nstates=4, disorder=0.25, ordertype=\static, order, probs;
order = Array.series(nstates);
ordertype.switch(
	\static, nil,
	\progressive, {order = (order+1) % nstates},
	\chaos, {order = order.scramble},
);
probs = order.collect({
	arg dest, rownum;
	var disordered, ordered = 0.dup(nstates);
	ordered[dest] = 1;
	disordered = Array.rand(nstates, 0.0, 1.0);
	(disorder * disordered) + ((1-disorder) * ordered);
});
)

PGeomRep(3, 0.9).asStream.nextN(20);
PGeomRep(Pn(3, inf), 0.9).asStream.nextN(20);
Pbind(\delta, PGeomRep(1, 0.9), \degree, 0).trace.play;
