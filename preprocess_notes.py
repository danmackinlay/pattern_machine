from math import floor
import tables
import warnings
from config import *
from serialization import write_sparse_hdf
import numpy as np
import scipy as sp
from scipy.sparse import coo_matrix, dok_matrix, csc_matrix

note_obs_table_description = {
    'result': tables.IntCol(dflt=0), #success/fail
    'file': tables.StringCol(50), # factor: which sourcefile
    'time': tables.FloatCol(), # event time
    'pitch': tables.UIntCol(), # midi note number for central pitch
    'obsId': tables.UIntCol(), #  for matching with the other data
    'eventId': tables.UIntCol(), # working out which event cause this
    'diameter': tables.UIntCol(), # number of notes consider in event changes observation base rate
}



def get_recence_data(cache=True):
    if not cache:
        try:
            os.unlink(NOTE_OBS_TABLE_PATH)
        except OSError, e:
            print e
            pass
    if not os.path.exists(NOTE_OBS_TABLE_PATH):
        encode_recence_data()
    return tables.open_file(NOTE_OBS_TABLE_PATH, 'r')

def encode_recence_data():
    global obs_counter
    obs_counter = 0

    # for building (redundent) spare representations
    flat_p_list = []
    flat_obs_list = []
    flat_recence_list = []
        
    with tables.open_file(NOTE_OBS_TABLE_PATH, 'w') as note_obs_table_handle, tables.open_file(NOTE_EVENT_TABLE_PATH, 'r') as note_event_table_handle:
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
        
        note_times = dict()

        for next_event in note_event_table:
            next_time_stamp = next_event['time']
            next_pitch = next_event['pitch']
            # first we increment time, which involves deleting notes too old to love
            for this_note, this_time_stamp in note_times.items():
                if next_time_stamp-this_time_stamp>MAX_AGE:
                    del(note_times[this_note])
            
            domain = set(note_times.keys() + [next_pitch])
            #now we record what transitions have just happened, conditional on the local env
            top = max(domain) + NEIGHBORHOOD_RADIUS + 1 
            bottom = (min(domain) - NEIGHBORHOOD_RADIUS)
            diameter = top - bottom
    
            for local_pitch in xrange(bottom, top):
                # count how many predictors we actually have
                n_held_notes = 0

                result = 0
                if next_pitch == local_pitch:
                    result = 1

                for this_note, this_time_stamp in note_times.iteritems():
                    rel_pitch = this_note - local_pitch
                    if abs(rel_pitch) <= NEIGHBORHOOD_RADIUS:
                        n_held_notes += 1
                        this_recence = MAX_AGE - next_time_stamp + this_time_stamp
                        flat_p_list.append(rel_pitch+NEIGHBORHOOD_RADIUS) # 0-based array indexing
                        flat_recence_list.append(this_recence)
                        flat_obs_list.append(obs_counter)

                if n_held_notes==0:
                    continue
                                
                note_obs_table.row['file'] = next_event['file']
                note_obs_table.row['time'] = next_event['time']
                note_obs_table.row['obsId'] = obs_counter
                note_obs_table.row['eventId'] = next_event['eventId']
                note_obs_table.row['pitch'] = next_event['pitch']
                note_obs_table.row['diameter'] = diameter
                note_obs_table.row['result'] = result
                note_obs_table.row.append()
                obs_counter += 1
            
            #for the next time step, we need to include the new note:
            note_times[next_pitch] = next_time_stamp
        
        #OK, now we have some bonus arrays still to go; partially redundant sparse encoding of some variables:
        obs_vec = csc_matrix(
            (
                np.asarray(flat_recence_list, dtype=np.float32),
                (
                    np.asarray(flat_obs_list, dtype=np.int32),
                    np.asarray(flat_p_list, dtype=np.int32)
                )
            ),
            shape=(obs_counter, NEIGHBORHOOD_RADIUS*2+1))
        del(flat_recence_list, flat_obs_list, flat_p_list)
        
        col_table = note_obs_table_handle.create_table('/', 'col_names',
            {'i': tables.IntCol(1), 'rname': tables.StringCol(5)})
        for i in sorted(r_name_for_i.keys()):
            col_table.row['i'] = i
            col_table.row['rname'] = r_name_for_i[i]
            col_table.row.append()

        note_obs_table.attrs.maxAge = MAX_AGE
        note_obs_table.attrs.neighborhoodRadius = NEIGHBORHOOD_RADIUS

        filt = tables.Filters(complevel=5)
        obs_group = note_obs_table_handle.create_group("/", "note_obs")
        write_sparse_hdf(note_obs_table_handle,
            obs_group, obs_vec,
            filt=filt)
