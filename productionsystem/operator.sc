/*
A POp is a normal pattern, but it composes nicely, for ease of legibility.
It covers the special case where you would like to have a pattern than applies unary
operations on the values of keys in the incoming stream.
Approximately, Pob(\delta, 2*_) is the same as Pbind(\delta, 2*Pkey(\delta))
*/
POp : Pbind {
	//closely cribbed from Pbind, but more convenient for fn application
	printOn { arg stream;
		stream << "%(%)".format(this.class, patternpairs.join(","));
	}	
	hash { ^([this.class.name] ++ this.storeArgs).hash }
	== {|that| 
		^(this.class==that.class) && (this.storeArgs == that.storeArgs)
	}
	embedInStream { arg inevent;
		var event;
		var sawNil = false;
		var streampairs = patternpairs.copy;
		var endval = streampairs.size - 1;

		forBy (1, endval, 2) { arg i;
			streampairs.put(i, streampairs[i].asStream);
		};

		loop {
			if (inevent.isNil) { ^nil.yield };
			event = inevent.copy;
			forBy (0, endval, 2) { arg i;
				var name = streampairs[i];
				var transform = streampairs[i+1];
				var inval = event[name];
				var transformed = transform.value(inval);
				//at this point, Pbind handles multichannel expansion. Should I?
				/*
				if (name.isSequenceableCollection) {
					if (name.size > transformed.size) {
						("the pattern is not providing enough values to assign to the key set:" + name).warn;
						^inevent
					};
					name.do { arg key, i;
						event.put(key, transformed[i]);
					};
				}{*/
					event.put(name, transformed);
				/*};*/

			};
			inevent = event.yield;
		}
	}
	at{|...args|
		^Event.newFrom(patternpairs).at(*args)
	}
	// compose POps
	<> { arg that;
		^(that.isKindOf(this.class).not).if(
			{
				//This is the implementation from Pattern
				//am not sure how to call super with weird method names like <>
				Pchain(this, that)
			}, {
				//First, copy 'im.
				var composedPOp = Event.newFrom(that.patternpairs);
				//now, compose all sub operations
				patternpairs.pairsDo({|key, transform|
					var intransform = composedPOp.at(key);
					var composedTransform = transform <> (intransform ?? {Affine1(1)});
					composedPOp.put(key, composedTransform);
				});
				that.class.new(*(composedPOp.getPairs.flat));
			}
		);
	}
}