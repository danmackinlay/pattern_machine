import os
from music21 import converter, instrument, midi
base = os.path.expanduser('~/Music/midi')
inpath = os.path.join(base, 'dillpick.mid')
outpath = os.path.join(base, 'dillpick-out.mid')

stream = converter.parse(inpath)

# now, I want to break out each part into note-on-note-off events
# this will probably involve the .offsetMap to be done in ful generality;

# for elem in stream.recurse():
#     pass

# For now I use the midi parser which gives us nice note-offs.
# However, it separates voice parts. 
mf = midi.translate.streamToMidiFile(stream)

# anyway, it will give us a cacnonical form for state transitions whcih we can try to analyse in various ways
note_transitions = []
# for now, just to the first track:
#for i, track in enumerate(mf.tracks):
for i, track in enumerate([mf.tracks[0]]):
    held_notes = dict()
    
    # check if it is unpitched percussion by pulling out
    # first instrumentation instruction
    # will fail if there are multiple PROGRAM_CHANGE messages
    instr_num = track.getProgramChanges()[0] 
    try:
        instr = instrument.instrumentFromMidiProgram(instr_num)
    except instrument.InstrumentException:
        instr = instrument.Instrument()
    if isinstance(instr, instrument.UnpitchedPercussion): break
    
    #OK, it plays pitches, probably. let's analyse it.
    for e in track.events:
        print e
        if e.isNoteOn():
            held_notes[e.pitch]=e.velocity
            note_transitions.append(held_notes.copy())
            print held_notes
            
        if e.isNoteOff():            
            del(held_notes[e.pitch])
            note_transitions.append(held_notes.copy())
            print held_notes

#one possible representation of transitions
curr_state = tuple()
curr_pitch_class = tuple()
state_transitions = dict()
for held_notes in note_transitions:
    next_state = tuple(sorted(held_notes.keys()))
    if len(curr_state)>0:
        lowest = curr_state[0]
    else:
        lowest = next_state[0]
    next_pitch_class = tuple([p-lowest for p in next_state])
    edge = tuple([curr_pitch_class, next_pitch_class])
    state_transitions[edge] = state_transitions.get(edge,0)+1
    
    curr_state = tuple(next_state)
    curr_pitch_class = tuple(next_pitch_class)
    
#stream.write('midi', outpath)
