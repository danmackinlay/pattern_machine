/*
a PSContext generalises partial application to Events. One may compose
PSContexts to one another to produce a transformed context, and to Events to
transform events.

An alternative approach that might work could be to subclass
EnvironmentRedirect from JITLib, which dispatches to a wrapped environment but
can set defaults.
*/
PSContext : IdentityDictionary {
	applyTo {|that|
		/* 
		<> composition per default operates right to left, but contexts are
		more intuitively applied left to right, and we don't want to have to patch
		Event to make this work (Which we would have to do, since that which is
		composed *with() gets to define the method.) so we make a new method which is
		basically <>, but backwards. Additionally, we assume that the values in this
		guy are functions and that we will compose by partial application instead of
		by replacing values Be careful with the order when using this guy.
		
		a b c d E should apply transforms as ((((a)b)c)d)E
		
		...hmmm. I could totally do this with an environment stack.
		*/
		(that.isKindOf(Event)).if({
			/*
			events get the transform applied to 'em.
			right now i ignore transforms with nothing to do to them.
			 that is not quite right, events have defaults. Also, some keys interact.
			see Pstretch -
			
			delta = event[\delta];
			if (delta.notNil) {
				inevent[\delta] = delta * val;
			};
			inevent[\dur] = inevent[\dur] * val;
			*/
			var transformedContext = that.class.newFrom(that);
			transformedContext.keysValuesChange({|key, value|
				var out;
				this.at(key).isNil.if({
					out = value;
				}, {
					out = this.at(key).value(value);
				});
				out;
			});
			^transformedContext;
		}, {
			//probably another PSContext. Compose the contents.
			var thisKeysOnly,thatKeysOnly,bothKeys;
			var transformedContext = that.class.new;
			bothKeys = this.keys & that.keys;
			thisKeysOnly = this.keys - bothKeys;
			thatKeysOnly = that.keys - bothKeys;
			//if this has no transformations, take that's
			thatKeysOnly.do({|key|
				transformedContext[key] = that[key];
			});
			//if that has no transformation, take this's
			thisKeysOnly.do({|key|
				transformedContext[key] = this[key];
			});
			//otherwise, compose them
			bothKeys.do({|key|
				transformedContext[key] = this[key].value(that[key]);
			});
			^transformedContext;
		});
	}
}
