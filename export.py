import tables
import math
import numpy as np
import scipy as sp
from config import *

"""
Export the model matrix into a supercollider script that outputs notes according to the model.
"""

def coefdict(coef_array):
    these_features = [new_feature_names[i] for i in np.where(coef_array!=0)[0]]
    these_coefs = [coef_array[i] for i in np.where(coef_array!=0)[0]]
    return dict(zip(these_features,these_coefs))

fmap = dict(
    F0=0,
    F1=1,
    F2=2,
    F3=3,
    F4=4
)
def sc_string(model, i_name="i", note_feature_matrix="featureData"):
    """code-generate an SC method
    This SC method returns logit probability from a note feature array, for a given pitch, i
    
    invoke this function through, e.g.,
    print sc_string(coefdict(coef_path[:,30]))
    """
    #clone the model for safety's sake:
    model = dict(**model)
    baseline = model.pop("(baseline)") #we ultimately ignore this guy
    intercept = model.pop("(intercept)")
    header = """^"""
    footer = ";"
    super_terms = ["({:f})".format(intercept)]
    # Walk through terms in order of magnitude
    for refs, coef in sorted(model.items(), cmp=lambda a,b: int(abs(a[1])<abs(b[1]))*2-1):
        terms = []
        for chunk in refs.split(":"):
            base = fmap[chunk[:2]]
            rel = p_for_r_name[chunk[2:]]
            terms.append("({}[{}][i{:+d}]?0)".format(note_feature_matrix, base, rel))
        if coef<0:
            terms.append("("+str(coef)+")")
        else:
            terms.append(str(coef))
        super_terms.append("(" + "*".join(terms)+")")
    return header + " +\n\t".join(super_terms) + footer


table_out_handle = tables.open_file(FEATURE_TABLE_FROM_PYTHON_PATH, 'r')
feature_names = list(table_out_handle.get_node('/','v_feature_col_names').read())
new_feature_names = ["(intercept)", "(baseline)"] + feature_names
table_out_handle.close()

table_in_handle = tables.open_file(FEATURE_TABLE_TO_PYTHON_PATH, 'r')
cv_lo = table_in_handle.get_node('/fit', 'v_cvlo').read()
cv_up = table_in_handle.get_node('/fit', 'v_cvup').read()
cv_sd = table_in_handle.get_node('/fit', 'v_cvsd').read()
cv_m = table_in_handle.get_node('/fit', 'v_cvm').read()
nzero = table_in_handle.get_node('/fit', 'v_nzero').read()
nulldev = table_in_handle.get_node('/fit', 'v_nulldev').read()
lambd = table_in_handle.get_node('/fit', 'v_lambda').read()
coef_path = table_in_handle.get_node('/fit', 'v_coef').read()
table_in_handle.close()

