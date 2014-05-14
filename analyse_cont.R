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
###settings
# how many observations we throw out (oversampling of cases means the data set blows up)
row.thin.factor = 6
# how many we cut off the edge of note neighbourhood
col.trim.count = 2

trim.col = function(mat,n=0){
  return(mat[,(n+1):(ncol(mat)-n)])
}

#can't work out how to extract this as attribute, although should as it is data-dependent
max.age = 1.5

#local settings
radius = 0.25

# Am I doing this wrong? I could model odds of each note sounding conditional on environment.
# Could also model, conditional on environment, which note goes on.
# More tractable, I could condition for note-on probabilities given the *number* of simultaneous notes
# this would possibly more interpretable. But I would lose a lot of speed when I throw out sparsity.
# should try and attribute amt of error to each song

# See packages glmnet, liblineaR, rms
# NB liblineaR has python binding
# if we wished to use non penalized regression, could go traditional AIC style: http://data.princeton.edu/R/glms.html
# OR even do hierarchical penalised regression using http://cran.r-project.org/web/packages/glinternet/index.html
# For now
# see http://www.stanford.edu/~hastie/glmnet/glmnet_alpha.html for an excellent guide
# and http://www.jstatsoft.org/v33/i01/paper

#if this DOESN'T work, could go to a discrete PGM model, such as
# http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
# https://r-forge.r-project.org/R/?group_id=1487
# gRaphHD http://www.jstatsoft.org/v37/i01/
# http://www.bnlearn.com/
# but let's stay simple.

dissect.coefs = function(coefs){
  #horrifically inefficient fc, but I can't be arsed working out how to do this better in R
  #it's not conceptually well-posed anyway
  coefmags = abs(coefs[summary(coefs)$i])[-1]
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
      mag=coefmags,
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

#peak-differntiable feature fn
feat.sin = function(...) {
  return(sin(pi/2*feat.tri(...)))
}
#everywhere differntiable feature fn
feat.sin2 = function(...) {
  return(sin(pi/2*feat.tri(...))^2)
}

feature.matrix = function (x0=1.0, radius=0.25, f.num=0, col.trim.count=0) {
  feat.val = feat.tri(notes.recence, max.age, radius)
  notes.mask = feat.val>0
  #should i use the obsids as names here?
  fmat = sparseMatrix(
      i=notes.obsid[notes.mask],
      j=notes.p[notes.mask],
      x=feat.val[notes.mask],
      dims=notes.dims,
      index1=F
  )
  colnames(fmat)=paste(notes.colnames$rname,f.num, sep='xF')
  return(trim.col(fmat, col.trim.count))
}


#load actual data
notes.obsdata = h5read("rag-11.h5", "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsid = as.vector(h5read("rag-11.h5", '/v_obsid'))
notes.p = as.vector(h5read("rag-11.h5", '/v_p'))
notes.recence = as.vector(h5read("rag-11.h5", '/v_recence'))
notes.dims = c(max(notes.obsid)+1, max(notes.p)+1)
notes.colnames = h5read("rag-11.h5", "/col_names")

#hist(notes.recence, breaks=seq(0,1.56,1/64)-1/128)

notes.f = cBind(feature.matrix(max.age, radius, 0,col.trim.count),
                feature.matrix(max.age-radius, radius, 1,col.trim.count),
                feature.matrix(max.age-2*radius, radius, 2,col.trim.count)
)  

if (row.thin.factor>1) {
  n = nrow(notes.f)
  samp = sample.int(n,floor(n/row.thin.factor))
  notes.f = notes.f[samp,]
  notes.obsdata = notes.obsdata[samp,]
}

notes.f.interact = cBind(notes.f,pred.matrix.squared(notes.f),pred.matrix.cubed(notes.f))
#notes.f.interact = cBind(notes.f,pred.matrix.squared(notes.f))
notes.response=as.matrix(notes.obsdata$result)

notes.fit.time = system.time( #note this only works for <- assignment!
  notes.fit <- cv.glmnet(
    notes.f.interact,
    notes.response,
    family="binomial",
    type.logistic="modified.Newton",
    alpha=1,
    #parallel=TRUE,
    foldid=unclass(notes.obsdata$file)
  )
)
print(notes.fit.time)

h <- file("coef-cont-11.json", "w")
cat(coefs.as.json(coef(notes.off.fit, s="lambda.1se")), file=h)
close(h)
coefmags = abs(coefs[summary(coefs)$i])
