Lemur
{
	var name, netAddr, oscServer, recvPort, <>responders;

	*new
	{
		arg name, addr, port;
		^super.new.initLemur(name, addr, port);
	}

	initLemur
	{
		arg n, a, p;
		name = n;
		responders = Dictionary.new(100);
		netAddr = NetAddr.new(a, p);
		oscServer = Server.new(name, netAddr);
	}

	sendMsg
	{
		arg msgArray;
		^oscServer.listSendMsg(msgArray);
	}

	addResponder
	{
		arg cmd, action, port;
		var resp;
		resp = OSCFunc( { arg msg, time ,netAddr ,recvPort;
			var array;
			array = msg.copy;
			array.removeAt(0);
			action.value(array);
		}, cmd, netAddr, port ).add;
		^if( responders.at(cmd) == nil, {
			responders.put(cmd, List.newUsing([resp]));
		},{
			responders.at(cmd).add(resp);
		});
	}

	removeResponder
	{
		arg cmd;
		var list;
		list = responders.at(cmd);
		list.do(_.remove;);
		list.clear;
		responders.removeAt(cmd);


		//responders.at(cmd).remove;
		//^responders.removeAt(cmd);
	}

	removeAllResponders
	{
		responders.asArray.do({|list| list.do(_.remove;); list.clear;});
		responders.clear;
	}

	map
	{
		arg synth, synth_arg, cmd;
		^this.addResponder(cmd, {
			arg array;
			synth.set(synth_arg, array.at(0));
		});
	}

	mapScaled
	{
		arg synth, synth_arg, cmd, min, max;
		^this.addResponder(cmd, {
			arg array;
			synth.set(synth_arg, array.at(0)*(max-min)+min);
		});
	}

	mapXScaled
	{
		arg synth, synth_arg, cmd, min, max;
		var offset;
		if (min >= max, {
			"Check your min/max".postln;
			^nil;
		},{
			if (min <= 0, {
				if(min==0, {offset=1;}, {offset=2*abs(min);});
				min = min + offset;
				max = max + offset;
				^this.addResponder(cmd, {
					arg array;
					synth.set(synth_arg, exp(array.at(0)*log(max/min))*min - offset);
				});
			},{
				^this.addResponder(cmd, {
					arg array;
					synth.set(synth_arg, exp(array.at(0)*log(max/min))*min);
				});
			});
		});
	}

	unmap
	{
		arg cmd;
		this.removeResponder(cmd);
	}

}
