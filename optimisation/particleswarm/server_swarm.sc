//Fuck client-side business. This optimises purely based on server action
(
var nGrains = 10;
var synthParams = (ControlSpec.new(100, 1000, 'exp'));
var server = s;
var fitnesses = Bus.control(server, nGrains);
var locations = Bus.control(server, nGrains*(synthParams.size));
var liveParams = (
	referenceBus: Bus.audio(server, 1),
	outputBus:  Bus.audio(server, 2),
	speed: 0.01,
	noise: 0.01,
	delay: 0.1,
	rate: 0.1
);


SynthDef.new(\particle, {}).add;
SynthDef.new(\sound, {}).add;
SynthDef.new(\evaluator, {}).add;

)