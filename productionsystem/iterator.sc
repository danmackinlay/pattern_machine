PSIterator {
	//syntactic sugar to define iterator routines easily.
	//could be made more informative
    *new {|iterable|
        ^Routine({iterable.do(_.yield)});
    }
}
PSReverseIterator {
	//syntactic sugar to define iterator routines easily.
	//could be made more informative
    *new {|iterable|
        ^Routine({iterable.reverseDo(_.yield)});
    }
}