library("Matrix")
#library("LiblineaR")
library("glmnet")
library("stringr")
library("jsonlite")
require(doMC)
registerDoMC(cores=2)
require(rhdf5)

###settings
# how many cases we throw out (oversampling of cases means the data set blows up)
case.scale.factor = 24
#can't work out how to extract this as attribute
max.age = 1.5

#local settings
radius = 0.25
n.ages = 3

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

notes.obsdata = h5read("rag-11.h5", "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsid = as.vector(h5read("rag-11.h5", '/v_obsid'))
notes.p = as.vector(h5read("rag-11.h5", '/v_p'))
notes.recence = as.vector(h5read("rag-11.h5", '/v_recence'))
notes.dims = c(max(notes.obsid)+1, max(notes.p)+1)
notes.colnames = h5read("rag-11.h5", "/col_names")

#hist(notes.recence, breaks=seq(0,1.56,1/64)-1/128)

#optionally thin out data for testing
#notes.obsdata=notes.obsdata[seq(1,4000000,100),]

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

feature.matrix = function (x0=1.0, radius=0.25, f.num=0) {
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
  colnames(fmat)=paste(notes.colnames$rname,f.num, sep='F')
  return(fmat)
}
notes.f = cBind(feature.matrix(max.age, radius, 0),
                feature.matrix(max.age-radius, radius, 1),
                feature.matrix(max.age-2*radius, radius, 2))

#notes.formula = as.formula(paste("~(", paste(colnames(notes.f), collapse="+"), ")^2"))
#Note that model.Matrix(*, sparse=TRUE) from package MatrixModels may be often be preferable to sparse.model.matrix() nowadays, as model.Matrix() returns modelMatrix objects with additional slots assign and contrasts which relate back to the variables used.  
#notes.mega.f=sparse.model.matrix(notes.formula, notes.f)
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

coefs.as.json <- function (coefs.matrix) {
  coef.list = list()
  for (n in row.names(coefs.matrix)) {
    if (coefs.matrix[n,] !=0) coef.list[n] = coefs.matrix[n,]
  }
  return(toJSON(coef.list, simplifyVector=TRUE, pretty = TRUE, digits=8))
}
h <- file("coef-cont-11.json", "w")
cat(coefs.as.json(coef(notes.off.fit, s="lambda.1se")), file=h)
close(h)