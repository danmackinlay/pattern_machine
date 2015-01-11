+ Ppoisson{
	*newFromCluster {
		arg m, length=inf;
		^this.new(1-(m.reciprocal), length);
	}
}