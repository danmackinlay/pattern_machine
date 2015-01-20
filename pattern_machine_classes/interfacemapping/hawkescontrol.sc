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
		state[\clusterSize] = state.atFail(\inits, 10);
		state[\decay] = state.atFail(\decay, -1.0);
		state[\corr] = state.atFail(\corr, [0.5, 0.5]);
		state[\int] = state.atFail(\int, 4);
		state[\pitchset] = state.atFail(\pitchset, Array.fill(8, 0));
		state[\pitchsetA] = state.atFail(\pitchsetA, Array.fill(8, 0));
		state[\pitchsetB] = state.atFail(\pitchsetB, Array.fill(8, 0));
		oscFuncs = Array.new(20);
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			intAddr = intAddr ? addr;
			msg.removeAt(0);
			
		}, prefix ++ "/trig/x"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			msg.removeAt(0);
			
		}, prefix ++ "/trig/y"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			intAddr = intAddr ? addr;
			msg.removeAt(0);
			state[\pitchsetA] = msg;
			state[\pitchset] = state[\pitchsetA] + (state[\pitchsetB].reciprocal);
		}, prefix ++ "/pitchset1/x"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			intAddr = intAddr ? addr;
			msg.removeAt(0);
			state[\pitchsetB] = msg;
			state[\pitchset] = state[\pitchsetA] + (state[\pitchsetB].reciprocal);
		}, prefix ++ "/pitchset2/x"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			msg.removeAt(0);
			intAddr = intAddr ? addr;
			intAddr !? intAddr.sendMsg(prefix ++ "/int_disp/value", msg[0]);
			state[\int] = msg[0];
		}, prefix ++ "/int/x"));
	}
	free {
		oscFuncs.do(_.free);
	}
}