/* I simulate uniform marginal variables from the stipulated 2d copula distribution
see http://www.math.uni-leipzig.de/~tschmidt/TSchmidt_Copulas.pdf
or, for exmpirical copulae, http://www.mathworks.com.au/products/statistics/examples.html?file=/products/demos/shipping/stats/copulademo.html#17

This turns out to be easiest for Gaussian, t-copulae and Marshall-Olkin, and
only somewhat easy for some Archimedeans - specifically, Frank, Gumbel and Clayton.
However, Archimedean copulae have a single coupling parameter for a large variable set which is nice. However, for bivariate coupling (and everythign can be done pariwise if we really want) Gaussians are very simple.
Aside: What is the difference between GaussTrig and TGaussRand?
 */

///////////////////////////
//Gaussian copulae
///////////////////////////

(
PSGaussCopula.arr_Erf;
PSGaussCopula.initServer(s);
PSGaussCopula.buffersFor(s)[\buf_iErf].plot;
PSGaussCopula.dict_Servers[\localhost][\buf_Erf].plot
)
