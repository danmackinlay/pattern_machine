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
}

for p in xrange(12):
    for t in xrange(8):
        note_obs_table_description['p%i-%i' % (p, t)] = tables.Int32Col()

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
        encode_recence_data(max_age=2.0, output_filename=output_filename)
    return tables.open_file(output_filename, 'r').get_node('/','note_obs_meta')

def encode_recence_data(max_age=2.0, output_filename, input_filenae):
    global obs_counter
    obs_counter = 0
    
    time_window = set()
    now = 0.0
    
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

        for next_event in note_event_table:
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
                    bases[rel_pitch] = bases[rel_pitch] + this_recence
                    
                result = 0
                if next_pitch == local_pitch:
                    result = 1
                                
                note_obs_table.row['file'] = next_event['file']
                note_obs_table.row['time'] = next_event['time']
                note_obs_table.row['obsId'] = obs_counter
                note_obs_table.row['eventId'] = next_event['eventId']
                note_obs_table.row['pitch'] = next_event['pitch']
                note_obs_table.row['result'] = result
                for p in xrange(12):
                    for t in xrange(8):
                        note_obs_table.row[r_name_for_p[p]] = bases[p]
                note_obs_table.row.append()
                obs_counter += 1
            
            #for the next time step, we need to include the new note:
            time_window.add((now, next_pitch))

        col_table = note_obs_table_handle.create_table('/', 'col_names',
            {'p': tables.IntCol(1), 'rname': tables.StringCol(5)})
        for i in sorted(r_name_for_p.keys()):
            col_table.row['p'] = p
            col_table.row['rname'] = r_name_for_p[p]
            col_table.row.append()

        note_obs_table.attrs.maxAge = max_age
