+ Boolean {
	/* HAck to allow Boolean to gracefully behave in SCLang how it does in scsynth,
	*/
	* {|that| ^this.asInteger * that }
	/ {|that| ^this.asInteger / that }
	+ {|that| ^this.asInteger + that }
	- {|that| ^this.asInteger + that }
}
