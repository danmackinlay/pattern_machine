import tables
import math
import numpy as np
import scipy as sp

from config import *


"""Export the model matrix into a supercollider script that outputs notes according to the model.
"""

table_out_handle = tables.open_file(FEATURE_TABLE_FROM_PYTHON_PATH, 'r')
feature_names = list(table_out_handle.get_node('/','v_feature_col_names').read())
new_feature_names = ["intercept", "baseline"] + feature_names
table_out_handle.close()

table_in_handle = tables.open_file(FEATURE_TABLE_TO_PYTHON_PATH, 'r')
cv_lo = table_in_handle.get_node('/', 'v_cvlo').read().astype(np.float32)
cv_up = table_in_handle.get_node('/', 'v_cvup').read().astype(np.float32)
cv_sd = table_in_handle.get_node('/', 'v_cvsd').read().astype(np.float32)
nzero = table_in_handle.get_node('/', 'v_nzero').read().astype(np.float32)
cv_m = table_in_handle.get_node('/', 'v_cvm').read().astype(np.float32)
nulldev = table_in_handle.get_node('/', 'v_nulldev').read().astype(np.float32)
coef_path = table_in_handle.get_node('/', 'v_coef').read().astype(np.float32)
table_in_handle.close()

def sc_string(model, i_name="i", nstate_name="nState"):
    """code-generate an SC function
    This SC function returns logit probability from a note volume array, nState, for a given pitch i
    Note that it hasn't yet been updated for the new matrix-based R export, so it doesn't work.
    """
    super_terms = []
    for refs, coef in model:
        terms = []
        for i in refs:
            subterm = ["("+nstate_name+"["+i_name]
            if i>=0: subterm.append("+")
            subterm.append(str(i))
            subterm.append("]?0)")
            terms.append("".join(subterm))
        if coef<0:
            terms.append("("+str(coef)+")")
        else:
            terms.append(str(coef))
        super_terms.append("("+"*".join(terms)+")")
    return " +\n\t".join(super_terms) + ";"

