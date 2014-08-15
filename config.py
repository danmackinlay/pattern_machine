import os.path
import random

# keep everything reproducible
random.seed(12345)
# how far I look to find neighbours
# perfect 5th
# NEIGHBORHOOD_RADIUS = 6
# 1 octave:
NEIGHBORHOOD_RADIUS = 11
# 1.5 octave (LARGE data set)
# NEIGHBORHOOD_RADIUS = 17

# All influence decays by...
MAX_AGE = 2.0

#when calculating onset statistics, aggregate notes this close together
ONSET_TOLERANCE = 0.06

MIDI_BASE_DIR = os.path.expanduser('~/Music/midi/rag/')
OUTPUT_BASE_PATH = os.path.normpath("./")
NOTE_EVENT_TABLE_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_events.h5')
NOTE_OBS_TABLE_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_obs.h5')
FEATURE_TABLE_FROM_PYTHON_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_from_python.h5')
FEATURE_TABLE_TO_PYTHON_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_to_python.h5')

MIN_FEATURE_FRAC = 10000
P_VAL_THRESH = 0.05 #loose! multiple comparison prob. But spurious effects will be regularised out. Whether we will find a *tidy* solution thereby is an open question; group penalty would be nice
MAX_N_FEATURES = 8000
MAX_FEATURE_ITER = 10000000

#Map between relative pitches, array columns and R-friendly relative pitch names
r_name_for_i = dict()
i_for_r_name = dict()
p_for_r_name = dict()
r_name_for_p = dict()

for i in xrange(2*NEIGHBORHOOD_RADIUS+1):
    p = i - NEIGHBORHOOD_RADIUS
    if p<0:
        r_name = "X." + str(abs(p))
    else:
        r_name = "X" + str(p)
    r_name_for_p[p] = r_name
    p_for_r_name[r_name] = p
    r_name_for_i[i] = r_name
    i_for_r_name[r_name] = i

csv_fieldnames = ["file"] + [r_name_for_p[p] for p in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] +\
            ['detune', 'span', 'spanup', 'spandown'] +\
            ['ons', 'offs']
