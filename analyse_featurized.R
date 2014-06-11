library("Matrix")
library("glmnet")
library("stringr")
#require(doMC)
#registerDoMC(cores=4)
require(rhdf5)
source("config.R")

#load actual data
notes.obsdata = h5read(h5.file.name.basic, "/obs_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsidx = as.vector(h5read(h5.file.name.basic, '/v_feature_indices'))
notes.obsptr = as.vector(h5read(h5.file.name.basic, '/v_feature_indptr'))
notes.vals = as.vector(h5read(h5.file.name.basic, '/v_feature_data'))
notes.dims = as.vector(h5read(h5.file.name.basic, '/v_feature_datadims'))
notes.colnames = h5read(h5.file.name.basic, "/v_feature_col_names")

notes.f = sparseMatrix(
  i=notes.obsidx,
  p=notes.obsptr,
  x=notes.vals,
  dims=notes.dims,
  index1=F
)
colnames(notes.f)=paste(notes.colnames)
rm(notes.obsidx, notes.obsptr, notes.vals)
notes.response=as.matrix(notes.obsdata$result)

notes.fit.time = system.time( #note this only works for <- assignment!
  notes.fit <- cv.glmnet(
    notes.f,
    notes.response,
    family="binomial",
    type.logistic="modified.Newton", #speed-up, apparently.
    alpha=1,
    dfmax=1000,
    #parallel=TRUE,
    foldid=ceiling(unclass(notes.obsdata$file)/3.4)
  )
)
print(notes.fit.time)

h5write(notes.fit$nzero, h5.file.name.basic, "/v_nzero")
h5write(notes.fit$cvlo, h5.file.name.basic, "/v_cvlo")
h5write(notes.fit$cvup, h5.file.name.basic, "/v_cvup")
h5write(notes.fit$cvsd, h5.file.name.basic, "/v_cvsd")
h5write(notes.fit$lambda, h5.file.name.basic, "/v_lambda")
h5write(notes.fit$cvm, h5.file.name.basic, "/v_cvm")
h5write(notes.fit$glmnet.fit$dev.ratio, h5.file.name.basic, "/v_nulldev")
coef.mat = matrix(data=0,nrow=length(notes.fit$lambda), ncol=length(coef(notes.fit)))
colnames(coef.mat)=rownames(coef(notes.fit))
for (i in 1:length(notes.fit$lambda)) { l=notes.fit$lambda[i]; coef.mat[i,]=t(as.matrix(coef(notes.fit,s=l)))}
#beware! includes new intercept term
h5write(coef.mat, h5.file.name.basic, "/v_coef")
#rm(coef.mat)
