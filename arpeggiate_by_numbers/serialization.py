"""
input and output some tricky matrix data in a cross-language format
"""

from scipy.sparse import coo_matrix, dok_matrix, csc_matrix
import tables
import numpy as np

def write_sparse_hdf(handle, group, data, colnames=None, filt=None):
    """
    sparse CSC (compressed sparse colums) matrices via hdf5
    32 bit for now, ok?
    """
    data_atom_type = tables.Float32Atom()
    if np.issubdtype(data.dtype, int):
        data_atom_type = tables.Int32Atom()
    handle.create_carray(group,'v_indices',
        atom=tables.Int32Atom(), shape=data.indices.shape,
        title="indices",
        filters=filt)[:] = data.indices
    handle.create_carray(group,'v_indptr',
        atom=tables.Int32Atom(), shape=data.indptr.shape,
        title="index ptr",
        filters=filt)[:] = data.indptr
    handle.create_carray(group,'v_data',
        atom=data_atom_type, shape=data.data.shape,
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
            ), shape=(len(colnames),),
            title="col names",
            filters=filt)[:] = colnames

def read_sparse_hdf(handle, group):
    """
    sparse CSC (compressed sparse colums) matrices via hdf5
    """
    shape = group.get_node(group,'v_datadims')
    return csc_matrix(
        (
            group.get_node(group,'v_data'),
            (
                group.get_node(group,'v_indices'),
                group.get_node(group,'v_indptr')
            )
        ),
        shape=shape)
    # if colnames:
    #     handle.create_carray(group,'v_col_names',
    #         atom=tables.StringAtom(
    #             max([len(n) for n in colnames])
    #         ), shape=(len(colnames),),
    #         title="col names",
    #         filters=filt)[:] = colnames

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