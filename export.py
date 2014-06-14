import tables
import math
import numpy as np
import scipy as sp
from config import *

"""
Export the model matrix into a supercollider script that outputs notes according to the model.
"""

table_out_handle = tables.open_file(FEATURE_TABLE_FROM_PYTHON_PATH, 'r')
feature_names = list(table_out_handle.get_node('/','v_feature_col_names').read())
new_feature_names = ["intercept", "baseline"] + feature_names
table_out_handle.close()

table_in_handle = tables.open_file(FEATURE_TABLE_TO_PYTHON_PATH, 'r')
cv_lo = table_in_handle.get_node('/', 'v_cvlo').read()
cv_up = table_in_handle.get_node('/', 'v_cvup').read()
cv_sd = table_in_handle.get_node('/', 'v_cvsd').read()
cv_m = table_in_handle.get_node('/', 'v_cvm').read()
nzero = table_in_handle.get_node('/', 'v_nzero').read()
nulldev = table_in_handle.get_node('/', 'v_nulldev').read()
lambd = table_in_handle.get_node('/', 'v_lambda').read()
coef_path = table_in_handle.get_node('/', 'v_coef').read()
table_in_handle.close()

def coefdict(coef_array):
    these_features = [new_feature_names[i] for i in np.where(coefs!=0)[0]]
    these_coefs = [coefs[i] for i in np.where(coefs!=0)[0]]
    return dict(zip(these_features,these_coefs))

l = []
for k in dc.keys(): l.extend(k.split(':'))
l = set(l)
#coefdict(coef_path[:,23])
 
def sc_string(model, i_name="i", note_age_name="features"):
    """code-generate an SC function
    This SC function returns logit probability from a note feature array, for a given pitch, i
    """
    super_terms = []
    for refs, coef in model:
        terms = []
        for i in refs:
            subterm = ["("+note_age_name+"["+i_name]
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

