Server.default=s=~serverboot.(prox:\local, device:\builtin);
~state=nil;
(
var state = ~state ?? {()};
var samplebuf, channel;
topEnvironment.put(\state, state);

state.use({fork {
	~bardelta = 4;
	~reseed = true;
	~lambda = 2;
	~density = 1;
	~quantstrength =0;
}});
)
~state;