(
~globalOuts = Bus.new(\audio, 0, 2);
Sample.dir = "/Users/dan/Library/Application Support/Ableton/Library/Samples/";
~sample = Sample.new("tests/cariboutesque.aif");
~instr = Instr("genosynth.defaultinstr");
~genosynth = Genosynth.new(~instr, []);
~genosynth = Genosynth.new;
~phenosynth=~genosynth.spawn;
~phenosynth.age;
~phenosynth.fitness;
~phenosynth.triggers;
//~phenosynth.voxPatch.play;
~phenosynth.play;
~phenosynth.reportingListenerPatch.play;
~phenosynth2=~genosynth.spawn;
~phenosynth2.voxPatch.play;
~phenosynth2.reportingListenerPatch.play;
~phenosynth2.fitness;
~phenosynth2.chromosome;
~phenosynth2.age;
~phenosynth.dump;
~phenosynth.class.dumpInterface;
Phenosynth.dumpInterface;
~phenosynth=~genosynth.spawnNaked;
~phenosynth.reportingListenerPatch.gui;
~phenosynth2.reportingListenerPatch.gui;
)
(
[\phenosynth, \vox, \default].asInstr;
Instr('vox.default');
[\combos2,\dustedDelayed].asInstr;
Instr.loadAll;
)
HOWTO proceed:
--  http://new-supercollider-mailing-lists-forums-use-these.2681727.n2.nabble.com/Instr-Patch-and-some-machine-listening-tp6519284p6522975.html --

        I've been looking at doing some machine listening in SC, using Instr's
        sweet, sweet reflection capabilities to listen to the output of a
        patch and classify it at the same time as I play it - that is, I would
        like to make the output of the Patch be audible both through my
        soundcard outputs, and to the input of the Instr that will do the
        machine listening. However, I can't get my head around how to patch
        that together. I get either stubborn silence through my speakers, or
        errors from my code. I'd really appreciate some guidance from the
        patching ninjas on this one.
        
         I'd like to take a Patch instance (call it "voxPatch") and an Instr
        which analyses it (call it "listener") outputting a signal to
        indicate, e.g. how well its inputs correlate with a specified signal.
        I'd like to get that signal back to the client so I can tweak my synth
        parameters based upon its value. I don't want to hear the output of
        "listener", which might be mostly DC - but I do want to poll its value
        on the client side, and i do want to hear the output of voxPatch, on
        some bus or other.

    the kr patch wouldn't be audible anyway, it plays on its own kr bus...
    
    you can use patch.bus to get its bus
    
    and I think you can pass patch.bus to another patch as an input arg
    
    the difference being that if you passed the patch to another patch then
    it would be a child
    
    but if you passed just its bus then it just reads from the bus and you
    need to start the patch separately.
