library("Matrix")
library("glmnet")
library("stringr")
library("jsonlite")
#disable parallelism for now because of ram shortage
require(doMC)
registerDoMC(cores=4)
require(rhdf5)
source("featureMatrix.R")
source("config.R")

###settings
# how many observations we throw out (oversampling of cases means the data set blows up)
row.thin.factor = 5
# how many we cut off the edge of note neighbourhood
col.trim.count = 0

basic.obs.matrix = function () {
  #should i use the obsids as names here?
  fmat = sparseMatrix(
      i=notes.obsid,
      j=notes.p,
      x=notes.recence,
      dims=notes.dims,
      index1=F
  )
  colnames(fmat)=paste(notes.colnames$rname)
  return(fmat)
}

featurized.obs.matrix = function () {
  #should i use the obsids as names here?
  fmat = sparseMatrix(
      i=notes.obsid,
      j=notes.p,
      x=notes.recence,
      dims=notes.dims,
      index1=F
  )
  colnames(fmat)=paste(notes.colnames$rname)
  return(fmat)
}


#load actual data
notes.obsdata = h5read(h5.file.name.basic, "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsid = as.vector(h5read(h5.file.name.basic, '/v_obsid'))
notes.p = as.vector(h5read(h5.file.name.basic, '/v_p'))
notes.recence = as.vector(h5read(h5.file.name.basic, '/v_recence'))
notes.dims = c(max(notes.obsid)+1, max(notes.p)+1)
notes.colnames = h5read(h5.file.name.basic, "/col_names")
#hist(notes.recence, breaks=seq(0,1.56,1/64)-1/128)
notes.base.f = basic.obs.matrix()

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
