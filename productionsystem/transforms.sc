Transform : AbstractFunction {
	//Abstract transform class. Exists for ease of detecting straight transforms
	//We require these to be deterministic, side-effect free, and possessed only of one (non-init-time)
	//argument, i.e. be unary.
	// We presume them to be linear too.
	//This makes them compose nicely.
	//Should this subclass UnaryOpFunction?
	//Should these compose using FunctionLists?
	isTransform{^true}
}
Affine1 : Transform {
	//A 1 dimensional affine transform
	var <mul;
	var <add;
	
	*new {|mul=1,add=0|
		^super.newCopyArgs(mul, add);
	}
	
	value{|in| ^((in * mul) + add)}
	
	printOn { arg stream;
		stream << "((_*%)+%)".format(mul, add);
	}
	
	storeArgs { ^[add, mul] }
	/*
	composeBinaryOp { arg aSelector, something, adverb;
		^BinaryOpFunction.new(aSelector, this, something, adverb);
	}
	reverseComposeBinaryOp { arg aSelector, something, adverb;
		^BinaryOpFunction.new(aSelector, something, this, adverb);
	}
	*/
	composeAffine1{|otherMul=1, otherAdd=0|
		//creates a new Affine1 equivalent to applying this one on the left to the other on the right
		^this.class.new(mul*otherMul, (otherMul*add)+otherAdd)
	}
	reverseComposeAffine1{|otherMul=1, otherAdd=0|
		//creates a new Affine1 equivalent to applying the other one on the left to this on the right
		^this.class.new(mul*otherMul, (mul*otherAdd)+add)
	}
	neg { ^this.composeAffine1(-1) }
	
	+ { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffine1(1, other)
		},{
			this.composeBinaryOp('-', other, adverb)
		})
	}
	- { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffine1(1, other.neg)
		},{
			this.composeBinaryOp('-', other, adverb)
		})
	}
	
	* { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffine1(other, 0)
		},{
			this.composeBinaryOp('-', other, adverb)
		})
	}
	/ { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffine1(other.reciprocal, 0)
		},{
			this.composeBinaryOp('-', other, adverb)
		})
	}
}
