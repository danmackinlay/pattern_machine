PS {
	classvar <>data;
// *initClass {
// 		data = IdentityDictionary.new;
// 	}
	*set {|key, val|
		this.addUniqueMethod(key, {val});
	}
	*unset{|key|
		this.removeUniqueMethod(key);
	}
}