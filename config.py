import os.path
import random

# keep everything reproducible
random.seed(12345)

#when calculating onset statistics, aggregate notes this close together
ONSET_TOLERANCE = 0.06

MIDI_BASE_DIR = os.path.expanduser('~/Music/midi/rag/')
OUTPUT_BASE_PATH = os.path.normpath("./")
NOTE_EVENT_TABLE_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_events.h5')
NOTE_OBS_TABLE_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_obs.h5')
FEATURE_TABLE_FROM_PYTHON_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_from_python.h5')
FEATURE_TABLE_TO_PYTHON_PATH = os.path.join(OUTPUT_BASE_PATH, 'rag_to_python.h5')

#Map between relative pitches, array columns and R-friendly relative pitch names
p_for_r_name = dict()
r_name_for_p = dict()

for p in xrange(12):
    r_name = "p%i" % p
    r_name_for_p[p] = r_name
    p_for_r_name[r_name] = p
