/*
more tests could be shamelessly jacked from, e.g.
 http://code.google.com/p/json-sans-eval/source/browse/trunk/tests/json_sans_eval_test.html */

TestJson : UnitTest {
	/*stash exemplars in a class var so they can be re-used
	in deserialization and (later) serialization tests:*/
	classvar <>qAndAList;
	*initClass {
		//SC complains if I do this in the classvar defn. Pfft.
		qAndAList = [
			["[]", []],
			["[true, false, null, true, false]", [true, false, nil, true, false]],
			["[\"true\", \"fot\", \"BAZ\"]", ["true", "fot", "BAZ"]],
			["[\"foo\"]", ["foo"]],
					["[\"bar\", \"BAZ\"]", ["bar", "BAZ"]],
			["{}", ()],
			["{\"x\": \"A\", \"y\": \"b\"}", (\x: "A", \y: "b")],
			["[1, 2, 3, 4, 5, 6, 7, 8, 9, -10, 12.34, 1e6]",
					[1, 2, 3, 4, 5, 6, 7, 8, 9, -10, 12.34, 1e6]],
			["{ \"foo\": null }", (\foo: nil)],
			["[\"line\\nbreak\", \"no line\\\\nbreak\", \"tabs \\t\", \"etc \\b\\r\\f\"]",
					["line\nbreak", "no line\\nbreak", "tabs \t", "etc \b\r\f"]],
			['[\"quotes\\\"\"]'.asString, //SC's parser cries if you try this in a string
					["quotes\""]]
		 ];
	}
	test_parsing {
		qAndAList.do({ arg qAndA ;
			var jsonStr, nativeObj;
			# jsonStr, nativeObj = qAndA.value;
			this.assertEquals(JsonParser.decode(jsonStr), nativeObj);
		});
	}
	test_serialization {
		qAndAList.do({ arg qAndA ;
			var jsonStr, nativeObj;
			# jsonStr, nativeObj = qAndA.value;
			this.assertEquals(JsonSerializer.encode(nativeObj), jsonStr);
		});
	}
}

