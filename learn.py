import os
from music21 import converter, instrument, midi
base = os.path.expanduser('~/Music/midi')
inpath = os.path.join(base, 'dillpick.mid')
outpath = os.path.join(base, 'dillpick-out.mid')

stream = converter.parse(inpath)

# now, I want to break out each part into note-on-note-off events
# this will probably involve the .offsetMap
# might be able to do with less
# really want to avoid percussion parts if i can
# for elem in stream.recurse():
#     pass

#this seems roundabout:
mf = midi.translate.streamToMidiFile(stream)
# and we still need to get instrument metadata:
# using midiEventsToInstrument
# midi.translate.midiEventsToInstrument
#for i, track in enumerate(mf.tracks):
for i, track in enumerate([mf.tracks[0]]):
    held_notes = dict()
    ons = dict()
    offs = dict()
    
    #check if it is unpitched percussion:
    instr_num = track.getProgramChanges()[0] #pull out first instrumentation instruction
    try:
        instr = instrument.instrumentFromMidiProgram(instr_num)
    except instrument.InstrumentException:
        instr = instrument.Instrument()
    if isinstance(instr, instrument.UnpitchedPercussion): break
    
    #OK, it plays pitches. let's analyse it.
    for e in track.events:
        print e
        if e.isNoteOn():
            if len(held_notes)>0:
                lowest = min(held_notes.keys())
                rel_on_pitch = e.pitch-lowest
                pitch_class = tuple(sorted([p-lowest for p in held_notes.keys()]))
                transitions = ons.setdefault(pitch_class, dict())
                transitions[rel_on_pitch]=transitions.get(rel_on_pitch,0)+1
            held_notes[e.pitch]=e.velocity
            print held_notes, transitions, ons
            
        if e.isNoteOff():            
            del(held_notes[e.pitch])
    
#stream.write('midi', outpath)
