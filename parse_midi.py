from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord
from random import randint, sample
from math import floor
import tables
import warnings
from config import *

note_event_table_description = {
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'pitch': tables.UIntCol(), # midi note number for central pitch
    'eventId': tables.UIntCol(), # working out which event cause this
}

def get_note_event_table(cache=True):
    if not cache:
        try:
            os.unlink(NOTE_EVENT_TABLE_PATH)
        except OSError, e:
            print e
            pass
    if not os.path.exists(NOTE_EVENT_TABLE_PATH):
        encode_notes()
    return tables.open_file(NOTE_EVENT_TABLE_PATH, 'r').get_node('/', 'note_event_meta')

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
                note_event_table.row['file'] = file_key
                note_event_table.row['time'] = next_time_stamp
                note_event_table.row['eventId'] = event_counter
                note_event_table.row['pitch'] = next_note
                #for the next time step, we need to include the new note:
                note_event_table.row.append()
                event_counter += 1

    def parse_if_midi(_, file_dir, file_list):
        for f in file_list:
            if f.lower().endswith('mid'):
                parse_midi_file(file_dir, f)

    with tables.open_file(NOTE_EVENT_TABLE_PATH, 'w') as note_event_out_handle:
        #ignore warnings for that bit; I know my column names are annoying.
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            note_event_table = note_event_out_handle.create_table('/', 'note_event_meta',
                note_event_table_description,
                filters=tables.Filters(complevel=1))
            os.path.walk(MIDI_BASE_DIR, parse_if_midi, None)
