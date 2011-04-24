/*
more tests could be shamelessly jacked from, e.g.
 http://code.google.com/p/json-sans-eval/source/browse/trunk/tests/json_sans_eval_test.html */

TestJsonParse : UnitTest {
  /*stash exemplars in a class var so they can be re-used
  in serialization tests:*/
  classvar <>qAndAList;
  *initClass {
    //SC complains if I do this in the classvar defn. Pfft.
    qAndAList = [
       ["[]", []],
       ["[true, false, null, true, false]", [true, false, nil, true, false]] /*,
       ["[\"foo\"]", ["foo"]],
              ["[\"bar\", \"BAZ\"]", ["bar", "BAZ"]] */ /*,
       ["{}", ()],
       ["{\"x\": 4, \"y\": 5}", (\x: 4, \y: 5)],
       ["[1, 2, 3, 4, 5, 6, 7, 8, 9, -10, 12.34, 1e6]",
            [1, 2, 3, 4, 5, 6, 7, 8, 9, -10, 12.34, 1e6]],
       ["{ \"foo\": null }", (\foo: nil)] */
     ];
  }
  test_parsing {
    var parser = JsonParser.new;
    qAndAList.do({ arg qAndA ;
      var jsonStr, nativeObj;
      "testing...".postln;
      qAndA.postln;
      # jsonStr, nativeObj = qAndA.value;
      "that is..".postln;
      jsonStr.postln;
      nativeObj.postln;
      this.assertEquals(parser.decode(jsonStr), nativeObj);
      "done!".postln;
    });
  }
}

