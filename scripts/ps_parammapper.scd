/*

*/

m=PSMetaParamMap.new;
MIDIClient.init;
MIDIClient.destinations;
t = PSParamWatcherMIDI(m, 0.05,
    MIDIOut.newByName("IAC-Driver", "Bus 1"),
);

t.addMIDIUpdater(0,5);

m.inParams;
m.set(1,-1,-1.1);
m.value;
m.phi_(0.4);
m.combinercoefs;
a=PSParamWatcher.new(m);
a.addUpdater({|val| val.postln;});
