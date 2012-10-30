TestPS : UnitTest {
	*expressPattern {|ps, defaultEv, limit=100, suppressZeroRests=false|
		var stream, accept, steps=Array.new;
		defaultEv = defaultEv ? Event.default;
		stream = ps.asStream;
		steps = stream.nextN(limit*2, defaultEv.copy);
		steps = steps.select(_.notNil);
		/*
		accept = {|ev| true;};
		//"acceptor" function for non-zero-length-rest events, which proliferate with branching
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
		*/
		steps = steps[0..limit.min(steps.size)];
		^steps;
	}
	assertAContainsB{|a,b|
		//makes sure that A contains all the keys that B does, with the same values
		b.pairsDo({|key, bval|
			var aval;
			this.assert(a.includesKey(key), "key % found".format(key), onFailure: {"key '%' not found in %".format(key, a).postln});
			aval = a[key];
			this.assertEquals(aval, bval, "key % equal in both (%=%)".format(key, aval, bval));
		});
	}
	test_op_association {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, [\halfSpeed, \bar, \bar, \halfSpeed, \halfSpeed, \bar]);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 3, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1));
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4));
	}
	test_parens {
		var steps, ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		ps.putRule(\root, 
			[\halfSpeed, PSParen(\bar, \bar), \halfSpeed, \halfSpeed, PSParen(\bar), \bar]);
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[2], ('note': 1, 'delta': 4));
		this.assertAContainsB(steps[3], ('note': 1, 'delta': 1));
	}
	test_arbitrary_symbols {
		var steps, ps;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putOp(\halfSpeed, Pbind(\delta, Pkey(\delta) * 2)) ;
		ps.putAtom(\bar, Pob(\note, 1, \delta, 1)) ;
		steps = this.class.expressPattern(ps.asPattern([\halfSpeed, \bar, \bar]));
		this.assertEquals(steps.size, 2, "correct number of steps");
		this.assertAContainsB(steps[0], ('note': 1, 'delta': 2));
		this.assertAContainsB(steps[1], ('note': 1, 'delta': 1));
	}
	test_branching {
		var steps, ps, firstpair, lastpair;
		ps = PSProductionSystem.new(NullLogger.new);
		ps.putAtom(\one, Pob(\note, 1, \delta, 1)) ;
		ps.putAtom(\two, Pob(\note, 2, \delta, 1)) ;
		ps.putRule(\root, PSBranch([\one, \one], [\two, \two]));
		steps = this.class.expressPattern(ps);
		this.assertEquals(steps.size, 4, "correct number of steps");
		firstpair = (steps[0..1]).collect(_.note);
		lastpair = (steps[2..3]).collect(_.note);
		this.assert(firstpair.includes(1));
		this.assert(firstpair.includes(2));
		this.assert(lastpair.includes(1));
		this.assert(lastpair.includes(2));
	}
}