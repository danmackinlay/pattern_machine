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
# NEIGHBORHOOD_RADIUS = 6
# 1 octave:
NEIGHBORHOOD_RADIUS = 11
# 1.5 octave (LARGE data set)
# NEIGHBORHOOD_RADIUS = 17

# how much to extend notes so that even momentary ones influence the future state
# measured in... crotchets?
TIME_SMEAR = 0.1251
# Floating point is probably adequate for machine-transcribed scores.
# Could get messy for real notes.
# We break cords apart by jittering based on pitch
#JITTER_FACTOR = 0.0
JITTER_FACTOR = 0.001

#TODO:
#trim neighbourhood size at statistical anlysis stage rather than re-run MIDI (low priority as this step is fast.)
# export inferred formula from R
# implement midi player that uses this
# could fit model condition on NUMBER OF HELD NOTES which woudl be faster to infer and to predict, and more accurate
# but it would fail to generalise to crazy values and be fiddlier to implement, and lose the bonus feature of being able to compare harmonicity. Would this be a problem?
# current model is very ugly - 90% of coefficients are non-zero, so something is messed up
# # could try to make python do something nicer with chords - don't conflate transitions for example, but break cords down into interleaved events. (random? or bottom-up?)
# source which track gave us which transitions and attempto to cross-valiate not on pure random folds, but on generalising to new pieces from the same genre

# Doubts and caveats:
# This will possibly unduly favour notes on the edge of the range
# Seems that we might not want to penalise repeating a note a lot etc
# We could extend and or delay notes randomly by a small amount to soften chord transitions
# Interesting idea might be to use a kernel regression system. Possible kernels (pos def?)
# # Convolution amplitude (effectively Fourier comparison)
# # mutual information of square waves at specified frequency (discrete distribution!)
# # # or Pearson statistic!
# # or mutual information of wavelength count at specified frequency
# # could be windowed. Real human hearing is, after all...

MIDI_BASE_DIR = os.path.expanduser('~/Music/midi/rag/')
CSV_BASE_PATH = os.path.normpath("./")
CSV_OUT_PATH = os.path.join(CSV_BASE_PATH, 'rag-%02d.csv' % NEIGHBORHOOD_RADIUS)

def parse_file(base_dir, midi_file, count_dicts):
    on_counts, off_counts, all_counts = count_dicts

    midi_in_file = os.path.join(base_dir, midi_file)
    note_stream = converter.parse(midi_in_file)
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
            #insert a small jitter here to break chords apart- base notes first
            jitter = JITTER_FACTOR*(pitch.midi-64.0)/64
            heappush(transition_heap, (on_time+jitter, 1, pitch.midi))
            heappush(transition_heap, (off_time+jitter, -1, pitch.midi))

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
            #time actually advanced.
            # we could randomise the tranistions that have happened,
            # or we could sort them
            # or we could do all possible combinations
            # for now, we do nothing, and instead jitter the notes using the JITTER_FACTOR
            # to break ties.
            note_transitions.append(held_notes.copy())
            print held_notes

    on_counts, off_counts, all_counts = transition_summary(note_transitions, (on_counts, off_counts, all_counts))

def transition_summary(note_transitions, count_dicts):
    on_counts, off_counts, all_counts = count_dicts
    # make transition dict from transition summary
    curr_global_state = tuple()
    
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
        curr_global_state = tuple(next_global_state)
    
    return on_counts, off_counts, all_counts

def parse_if_midi(count_dicts, file_dir, file_list):
    print (count_dicts, file_dir, file_list)
    for f in file_list:
        if f.lower().endswith('mid'):
            print "parsing", f
            parse_file(file_dir, f, count_dicts)

on_counts = dict()
off_counts = dict()
all_counts = dict()

os.path.walk(MIDI_BASE_DIR, parse_if_midi, (on_counts, off_counts, all_counts))

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