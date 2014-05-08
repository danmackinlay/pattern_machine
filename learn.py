import numpy as np
from pprint import pprint
import os
from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord
import csv
import tables
from util import total_detunedness, span_in_5ths, span_in_5ths_up, span_in_5ths_down
import random
import warnings

#TODO: compress hdf5 data.

# keep the jitter reproducible
random.seed(12345)
# how far I look to find neighbours
# perfect 5th
# NEIGHBORHOOD_RADIUS = 6
# 1 octave:
NEIGHBORHOOD_RADIUS = 11
# 1.5 octave (LARGE data set)
# NEIGHBORHOOD_RADIUS = 17

# radius of time-step function
TIME_STEP_RADIUS = 0.5
# How many to measure
TIME_STEPS = 3
MAX_AGE = TIME_STEPS*TIME_STEP_RADIUS
ROUGH_NEWNESS_THRESHOLD = max(MAX_AGE - 0.75, 0.25)

# We break chords apart by jittering
#JITTER_FACTOR = 0.0
JITTER_FACTOR = 0.01
#when calculating note rate, aggregate notes this close together (JITTER_FACTOR ignored for those)
ONSET_TOLERANCE = 0.06

#TODO:
# trim neighbourhood size at statistical analysis stage rather than re-run MIDI (low priority as this step is fast.)
# call into R using rpy2, to avoid this horrible manual way of doing things
# export inferred formula from R
# implement midi player that uses this
# could fit model condition on NUMBER OF HELD NOTES which would be faster to infer and to predict, and more accurate
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
TABLE_OUT_PATH = os.path.join(CSV_BASE_PATH, 'rag-%02d.h5' % NEIGHBORHOOD_RADIUS)

r_name_for_i = dict()
i_for_r_name = dict()

for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1):
    if i<0:
        r_name = "X." + str(abs(i))
    else:
        r_name = "X" + str(i)
    r_name_for_i[i] = r_name
    i_for_r_name[r_name] = i

table_description = {
    'success': tables.IntCol(1),
    'file': tables.StringCol(50),
}
for r_name in r_name_for_i.values():
    table_description[r_name]=tables.FloatCol()

csv_fieldnames = ["file"] + [str(i) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] +\
            ['detune', 'span', 'spanup', 'spandown'] +\
            ['ons', 'offs']

def transition_summary(note_transitions, threshold=0):
    #binomial note summary
    on_counts = dict()
    off_counts = dict()
    all_counts = dict()

    curr_held_notes = tuple()

    for held_notes in note_transitions:
        next_held_notes = tuple(sorted([n for n,t in held_notes.iteritems() if t>threshold]))
        # we only want to look at notes within a neighbourhood of something happening
        # otherwise nothing->nothing dominates the data
        domain = set(curr_held_notes + next_held_notes)
        for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain) + NEIGHBORHOOD_RADIUS+1):
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

def analyse_times(note_stream):
    # do some analysis of note inter-arrival times to check our tempo assumptions
    # not currently used, since I have removed the unusual note-times from my current data set
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
    return(mean_note_time)

# #Convert to arrays for regression - left columns predictors, right 2 responses
# predictors = np.zeros((len(all_counts), 2*NEIGHBORHOOD_RADIUS+1), dtype='int32')
# regressors = np.zeros((len(all_counts), 2), dtype='int32')
# for i, predictor in enumerate(sorted(all_counts.keys())):
#     predictors[i][np.array(predictor, dtype='int32') + NEIGHBORHOOD_RADIUS] = 1
#     regressors[i][0] = all_counts.get(predictor, 0)
#     regressors[i][1] = on_counts.get(predictor, 0)

with open(CSV_OUT_PATH, 'w') as csv_handle, tables.open_file(TABLE_OUT_PATH, 'w') as table_handle:
    csv_writer = csv.writer(csv_handle, quoting=csv.QUOTE_NONNUMERIC)
    csv_writer.writerow(csv_fieldnames)

    def write_csv_row(counts):
        on_counts, off_counts, all_counts = counts
        for i, neighborhood in enumerate(sorted(all_counts.keys())):
            csv_writer.writerow(
              [file_key] +
              [(1 if i in neighborhood else 0) for i in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] +
              [total_detunedness(neighborhood), span_in_5ths(neighborhood),
                span_in_5ths_up(neighborhood), span_in_5ths_down(neighborhood)] +
              [on_counts.get(neighborhood, 0), off_counts.get(neighborhood, 0)]
            )
    #ignore warnings for that bit; I know my column names are annoying.
    with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        table = table_handle.create_table('/', 'note_transitions', table_description)

    def write_table_row(note_times, next_time_stamp, next_note, file_key):
        domain = set(note_times.keys() + [next_note])

        #now we regress what transitions have just happened, conditional on the local env
        for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain) + NEIGHBORHOOD_RADIUS+1):
            # create a new row for each local note environment
            table.row['file'] = file_key

            for this_note, this_time_stamp in note_times.iteritems():
                rel_pitch = next_note - local_pitch
                if abs(rel_pitch) <= NEIGHBORHOOD_RADIUS:
                    table.row[r_name_for_i[rel_pitch]] = MAX_AGE - next_time_stamp + this_time_stamp
                if rel_pitch == 0:
                    table.row['success'] = 1
                else:
                    table.row['success'] = 0
            table.row.append()

    def parse_midi_file(base_dir, midi_file, per_file_counts):
        """workhorse function
        does too much, for reasons of efficiency
        plus the inconvenient os.path.walk API"""
        midi_in_file = os.path.join(base_dir, midi_file)
        file_key = midi_in_file[len(MIDI_BASE_DIR):]
        print "parsing", file_key
        note_stream = converter.parse(midi_in_file)
        note_transitions = []
        note_times = dict()

        for next_elem in note_stream.flat.notes.offsetMap:
            event = next_elem['element']
            #only handle Notes and Chords
            if not isinstance(event, NotRest):
                continue
            on_time = next_elem['offset']
            if hasattr(event, 'pitch'):
                pitches = [event.pitch.midi]
                on_times = [on_time]
            if hasattr(event, 'pitches'):
                pitches = [p.midi for p in event.pitches]
                #insert a small jitter here to break chords apart, random-style
                on_times = sorted([(on_time + JITTER_FACTOR*random.random(), p) for p in pitches])
                #TODO: restore the old strum-style chord breaking.

            for next_time_stamp, next_note in on_times:
                # first we increment time, which involves deleting notes too old to love
                for this_note, this_time_stamp in note_times.items():
                    if next_time_stamp-this_time_stamp>MAX_AGE:
                        del(note_times[this_note])

                #table writer can have a bash
                write_table_row(note_times, next_time_stamp, next_note, file_key)

                #for the next time step, we need to include the new note:
                note_times[next_note] = next_time_stamp

                # For the CSV file we append the next note to the transition info
                # NB this means that CSV ignores the note's own prior state, a difference with the full data.
                next_transition = dict([
                    (this_note, MAX_AGE - next_time_stamp + this_time_stamp)
                    for this_note, this_time_stamp in note_times.iteritems()
                ])

        # CSV writer can haz pound of flesh
        write_csv_row(transition_summary(note_transitions, ROUGH_NEWNESS_THRESHOLD))

        #keep data around despite ourselves
        per_file_counts[file_key] = list(note_transitions)

    def parse_if_midi(transitions, file_dir, file_list):
        for f in file_list:
            if f.lower().endswith('mid'):
                parse_midi_file(file_dir, f, transitions)

    transitions = dict()
    os.path.walk(MIDI_BASE_DIR, parse_if_midi, transitions)

def get_table():
    table_handle = tables.open_file(TABLE_OUT_PATH, 'r')
    return table_handle.get_node('/', 'note_transitions')
