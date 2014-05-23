from config import *
import numpy as np
import scipy as sp
from scipy.sparse import coo_matrix

def square_feature(A, center=1.5, radius=0.125):
    return ((A-center)<radius).astype(np.int8)

def triangle_feature(A, center=1.5, radius=0.125):
    return (1.0-np.abs(A-center)/radius)*((A-center)<radius)

table_handle = tables.open_file(TABLE_OUT_PATH, 'r')
note_meta = table_handle.get_node('/', 'note_meta')
meta_obsid = note_meta.read(field="obsID")
meta_result = note_meta.read(field="result")
meta_this_note = note_meta.read(field="thisNote")
n_obs = note_meta.nrows
n_basic_vars = note_meta.attrs.neighborhoodRadius * 2 + 1
max_age = note_meta.attrs.maxAge

base_rate = table_handle.get_node('/', 'v_base_rate').read()
rel_base_rate = table_handle.get_node('/', 'v_rel_base_rate').read()
col_names = [r['rname'] for r in table_handle.get_node('/', 'col_names').iterrows()]

obs_id = table_handle.get_node('/', 'v_obsid').read()
basic_var_id = table_handle.get_node('/', 'v_p').read()
recence = table_handle.get_node('/', 'v_recence').read()

f0 = coo_matrix(
    (
        square_feature(recence, max_age, 0.125),
        (obs_id,basic_var_id))
    ,
    shape=(n_obs, n_basic_vars))
f0 = f0.tocsc()
f0.eliminate_zeros()

