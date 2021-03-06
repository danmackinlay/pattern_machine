Transform : AbstractFunction {
	//Abstract transform class. Exists for ease of detecting straight transforms
	//We require these to be deterministic, side-effect free, and possessed only of one (non-init-time)
	//argument, i.e. be unary.
	// We presume them to be linear too.
	//This makes them compose nicely.
	//Should this subclass UnaryOpFunction?
	//Should these compose using FunctionLists?
	//
	//I'm sure that real lazy-functional-language jockeys are facepalming at this, and fair enough.
	//
	isTransform{^true}
}
Affine1 : Transform {
	//A 1 dimensional affine transform
	var <>mul;
	var <>add;
	var <nilSafe;
	var <transformFunc;
	*new {|mul=1,add=0, nilSafe=true|
		^super.newCopyArgs(mul, add,nilSafe).init;
	}
	init {
		var basictransform = {|in| ((in * mul) + add)};
		transformFunc = basictransform;
		nilSafe.if({transformFunc = {|in| in.isNil.if({nil}, {basictransform.value(in)})}});
	}
	
	value{|in| ^transformFunc.value(in)}
	guiClass { ^Affine1Gui }
	
	printOn { arg stream;
		(add==0).if({
				stream << "(%x)".format(mul);
			}, {
				stream << "(%x+%)".format(mul, add);
			}
		)
	}	
	storeArgs { ^[mul, add] }
	hash { ^([this.class.name] ++ this.storeArgs).hash }
	== {|other| ^((other.storeArgs == this.storeArgs) && (this.class==other.class))}
	
	<> { arg that;
		^(that.isKindOf(this.class)).if(
			{
				this.reverseComposeAffineFromArgs(*(that.storeArgs))
			}, {
				//This is the implementation from AbstractFunction
				//am not sure how to call super with weird method names like <>
				{|...args| 
					this.value(that.value(*args))
				}
			}
		);
	}
	composeAffineFromArgs{|otherMul=1, otherAdd=0|
		//creates a new Affine1 equivalent to applying the other one on the left to this on the right
		^this.class.new(mul*otherMul, (otherMul*add)+otherAdd)
	}
	///Not sure this method is necessary
	reverseComposeAffineFromArgs{|otherMul=1, otherAdd=0|
		//creates a new Affine1 equivalent to applying this one on the left to the other on the right
		^this.class.new(mul*otherMul, (mul*otherAdd)+add)
	}
	neg { ^this.composeAffineFromArgs(-1) }
	
	+ { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffineFromArgs(1, other)
		},{
			this.composeBinaryOp('+', other, adverb)
		})
	}
	- { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffineFromArgs(1, other.neg)
		},{
			this.composeBinaryOp('-', other, adverb)
		})
	}
	
	* { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffineFromArgs(other, 0)
		},{
			this.composeBinaryOp('*', other, adverb)
		})
	}
	/ { arg other, adverb;
		^other.isKindOf(Number).if({
			this.composeAffineFromArgs(other.reciprocal, 0)
		},{
			this.composeBinaryOp('/', other, adverb)
		})
	}
}
