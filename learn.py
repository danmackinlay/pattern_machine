import numpy as np
from pprint import pprint
import os
from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord
import csv
from heapq import heappush, heapify, heappop

# how far I look to find neighbours
# perfect 5th
NEIGHBORHOOD_RADIUS = 6
# 1 octave:
# NEIGHBORHOOD_RADIUS = 11
# 1.5 octave
# NEIGHBORHOOD_RADIUS = 17

# how much to extend notes so that even momentary ones influence the future state
# measured in... crotchets?
TIME_SMEAR = 0.125001
# Floating point is probably adequate for machine-transcribed scores.
# Could get messy for real notes.

# Doubts and caveats:
# This will possibly unduly favour notes on the edge of the range
# I wonder if it makes a difference to calculate state *change* formulae rather than on-off forumlae?
# Seems that we might not want to penalise repeating a note a lot etc
# I wonder if we want to give note 0 its own interaction term with all the others? probably.
# Also possible: discard negative data. Weight likelihood solely by positives.
# No that's crazy. but interesting idea might be to use a kernel regression system. Possible kernels (pos def?)
# # Convolution amplitude (effectively fourier comparison)
# # mutual information of square waves at specified frequency (discrete distribution!)
# # # or Pearson statistic!
# # or mutual information of wavelength countat specified frequency
# could be windowed. Real human hearing is, after all...

MIDI_BASE_PATH = os.path.expanduser('~/Music/midi/rag/')
MIDI_IN_PATH = os.path.join(MIDI_BASE_PATH, 'dillpick.mid')
MIDI_OUT_PATH = os.path.join(MIDI_BASE_PATH, 'dillpick-out.mid')
CSV_BASE_PATH = os.path.normpath("./")
CSV_OUT_PATH = os.path.join(CSV_BASE_PATH, 'dillpick.csv')

note_stream = converter.parse(MIDI_IN_PATH)
transition_heap = []

# flattening doesn't squash parallel events down or give us nice note offs
# push note ons and offs onto a heap to do this more gracefully
for next_elem in note_stream.flat.offsetMap:
    event = next_elem['element']
    #only handle Notes and Chords
    if not isinstance(event, NotRest):
        continue
    on_time = next_elem['offset']
    off_time = next_elem['endTime'] + TIME_SMEAR
    pitches = []
    if hasattr(event, 'pitch'):
        pitches = [event.pitch]
    if hasattr(event, 'pitches'):
        pitches = event.pitches
    for pitch in pitches:
        heappush(transition_heap, (on_time, 1, pitch.midi))
        heappush(transition_heap, (off_time, -1, pitch.midi))

note_transitions = []
held_notes = dict()
time_stamp = 0.0

while True:
    try:
        next_time_stamp, action, pitch = heappop(transition_heap)
    except IndexError:
        break
    time_delta = next_time_stamp - time_stamp
    this_pitch_count = held_notes.get(pitch, 0) + action
    if this_pitch_count < 0:
        print "warning, negative pitch count for %d at offset %f" % (pitch, next_time_stamp)
    if this_pitch_count > 0:
        held_notes[pitch] = this_pitch_count
    else:
        del(held_notes[pitch])

    if next_time_stamp > time_stamp:
        #time actually advanced. Aggregate data here? Or next step?
        note_transitions.append(held_notes.copy())
        print held_notes

# one possible representation of transitions
# more generally, I'd like to do this using logistic lasso regression on neighbourhoods of notes.
curr_global_state = tuple()
on_counts = dict()
off_counts = dict()
all_counts = dict()

def transition_summary(note_transitions):
    # make dict form transition summary
    for held_notes in note_transitions:
        next_global_state = tuple(sorted(held_notes.keys()))
        # we only want to look at notes within a neighbourhood of something happening
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
            #if len(neighborhood)>0:
            #    print neighborhood
        curr_global_state = tuple(next_global_state)

def all_trials(note_transitions):
    # make list of trials - easily up to 10**5/minute. Be careful.
    for held_notes in note_transitions:
        next_global_state = tuple(sorted(held_notes.keys()))
        # we only want to look at notes within a neighbourhood of something happening
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
            #if len(neighborhood)>0:
            #    print neighborhood
        curr_global_state = tuple(next_global_state)


# #Convert to arrays for regression - left columns predictors, right 2 responses
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