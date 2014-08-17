require("Matrix")
require("MatrixModels")
require("glmnet")
require("rhdf5")
source("serialization.R")
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

# which file has the data? Support defaults for interaction, and CLI use
h5.file.name.from.python = "rag_obs.h5"
h5.file.name.to.python = "rag_to_python.h5"
args = commandArgs( trailingOnly = TRUE)
if (length(args) >=2) {
  h5.file.name.from.python = args[[1]]
  h5.file.name.to.python = args[[2]]
}
print(c("files:",h5.file.name.from.python, h5.file.name.to.python))

# handy coef inspection
tidycoef = function(spcoef, cutoff=0) {
  cf=as.array(Matrix(spcoef, sparse=F))
  nzero.mask = abs(cf)>cutoff
  cfvals=cf[nzero.mask]
  cfnames = rownames(cf)[nzero.mask]
  cforder = order(abs(cfvals), decreasing=TRUE)
  cfl=as.list(cfvals[cforder])
  names(cfl)=cfnames[cforder]
  return(cfl)
}

#load actual data
notes.obsdata = h5read(h5.file.name.from.python, "/note_obs_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
#reduce the data for testing
notes.obsdata = notes.obsdata[notes.obsdata$file %in% c("AmericanBeautyRag.mid"),]
# design matrix; we need the +0 term to elinimate the intercept which will just be added in again later
# sparse support:
#notes.f = model.Matrix(~(p0+p1+p2+p3+p4+p5+p6+p7+p8+p9+p10+p11)+0, data=notes.obsdata)
# strictly dense:
notes.f = model.matrix(~(p0+p1+p2+p3+p4+p5+p6+p7+p8+p9+p10+p11)+0, data=notes.obsdata)

notes.fit.time = system.time( #note this only works for <- assignment!
  notes.fit <- cv.glmnet(
    x=notes.f,
    y=as.factor(notes.obsdata$result),
    family="binomial",
    alpha=1,
    #dfmax=200,
    #parallel=TRUE,
    #foldid=ceiling(unclass(notes.obsdata$file)/3.4)
  )
)
print(notes.fit.time)
print(tidycoef(coef(notes.fit, s="lambda.1se")))

#write out to a different file because we can't change the matrix sizes
# At least, I can't see how to do that from R which doesn't support deletion
if (file.exists(h5.file.name.to.python)) file.remove(h5.file.name.to.python)
h5createFile(h5.file.name.to.python)
h5createGroup(h5.file.name.to.python, "/fit")
save.glmnet.hdf(h5.file.name.to.python, "/fit/all", notes.fit)
