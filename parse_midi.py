from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord
from random import randint, sample
from math import floor
import tables
import warnings

from config import *

note_table_description = {
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'thisNote': tables.UIntCol(), # midi note number for central pitch
    'eventId': tables.UIntCol(), # working out which event cause this
}

def get_recence_data(cache=True):
    global event_counter, obs_counter
    event_counter = 0
    obs_counter = 0
    obs_list = []
    p_list = []
    #"pandas lite"
    obs_meta = dict(
        file=[],
        time=[],
        obsId=[],
        eventId=[],
        thisNote=[],
        diameter=[],
        result=[],
        b4=[],
        b3=[],
        b2=[],
        b1=[]
    )
    recence_list = []
    mean_pitch_rate = [0.0] * 128
    curr_delta = 0.0
    
    def fan_out_event(note_times, next_time_stamp, next_note, file_key):
        global event_counter, mean_pitch_rate, obs_counter
        """turn one event into a set of observations - one of which is a success.
        Send this to a file."""
        domain = set(note_times.keys() + [next_note])

        #now we record what transitions have just happened, conditional on the local env
        top = max(domain) + NEIGHBORHOOD_RADIUS + 1 
        bottom = (min(domain) - NEIGHBORHOOD_RADIUS)
        diameter = top - bottom
        
        for local_pitch in xrange(bottom, top):
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
                #map bar pos to (0,15] ; this is more convenient to interpret
                barcode = int(floor(((next_time_stamp + 1.0/8) % 4.0 ) * 4.0))
                obs_meta['file'].append(file_key)
                obs_meta['time'].append(next_time_stamp)
                obs_meta['obsId'].append(obs_counter)
                obs_meta['eventId'].append(event_counter)
                obs_meta['thisNote'].append(local_pitch)
                obs_meta['diameter'].append(diameter)
                obs_meta['result'].append(result)
                # map the barcode to reflct our suspicion that downbeats are more constrained
                # 1111 0111 1011 0011 ...
                obs_meta['b1'].append(1 - (barcode & 1))
                obs_meta['b2'].append(1 - (barcode & 2) /2)
                obs_meta['b3'].append(1 - (barcode & 4) /4)
                obs_meta['b4'].append(1 - (barcode & 8) /8)
                obs_counter += 1

    def parse_midi_file(base_dir, midi_file):
        """workhorse function
        does too much, for reasons of efficiency
        plus the inconvenient os.path.walk API"""
        global event_counter
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
                event_counter += 1

    def parse_if_midi(_, file_dir, file_list):
        for f in file_list:
            if f.lower().endswith('mid'):
                parse_midi_file(file_dir, f)

    os.path.walk(MIDI_BASE_DIR, parse_if_midi, None)
    
    return (
        obs_meta,
        dict(
            obs_list = obs_list,
            p_list = p_list,
            recence_list = recence_list,
        )
    )

def get_note_table(cache=True):
    if not cache:
        try:
            os.unlink(NOTE_TABLE_PATH)
        except OSError, e:
            print e
            pass
    if not os.path.exists(NOTE_TABLE_PATH):
        encode_notes()
    return tables.open_file(NOTE_TABLE_PATH, 'r')

def encode_notes():
    global event_counter
    event_counter = 0

    def parse_midi_file(base_dir, midi_file):
        """workhorse function
        does too much, for reasons of efficiency
        plus the inconvenient os.path.walk API"""
        global event_counter
        midi_in_file = os.path.join(base_dir, midi_file)
        file_key = midi_in_file[len(MIDI_BASE_DIR):]
        print "parsing", file_key
        note_stream = converter.parse(midi_in_file)

        for next_elem in note_stream.flat.notes.offsetMap:
            event = next_elem['element']
            #only handle Notes and Chords
            if not isinstance(event, NotRest):
                continue
            next_time_stamp = next_elem['offset']

            if hasattr(event, 'pitch'):
                pitches = [event.pitch.midi]
            if hasattr(event, 'pitches'):
                pitches = sorted([p.midi for p in event.pitches])
                ## OR: randomize order:
                #pitches = random.sample(pitches, len(pitches))

            for next_note in pitches:
                note_table.row['file'] = file_key
                note_table.row['time'] = next_time_stamp
                note_table.row['eventId'] = event_counter
                note_table.row['thisNote'] = next_note
                #for the next time step, we need to include the new note:
                note_table.row.append()
                event_counter += 1

    def parse_if_midi(_, file_dir, file_list):
        for f in file_list:
            if f.lower().endswith('mid'):
                parse_midi_file(file_dir, f)

    with tables.open_file(NOTE_TABLE_PATH, 'w') as table_out_handle:
        #ignore warnings for that bit; I know my column names are annoying.
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            note_table = table_out_handle.create_table('/', 'note_meta',
                note_table_description,
                filters=tables.Filters(complevel=1)) 
            os.path.walk(MIDI_BASE_DIR, parse_if_midi, None)
