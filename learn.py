import numpy as np
from pprint import pprint
import os
from music21 import converter, instrument, midi
import csv
# how far I look to find neighbours
# perfect 5th
NEIGHBORHOOD_RADIUS = 6
# 1 octave:
# NEIGHBORHOOD_RADIUS = 11
# 1.5 octave
#NEIGHBORHOOD_RADIUS = 17

MIDI_BASE_PATH = os.path.expanduser('~/Music/midi')
MIDI_IN_PATH = os.path.join(MIDI_BASE_PATH, 'dillpick.mid')
MIDI_OUT_PATH = os.path.join(MIDI_BASE_PATH, 'dillpick-out.mid')
CSV_BASE_PATH = os.path.normpath("./")
CSV_OUT_PATH = os.path.join(CSV_BASE_PATH, 'dillpick.csv')

note_stream = converter.parse(MIDI_IN_PATH)

# now, I want to break out each part into note-on-note-off events
# this will probably involve the .offsetMap to be done in full generality;

# for elem in note_stream.recurse():
#     pass

# For now I use the midi parser which gives us nice note-offs.
# However, it separates voice parts. 
mf = midi.translate.streamToMidiFile(note_stream)

# anyway, it will give us a canonical form for state transitions which we can try to analyse in various ways
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
# more generally, I'd like to do this using logistic lasso regression on neighbourhoods of notes.

curr_global_state = tuple()
on_counts = dict()
off_counts = dict()
all_counts = dict()

# I wonder if it makes a difference to calculate state *change* formulae rather than on-off forumlae?
#  Seems that we might not want to penalise repeating a note a lot etc
# I wonder if we want to give note 0 its own interaction term with all the others? probably.

# make a sparse dict of transitiona
for held_notes in note_transitions:
    next_global_state = tuple(sorted(held_notes.keys()))
    #we only want to look at notes within a neighbourhood of something happening
    # otherwise nothing->nothing dominates the data
    domain = set(curr_global_state + next_global_state)
    for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain)+NEIGHBORHOOD_RADIUS+1):
        neighborhood = []
        # find ON notes:
        for i in curr_global_state:
            rel_pitch = i - local_pitch
            if abs(rel_pitch)<=NEIGHBORHOOD_RADIUS:
                neighborhood.append(rel_pitch)
        neighborhood = tuple(neighborhood)
        all_counts[neighborhood] = all_counts.get(neighborhood,0)+1
        if local_pitch in next_global_state:
            on_counts[neighborhood] = on_counts.get(neighborhood,0)+1
        else:
            off_counts[neighborhood] = off_counts.get(neighborhood,0)+1
        if len(neighborhood)>0:
            print neighborhood
    curr_global_state = tuple(next_global_state)

# #Convert to arrays for regression - left columns predictors, right 2 variates
# predictors = np.zeros((len(all_counts), 2*NEIGHBORHOOD_RADIUS+1), dtype='int32')
# regressors = np.zeros((len(all_counts), 2), dtype='int32')
# for i, predictor in enumerate(sorted(all_counts.keys())):
#     predictors[i][np.array(predictor, dtype='int32') + NEIGHBORHOOD_RADIUS] = 1
#     regressors[i][0] = all_counts.get(predictor, 0)
#     regressors[i][1] = on_counts.get(predictor, 0)

# But sod it; we ain't doing analysis in python right now; let's pump this out to R
fieldnames = [str(i) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] + ['ons', 'offs']
with open(CSV_OUT_PATH, 'w') as handle:
    writer = csv.writer(handle, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow(fieldnames)
    for i, predictor in enumerate(sorted(all_counts.keys())):
        writer.writerow(
          [(1 if i in predictor else 0) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] + 
          [on_counts.get(predictor, 0), off_counts.get(predictor, 0)]
        )
        