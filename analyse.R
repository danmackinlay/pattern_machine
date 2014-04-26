library("Matrix")
#library("LiblineaR")
library("glmnet")
library("stringr")
library("jsonlite")
require(doMC)
registerDoMC(cores=2)

###settings
# how many cases we throw out (oversampling of cases means the data set blows up)
case.scale.factor = 24


# Am I doing this wrong? I could model odds of each note sounding conditional on environment.
# Could also model, conditional on environment, which note goes on.
# More tractable, I could condition for note-on probabilities given the *number* of simultaneous notes
# this would possibly more interpretable. But I would lose a lot of speed when I throw out sparsity.

# See packages glmnet, liblineaR, rms
# NB liblineaR has python binding
# NB glmnet and liblineaR do not support interaction terms natively
# NB glm doesn't support penalised regression.
# or traditional AIC style: http://data.princeton.edu/R/glms.html
# see also http://www.stanford.edu/~hastie/glmnet/glmnet_alpha.html for an excellent guide
#and http://www.jstatsoft.org/v33/i01/paper

#if this DOESN'T work, could go to a discrete PGM model, such as
# http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
# https://r-forge.r-project.org/R/?group_id=1487
# gRaphHD http://www.jstatsoft.org/v37/i01/
# http://www.bnlearn.com/
# but let's stay simple.

source.notes = read.csv("rag-11.csv", header=TRUE)
source.notes$file = as.factor(source.notes$file)

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
  notes.predictors.sparse=sparse.model.matrix(notes.formula, notes.data)
  notes.response=as.matrix(notes.data$response)
  notes.fit = 0
  notes.fit.time = system.time( #note this only works for <- assignment!
    notes.fit <- cv.glmnet(notes.predictors.sparse,
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
export.formula <- function (coefs.matrix) {
#cast to string for export
#   coef.list = list()
#   for (n in row.names(coefs.matrix)) {
#     if (coefs.matrix[n,] !=0) coef.list[n] = coefs.matrix[n,]
#   }
  export.formula = "["
  for (n in row.names(coefs.matrix)) {
    if (coefs.matrix[n,] !=0) {
      export.formula = paste(export.formula, "[")
      coef.bit = strsplit(
        str_replace_all(str_replace_all(n, "X",""), "[.]", "-"), ":"
      )
      export.formula = paste(
        export.formula, 
        paste(
          coef.bit
        ), sep=", "
      )
      export.formula = paste(export.formula, coefs.matrix[n,], sep=", ")
      export.formula = paste(export.formula, "]")
      export.formula = paste(export.formula, "]")
      #coef.list[n] = coefs.matrix[n,]
    }
  }
  export.formula = paste(export.formula, "]")
  return(export.formula)
}

# data to fit the note model, GIVEN THE CURRENT NOTE IS OFF
# i.e. the note ADDITION model
# with the new onset-led model, this is the only fit of relevence.
notes.off = source.notes[source.notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off.held.names = colnames(notes.off)[substr(names(notes.off),1,1)=="X"]
#use all predictors
#notes.off.predictor.names = colnames(source.notes)[2:(length(colnames(source.notes))-2)]
#use only held notes
notes.off.predictor.names  = notes.off.held.names
notes.off.formula = as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^2"))

notes.off$totalHeld=rowSums(notes.off[notes.off.held.names])
#remove initial nodes - i.e. there has to be one other note in range for this note to switch on
notes.off = subset(notes.off, totalHeld>0)
notes.off$totalHeld = NULL

