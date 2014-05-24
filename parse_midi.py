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
import math

from config import *

###PROBABILISTIC CONCERNS
# Am I doing this wrong? I could model odds of each note sounding conditional on environment.
# Could also model, conditional on environment, which note goes on.
# should try and attribute amt of error to each song
# I could go to AIC or BIC instead of cross validation to save CPU cycles

#### IMPLMEMENTING LINEAR MODEL
# See R packages glmnet, liblineaR, rms
# NB liblineaR has python binding
# if we wished to use non penalized regression, could go traditional AIC style: http://data.princeton.edu/R/glms.html
# OR even do hierarchical penalised regression using http://cran.r-project.org/web/packages/glinternet/index.html
# For now
# see http://www.stanford.edu/~hastie/glmnet/glmnet_alpha.html for an excellent guide
# and http://www.jstatsoft.org/v33/i01/paper

# if this DOESN'T work, could go to a discrete PGM model, such as
# http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
# https://r-forge.r-project.org/R/?group_id=1487
# gRaphHD http://www.jstatsoft.org/v37/i01/
# http://www.bnlearn.com/
# but let's stay simple.



###TODO:
# hint hdf chunk size http://pytables.github.io/usersguide/optimization.html#informing-pytables-about-expected-number-of-rows-in-tables-or-arrays
# trim data set to save time http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#how_large_the_training_set_should_be?
# use feature selection to save time? http://www.csie.ntu.edu.tw/~cjlin/libsvmtools/#feature_selection_tool
# Switch to pure python using liblinear http://www.csie.ntu.edu.tw/~cjlin/liblinear/
# save metadata:
# # MAX_AGE
# # matrix dimensions
# # source dataset
# # factor mapping
# bludgeon R into actually reading the fucking metadata Grrrr R.
# explicitly use R-happy names for CSV, for clarity
# call into R using rpy2, to avoid this horrible manual way of doing things, and also R
# could fit model condition on NUMBER OF HELD NOTES which would be faster to infer and to predict, and more accurate

### FEATURE CONCERNS
#TODO: I have a lot of data here;
# should probably throw over CV and do straight training/prediction split
# todo: fits should know own AND NEIGHBOURS' base rates
# remove rows, and disambiguate what remains. (trimming columns leads to spurious duplicates with 0 notes in)
# Add a logical feature specifying bar position; possibly fit separate models for each

# Bonus datasets I jsut noticed on http://deeplearning.net/datasets/
# Piano-midi.de: classical piano pieces (http://www.piano-midi.de/)
# Nottingham : over 1000 folk tunes (http://abc.sourceforge.net/NMD/)
# MuseData: electronic library of classical music scores (http://musedata.stanford.edu/)
# JSB Chorales: set of four-part harmonized chorales (http://www.jsbchorales.net/index.shtml)

# see also the deep learning approach: http://deeplearning.net/tutorial/rnnrbm.html#rnnrbm andd
# http://www-etud.iro.umontreal.ca/~boulanni/ICML2012.pdf

# Deep learning feels like overkill, but i feel like i could do some *un*principled feature construction;
# we suspect marginal changes in features have a linear effect, fine
# but we also suspect that interaction terms are critical;
# can we manufacture some hopefully-good features without an exhuastive, expensive, simultaneous optimisation over all of them?
# Naive approach: walk through term-interaction space, discrectized. Start with one predictor, and add additional predictors randomly (greedily) if the combination has improved deviance wrt the mean. it "feels" like features shoudl be positive or negative
# # If i wanted features that did not naturally look discrete i coudl fit minature linear models to each combination?
# # Or make features that correspond to being "near" some value
# # it seems like boolean opeartions on features should also be allowed - intersections and unions and such
# # this could be  naturally accomplished by generating each generation of eatures from the previous and ditching the crappy ones. This feels dangerously close to evolutionary algorithms, or maybe random forests or somesuch. vectorisable tho.
# I could always give up and infer hidden markov states. sigh.

# current model is ugly but works - Not guarnnteed to respect hierarchicality but seems to anyway.
# go to "time-since-last-onset" rather than midi note hold times, which are very noisy anyway. NB - large data sets.
# experiment with longer note smears
# experiment with adaptive note smearing
# I would like to capture spectrally-meaningful relations
# # such as projecting onto harmonic space
# # note that otherwise, I am missing out (really?) under-represented transitions in the data.
# # I could use Dictionary learning http://scikit-learn.org/stable/modules/decomposition.html#dictionary-learning to reduce the number of features from the combinatorial combinations (feels weird; am I guaranteed this will capture *important* features?)
# # I could use PCA - http://scikit-learn.org/stable/modules/decomposition.html#approximate-pca
# # I could use NNMF - http://scikit-learn.org/stable/modules/decomposition.html#non-negative-matrix-factorization-nmf-or-nnmf
# # TruncatedSVD also looks sparse-friendly and is linguistics-based - i.e. polysemy friendly
# Interesting idea might be to use a kernel regression system. Possible kernels (pos def?)
# # Convolution amplitude (effectively Fourier comparison)
# # mutual information of square waves at specified frequency (discrete distribution!)
# # # or Pearson statistic!
# # or mutual information of wavelength count at specified frequency
# # could be windowed. Real human hearing is, after all...
# improved feature ideas:
# # feature vector of approximate prime decomposition of ratios
# # number of held notes (nope, no good)
# # time since last note at a given relative pitch (not clear what to do with this yet)
# # span in 5ths at various time offsets (nope, didn't work)
# # f-divergence between spectral band occupancy folded onto one octave (free "smoothing" param to calibrate, slow, but more intuitive. Not great realtime...)

meta_table_description = {
    'result': tables.IntCol(1, dflt=0), #success/fail
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'thisNote': tables.UIntCol(), # midi note number for central pitch
    'obsID': tables.UIntCol(), #  for matching with the other data
    'eventID': tables.UIntCol(), # working out which event cause this
}

barcode_table_description = {
    'obsID': tables.UIntCol(), #  for matching with the other data
    'b5': tables.IntCol(1, dflt=0),
    'b4': tables.IntCol(1, dflt=0),
    'b3': tables.IntCol(1, dflt=0),
    'b2': tables.IntCol(1, dflt=0),
    'b1': tables.IntCol(1, dflt=0),
}


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

def analyze_times(note_stream):
    # do some analysis of note inter-arrival times to check our tempo assumptions
    first_event = note_stream.flat.notes.offsetMap[0]['offset']
    last_event = note_stream.flat.notes.offsetMap[-1]['offset']
    midi_length = float(last_event-first_event)
    curr_time_stamp = first_event
    pitch_rates = [0.0] * 128
    thinned_intervals = []
    for next_elem in note_stream.flat.notes.offsetMap:
        #event density stats
        event = next_elem['element']
        #only handle Notes and Chords
        if not isinstance(event, NotRest):
            continue
        next_time_stamp = next_elem['offset']
        if next_time_stamp > curr_time_stamp + ONSET_TOLERANCE:
            thinned_intervals.append(next_time_stamp-curr_time_stamp)
            curr_time_stamp = next_time_stamp
        #individual pitch density stats:
        pitches = []
        if hasattr(event, 'pitch'):
            pitches = [event.pitch.midi]
        if hasattr(event, 'pitches'):
            pitches = [p.midi for p in event.pitches]
        for p in pitches:
            pitch_rates[p] += 1.0/midi_length
    mean_event_time = sum(thinned_intervals)/len(thinned_intervals)
    return mean_event_time, pitch_rates



def parse():
    global event_counter, obs_counter
    event_counter = 0
    event_list = []
    obs_counter = 0
    obs_list = []
    p_list = []
    recence_list = []
    mean_pitch_rate = [0.0] * 128
    curr_delta = 0.0
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
            obs_table = table_handle.create_table('/', 'note_meta',
                meta_table_description,
                filters=tables.Filters(complevel=1))
            barcode_table = table_handle.create_table('/', 'note_barcode',
                barcode_table_description,
                filters=tables.Filters(complevel=1))
        col_table = table_handle.create_table('/', 'col_names',
            {'i': tables.IntCol(1), 'rname': tables.StringCol(5)})
        for i in sorted(r_name_for_i.keys()):
            col_table.row['i'] = i
            col_table.row['rname'] = r_name_for_i[i]
            col_table.row.append()

        obs_table.attrs.maxAge = MAX_AGE
        obs_table.attrs.neighborhoodRadius = NEIGHBORHOOD_RADIUS

        def fan_out_event(note_times, next_time_stamp, next_note, file_key):
            global event_counter, mean_pitch_rate, obs_counter
            """turn one event into a set of observations - one of which is a success.
            Send this to a file."""
            domain = set(note_times.keys() + [next_note])

            #now we record what transitions have just happened, conditional on the local env
            for local_pitch in xrange(min(domain)-NEIGHBORHOOD_RADIUS, max(domain) + NEIGHBORHOOD_RADIUS+1):
                # count how many predictors we actually have
                n_held_notes = 0

                # create a new row for each local note environment
                result = 0
                if next_note == local_pitch:
                    result = 1

                for this_note, this_time_stamp in note_times.iteritems():
                    rel_pitch = this_note - local_pitch
                    if abs(rel_pitch) <= NEIGHBORHOOD_RADIUS:
                        n_held_notes += 1
                        this_recence = MAX_AGE - next_time_stamp + this_time_stamp
                        p_list.append(rel_pitch+NEIGHBORHOOD_RADIUS) # 0-based array indexing
                        recence_list.append(this_recence)
                        obs_list.append(obs_counter)

                if n_held_notes>0:
                    barcode = int(math.floor((next_time_stamp % 4.0 + 0.99/8) * 4.0))
                    obs_table.row['file'] = file_key
                    obs_table.row['time'] = next_time_stamp
                    obs_table.row['obsID'] = obs_counter
                    obs_table.row['eventID'] = event_counter
                    obs_table.row['thisNote'] = local_pitch
                    obs_table.row['result'] = result
                    obs_table.row.append()
                    barcode_table.row['obsID'] = obs_counter
                    barcode_table.row['b4'] = (barcode & 8) /8
                    barcode_table.row['b3'] = (barcode & 4) /4
                    barcode_table.row['b2'] = (barcode & 2) /2
                    barcode_table.row['b1'] = (barcode & 1)
                    barcode_table.row.append()
                    obs_counter += 1

        def parse_midi_file(base_dir, midi_file):
            """workhorse function
            does too much, for reasons of efficiency
            plus the inconvenient os.path.walk API"""
            global mean_pitch_rate, event_counter
            midi_in_file = os.path.join(base_dir, midi_file)
            file_key = midi_in_file[len(MIDI_BASE_DIR):]
            print "parsing", file_key
            note_stream = converter.parse(midi_in_file)
            note_transitions = []
            note_times = dict()
            mean_event_time, mean_pitch_rate = analyze_times(note_stream)

            for next_elem in note_stream.flat.notes.offsetMap:
                event = next_elem['element']
                #only handle Notes and Chords
                if not isinstance(event, NotRest):
                    continue
                next_time_stamp = next_elem['offset']

                # first we increment time, which involves deleting notes too old to love
                for this_note, this_time_stamp in note_times.items():
                    if next_time_stamp-this_time_stamp>MAX_AGE:
                        del(note_times[this_note])

                if hasattr(event, 'pitch'):
                    pitches = [event.pitch.midi]
                if hasattr(event, 'pitches'):
                    pitches = sorted([p.midi for p in event.pitches])
                    ## OR: randomize order:
                    #pitches = random.sample(pitches, len(pitches))

                for next_note in pitches:
                    #table writer can have a bash
                    fan_out_event(note_times, next_time_stamp, next_note, file_key)

                    #for the next time step, we need to include the new note:
                    note_times[next_note] = next_time_stamp

                    # For the CSV file we append the next note to the transition info
                    # NB this means that CSV ignores the note's own prior state, a difference with the full data.
                    next_transition = dict([
                        (this_note, MAX_AGE - next_time_stamp + this_time_stamp)
                        for this_note, this_time_stamp in note_times.iteritems()
                    ])

                    event_counter += 1

            # CSV writer can haz pound of flesh
            write_csv_row(transition_summary(note_transitions, ROUGH_NEWNESS_THRESHOLD))

        def parse_if_midi(_, file_dir, file_list):
            for f in file_list:
                if f.lower().endswith('mid'):
                    parse_midi_file(file_dir, f)

        os.path.walk(MIDI_BASE_DIR, parse_if_midi, None)

        filt = tables.Filters(complevel=5)
    
        table_handle.create_carray('/','v_obsid',
            atom=tables.Int32Atom(), shape=(len(obs_list),),
            title="obsID",
            filters=filt)[:] = obs_list
        table_handle.create_carray('/','v_p',
            atom=tables.Int32Atom(), shape=(len(p_list),),
            title="pitch index",
            filters=filt)[:] = p_list
        table_handle.create_carray('/','v_recence',
            atom=tables.Float32Atom(), shape=(len(recence_list),),
            title="recence",
            filters=filt)[:] = recence_list
        table_handle.create_carray('/','v_base_rate',
            atom=tables.Float32Atom(), shape=(128,),
            title="base rate",
            filters=filt)[:] = mean_pitch_rate
        # Now, because this is easier in Python than in R, we precalc relative pitch neighbourhoods
        # BEWARE 1-BASED INDEXING IN R
        base_rate_store = table_handle.create_carray('/','v_rel_base_rate',
            atom=tables.Float32Atom(), shape=(128,2*NEIGHBORHOOD_RADIUS+1),
            title="rel base rate",
            filters=filt)
        _mean_pitch_rate_plus = [0]*NEIGHBORHOOD_RADIUS + mean_pitch_rate + [0]*NEIGHBORHOOD_RADIUS
        for i in xrange(128):
            base_rate_store[i,:] = _mean_pitch_rate_plus[i:i+(2*NEIGHBORHOOD_RADIUS+1)]
        #it would also be a very convenient time to generate exotic features here based on this sparse matrix form

