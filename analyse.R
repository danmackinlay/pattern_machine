library("Matrix")
#library("LiblineaR")
library("glmnet")
require(doMC)
registerDoMC(cores=4)

# Am I doing this wrong? I could model odds of each note sounding conditional on environment.
# Could also model, conditional on environemtn, which note goes on.
# More tractable, I could condition for note-on probabilities given the *number* of simultaneous notes
# this would possibly more interpretable.

# See packages glmnet, penalized, liblineaR, rms
# NB liblineaR has python binding
# NB glmnet and liblineaR do not support interaction terms natively
# NB glm doesn't support penalised regression.
# nice vignette: http://nlp.stanford.edu/manning/courses/ling289/logistic.pdf
# or traditional AIC style: http://data.princeton.edu/R/glms.html

#if this DOESN'T work, could go to a discrete PGM model, such as
# http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
# https://r-forge.r-project.org/R/?group_id=1487
# gRaphHD http://www.jstatsoft.org/v37/i01/
# http://www.bnlearn.com/
# but let's stay simple.

source.notes = read.csv("rag.csv", header=TRUE)

note.log.model = function(notes.data) {
  notes.predictor.names = colnames(notes.data)[substr(names(notes.data),1,1)=="X"]
  notes.successes = notes.data[rep(row.names(notes.data), notes.data$ons),]
  notes.successes$ons=NULL
  notes.successes$offs=NULL
  notes.successes$response=1
  notes.fails = notes.data[rep(row.names(notes.data), notes.data$offs),]
  notes.fails$ons=NULL
  notes.fails$offs=NULL
  notes.fails$response=0
  notes.data = rbind(notes.successes, notes.fails)
  rm(notes.fails)
  rm(notes.successes)
  
  # the original data frame and formula
  notes.formula = as.formula(paste("~(", paste(notes.predictor.names, collapse="+"), ")^2"))
  notes.predictors.sparse=sparse.model.matrix(notes.formula, notes.data)
  notes.response=as.matrix(notes.data$response)
  #notes.fit.time = system.time( //don't seem to work with multicore
  notes.fit = cv.glmnet(notes.predictors.sparse,
                        notes.response,
                        family="binomial",
                        alpha=1, parallel=TRUE)
  #)
  return(notes.fit)
}

# data to fit the note model, GIVEN THE CURRENT NOTE IS OFF
# i.e. the note ADDITION model
notes.off = source.notes[source.notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off.predictor.names = colnames(notes.off)[substr(names(notes.off),1,1)=="X"]
notes.off$totalHeld=rowSums(notes.off[notes.off.predictor.names])
#remove initial nodes - i.e. there has to be one other note in range for this note to switch on
notes.off = subset(notes.off, totalHeld>0)
notes.off$totalHeld = NULL

notes.off.fit = note.log.model(notes.off)

#data to fit the note model, GIVEN THE CURRENT NOTE IS ON
# i.e. note removal.
notes.on = source.notes[source.notes$X0==1,]
notes.on[names(notes.on)=="X0"] = NULL
notes.on.predictor.names = colnames(notes.on)[substr(names(notes.on),1,1)=="X"]
notes.on$totalHeld=rowSums(notes.on[notes.on.predictor.names])
#remove terminal nodes
# I.e. this note has to be interacting with at least one other note for us to care if it goes off
notes.on = subset(notes.on, totalHeld>0)
notes.on$totalHeld = NULL

notes.on.fit = note.log.model(notes.on)

#data to fit the COMBINED model, for tracking consonance
notes.all.predictor.names = colnames(source.notes)[substr(names(source.notes),1,1)=="X"]
notes.all = source.notes
notes.all$totalHeld=rowSums(source.notes[substr(names(source.notes),1,1)=="X"])
#remove initial nodes
notes.all = subset(notes.all, totalHeld>0)
notes.all$totalHeld = NULL

notes.all.fit = note.log.model(notes.all)