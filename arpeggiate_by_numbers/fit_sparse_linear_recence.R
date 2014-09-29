library("Matrix")
library("glmnet")
library("rhdf5")
source("serialization.R")
# # crashes with index error; seems to work ATM though
# library(doMC)
# registerDoMC(cores=4)

# # crashes with index error
# library(doParallel)
# registerDoParallel(cores=4)

# # ?
# library(doParallel)
# cl <- makeCluster(2)
# registerDoParallel(cl)

# # works; could be faster
# library(doSNOW)
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
notes.obsdata = h5read(h5.file.name.from.python, "/obs_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.f = load.sparse.hdf(h5.file.name.from.python, "/features")

#augment with base rate data
notes.f = cBind(as.matrix(-log(notes.obsdata["diameter"]-1)), notes.f)
penalties = rep(1.0,dim(notes.f)[2]) 
#don't weight baseline term
penalties[1] = 0
colnames(notes.f)[1]="baselogodds"
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
h5createGroup(h5.file.name.to.python, "/fit")
save.glmnet.hdf(h5.file.name.to.python, "/fit/all", notes.fit)

notes.f = notes.f[,grep("^b.*", colnames(notes.f), value=FALSE, invert=TRUE)]
fits=list()
for (code in c("b1", "b2", "b3", "b4")) {
  print(code)
  #need numeric, not logical, lookup vector for mixed indexing
  lookup.numeric = (1:(dim(notes.obsdata)[1]))[notes.obsdata[code]==1]
  fits[[code]] <- cv.glmnet(
    notes.f[lookup.numeric,],
    notes.response[lookup.numeric],
    family="binomial",
    #type.logistic="modified.Newton", #speed-up, apparently.
    alpha=1,
    penalty.factor=penalties,
    #dfmax=200,
    #parallel=TRUE,
    foldid=ceiling(unclass(notes.obsdata[lookup.numeric,"file"])/3.4)
  )
  print(tidycoef(coef(fits[[code]], s="lambda.1se")))
  save.glmnet.hdf(h5.file.name.to.python, paste("/fit", code, sep="/"), fits[[code]])
}
