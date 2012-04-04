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
