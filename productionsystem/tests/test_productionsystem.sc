TestPS : UnitTest {
	*expressSystem {|ps, defaultEv, limit=100|
		var stream, steps;
		stream = ps.asStream;
		//stream = Pbind(\note, Pseq([1,2,3], \delta, 1)).asStream;
		"TESTEST2.2".postln;
		//The test hangs here. Why?
		//because PSpawner rules explode UnitTest
		steps = stream.nextN(limit, defaultEv ? Event.default);
		"TESTEST2.3".postln;
		steps = steps.select(_.notNil);
		^steps;
	}
	assertAContainsB{|a,b|
		[\A, a].postln;
		[\B, b].postln;
		//makes sure that A contains all the keys that B does, with the same values
		b.keysDo({|key, bval|
			var aval;
			[\a, a].postln;
			[\b, b].postln;
			this.assert(a.includesKey(key), "key % found".format(key), onFailure: {"key '%' not found in %".format(key, a).postln});
			aval = a.at(key);
			this.assertEquals(aval, bval, "key % equal in both (%,%)".format(key, aval, bval));
		});
	}
	test_unittest {
		var steps, ps, halfSpeed, bar;
		halfSpeed = Pbind(\delta, Pkey(\delta) * 2);
		bar = Pob(\note, 1, \delta, 1);
		ps = Pspawner({ |sp|
			var nextStream;
			nextStream = sp.seq(Pchain(halfSpeed, bar));
			nextStream = sp.seq(Pchain(bar));
			nextStream = sp.seq(Pchain(halfSpeed, halfSpeed, bar));
		});
		steps = this.class.expressSystem(ps);
		this.assertEquals(steps.size, 3, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1));
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4));
	}
	test_interleaved_events_and_ops {
		var steps, ps = PSProductionSystem.new(PostLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, [1, [\halfspeed, \bar, \bar, \halfspeed, \halfspeed, \bar]]);
		steps = this.class.expressSystem(ps);
		this.assertEquals(steps.size, 3, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1));
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4));
	}
}