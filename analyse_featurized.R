library("Matrix")
library("glmnet")
library("stringr")
require(doMC)
registerDoMC(cores=4)
require(rhdf5)
source("config.R")

#load actual data
notes.obsdata = h5read(h5.file.name.basic, "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsidx = as.vector(h5read(h5.file.name.basic, '/v_indices'))
notes.obsptr = as.vector(h5read(h5.file.name.basic, '/v_indptr'))
notes.vals = as.vector(h5read(h5.file.name.basic, '/v_data'))
notes.dims = as.vector(h5read(h5.file.name.basic, '/v_datadims'))
notes.colnames = h5read(h5.file.name.basic, "/v_col_names")

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
    type.logistic="modified.Newton",
    alpha=1,
    dfmax=1000,
    parallel=TRUE,
    foldid=ceiling(unclass(notes.obsdata$file)/3.4)
  )
)
print(notes.fit.time)

h <- file("coef-cont.json", "w")
cat(coefs.as.json(coef(notes.fit, s="lambda.1se")), file=h)
close(h)
