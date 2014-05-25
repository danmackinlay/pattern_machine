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
# which file has the data

#can't work out how to extract this as attribute, although should as it is data-dependent
max.age = 2.0
radius = 0.125


#function to trim rows from a sparse matrix
#(also removes entirely rows which are all 0, which is only appropriate for this particular model.)
#seems to be broken in the sparse case.

feature.matrix = function (sourceSparseMat, x0=1.0, radius=0.25, f.num=0) {
  feat.val = feat.tri(sourceSparseMat@x, max.age, radius)
  #should i use the obsids as names here?
  fmat = drop0(sparseMatrix(
    i=sourceSparseMat@i,
    p=sourceSparseMat@p,
    x=feat.val,
    dims=sourceSparseMat@Dim,
    index1=F
  ))
  colnames(fmat)=paste(notes.colnames$rname,f.num, sep='xF')
  return(fmat)
}

#load actual data
notes.obsdata = h5read(h5.file.name.basic.basic, "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsid = as.vector(h5read(h5.file.name.basic.basic, '/v_obsid'))
notes.p = as.vector(h5read(h5.file.name.basic.basic, '/v_p'))
notes.recence = as.vector(h5read(h5.file.name.basic.basic, '/v_recence'))
notes.dims = c(max(notes.obsid)+1, max(notes.p)+1)
notes.colnames = h5read(h5.file.name.basic.basic, "/col_names")
#hist(notes.recence, breaks=seq(0,1.56,1/64)-1/128)
notes.base.f = basic.obs.matrix()

if (row.thin.factor>1) {
  n = nrow(notes.base.f)
  samp = sort.int(sample.int(n,floor(n/row.thin.factor)))
  notes.base.f = notes.base.f[samp,]
  notes.obsdata = notes.obsdata[samp,]
}
#THIS IS NOW A MESS AND COLUMN TRIMMING IS TEMPORARILY NOT SUPPORTED
if (col.trim.count>0) {
  trimmed = trim.col(notes.base.f)
  notes.base.f = trimmed$trimmed
  notes.obsdata = notes.obsdata[trimmed$mask,]
}

#165000 columns
notes.f0 = feature.matrix(notes.base.f, max.age, radius, 0)
notes.f4 = feature.matrix(notes.base.f, max.age-4*radius, radius, 4)
notes.fall = cBind(notes.f0, pred.matrix.squared(notes.f0), notes.f4, pred.matrix.squared(notes.f4))
notes.f = cBind(notes.fall, pred.matrix.squared(notes.fall))

#A mere 8000 columns.
# notes.f0 = feature.matrix(notes.base.f, max.age, radius, 0)
# notes.f4 = feature.matrix(notes.base.f, max.age-4*radius, radius, 4)
# notes.f = cBind(notes.f0, pred.matrix.squared(notes.f0))
# notes.f = cBind(notes.f, notes.f4, pred.matrix.product(notes.f, notes.f4))
# notes.f = cBind(notes.f, pred.matrix.cubed(notes.f0))
# #A mere 8000 columns.

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
