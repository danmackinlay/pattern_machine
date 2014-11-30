//Library-like, terse method namespace
PS {
	classvar <>data;
	*put {|key, val|
		this.addUniqueMethod(key, {val});
	}
	*remove{|key|
		this.removeUniqueMethod(key);
	}
}