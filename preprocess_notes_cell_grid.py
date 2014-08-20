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

def get_recence_data(
        quantum=0.25,
        max_steps=9,
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
            quantum=0.25,
            input_filename=input_filename,
            output_filename=output_filename)
    return tables.open_file(output_filename, 'r').get_node('/','note_obs_meta')

def encode_recence_data(
        output_filename,
        input_filename,
        quantum=0.25,
        max_steps=9):
    note_obs_table_description = {
        'result': tables.IntCol(dflt=0), #success/fail
        'file': tables.StringCol(50), # factor: which sourcefile
        'time': tables.Float32Col(), # event time
        'pitch': tables.UIntCol(), # midi note number for central pitch
        'obsId': tables.UIntCol(), #  for matching with the other data
        'eventId': tables.UIntCol(), # working out which event cause this
    }

    for p in xrange(12):
        for t in xrange(max_steps):
            note_obs_table_description['p%ix%i' % (p, t)] = tables.Int32Col(dflt=0)
    
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
        max_age = 8.5 * quantum
        obs_counter = 0
        time_window = set()
        now = 0.0
        current_song = ""
        for next_event in note_event_table:
            next_song = next_event['file']
            if current_song != next_song:
                time_window = set()
                now = 0.0
            current_song = next_song
            
            next_now = next_event['time']
            delta_time = next_now - now
            now = next_now
            next_pitch = next_event['pitch'] % 12
            
            if delta_time > 0.0:
                for this_event in list(time_window):
                    note_time, note_pitch = this_event
                    if now-note_time >= max_age:
                        time_window.remove(this_event)
            
            for local_pitch in xrange(12):
                bases = {}
                if obs_counter % 10000==0:
                    print obs_counter

                for note_time, note_pitch in time_window:
                    rel_pitch = (note_pitch - local_pitch) % 12
                    cell_time = int((now - note_time)/quantum + 0.5)
                    if cell_time < max_steps:
                        bases[(rel_pitch, cell_time)] = bases.get((rel_pitch, cell_time), 0) + 1
                    
                result = 0
                if next_pitch == local_pitch:
                    result = 1
                                
                note_obs_table.row['file'] = next_event['file']
                note_obs_table.row['time'] = next_event['time']
                note_obs_table.row['obsId'] = obs_counter
                note_obs_table.row['eventId'] = next_event['eventId']
                note_obs_table.row['pitch'] = next_event['pitch']
                note_obs_table.row['result'] = result
                for (p, t), v in bases.iteritems():
                    note_obs_table.row['p%ix%i' % (p, t)] = v
                note_obs_table.row.append()
                obs_counter += 1
            
            #for the next time step, we need to include the new note:
            time_window.add((now, next_pitch))

        note_obs_table.attrs.maxAge = max_age
