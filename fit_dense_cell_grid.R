library("Matrix")
library("MatrixModels")
library("glmnet")
library("rhdf5")
library("pcalg")

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
predictorNames = outer(0:11,0:8, function(p,t){ sprintf("p%dx%d", p, t)})
dim(predictorNames)=prod(dim(predictorNames))

# clip to binary factors
for (pn in predictorNames) {notes.obsdata[,pn] = factor(pmin(notes.obsdata[,pn],1))}
notes.obsdata[,"result"] = factor(notes.obsdata[,"result"])

# design matrix; we need the +0 term to eliminate the intercept which will just be added in again later
notes.f = model.Matrix(
  as.formula(paste("result ~ (", paste(predictorNames, collapse=" + "), ")^2 +0")),
  data=notes.obsdata, sparse=T, 
  drop.unused.levels=T)
# This does not do what i think; else why would i get colnames like "p6x31:p2x51"?
notes.result = notes.f[,"result"]

notes.fit.time = system.time( #note this only works for <- assignment!
  notes.fit <- cv.glmnet(
    x=notes.f[,predictorNames],
    y=notes.f[,"result"],
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



> ## using data("gmG", package="pcalg")
  > suffStat <- list(C = cor(gmG$x), n = nrow(gmG$x))
> skel.gmG <- skeleton(suffStat, indepTest = gaussCItest,
                       p = ncol(gmG$x), alpha = 0.01)
> par(mfrow = c(1,2))
> plot(gmG$g, main = ""); plot(skel.gmG, main = "")
