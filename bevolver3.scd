s.boot;
i = MCPhenosynthIsland.new(server:s, numinds:24, channels:2);
i;
i.cullProportion_(0.2);
i.groupsize
j=i.start;
 i.stop;

p = MCPhenosynthIndividual.new.genome_({1.0.rand}.dup(20));
f = MCPhenosynthIsland.phenomeToGraphFunc(p.calculatePhenome).postcs.play;
f.set(\t_trig, 1);