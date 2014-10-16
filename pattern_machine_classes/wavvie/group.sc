//Manage a whole bunch of sequencing for my typical synth voice. no pretensions to universality. This ain't jitlib.
PSWavvieGroup {
	var <group,<bus,<index,<numChannels,<server;
	var <synthgroup, <fxgroup, <mixergroup;
	var <freebus, <freegroup;
	var <pats2stop, <stuff2free;
	 
	*new {arg cutsynths,group,bus,numChannels;
		^super.new.initWavvieGroup(cutsynths,group,bus,numChannels);
	}	
	
	addStoppablePat {|pat|
		pats2stop = pats2stop.add(pat);
	}
	
	addFreeableStuff {|stuff|
		stuff2free = stuff2free.add(stuff);
	}
		
	initWavvieGroup { arg g,b,chan;
		pats2stop = Array.new;
		stuff2free = Array.new;
		
		freegroup=false;
		
		//server=s ?? {Server.default};
		group=g ?? {freegroup=true; Group.new;};
		
		server=group.server;
		
		synthgroup=Group.head(group);
		fxgroup=Group.after(synthgroup);
		mixergroup=Group.after(fxgroup);
		
		numChannels=chan ? 1; //may only support mono
		
		freebus=false; //don't free if bus passed in, responsibility of client code
		bus= b ?? {
			//must free eventually if not passed in
			freebus=true;
			Bus.audio(server,numChannels);
		};//{Bus.new(\audio,0,numChannels,server)}; //defaults  
		index=bus.index;
		
		//This would be where to make a mixer, if no bus was passed in.		
	}
	free {
		pats2stop.do({arg pat; pat.stop});
		stuff2free.do({arg stuff; stuff.free});
				
		if(freebus, {
			bus.free;});
		
		if(freegroup, {
			group.free;});
	}
	
}
/*
{|state, i|
	state.make({
		var sequencemaker;
		~i=i;
		state.voiceStates[i]=(state);
		~sampleDur = state.sampleDur ? 30;
		~cleanup={|self|
			var nextitem, ct = self.cleanupList.size;
			//[\precleaning, ct].postln;
			{self.cleanupList.isEmpty.not}.while({
				nextitem = self.cleanupList.pop;
				ct = ct-1;
				{
					//[\cleaning, self.i, ct].postln;
					nextitem.value;
				}.try(_.postcs);
			});
		};
		~cleanupList = List.new;
		CmdPeriod.doOnce({ state.cleanup();});
		//can't do this one until the cleanup list exists; has to be first if at all
		//~cleanupList.add({ state.voiceStates[i]=nil });

		~loopbuf = Buffer.alloc(~server, ~server.sampleRate * ~sampleDur, 1);
		~cleanupList.add({ state.loopbuf.free });
		~modbus = Bus.control(~server,1);
		~cleanupList.add({ state.modbus.free });
		~loopphasebus = Bus.control(~server, 1);
		~cleanupList.add({ state.loopphasebus.free });
		//looks tidier in debug to use groups instead of synths
		~headGroup = Group.head(~instgroup);
		~tailGroup = Group.tail(~instgroup);
		s.sync;

		//record input (I would prefer resumble record)
		~rec = {|self, dur|
			//[\rec, \self, self].postcs;
			//[\rec, \dur, dur].postcs;
			(
				instrument: \ps_bufwr_phased__1x1,
				in: self.inbus,
				bufnum: self.loopbuf,
				phasebus: self.loopphasebus,
				fadetime: 0.05,
				group: self.headGroup,
				addAction: \addToHead,
				dur: dur ? self.sampleDur,
			//sendGate: false,//persist
			).play(self[\clock]);
		};
		//channel fx
		~reverb = (
			instrument: \ps_gverb__2x2,
			group: ~tailGroup,
			server: ~server,
			addAction: \addToHead,
			sendGate: false,//persist
			out: ~outbus,
			index: 1,
			wet: 0.2,
			damping: 0.4,
			revtime: 0.8,
			roomsize: 170,
		).play;
		~cleanupList.add({ state.reverb.free });
		//channel fx
		~jack = (
			instrument: \jack__2,
			group: ~tailGroup,
			server: ~server,
			addAction: \addToTail,
			sendGate: false,//persist
			in: ~outbus,
			out: state.masteroutbus,
		).play;
		~cleanupList.add({ state.jack.free });
		~parentevt = (
			group: ~headGroup,
			addAction: \addToTail,
			server: ~server,
			out: ~outbus,
		);
	});
}
*/