Server.default = s = ~serverboot.(\local, \builtin);
/*
Some Unit Tests
*/
TestPSEventOperator.run(false, false);
TestPSProductionCoding.run(false, false);
/*
This is the API I want to approximate.

Here I will, for my own sanity, use \CAPITALS for things I intend to be preterminals,
and \lowercase for terminals (i.e. operators or atoms).
This is not enforced by code; you can use whatever convention you'd like.
Things that have no rules are terminals.
A terminal is anything without a rewrite rule. Everything else is a Preterminal.
*/

*/
(
~productions = PSProductionRuleSet.new;
~productions.add(\A, 2, [\B, \A]);
~productions.add(\A, 3, [\c, \A]);

//productions.add(\A, 10, [\c, [\A, \d]]); // This one should branch.

~productions.rules;
~productions.weights;
~productions.cdfs;
~productions.next(\A);

~productions.next(\A); //returns [\B, \A] with probability 0.4, [\c, \A] with probability 0.6
~productions.next(\A, 0.39);//returns [\B, \A]
~productions.next(\A, 0.99);//returns [\c, \A]
~productions.isTerminal(\A); //false
~productions.isTerminal(\B); //false
~productions.isTerminal(\c); //true

~productions = PSProductionRuleSet.new;
~productions.add(\A, 1, [\a, \B]);
~productions.add(\B, 1, [\b, \C]);
~productions.add(\C, 1, [\c]);
~symbolStream = ~productions.asStream(\A);
~symbolStream.next; // \a
~symbolStream.next; // \b
~symbolStream.next; // \c
~symbolStream.next; // nil

~productions.add(\c, 1, [\d, \A]);
~symbolStream = ~productions.asStream(\A);
~symbolStream.next; // \a
~symbolStream.next; // \b
~symbolStream.next; // \d
~symbolStream.next; // \a
~symbolStream.next; // \b
~symbolStream.next; // \d

~symbolStream = ~productions.asStream(\A);
//can we smash the stack by recursing in this fashion?
~manySteps = 999.collect({~symbolStream.next;});
[\a, \b, \d].dup(333).flat == ~manySteps; //true. So apparently we cannot.
//how does this generalise to polyphony?
~manySteps = nil;

//Now, how to do the next bit?
//i.e. Turning a stream of symbols into a stream of events with nested context.
~coding = PSProductionCoding.new;
/*
////Pattern-style
//operator coding
~coding[\a] = [\operator, Pbindf(_, \pitch, Pkey(\pitch) +2)];
~coding[\b] = [\operator, Padd(\pitch, 3, _)];
//atom coding
~coding[\d] = [\atom, (\dur:1, \pitch: 64, \instrument: \test,)];
*/

////pseudoevent-style
// Feels more natural, but requires more code and is less general
// What if the alteration to pitch should depend on duration?

//operator coding
~coding[\a] = PSEventOperator(\pitch, _+2);
~coding[\b] = PSEventOperator(\pitch, _+3);
//atom coding
~coding[\d] = (\dur:1, \pitch: 60, \instrument: \test);

~eventStream = PSProductionPlayer(~symbolStream, ~coding).asStream;
~eventStream.next; //(\dur:1, \pitch: 65, \instrument: \test);
~eventStream.next; //(\dur:1, \pitch: 70, \instrument: \test);
/*
but this isn't quite right, is it? sometimes we have operators applying to Preterminals, and it seems natural in that case that the operations should apply to the whole content, yes? More generally, we want to be able to apply it to a given range. we want a turtle/L-system like push-pop pair of operators. probably '(' and ')' - pity the \ syntax doesn't work for those.
So what we probably wish to have is the Kleene star for repetition raither than tail recursion, so that the stack can get popped. (It woudl be nice to support tail recursion as well while recognising its PITA nature, and likelihood of most operators diverging in the long run under repeated application. Nah, fuck it.)

*/


)
/*
We will likely need affine transform objects to hold the current transform context.
This is  so that affine functions can be curried without wasting stack.
Maybe I can get away without those for now and build something optimised for affine transforms as needed.
Also, memoisation might get us there (?).

Should we be able to play Patterns in Contexts as well?
Would be lots of work; ignore for now.
Work around by playing events with recursive patterns Prewrite-style

These operators and atoms will be composed by something like <>?
No, it is close but not right.

There is an asymmetry here - the (time)shift operator.
Since  productions need to schedule themselves
they need to have an idea of setting a note length
Time passes without my help so that "state" is managed,
after a fashion, automatically.

This is surprisingly fiddly, because Events have default values. See also Pstretch for some default value complexities.
Perhaps those cases could be handled by subclassing PSEventOperator to
enact more complex behaviour.

We would like state to collapse for us into polite flat context dictionaries.
The context should be enough to know which note to play on next, and what default params to be working with.
We can't really keep stacks of the fucking things lying about forever,
so it would be nice to know how much to keep.

This might need a StatefulEvent, which should emit a PLazyEnvirN that transforms patterns appropriately.
or a PeventMod.

A pity, because otherwise Environment has great stack push/pop methods that would be
easy to work with. Maybe we still could?
*/


/*
 *other implementations
 */
String.rewrite
Plsys
Prewrite
Quarks.gui
redUniverse LSystem
	http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/A-question-abour-LazyLindenmayer-from-MathLib-http://www.fredrikolofsson.com/f0blog/?q=node/388
		file://localhost/Users/dan/Library/Application%20Support/SuperCollider/quarks/NatureToolkit/LSys/Help/LSys.html
PpatRewrite:
	http://www.dewdrop-world.net/words/blog5.php/2011/05/01/neo-complexity-rhythm-generator
	file://localhost/Users/dan/Library/Application%20Support/SuperCollider/quarks/dewdrop_lib/ddwPatterns/Help/PpatRewrite.html
	only appears to rewrite values, not whole events

//NB I have moved all the examples here to elsewhere - it's gone to productionsystem-rawevent-propotype.scd where I'm trying some more minimal approaches