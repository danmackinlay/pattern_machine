TestPS : UnitTest {
	*expressSystem {|ps, defaultEv, limit=100|
		var stream, steps;
		"TESTEST2.1".postln;
		stream = ps.asStream;
		"TESTEST2.2".postln;
		//The test hangs here. Why?
		steps = stream.nextN(limit, Event.default);
		// steps = stream.nextN(limit, defaultEv ? Event.default);
		"TESTEST2.3".postln;
		steps = steps.select(_.notNil);
		"TESTEST2.4".postln;
		^steps;
	}
	assertAContainsB{|a,b|
		//makes sure that A contains all the keys that B does, with the same values
		b.keysDo({|key, bval|
			var aval;
			this.assert({a.includesKey(key)}, "key % found".format(key), onFailure: {"key '%' not found in %".format(key, a).postln});
			aval = a[key];
			this.assertEquals(aval, bval, "key % equal in both (%=%)".format(key, aval, bval));
		});
	}
	test_interleaved_events_and_ops {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		"TESTEST".postln;
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, [1, [\halfspeed, \bar, \bar, \halfspeed, \halfspeed, \bar]]);
		"TESTEST2".postln;
		steps = this.class.expressSystem(ps);
		//The following line is never run. Why?
		"TESTEST3".postln;
		this.assertEquals(steps.size, 3, "correct number of steps");
		"TESTEST4".postln;
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1));
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4));
		"TESTEST5".postln;
	}
}