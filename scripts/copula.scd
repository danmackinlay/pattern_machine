/* I simulate uniform marginal variables from the stipulated 2d copula distribution
see http://www.math.uni-leipzig.de/~tschmidt/TSchmidt_Copulas.pdf
or, for exmpirical copulae, http://www.mathworks.com.au/products/statistics/examples.html?file=/products/demos/shipping/stats/copulademo.html#17

This turns out to be easiest for Gaussian, t-copulae and Marshall-Olkin, and
only somewhat easy for some Archimedeans - specifically, Frank, Gumbel and Clayton.
Archimedean copulae have a single coupling parameter for a large variable set, which is nice. However, for bivariate coupling (and everything can be done pairwise if we want) Gaussians are yet simpler.
Aside: What is the difference between GaussTrig and TGaussRand?
 */

///////////////////////////
//Gaussian copulae
///////////////////////////
(
PSGaussCorrelate.arr_Erf;
//PSUGaussCorrelate.initServer(s);
//PSUGaussCorrelate.buffersFor(s)[\buf_iErf].plot;
//PSUGaussCorrelate.dict_Servers[\localhost][\buf_Erf].plot;
PSGaussCorrelate.arr_Erf.plot;
PSGaussCorrelate.arr_iErf.gnuplot;
PSGaussCorrelate.degaussianize({0.gauss(1)}.dup(1000)).histo(25).plot;
h=GNUPlot.new;
v={0.gauss(1)}.dup(200);
h.scatter([v,PSGaussCorrelate.corr(0.99, v)].flop);
)
{PSUGaussCorrelate.krGaussianize(WhiteNoise.kr(0.5, 0.5))}.plot(0.1);
{PSUGaussCorrelate.krDegaussianize(
	PSUGaussCorrelate.krGaussianize(WhiteNoise.kr(0.5, 0.5))
)}.plot(0.1);

PSUGaussCorrelate.kr(0, PSGaussCorrelate.gaussianize(WhiteNoise.kr(0.5, 0.5)));
