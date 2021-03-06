/*
Unlike normal patterns, which special-case event patterns to do particular operations on keys, rather than composing.
Pcomp composes event patterns in a plain-old-functional-style with other event patterns.
This is useful for composing unary operations acting on whole streams (e.g. Pfindur) 
with the streams and getting the right behaviour.
*/
Pcomp : Pattern {
	var fn;//a function wrapping a pattern, e.g. Pfindur(2,_)
	*new {|fn|
		^super.newCopyArgs(fn)
	}
	guiClass { ^PcompGui }
	<> {|that|
		^fn.value(that)
	}
	printOn { arg stream;
		stream << "%(%)".format(this.class, fn);
	}	
	hash { ^([this.class.name] ++ this.storeArgs).hash }
	== {|that| 
		^(this.hash==that.hash)
	}
	storeArgs { ^[fn] }
	
}
/*
A Pop is a normal pattern, but it composes nicely, for ease of legibility.
It covers the special case where you would like to have a pattern than applies unary
operations on the *values of keys* in the incoming stream.
Approximately, P1bind(\delta, 2*_) is the same as Pbind(\delta, 2*Pkey(\delta))
*/
Pop : Pbind {
	//closely cribbed from Pbind, but more convenient for fn application
	printOn { arg stream;
		stream << "%(%)".format(this.class, patternpairs.join(","));
	}	
	hash { ^([this.class.name] ++ this.storeArgs).hash }
	== {|that| 
		^(this.hash==that.hash)
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
	// compose Pops
	<> { arg that;
		^(that.isKindOf(this.class).not).if(
			{
				//This is the implementation from Pattern
				//am not sure how to call super with weird method names like <>
				Pchain(this, that)
			}, {
				//First, copy 'im.
				var composedPop = Event.newFrom(that.patternpairs);
				//now, compose all sub operations.
				patternpairs.pairsDo({|key, lefttransform|
					var righttransform = composedPop.at(key) ?? {Affine1(1)};
					//Special case non-composable things here by presuming them constant.
					//This gives us a convenient way to straight-out overwriting keys with constants.
					var composedTransform = case
						 { lefttransform.respondsTo('<>').not } {lefttransform}
						 { righttransform.respondsTo('<>').not} {lefttransform.value(righttransform)}
						 { true } {lefttransform <> righttransform };
					composedPop.put(key, composedTransform);
				});
				that.class.new(*(composedPop.getPairs.flat));
			}
		);
	}
}
