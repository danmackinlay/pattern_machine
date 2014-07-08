require("Matrix")
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
notes.f = load.sparse.hdf(h5.file.name.from.python, "/features")

#augment with base rate data
notes.f = cBind(as.matrix(-log(notes.obsdata["diameter"]-1)), notes.f)
penalties = rep(1.0,length(colnames(notes.f))) 
#don't weight baseline term
penalties[1] = 0
#colnames(notes.f)=c("baselogodds", colnames(notes.f)))
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

#write out to a different file because we can't change the matrix sizes
# At least, I can't see how to do that from R which doesn't support deletion
if (file.exists(h5.file.name.to.python)) file.remove(h5.file.name.to.python)
h5createFile(h5.file.name.to.python)
save.glmnet.hdf(h5.file.name.to.python, "/fit", notes.fit)
