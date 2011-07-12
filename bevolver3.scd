s.boot;
i = MCPhenosynthIsland.new(server:s, numinds:24, channels:2);
i.cullProportion_(0.2);
i.loopYear_(true)
i.numTestsPerYear_(1);
i.runOneYear;
i.start;
i.stop;
i.bestEverIndivid.fitness;
i.inds.collect({|j| j.fitness;})
p = MCPhenosynthIndividual.new.genome_({1.0.rand}.dup(20));
f = MCPhenosynthIsland.phenomeToGraphFunc(p.calculatePhenome).postcs.play;
f.set(\t_trig, 1);