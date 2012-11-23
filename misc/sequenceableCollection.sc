+ SequenceableCollection {
	reverseReduce { arg operator;
		//reduce, but backwards. Handy for non-associative operators
		var result = this.last, len = this.size;
		if(len==1){ ^result }; //because for loops run at least once. pfft.
		for (2, len, {|i|
			result =  operator.applyTo(this[len-i], result);
		});
		^result
	}
	
}