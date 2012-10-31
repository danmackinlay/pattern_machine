Transform : AbstractFunction {
	//Abstract transform class. Exists for ease of detecting straight transforms
	//We require these to be deterministic, side-effect free, and possessed only of one (non-init-time)
	//argument, i.e. be unary.
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
}
