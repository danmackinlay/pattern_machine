import numpy as np
from pprint import pprint
import os
from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord
import csv
from heapq import heappush, heapify, heappop
from util import total_detunedness, span_in_5ths, span_in_5ths_up, span_in_5ths_down

# how far I look to find neighbours
# perfect 5th
# NEIGHBORHOOD_RADIUS = 6
# 1 octave:
NEIGHBORHOOD_RADIUS = 11
# 1.5 octave (LARGE data set to use raw)
# NEIGHBORHOOD_RADIUS = 17

# how much to extend notes so that even momentary ones influence the future state
# measured in... crotchets?
TIME_SMEAR = 1.5
# Floating point is probably adequate for machine-transcribed scores.
# Could get messy for real notes.
# We break cords apart by jittering based on pitch
#JITTER_FACTOR = 0.0
JITTER_FACTOR = 0.001
#when calculating note rate, aggregate notes this close together:
ONSET_TOLERANCE = 0.06


#TODO:
# trim neighbourhood size at statistical analysis stage rather than re-run MIDI (low priority as this step is fast.)
# call into R using rpy2, to avoid this horrible manual way of doing things
# export inferred formula from R
# implement midi player that uses this
# could fit model condition on NUMBER OF HELD NOTES which woudl be faster to infer and to predict, and more accurate
# but it would fail to generalise to crazy values and be fiddlier to implement.
# current model is ugly but works - Nto guarnateed to respect hierarchicality but seems to anyway.
# go to "time-since-last-onset" rather than midi note hold times, which are very noisy anyway. NB - large data sets.
# experiment with longer note smears
# experiment with adaptive note smearing
# What I really want is smoothing that favours spectrally-meaningful relations
# # such as projecting onto harmonic space
# # note that otherwise, I am missing out (really?) under-represented transitions in the data.
# # NB I should check that treating each note event as independent actually corresponds to meaningful bayesian inversion
# Doubts and caveats:
# Interesting idea might be to use a kernel regression system. Possible kernels (pos def?)
# # Convolution amplitude (effectively Fourier comparison)
# # mutual information of square waves at specified frequency (discrete distribution!)
# # # or Pearson statistic!
# # or mutual information of wavelength count at specified frequency
# # could be windowed. Real human hearing is, after all...
# improved feature ideas:
# # feature vector of approximate prime decomposition of ratios
# # number of held notes
# # time since last note at a given relative pitch
# # span in 5ths at various time offsets
# # f-divergence between spectral band occupancy folded onto one octave (free "smoothing" param to calibrate, slow, but more intuitive. Not great realtime...)

MIDI_BASE_DIR = os.path.expanduser('~/Music/midi/rag/')
CSV_BASE_PATH = os.path.normpath("./")
CSV_OUT_PATH = os.path.join(CSV_BASE_PATH, 'rag-%02d.csv' % NEIGHBORHOOD_RADIUS)

def parse_midi_file(base_dir, midi_file, per_file_counts):
    midi_in_file = os.path.join(base_dir, midi_file)
    file_key = midi_in_file[len(MIDI_BASE_DIR):]
    print "parsing", file_key
    note_stream = converter.parse(midi_in_file)
    
    # do some analysis first
    first_event = note_stream.flat.notes.offsetMap[0]['offset']
    last_event = note_stream.flat.notes.offsetMap[-1]['offset']
    midi_length = last_event-first_event
    curr_time = first_event
    thinned_intervals = []
    for ev in note_stream.flat.notes.offsetMap:
        next_time = ev['offset']
        if next_time > curr_time + ONSET_TOLERANCE:
            thinned_intervals.append(next_time-curr_time)
            curr_time = next_time
    mean_note_time = sum(thinned_intervals)/ len(thinned_intervals)
    time_step = TIME_SMEAR * mean_note_time
    print "mean inter-event time", time_step
    
    transition_heap = []

    # flattening doesn't squash parallel events down or give us nice note offs
    # push note ons and offs onto a heap to do this more gracefully
    for next_elem in note_stream.flat.notes.offsetMap:
        event = next_elem['element']
        #only handle Notes and Chords
        if not isinstance(event, NotRest):
            continue
        on_time = next_elem['offset']
        off_time = max(next_elem['endTime'], on_time + time_step)
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
            # print held_notes
            note_transitions.append(held_notes.copy())
    
    per_file_counts[file_key] = transition_summary(note_transitions)

def transition_summary(note_transitions):
    on_counts = dict()
    off_counts = dict()
    all_counts = dict()
    
    curr_held_notes = tuple()
    
    for held_notes in note_transitions:
        next_held_notes = tuple(sorted(held_notes.keys()))
        # we only want to look at notes within a neighbourhood of something happening
        # otherwise nothing->nothing dominates the data
        domain = set(curr_held_notes + next_held_notes)
        for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain)+NEIGHBORHOOD_RADIUS+1):
            neighborhood = []
            # find ON notes:
            for i in curr_held_notes:
                rel_pitch = i - local_pitch
                if abs(rel_pitch)<=NEIGHBORHOOD_RADIUS:
                    neighborhood.append(rel_pitch)
            neighborhood = tuple(neighborhood)
            
            all_counts[neighborhood] = all_counts.get(neighborhood,0)+1
            if local_pitch in next_held_notes:
                on_counts[neighborhood] = on_counts.get(neighborhood,0)+1
            else:
                off_counts[neighborhood] = off_counts.get(neighborhood,0)+1
        curr_held_notes = tuple(next_held_notes)
    
    return on_counts, off_counts, all_counts

def parse_if_midi(per_file_counts, file_dir, file_list):
    for f in file_list:
        if f.lower().endswith('mid'):
            parse_midi_file(file_dir, f, per_file_counts)

per_file_counts= dict()

os.path.walk(MIDI_BASE_DIR, parse_if_midi, per_file_counts)

# #Convert to arrays for regression - left columns predictors, right 2 responses
# predictors = np.zeros((len(all_counts), 2*NEIGHBORHOOD_RADIUS+1), dtype='int32')
# regressors = np.zeros((len(all_counts), 2), dtype='int32')
# for i, predictor in enumerate(sorted(all_counts.keys())):
#     predictors[i][np.array(predictor, dtype='int32') + NEIGHBORHOOD_RADIUS] = 1
#     regressors[i][0] = all_counts.get(predictor, 0)
#     regressors[i][1] = on_counts.get(predictor, 0)

# But sod it; we ain't doing analysis in python right now; let's pump this out to R
fieldnames = ["file"] + [str(i) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] + ['detune', 'span', 'spanup', 'spandown']+ ['ons', 'offs']

with open(CSV_OUT_PATH, 'w') as handle:
    writer = csv.writer(handle, quoting=csv.QUOTE_NONNUMERIC)
    writer.writerow(fieldnames)
    for file_key, (on_counts, off_counts, all_counts) in per_file_counts.iteritems():
        
        for i, neighborhood in enumerate(sorted(all_counts.keys())):
            writer.writerow(
              [file_key] +
              [(1 if i in neighborhood else 0) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] +
              [total_detunedness(neighborhood), span_in_5ths(neighborhood),
                span_in_5ths_up(neighborhood), span_in_5ths_down(neighborhood)] +
              [on_counts.get(neighborhood, 0), off_counts.get(neighborhood, 0)]
            )