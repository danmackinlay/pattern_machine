import os.path
#OUTPUT_BASE_PATH = os.path.normpath("./")
#CORR_PATH = os.path.join(OUTPUT_BASE_PATH, 'corr.h5')

#SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/note_sweep.aif')
SF_PATH = os.path.expanduser('~/src/sc/f_lustre/sounds/draingigm.aif')
TIME_QUANTUM = 1.0/80.0 #Analyse at ca 80Hz
BASEFREQ = 440.0
N_STEPS = 12
MIN_LEVEL = 0.001 #ignore stuff less than -60dB
MIN_MS_LEVEL = MIN_LEVEL**2
SC_SYNTH_PORT = 57110
SC_LANG_PORT = 57120
PS_CORREL_PORT = 36000
SCSYNTH_BUS_NUM = 83
N_RESULTS = 6 #need thrice this many
