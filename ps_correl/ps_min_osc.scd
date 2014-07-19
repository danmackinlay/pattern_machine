s=~serverboot.(prox:\local, device:\builtin);
~pscorrelpath = ~pm +/+ "ps_correl";
// ~dataServerPid = -1000;
// ~dataServerPid.pidRunning.not.if({
// ~dataServerPid= "python %".format(
//    (~pscorrelpath +/+ "ps_correl.py").shellQuote
// ).unixCmd(
// 		action: {|result, pid| [result, pid].postln},
// 		postOutput: true
// 	);
// });
"python %".format(
	(~pscorrelpath +/+ "ps_min_osc_server.py").shellQuote
).runInTerminal;
s.dumpOSC(1);
OSCdef.trace(true);

s.dumpOSC(0);
OSCdef.trace(false);

NetAddr("127.0.0.1", 36000).sendMsg("/woom", 5);
NetAddr("127.0.0.1", 36001).sendMsg("/blarg", 5);
NetAddr("127.0.0.1", 36002).sendMsg("/info");
NetAddr("127.0.0.1", 36003).sendMsg("/error", 5);
NetAddr("127.0.0.1", 7667).sendMsg("/blorgh", 5);
NetAddr("127.0.0.1", 7887).sendMsg("/skeeeeennnn", 5);
NetAddr("127.0.0.1", 36000).sendMsg("/hello", 5);
NetAddr("127.0.0.1", 36001).sendMsg("/hello", 5);
NetAddr("127.0.0.1", 36002).sendMsg("/hello", 5);
NetAddr("127.0.0.1", 36003).sendMsg("/hello", 5);
r = OSCFunc({ |a,b,c,d| [a,b,c,d].postln }, '/x');
n = NetAddr("127.0.0.1", 57120);
n.sendMsg("/x")

(
fork {
	65536.do({|i|
		//i.postln;
		NetAddr("localhost", i).sendMsg("/fatsch", 5);
		0.001.yield;
	});
};
)