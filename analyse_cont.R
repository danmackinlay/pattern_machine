library("Matrix")
#library("LiblineaR")
library("glmnet")
library("stringr")
library("jsonlite")
#disable parallelism for now because of ram shortage
#require(doMC)
#registerDoMC(cores=2)
require(rhdf5)
source("featureMatrix.R")

#TODO: I have a lot of data here;
# should probably throw over CV and do straight training/prediction split
# todo: fits should know own AND NEIGHBOURS' base rates
# remove rows, and disambiguate what remains. (trimming columns leads to spurious duplicates with 0 notes in)
# Add a logical feature specifying bar position; possibly fit separate models for each

###settings
# how many observations we throw out (oversampling of cases means the data set blows up)
row.thin.factor = 6
# how many we cut off the edge of note neighbourhood
col.trim.count = 2
h5.file.name = "rag.h5"

#function to trim rows from a sparse matrix
#(also removes entirely rows which are all 0, which is only appropriate for this particular model.)
#seems to be broken in the sparse case.
trim.col = function(mat,n=0){
  trimmed = mat[,(n+1):(ncol(mat)-n)]
  mask = rowSums(mat)>0
  return(list(trimmed=trimmed[mask,], mask = mask))
}

#can't work out how to extract this as attribute, although should as it is data-dependent
max.age = 1.5

#local settings
radius = 0.125

dissect.coefs = function(coefs){
  #horrifically inefficient, but I can't be arsed working out how to do this better in R
  #it's not conceptually well-posed anyway
  scoefmags = (coefs[summary(coefs)$i])[-1]
  coefmags = abs(scoefmags)
  coefnames = rownames(coefs)[summary(coefs)$i][-1]
  coeford = order(coefmags, decreasing=T)
  coefchunks = data.frame()
  for (i in 1:length(coefnames)) {
    for (j in as.vector(str_split(coefnames[[i]], "[:x]")[[1]])) {
      coefchunks = rbind(coefchunks, data.frame(name = j, mag=coefmags[i]))
    }
  }
  coefchunks$name = as.factor(coefchunks$name)
  coefsumm = data.frame()
  for (j in levels(coefchunks$name)) {coefsumm = rbind(coefsumm, data.frame(name=j, mag = sum(coefchunks[coefchunks$name==j,"mag"])))}
  coefsumm=coefsumm[order(coefsumm$mag,decreasing=T),]
  return(list(
    mag.imp=data.frame(
      mag=scoefmags[coeford],
      name=as.factor(coefnames[coeford])), 
    chunks = coefsumm)
  )
}

coefs.as.json <- function (coefs.matrix) {
  coef.list = list()
  for (n in row.names(coefs.matrix)) {
    if (coefs.matrix[n,] !=0) coef.list[n] = coefs.matrix[n,]
  }
  return(toJSON(coef.list, simplifyVector=TRUE, pretty = TRUE, digits=8))
}

#triangular feature fn
feat.tri = function(col, x0=1.0, radius=0.25) {
  return(pmax(1.0-abs((col-x0)/radius),0))
}

#peak-differentiable feature fn
feat.sin = function(...) {
  return(sin(pi/2*feat.tri(...)))
}
#everywhere differentiable feature fn
feat.sin2 = function(...) {
  return(sin(pi/2*feat.tri(...))^2)
}

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
notes.obsdata = h5read(h5.file.name, "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsid = as.vector(h5read(h5.file.name, '/v_obsid'))
notes.p = as.vector(h5read(h5.file.name, '/v_p'))
notes.recence = as.vector(h5read(h5.file.name, '/v_recence'))
notes.dims = c(max(notes.obsid)+1, max(notes.p)+1)
notes.colnames = h5read(h5.file.name, "/col_names")

#hist(notes.recence, breaks=seq(0,1.56,1/64)-1/128)
#THIS IS NOW A MESS AND COLUMN TRIMMING IS TEMPORARILY NOT SUPPORTED
notes.base.f = basic.obs.matrix()

if (row.thin.factor>1) {
  n = nrow(notes.base.f)
  samp = sample.int(n,floor(n/row.thin.factor))
  notes.base.f = notes.base.f[samp,]
  notes.obsdata = notes.obsdata[samp,]
}
if (col.trim.count>0) {
  trimmed = trim.col(notes.base.f)
  notes.base.f = trimmed$trimmed
  notes.obsdata = notes.obsdata[trimmed$mask,]
}

#50000 columns
notes.f0 = feature.matrix(notes.base.f, max.age, radius, 0)
notes.f1 = feature.matrix(notes.base.f, max.age-1*radius, radius, 1)
notes.f4 = feature.matrix(notes.base.f, max.age-4*radius, radius, 4)
notes.fall = cBind(notes.f0, pred.matrix.squared(notes.f0), notes.f1, notes.f4)
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
    #parallel=TRUE,
    foldid=unclass(notes.obsdata$file)
  )
)
print(notes.fit.time)

h <- file("coef-cont.json", "w")
cat(coefs.as.json(coef(notes.fit, s="lambda.1se")), file=h)
close(h)
