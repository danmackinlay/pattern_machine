import os.path
import random
import tables

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
MAX_AGE = 1.5
# for the one-step model we take even less:
ROUGH_NEWNESS_THRESHOLD = max(MAX_AGE - 0.75, 0.25)

#when calculating event rate, aggregate notes this close together
ONSET_TOLERANCE = 0.06

MIDI_BASE_DIR = os.path.expanduser('~/Music/midi/rag/')
CSV_BASE_PATH = os.path.normpath("./")
CSV_OUT_PATH = os.path.join(CSV_BASE_PATH, 'rag.csv')
TABLE_OUT_PATH = os.path.join(CSV_BASE_PATH, 'rag.h5')

#Map between relative pitches, array columns and r-friendly relative pitch names
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

meta_table_description = {
    'result': tables.IntCol(1, dflt=0), #success/fail
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'thisNote': tables.UIntCol(), # midi note number for central pitch
    'obsID': tables.UIntCol(), #  for matching with the other data
    'eventID': tables.UIntCol(), # working out which event cause this
}

csv_fieldnames = ["file"] + [r_name_for_p[p] for p in xrange(-NEIGHBORHOOD_RADIUS, NEIGHBORHOOD_RADIUS+1)] +\
            ['detune', 'span', 'spanup', 'spandown'] +\
            ['ons', 'offs']
