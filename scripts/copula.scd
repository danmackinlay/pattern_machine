/* I simulate uniform marginal variables from the stipulated 2d copula distribution
see http://www.math.uni-leipzig.de/~tschmidt/TSchmidt_Copulas.pdf
or, for exmpirical copulae, http://www.mathworks.com.au/products/statistics/examples.html?file=/products/demos/shipping/stats/copulademo.html#17

This turns out to be easiest for Gaussian, t-copulae and Marshall-Olkin, and
only somewhat easy for some Archimedeans - specifically, Frank, Gumbel and Clayton.
However, Archimedean copulae have a single coupling parameter, which is the whole
reason I'm interested in this technique, so I'd rather them. OTOH, for bivariate
coupling, it's not too crazy.
 */

///////////////////////////
//Archimedean copulae
///////////////////////////

//We define a 2d CDF using a specified generator.

~generators = (
	\clayton: (
		\forward: {|t, param=0| (1+t)**((-1/param).neg)},
		\inverse: {|t, param=0| ( t**(param.neg)) -1 },
		\ghat: {}
	)
);
~generators[\clayton][\forward].(0);
~generators[\clayton][\inverse].(0);
((0..16)/16).collect(~generators[\clayton][\inverse].(_, 0.5));
~generators[\clayton][\inverse].(0.5);


////Bleargh. OK, actually, let's start with gaussian.(
(
var length, arr_Erf, arr_iErf, buf_Erf, buf_iErf;
length=1025;
buf_Erf = Buffer.alloc(s, length, 1);
buf_iErf = Buffer.alloc(s, length, 1);

arr_Erf = Array.interpolation(length,-4,4).collect(_.gaussCurve).integrate.normalize;
arr_Erf.plot;
arr_iErf = Array.interpolation(length).collect({|v| arr_Erf.indexInBetween(v)}).normalize(-4,4);
arr_iErf.plot;

buf_Erf.getn(0, buf_Erf.numFrames, {|x| x.postln })

)