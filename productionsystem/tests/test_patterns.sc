PSTestPattern : UnitTest {
	*expressPattern {|patt, defaultEv, limit=100, suppressZeroRests=true|
		var stream, accept, steps=Array.new;
		defaultEv = defaultEv ? Event.default;
		stream = patt.asStream;
		steps = stream.nextN(limit*2, defaultEv.copy);
		steps = steps.select(_.notNil);
		accept = {|ev| true;};
		//"acceptor" function for non-zero-length-rest events, which proliferate with, e.g, branching
		suppressZeroRests.if({
			accept = {|ev|
				(ev[\isRest] ? false).if(
					{
						(ev[\delta] == 0).if({false}, {true});
					}, {
						true
					};
				);
			};
		});
		steps = steps.select(accept);
		steps = steps[0..limit.min(steps.size)];
		^steps;
	}
	assertAContainsB{|a,b, message=""|
		//makes sure that A contains all the keys that B does, with the same values
		(message.size>0).if({message = message ++ ": "});
		b.pairsDo({|key, bval|
			var aval;
			this.assert(a.includesKey(key), message ++ "key % found".format(key), onFailure: {"key '%' not found in %".format(key, a).postln});
			aval = a[key];
			this.assertEquals(aval, bval, message ++ "key % equal in both (%=%)".format(key, aval, bval));
		});
	}
}
TestDropdur : PSTestPattern {
	test_basic_drop {
		var steps, patt = Pdropdur(2, Pbind(\note, Pseq([1,2,3,4]), \delta, 1));
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 2, "basic Dropdur: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 3, 'delta': 1), "basic Dropdur");
		this.assertAContainsB(steps[1], ('note': 4, 'delta': 1), "basic Dropdur");
	}
	test_rounded_drop {
		var steps, patt = Pdropdur(1, Pbind(\note, Pseq([1,2,3,4,5,6]), \delta, 1/3));
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 3, "rounded Dropdur: correct number of steps");
		this.assertAContainsB(steps[0], ('note': 4, 'delta': 1/3), "rounded Dropdur");
		this.assertAContainsB(steps[1], ('note': 5, 'delta': 1/3), "rounded Dropdur");
		this.assertAContainsB(steps[2], ('note': 6, 'delta': 1/3), "rounded Dropdur");
	}
	test_rest_drop {
		var steps, patt = Pdropdur(2.5, Pbind(\note, Pseq([1,2,3,4]), \delta, 1));
		steps = this.class.expressPattern(patt);
		this.assertEquals(steps.size, 2, "rest Dropdur: correct number of steps");
		this.assertAContainsB(steps[0], ('dur': 0.5, 'delta': 0.5, 'isRest': true), "rest Dropdur");
		this.assertAContainsB(steps[1], ('note': 4, 'delta': 1), "rest Dropdur");
	}
}