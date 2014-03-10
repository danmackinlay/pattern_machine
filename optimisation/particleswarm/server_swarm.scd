//Fuck client-side business. This optimises purely based on server action
(
fork {
	var nAgents = 10;
	var synthParams = (freq: ControlSpec.new(100, 1000, 'exp'));
	var nParams = synthParams.size;
	var speed = 0.1;
	var noise = 0.05;
	var decay = 0.1; //check parameterisation
	var updateRate = 10;
	var server = s;
	var fitnessBuses = Bus.control(server, nAgents);
	var locationBuses = Bus.control(server, nAgents*nParams);
	var paramBuses = Bus.control(server, nAgents*nParams);
	var tickBus = Bus.control(server, 1);
	var referenceBus = Bus.audio(server, 1);
	var outputBus = Bus.audio(server, 1);
	var controlGroup, listenGroup, playGroup;
	controlGroup = Group.new(server);
	server.sync;
	listenGroup = Group.after(controlGroup);
	server.sync;
	playGroup = Group.after(listenGroup);

	SynthDef.new(\ticker, {
		Out.kr(tickBus, Impulse.kr(updateRate);
	}).add;

	SynthDef.new(\agent, {|selfIndex|
		var otherIndex = TIRand.kr(lo: 0, hi: (nAgents-2), trig: tickBus);
		otherIndex = otherIndex + (otherIndex>=selfIndex);
		var selfFitness = fitnessBuses.kr(1, selfIndex);
		var otherFitness = fitnessBuses.kr(1, otherIndex);
		var otherFitter = otherFitness<selfFitness; //lower is fitter. should I rename?
		var otherLocation = locationBuses.kr(nParams, nParams*otherIndex);
		var selfVelocity = LocalIn.kr(nParams, Rand(-1,1));
		selfVelocity = (1-otherFitter)*selfVelocity) +
			(otherfitter*(otherLocation-selfLocation)) +
			TRand.kr(-1, 1, trig: tickBus)*noise;
		LocalOut.kr(selfVelocity);
		var coeff = speed * ControlRate.ir.reciprocal;//.poll(0.1, \leak);
		// would be nice to clip velocity based on whether coefficients are inside the bounds or not
		var selfLocation = Integrator.kr(selfVelocity * coeff).dup(nParams);
		Out.kr(paramBuses.subBus(nParams*otherIndex, nParams), selfLocation);
	}).add;

	//we will be using play synth \ps_reson_saw and listen synth \ps_judge_pitchamp_distance__1_1
}
)
	1+true