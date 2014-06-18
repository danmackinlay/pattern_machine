//Pipe IO in SC is not asynchronous
(
p=Pipe.new("{ while true; do echo 3; sleep 1; done ;};", "r");
r=Routine{inf.do{
	"trying".postln;
	n=4;
	n=p.getLine;
	n.asCompileString.postln;
	0.3.yield;
}}.play;
//never run, since the preceding pipe is infinite
t=Routine{inf.do{
	"trying2".postln;
	5.postln;
	0.4.yield;
}}.play;
)
r.stop;
p.close;