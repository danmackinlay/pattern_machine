from pprint import pprint
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
        if e.isNoteOn():
            held_notes[e.pitch]=e.velocity
            note_transitions.append(held_notes.copy())
            
        if e.isNoteOff():            
            del(held_notes[e.pitch])
            note_transitions.append(held_notes.copy())
            
# one possible representation of transitions
# more generally, I'd like to do this using regression on neighbourhoods of notes.
curr_state = set()
curr_pitch_class = set()
note_on_transitions = dict()
note_off_transitions = dict()
for held_notes in note_transitions:
    next_state = set(held_notes.keys())
    if len(curr_state)>0:
        lowest = min(curr_state)
    else:
        lowest = min(next_state)
    curr_pitch_class = set([p-lowest for p in curr_state])
    next_pitch_class = set([p-lowest for p in next_state])
    state_key = tuple(sorted(curr_pitch_class))
    if len(next_pitch_class)>len(curr_pitch_class):
        #added a note
        note_added = (next_pitch_class - curr_pitch_class).pop()
        edges = note_on_transitions.setdefault(state_key, dict())
        edges[note_added] = edges.get(note_added,0)+1
    elif len(next_pitch_class)<len(curr_pitch_class):
        #removed a note
        note_removed = (curr_pitch_class - next_pitch_class).pop()
        edges = note_off_transitions.get(state_key, dict())
        edges[note_removed] = edges.get(note_removed,0)+1

    curr_state = set(next_state)
    
#stream.write('midi', outpath)
