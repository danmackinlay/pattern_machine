from music21 import converter, instrument, midi
from music21.note import Note, NotRest, Rest
from music21.chord import Chord
import random
from random import randint, sample
import math

from config import *

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

def get_data_set():
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
                obs_meta['file'].append(file_key)
                obs_meta['time'].append(next_time_stamp)
                obs_meta['obsId'].append(obs_counter)
                obs_meta['eventId'].append(event_counter)
                obs_meta['thisNote'].append(local_pitch)
                obs_meta['result'].append(result)
                obs_meta['b4'].append((barcode & 8) /8)
                obs_meta['b3'].append((barcode & 4) /4)
                obs_meta['b2'].append((barcode & 2) /2)
                obs_meta['b1'].append((barcode & 1))
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
        ),
        mean_pitch_rate
    )


