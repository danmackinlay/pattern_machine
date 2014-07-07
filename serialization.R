require(rhdf5)

load.sparse.hdf = function (filename, path) {
  idx = as.vector(h5read(filename, paste(path, "v_indices", sep="/")))
  idxptr = as.vector(h5read(filename, paste(path, "v_indptr", sep="/")))
  vals = as.vector(h5read(filename, paste(path, "v_data", sep="/")))
  dims = as.vector(h5read(filename, paste(path, "v_datadims", sep="/")))
  col.names = h5read(filename, paste(path, "v_col_names", sep="/"))
  
  data = sparseMatrix(
    i=idx,
    p=idxptr,
    x=vals,
    dims=dims,
    index1=F
  )
  colnames(data)=col.names
  return(data)
}

save.glmnet.hdf = function (filename, path, cv.fit) {
  h5createGroup(filename, path)
  h5write.default(cv.fit$nzero, filename, paste(path, "v_nzero", sep="/"))
  h5write(cv.fit$cvlo, filename, paste(path, "v_cvlo", sep="/"))
  h5write(cv.fit$cvup, filename, paste(path, "v_cvup", sep="/"))
  h5write(cv.fit$cvsd, filename, paste(path, "v_cvsd", sep="/"))
  h5write(cv.fit$lambda, filename, paste(path, "v_lambda", sep="/"))
  h5write(cv.fit$cvm, filename, paste(path, "v_cvm", sep="/"))
  if (!is.null(cv.fit$glmnet.cv.fit$dev.ratio)) {h5write(cv.fit$glmnet.cv.fit$dev.ratio, filename, paste(path, "v_nulldev", sep="/"))}
  coef.mat = matrix(data=0,nrow=length(cv.fit$lambda), ncol=length(coef(cv.fit)))
  colnames(coef.mat) =rownames(coef(cv.fit))
  for (i in 1:length(cv.fit$lambda)) { l=cv.fit$lambda[i]; coef.mat[i,]=t(as.matrix(coef(cv.fit,s=l)))}
  #beware! includes new intercept term, and there is no colnames attribute to make this clear
  # > h5write(coef.mat, filename, "v_coef",  write.attributes = T)
  ## Warning message:
  ##In h5writeAttribute.default(Attr[[i]], h5obj, name = names(Attr)[i]) :
  ##  No function found to write attribute of class 'list'. Attribute 'dimnames' is not written to hdf5-file.
  h5write(coef.mat, filename,  paste(path, "v_coef", sep="/"))
}
