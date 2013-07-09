Vowel
Vowel.formLib.at(\a)
Vowel.formLib.at(\a, \bass)
Vowel.formLib.at(\a, \bass, \freq)
Vowel.formLib.postTree;

(
x = SynthDef(\vowel, {|freq = 420|
    Out.ar(0,
        Formants.ar(
			freq.lag(0.1),
			Vowel(\a).addControls(lag: 1)
		) * 0.01
    )
}).play;
)

x.setn(*([\freq, exprand(100, 1000)] ++ Vowel(\u, \soprano).asKeyValuePairs));
x.setn(*([\freq, exprand(100, 500)] ++ Vowel(\e, \bass).asKeyValuePairs));
x.setn(*([\freq, exprand(400, 1000)] ++ Vowel(\a, \soprano).asKeyValuePairs));
Vowel(\e, \soprano)