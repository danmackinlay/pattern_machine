/*
 * TODO:
 *
 * * types of grains spawned
 * * arpeggiations
 * * track down stuck notes
 * * chirping and twanging - server-side, or client-side?
 *
 */
(
//initialisation
Server.default = s = Server.internal;
//Server.default = s = Server.local;
s.reboot;
StartUp.run;
)
(
SynthDef(\ps_infest_poly_host, {
	|in, i_sndbuffer, phaseout|
	//have a stab at recording some stuff
	RecordBuf.ar(
		inputArray: In.ar(in),
		bufnum: i_sndbuffer,
		run:1,
		loop:0,
		doneAction:2
	);
}).add;
SynthDef(\ps_infest_poly_parasite, {
	|out, gate=1,
	i_sndbuffer,
	phase=0,
	windowSize=0.1,
	windowRandRatio=0.1,
	attack=0.05,
	amp=1.0,
	release=0.5|
	var monosig, env;
	env = EnvGen.kr(
		Env.asr(attackTime:attack, releaseTime:release),
		gate: gate,
		doneAction: 2
	);
	monosig = Warp1.ar(
		numChannels: 1,
		bufnum: i_sndbuffer,
		pointer: phase,
		interp: 2,
		windowSize: windowSize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env
	);
	Out.ar(out, monosig);
}).add;
SynthDef(\ps_infest_poly_parasite_lfo, {
	|out, gate=1,
	i_sndbuffer,
	phase=0,
	windowSize=0.1,
	windowRandRatio=0.1,
	attack=0.05,
	amp=1.0,
	release=0.5,
	lfof=1,
	lfoam=0.1,
	llfof=0.3,
	llfoa=1,
	llfoam=0.5,
	llfofm=0.5,
	lfophase=0|
	var monosig, env, lfo, llfo;
	llfo = SinOsc.kr(
		freq: llfof,
		mul: llfoa,
	);
	lfo = SinOsc.kr(
		phase: lfophase * 2 * pi,
		freq: lfof * (1 + (llfo*llfofm)),
		mul: (1+ (llfo*llfoam)),
	);
	(lfof * (1 + (llfo*llfofm))).poll(1, label:\lfof);
	env = EnvGen.kr(
		Env.asr(attackTime:attack, releaseTime:release),
		gate: gate,
		doneAction: 2
	);
	monosig = Warp1.ar(
		numChannels: 1,
		bufnum: i_sndbuffer,
		pointer: phase,
		interp: 2,
		windowSize: windowSize,
		overlaps: 2,
		windowRandRatio: windowRandRatio,
		mul: env * (1+ (lfoam * lfo))
	);
	Out.ar(out, monosig);
}).add;
SynthDef(\ps_morph_delay, {|in, out, gate| Out.ar(out, In.ar(in)*gate)}).add;
SynthDef(\ps_twinkle_listener, {|in, out, gate| Out.ar(out, In.ar(in)*gate)}).add;
SynthDef(\ps_twinkle_player, {|in, out, gate| Out.ar(out, In.ar(in)*gate)}).add;
)
(
// poly_ -style
~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\in, ~in, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//~makeparasite.(~makehost.(0));
~recBuf = ~makehost.(0);
~recBuf.plot;
~makeparasite.(~recBuf);
)
(
// poly_ _lfo -style
~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\in, ~in, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite_lfo, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//~makeparasite.(~makehost.(0));
~recBuf = ~makehost.(1);
~recBuf.plot;
~makeparasite.(~recBuf);
)
(
// poly_ _lfo -style, MIDIfied
~recBufs = Buffer.allocConsecutive(numBufs:8, server:s, numFrames: s.sampleRate*10.0, numChannels:1);
~in = Bus.new(\audio, s.options.numOutputBusChannels, 1);
~globalOuts = Bus.new(\audio, 0, 1);
~makehost = {|i=0| Synth.new(\ps_infest_poly_host, [\in, ~in, \i_sndbuffer, ~recBufs[i]], s); ~recBufs[i]};
~makeparasite = {|buf| Synth.new(\ps_infest_poly_parasite_lfo, [\out, ~globalOuts, \gate, 1, \i_sndbuffer, buf], addAction:\addToTail, target:s); };
//controllerism
MIDIIn.connectAll;
~o=Ohm64.new(debounceTime:0.1);
~o.initDebugResponders;
~o.resetLights;
~parasites = Array.fill2D(7,8,[false,nil]);
~hosts = Array.fill(8,[false,nil]);
~swarmvoices
~o.setNoteResponder(\grid, 
	{
		|id, val, selector, inchan, on|
		var row, col;
		#row, col = ~o.gridNote(id);
		on.if({
			(row<7).if({
				//parasite bidness
				var state, synth;
				#state, synth = ~parasites[row][col];
				state = state.not;
				state.if(
					{
						synth = ~makeparasite.(col);
					},
					{
						synth ?? {synth.set(\gate, 0)};
						synth=nil;
					}
				);
				~o.sendGridNote([row,col], state.binaryValue*65);
				~parasites[row][col] = [state, synth];
			}, {
				var state, buffer;
				#state, buffer = ~hosts[col];
				state = state.not;
				state.if(
					{
						buffer = ~makehost.(col);
					},
					{
						buffer = nil;
					}
				);
				~o.sendGridNote([row,col], state.binaryValue*65);
				~hosts[col] = [state, buffer];
			});
		});
	}
);
~parasites[4][1];
~recBufs[3].plot;
)
