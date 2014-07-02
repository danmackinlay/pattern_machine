require("Matrix")
require("glmnet")
require(rhdf5)

# # crashes with index error; seems to work ATM though
# require(doMC)
# registerDoMC(cores=4)

# # crashes with index error
# require(doParallel)
# registerDoParallel(cores=4)

# # ?
# require(doParallel)
# cl <- makeCluster(2)
# registerDoParallel(cl)

# # works; could be faster
# require(doSNOW)
# cl <- makeCluster(4)
# registerDoSNOW(cl)

# which file has the data? Support defaults ofr interaction, and CLI use
h5.file.name.from.python = "rag_from_python.h5"
h5.file.name.to.python = "rag_to_python.h5"
args = commandArgs( trailingOnly = TRUE)
if (length(args) >=2) {
  h5.file.name.from.python = args[[1]]
  h5.file.name.to.python = args[[2]]
}
print(c("files:",h5.file.name.from.python, h5.file.name.to.python))

# handy coeff inspection
tidycoef = function(spcoef) {
  cf=as.array(Matrix(spcoef, sparse=F))
  nzero.mask = abs(cf)>0
  cfl=as.list(cf[nzero.mask])
  names(cfl)=rownames(cf)[nzero.mask]
  return(cfl)
}

#load actual data
notes.obsdata = h5read(h5.file.name.from.python, "/obs_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsidx = as.vector(h5read(h5.file.name.from.python, '/v_feature_indices'))
notes.obsptr = as.vector(h5read(h5.file.name.from.python, '/v_feature_indptr'))
notes.vals = as.vector(h5read(h5.file.name.from.python, '/v_feature_data'))
notes.dims = as.vector(h5read(h5.file.name.from.python, '/v_feature_datadims'))
notes.colnames = h5read(h5.file.name.from.python, "/v_feature_col_names")

notes.f = sparseMatrix(
  i=notes.obsidx,
  p=notes.obsptr,
  x=notes.vals,
  dims=notes.dims,
  index1=F
)
rm(notes.obsidx, notes.obsptr, notes.vals)
#augment with base rate data
notes.f = cBind(as.matrix(-log(notes.obsdata["diameter"]-1)), notes.f)
#penalties = str_count(colnames(notes.f), "b")+1
penalties = rep(1.0,length(colnames(notes.f))) 
#don't weight baseline term
penalties[1] = 0
colnames(notes.f)=c("baselogodds", paste(notes.colnames))
notes.response=as.matrix(notes.obsdata$result)

notes.fit.time = system.time( #note this only works for <- assignment!
  notes.fit <- cv.glmnet(
    notes.f,
    notes.response,
    family="binomial",
    #type.logistic="modified.Newton", #speed-up, apparently.
    alpha=1,
    penalty.factor=penalties,
    #dfmax=200,
    #parallel=TRUE,
    foldid=ceiling(unclass(notes.obsdata$file)/3.4)
  )
)
print(notes.fit.time)
print(tidycoef(coef(notes.fit, s="lambda.1se")))

#write out to a different file because we can't change the matrix sizes after updated
# At least, I can't see how to do that from R which doesn't support deletion
if (file.exists(h5.file.name.to.python)) file.remove(h5.file.name.to.python)
h5createFile(h5.file.name.to.python)
h5write.default(notes.fit$nzero, h5.file.name.to.python, "/v_nzero")
h5write(notes.fit$cvlo, h5.file.name.to.python, "/v_cvlo")
h5write(notes.fit$cvup, h5.file.name.to.python, "/v_cvup")
h5write(notes.fit$cvsd, h5.file.name.to.python, "/v_cvsd")
h5write(notes.fit$lambda, h5.file.name.to.python, "/v_lambda")
h5write(notes.fit$cvm, h5.file.name.to.python, "/v_cvm")
h5write(notes.fit$glmnet.fit$dev.ratio, h5.file.name.to.python, "/v_nulldev")
coef.mat = matrix(data=0,nrow=length(notes.fit$lambda), ncol=length(coef(notes.fit)))
colnames(coef.mat)=rownames(coef(notes.fit))
for (i in 1:length(notes.fit$lambda)) { l=notes.fit$lambda[i]; coef.mat[i,]=t(as.matrix(coef(notes.fit,s=l)))}
#beware! includes new intercept term, and there is no colnames attribute to make this clear
# > h5write(coef.mat, h5.file.name.to.python, "/v_coef",  write.attributes = T)
## Warning message:
##In h5writeAttribute.default(Attr[[i]], h5obj, name = names(Attr)[i]) :
##  No function found to write attribute of class 'list'. Attribute 'dimnames' is not written to hdf5-file.
h5write(coef.mat, h5.file.name.to.python, "/v_coef")
#rm(coef.mat)
