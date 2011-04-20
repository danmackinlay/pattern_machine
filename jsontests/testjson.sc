/*
more tests could be shamelessly jacked from, e.g.
 http://code.google.com/p/json-sans-eval/source/browse/trunk/tests/json_sans_eval_test.html */

TestJsonParse : UnitTest {
  /*stash exemplars in a class var so they can be re-used
  in serialization tests:*/
  classvar <>q_and_a_list;
  *initClass {
    //SC complains if I do this in the classvar defn. Pfft.
    q_and_a_list = [
       ["{}", ()],
       ["[]", []],
       ["{\"x\": 4, \"y\": 5}", (\x: 4, \y: 5)],
       ["[1, 2, 3, 4, 5, 6, 7, 8, 9, -10, 12.34, 1e6]",
            [1, 2, 3, 4, 5, 6, 7, 8, 9, -10, 12.34, 1e6]],
       ["{ \"foo\": null }", (\foo: nil)]
     ];
  }
  test_parsing {
    q_and_a_list.do({ arg q_and_a ;
      var json_str, sc_obj;
      # json_str, sc_obj = q_and_a;
      this.assertEquals(JsonParser.parse(json_str), sc_obj);
    });
  }
}

