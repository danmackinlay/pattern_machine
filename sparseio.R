require(rhdf5)

load.sparse.hdf = function (filename, path) {
  h5createGroup(filename, path)
  idx = as.vector(h5read(filename, paste(path, "v_indices", sep="/")))
  idxptr = as.vector(h5read(filename, paste(path, "v_indptr", sep="/")))
  vals = as.vector(h5read(filename, paste(path, "v_data", sep="/")))
  dims = as.vector(h5read(filename, paste(path, "v_datadims", sep="/")))
  colnames = h5read(filename, paste(path, "v_col_names", sep="/"))
  
  data = sparseMatrix(
    i=idx,
    p=idxptr,
    x=vals,
    dims=dims,
    index1=F
  )
  colnames(data)=colnames
  return(data)
}
