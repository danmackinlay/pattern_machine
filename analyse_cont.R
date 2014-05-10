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
width = 0.25
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

#TODO: HDF and float values are the future. see http://www.bioconductor.org/packages/release/bioc/vignettes/rhdf5/inst/doc/rhdf5.pdf
notes.float = h5read("rag-11.h5", "/note_transitions")

notes.float=notes.float[seq(1,4000000,100),]
notes.float$file = as.factor(notes.float$file)

#feature fn - only works on columns:
nr = function(col, x0=1.0, width=0.25) {
  return(pmax(width-abs(col-x0),0))
}

notes.float.predictor.names  = colnames(notes.float)[substr(names(notes.float),1,1)=="X"]
notes.float.predictors = notes.float[,notes.float.predictor.names]

notes.float.formula = as.formula(paste("~(", paste(notes.float.predictor.names, collapse="+"), ")^3"))

note.log.model = function(notes.data, notes.formula, ...) {
  notes.successes = notes.data[rep(row.names(notes.data), round(notes.data$ons/case.scale.factor)),]
  notes.successes$ons=NULL
  notes.successes$offs=NULL
  notes.successes$response=1
  notes.fails = notes.data[rep(row.names(notes.data), round(notes.data$offs/case.scale.factor)),]
  notes.fails$ons=NULL
  notes.fails$offs=NULL
  notes.fails$response=0
  notes.data = rbind(notes.successes, notes.fails)
  rm(notes.fails)
  rm(notes.successes)
  
  # the original data frame and formula
  #Note that model.Matrix(*, sparse=TRUE) from package MatrixModels may be often be preferable to sparse.model.matrix() nowadays, as model.Matrix() returns modelMatrix objects with additional slots assign and contrasts which relate back to the variables used.
  
  
  notes.predictors.sparse=sparse.model.matrix(notes.formula, notes.data)
  notes.response=as.matrix(notes.data$response)
  notes.fit = 0
  notes.fit.time = system.time( #note this only works for <- assignment!
    notes.fit <- cv.glmnet(
      notes.predictors.sparse,
      notes.response,
      family="binomial",
      type.logistic="modified.Newton",
      alpha=1,
      parallel=TRUE,
      foldid=unclass(notes.data$file),
      ...
    )
  )
  print(notes.fit.time)
  return(notes.fit)
}
coefs.as.json <- function (coefs.matrix) {
  coef.list = list()
  for (n in row.names(coefs.matrix)) {
    if (coefs.matrix[n,] !=0) coef.list[n] = coefs.matrix[n,]
  }
  return(toJSON(coef.list, simplifyVector=TRUE, pretty = TRUE, digits=8))
}

# data to fit the note model
notes.off = source.notes[source.notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off.held.names = colnames(notes.off)[substr(names(notes.off),1,1)=="X"]
##use all predictors
#notes.off.predictor.names = colnames(source.notes)[2:(length(colnames(source.notes))-2)]
##use only held notes
notes.off.predictor.names  = notes.off.held.names
notes.off.formula = as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^3"))
notes.off$totalHeld=rowSums(notes.off[notes.off.held.names])
#remove initial nodes - i.e. there has to be one other note in range for this note to switch on
notes.off = subset(notes.off, totalHeld>0)
notes.off$totalHeld = NULL
notes.off.fit = note.log.model(notes.off, notes.off.formula)
h <- file("coef-off-11.json", "w")
cat(coefs.as.json(coef(notes.off.fit, s="lambda.1se")), file=h)
close(h)