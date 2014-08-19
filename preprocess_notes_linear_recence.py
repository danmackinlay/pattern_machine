"""
Walk through a note-event data set and generate some decaying factor levels based on time.
I think I'll assume circular tuning for the moment
"""

from math import floor
import tables
import warnings
from config import *
from serialization import write_sparse_hdf
import numpy as np
import scipy as sp
from scipy.sparse import coo_matrix, dok_matrix, csc_matrix
from heapq import heappush, heappop

note_obs_table_description = {
    'result': tables.IntCol(dflt=0), #success/fail
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.Float32Col(), # event time
    'pitch': tables.UIntCol(), # midi note number for central pitch
    'obsId': tables.UIntCol(), #  for matching with the other data
    'eventId': tables.UIntCol(), # working out which event cause this
    'p0': tables.Float32Col(), # note  0-based float signal
    'p1': tables.Float32Col(), # note  1-based float signal
    'p2': tables.Float32Col(), # note  2-based float signal
    'p3': tables.Float32Col(), # note  3-based float signal
    'p4': tables.Float32Col(), # note  4-based float signal
    'p5': tables.Float32Col(), # note  5-based float signal
    'p6': tables.Float32Col(), # note  6-based float signal
    'p7': tables.Float32Col(), # note  7-based float signal
    'p8': tables.Float32Col(), # note  8-based float signal
    'p9': tables.Float32Col(), # note  9-based float signal
    'p10': tables.Float32Col(), # note 10-based float signal
    'p11': tables.Float32Col(), # note 11-based float signal
}


def get_recence_data(
        max_age=2.0,
        input_filename=NOTE_EVENT_TABLE_PATH,
        output_filename=NOTE_OBS_TABLE_PATH,
        cached=True):
    if not cached:
        try:
            os.unlink(output_filename)
        except OSError, e:
            print e
            pass
    if not os.path.exists(output_filename):
        encode_recence_data(
            max_age=max_age,
            input_filename=input_filename,
            output_filename=output_filename)
    return tables.open_file(output_filename, 'r').get_node('/','note_obs_meta')

def encode_recence_data(output_filename, input_filename, max_age=2.0, ):    
    with tables.open_file(output_filename, 'w') as note_obs_table_handle, tables.open_file(input_filename, 'r') as note_event_table_handle:
        #ignore warnings for that bit; I know my column names are annoying.
        with warnings.catch_warnings():
            warnings.simplefilter("ignore")
            note_obs_table = note_obs_table_handle.create_table(
                '/', 'note_obs_meta',
                note_obs_table_description,
                filters=tables.Filters(complevel=1))
        note_event_table = note_event_table_handle.get_node(
            '/', 'note_event_meta'
        )
        obs_counter = 0
        time_window = set()
        now = 0.0
        current_song = ""
        for next_event in note_event_table:
            if current_song != next_song:
                time_window = set()
                now = 0.0
            next_now = next_event['time']
            delta_time = next_now - now
            now = next_now
            next_pitch = next_event['pitch'] % 12
            
            for this_event in list(time_window):
                note_time, note_pitch = this_event
                if now-note_time>max_age:
                    time_window.remove(this_event)
            
            for local_pitch in xrange(12):
                bases = [0.0] * 12

                for note_time, note_pitch in time_window:
                    rel_pitch = (note_pitch - local_pitch) % 12
                    this_recence = (max_age - now + note_time)
                    bases[rel_pitch] += this_recence
                    
                result = 0
                if next_pitch == local_pitch:
                    result = 1
                                
                note_obs_table.row['file'] = next_event['file']
                note_obs_table.row['time'] = next_event['time']
                note_obs_table.row['obsId'] = obs_counter
                note_obs_table.row['eventId'] = next_event['eventId']
                note_obs_table.row['pitch'] = next_event['pitch']
                note_obs_table.row['result'] = result
                for p in xrange (12):
                    note_obs_table.row[r_name_for_p[p]] = bases[p]
                note_obs_table.row.append()
                obs_counter += 1
            
            #for the next time step, we need to include the new note:
            time_window.add((now, next_pitch))

        note_obs_table.attrs.maxAge = max_age
