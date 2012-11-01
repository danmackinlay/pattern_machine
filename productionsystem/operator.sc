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