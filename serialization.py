"""
input and output sparse CSC (compressed sparse colums) matrices via hdf5
32 bit for now, ok?
"""

from scipy.sparse import coo_matrix, dok_matrix, csc_matrix
import tables

def write_sparse_hdf(handle, group, data, colnames=None, filt=None):
    handle.create_carray(group,'v_indices',
        atom=tables.Int32Atom(), shape=data.indices.shape,
        title="indices",
        filters=filt)[:] = data.indices
    handle.create_carray(group,'v_indptr',
        atom=tables.Int32Atom(), shape=data.indptr.shape,
        title="index ptr",
        filters=filt)[:] = data.indptr
    handle.create_carray(group,'v_data',
        atom=tables.Int32Atom(), shape=data.data.shape,
        title="data",
        filters=filt)[:] = data.data
    handle.create_carray(group,'v_datadims',
        atom=tables.Int32Atom(), shape=(2,),
        title="data dims",
        filters=filt)[:] = data.shape
    if colnames:
        handle.create_carray(group,'v_col_names',
            atom=tables.StringAtom(
                max([len(n) for n in colnames])
            ), shape=(len(feature_names),),
            title="col names",
            filters=filt)[:] = colnames

def read_cv_glmnet(handle, group):
    cv_lo = handle.get_node(group, 'v_cvlo').read()
    cv_up = handle.get_node(group, 'v_cvup').read()
    cv_sd = handle.get_node(group, 'v_cvsd').read()
    cv_m = handle.get_node(group, 'v_cvm').read()
    nzero = handle.get_node(group, 'v_nzero').read()
    nulldev = handle.get_node(group, 'v_nulldev').read()
    lambd = handle.get_node(group, 'v_lambda').read()
    coef_path = handle.get_node(group, 'v_coef').read()

    return d(
        cv_lo = cv_lo,
        cv_up = cv_up,
        cv_sd = cv_sd,
        cv_m = cv_m,
        nzero = nzero,
        nulldev = nulldev,
        lambd = lambd,
        coef_path = coef_path,
    )