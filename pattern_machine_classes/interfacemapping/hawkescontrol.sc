//Shamelessly specific mapping for a particular OSC interface I have
//TODO: make all controls update bidirectionally.
PSHawkesLemurControlChan {
	var <state;
	var <prefix="chan1";
	var <parent;
	var <intAddr;
	var <oscFuncs;
	var <>trace;
	
	*new {arg state, prefix="/chan1", parent, trace=false;
		^super.newCopyArgs(
			state ?? {()},
			prefix,
			parent,
		).initPSHawkesLemurControlChan.trace_(trace);
	}
	initPSHawkesLemurControlChan {
		state[\inits] = state.atFail(\inits, []);
		state[\cluster] = state.atFail(\cluster, 10);
		state[\decay] = state.atFail(\decay, -1.0);
		state[\corr] = state.atFail(\corr, [0.5, 0.5]);
		state[\int] = state.atFail(\int, 4);
		state[\buffers] = state.atFail(\buffers, [\buf0, \buf1]);
		state[\pitchset] = state.atFail(\pitchset, Array.fill(8, 0));
		state[\pitchsetA] = state.atFail(\pitchsetA, Array.fill(8, 0));
		state[\pitchsetB] = state.atFail(\pitchsetB, Array.fill(8, 0));
		oscFuncs = Array.new(20);
		this.addHandler("/cluster/x", { arg msg;
			state[\cluster] = msg[0].linlin(0.0,1.0,0.0,6.0).exp;
			this.trySendMsg("/cluster_disp/value", state[\cluster]);
		});
		this.addHandler("/decay/x", { arg msg;
			state[\decay] = msg[0].linlin(0.0,1.0,-20.0,0.0);
		});
		this.addHandler("/trig/x", { arg msg;
		});
		this.addHandler("/trig/y", { arg msg;
		});
		this.addHandler("/evolve/x", { arg msg;
		});
		this.addHandler("/evolve/y", { arg msg;
		});
		this.addHandler("/pitchset1/x", { arg msg;
			state[\pitchsetA] = msg;
			state[\pitchset] = state[\pitchsetA] + (state[\pitchsetB].reciprocal);
		});
		this.addHandler("/pitchset2/x", { arg msg;
			state[\pitchsetB] = msg;
			state[\pitchset] = state[\pitchsetA] + (state[\pitchsetB].reciprocal);
		});
		this.addHandler("/int/x", { arg msg;
			this.trySendMsg("/int_disp/value", msg[0]);
			state[\int] = msg[0];
		});
		this.addHandler("/buffer/selection", { arg msg;
			state[\bufferInd] = msg[0];
		});
	}
	intAddr_{
		//called when we first know the return address 
		// (or when manually fored later I suppose)
		arg addr;
		intAddr = addr;
		//could update interface from state here.
		this.updateInt;
	}
	updateInt {
		this.sendMsg("/buffer", "@items", *state[\buffers]);
	}
	sendMsg {
		arg path ... msg;
		intAddr.sendMsg(prefix ++ path, *msg);
	}
	trySendMsg {
		arg path ... msg;
		intAddr.notNil.if({intAddr.sendMsg(prefix ++ path, *msg)});
	}
	//handler func factory
	//updates state vars
	//may provide additional feedback on the lemur
	//but does not update everything else
	//ignores empty messages
	oscHandler {
		arg func, pathEnd;
		^{
			arg msg, time, replyAddr, recvPort;
			trace.if({
				[\trace, pathEnd, msg, time, replyAddr, recvPort].postln;
			});
			intAddr.isNil.if({this.intAddr_(replyAddr)});
			(msg.size>1).if({
				var path;
				path = msg.removeAt(0);
				func.value(msg);
			}, {
				("contentless message:" + pathEnd + msg.asCompileString).warn;
			});
		};
	}
	//add handler
	addHandler {
		arg pathEnd, func;
		oscFuncs = oscFuncs.add(
			OSCFunc(this.oscHandler(func, pathEnd), prefix ++ pathEnd)
		);
	}
	free {
		oscFuncs.do(_.free);
	}
}
PSWavvieLemurControl {
	var <childHawkesControls;
	*new {
		
	}
	init {
		
	}
	free {
		childHawkesControls.do(_.free);
	}
	
}