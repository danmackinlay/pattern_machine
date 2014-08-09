(
var parenty, childy, grandchildy;
parenty = (
	me: \parenty,
	stuff: \parenty,
	dreck: \parenty,
);
childy = Event.new(n:60, proto: parenty).make({
	~me = \childy;
	~dreck = \childy;
	~quatsch = ~stuff;
});
grandchildy = Event.new(n:60, proto: childy).make({
	~me = \grandchildy;
	~unsinn = ~stuff;
});
\parenty.postln;
parenty.postcs;
\childy.postln;
childy.postcs;
childy[\stuff].postln;
\grandchildy.postln;
grandchildy.postcs;
grandchildy.push;
nil;
)
currentEnvironment.proto.push
Event.stack;
Environment.stack;
