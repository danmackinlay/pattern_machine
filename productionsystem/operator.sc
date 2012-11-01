/*
A PSEventOperator generalises partial application to Events. One may compose
PSEventOperators to one another to produce a transformed PSEventOperator, and 
to Events to transform events.

An alternative approach that might work could be to subclass
EnvironmentRedirect from JITLib, which dispatches to a wrapped environment but
can set defaults.
*/
PSEventOperator : IdentityDictionary {
	*new {|...listOfPairs|
		var newCollection;
		newCollection = super.new(listOfPairs.size);
		listOfPairs.pairsDo({|k,v, i|
			newCollection.put(k,v);
		});
		^newCollection;
	}
	applyTo {|that|
		/*
		<> composition per default operates right to left, but contexts are
		more intuitively applied left to right, and we don't want to have to patch
		Event to make this work (Which we would have to do, since that which is
		composed *with() gets to define the method.) so we make a new method which is
		basically <>, but backwards. Additionally, we assume that the values in this
		guy are functions and that we will compose by partial application instead of
		by replacing values. Be careful with the order when using this guy.

		a b c d E should apply transforms as ((((a)b)c)d)E

		...hmmm. I could totally do this with an environment stack. Should.
		*/
		(that.isKindOf(Event)).if({
			/*
			events get the transform applied to 'em.
			right now i ignore transforms with nothing to do to them.
			 that is not quite right, events have defaults. Also, some keys interact.
			e.g. Pstretch:

			delta = event[\delta];
			if (delta.notNil) {
				inevent[\delta] = delta * val;
			};
			inevent[\dur] = inevent[\dur] * val;
			*/
			var transformedEvent = that.class.newFrom(that);
			transformedEvent.keysValuesChange({|key, value|
				var out;
				this.at(key).isNil.if({
					out = value;
				}, {
					out = this.at(key).value(value);
				});
				out;
			});
			^transformedEvent;
		}, {
			//probably another PSEventOperator. Compose the contents.
			var thisKeysOnly,thatKeysOnly,bothKeys;
			var transformedOperator = that.class.new;
			bothKeys = this.keys & that.keys;
			thisKeysOnly = this.keys - bothKeys;
			thatKeysOnly = that.keys - bothKeys;
			//if this has no transformations, take that's
			thatKeysOnly.do({|key|
				transformedOperator[key] = that[key];
			});
			//if that has no transformation, take this's
			thisKeysOnly.do({|key|
				transformedOperator[key] = this[key];
			});
			//otherwise, compose them
			bothKeys.do({|key|
				transformedOperator[key] = this[key].value(that[key]);
			});
			^transformedOperator;
		});
	}
}

POp : Pattern {
	var <opDict;
	*new {|...listOfPairs|
		if (pairs.size.odd, { Error("Pbind should have even number of args.\n").throw; });
		^super.newCopyArgs(Event.newFrom(listOfPairs));
	}
	printOn { arg stream;
		stream << "%%".format(this.class, opDict);
	}	
	storeArgs { ^[opDict] }
	hash { ^([this.class.name] ++ this.storeArgs).hash }
	== {|that| 
		//compare only opDict, because that is simple, and,
		// compare it as a pairs array, because Dictionary comparison ignores keys.
		^(this.class==that.class) && ((opDict.getPairs) == (that.opDict.getPairs))
	}
}