//Shamelessly specific mapping for a particular OSC interface I have

PSHawkesLemurControl {
	var <state;
	var <prefix="chan1";
	var <myAddr;
	var <intAddr;
	var <oscFuncs;

	*new {arg state, prefix="/chan1", myAddr, intAddr;
		^super.newCopyArgs(
			state ?? {()},
			prefix,
			myAddr ? NetAddr.localAddr,
			intAddr
		).initPSHawkesControl;
	}
	initPSHawkesControl {
		state[\inits] = state.atFail(\inits, []);
		state[\cluster] = state.atFail(\cluster, 10);
		state[\decay] = state.atFail(\decay, -1.0);
		state[\corr] = state.atFail(\corr, [0.5, 0.5]);
		state[\int] = state.atFail(\int, 4);
		state[\pitchset] = state.atFail(\pitchset, Array.fill(8, 0));
		state[\pitchsetA] = state.atFail(\pitchsetA, Array.fill(8, 0));
		state[\pitchsetB] = state.atFail(\pitchsetB, Array.fill(8, 0));
		oscFuncs = Array.new(20);
		this.addHandler("/cluster/x", { arg msg;
			state[\cluster] = msg[0].linlin(0.0,1.0,0.0,6.0).exp;
			intAddr !? intAddr.sendMsg(prefix ++ "/cluster_disp/value", state[\cluster]);
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
			intAddr !? intAddr.sendMsg(prefix ++ "/int_disp/value", msg[0]);
			state[\int] = msg[0];
		});
	}
	//handler func factory
	//updates state vars
	//ignores empy messages
	oscHandler {
		arg func;
		^{
			arg msg, time, addr, recvPort;
			msg.notEmpty.if({
				var path;
				path = msg.removeAt(0);
				intAddr = intAddr ? addr;
				msg.notEmpty.if({
					func.value(msg);
				});
			});
		};
	}
	//add handler
	addHandler {
		arg pathEnd, func;
		oscFuncs = oscFuncs.add(
			OSCFunc(this.oscHandler(func), prefix ++ pathEnd)
		);
	}
	free {
		oscFuncs.do(_.free);
	}
}