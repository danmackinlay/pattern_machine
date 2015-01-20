//Shamelessly specific mapping for a particular OSC interface I have

PSHawkesControl {
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
		oscFuncs = Array.new(20);
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			intAddr = intAddr ? addr;
			
		}, prefix ++ "/trig/x"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			
		}, prefix ++ "/trig/y"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			
		}, prefix ++ "/trig/z"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			intAddr = intAddr ? addr;
			
		}, prefix ++ " /chan1/pitchset1/x"));
		oscFuncs = oscFuncs.add(OSCFunc({
			arg msg, time, addr, recvPort;
			intAddr = intAddr ? addr;
			
		}, prefix ++ " /chan1/pitchset2/x"));
	}
	free {
		oscFuncs.do(_.free);
	}
}