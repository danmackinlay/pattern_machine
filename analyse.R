require("penalized")

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

source.notes = read.csv("dillpick.csv", header=TRUE)

# data to fit the note model, GIVEN THE CURRENT NOTE IS OFF
# i.e. the note ADDITION model
notes.off = source.notes[source.notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off.predictor.names = colnames(notes.off)[substr(names(notes.off),1,1)=="X"]
notes.off$totalHeld=rowSums(notes.off[notes.off.predictor.names])
#remove initial nodes - i.e. there has to be one other note in range for this note to switch on
notes.off = subset(notes.off, totalHeld>0)
notes.off$totalHeld = NULL

notes.off.successes = notes.off[rep(row.names(notes.off), notes.off$ons),]
notes.off.successes$ons=NULL
notes.off.successes$offs=NULL
notes.off.successes$response=1
notes.off.fails = notes.off[rep(row.names(notes.off), notes.off$offs),]
notes.off.fails$ons=NULL
notes.off.fails$offs=NULL
notes.off.fails$response=0
notes.off = rbind(notes.off.successes, notes.off.fails)
rm(notes.off.fails)
rm(notes.off.successes)

# this would be how to manufacture interaction terms for oneself.
# homework: make sparse
# you would start with
notes.off.predictors.sparse = as(data.matrix(notes.off[notes.off.predictor.names]), "sparseMatrix")
notes.off.interaction.combs = combn(note.on.predictor.names,2)
notes.off.interaction.strings = apply(
  notes.off.interaction.combs, 2,
  function (intn.names) {
    paste(as.list(intn.names),  collapse="*")
  })
notes.off.interactions = apply(
  notes.off.interaction.combs, 2,
  function (intn.names) {
    notes.off.predictors.sparse[,intn.names[1]]*notes.off.predictors.sparse[,intn.names[2]]
  })
colnames(notes.off.interactions) = notes.off.interaction.strings

# # Finding an optimal cross-validated likelihood
# notes.off.opt = optL1(
#   response=notes.off$response,
#   penalized=as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^2")),
#   data=notes.off, model="logistic", trace=TRUE, fold = 10)
# plot(notes.off.opt$predictions)
# 
# # Plotting the profile of the cross-validated likelihood
# notes.off.prof <- profL1(
#   response=notes.off$response,
#   penalized=as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^2")),
#   data=notes.off, fold = notes.off.opt$fold, steps=20,
#   trace=TRUE)
# plot(notes.off.prof$lambda, notes.off.prof$cvl, type="l")
# plotpath(notes.off.prof$fullfit)

#data to fit the note model, GIVEN THE CURRENT NOTE IS ON
# i.e. note removal.
notes.on = source.notes[source.notes$X0==1,]
notes.on[names(notes.on)=="X0"] = NULL
notes.on.predictor.names = colnames(notes.on)[substr(names(notes.on),1,1)=="X"]
notes.on$totalHeld=rowSums(notes.on[notes.on.predictor.name])
#remove terminal nodes
# I.e. this note has to be interacting with at least one other note for us to care if it goes off
notes.on = subset(notes.on, totalHeld>0)
notes.on$totalHeld = NULL

notes.on.successes = notes.on[rep(row.names(notes.on), notes.on$ons),]
notes.on.successes$ons=NULL
notes.on.successes$offs=NULL
notes.on.successes$response=1
notes.on.fails = notes.on[rep(row.names(notes.on), notes.on$offs),]
notes.on.fails$ons=NULL
notes.on.fails$offs=NULL
notes.on.fails$response=0
notes.on = rbind(notes.on.successes, notes.on.fails)
rm(notes.on.fails)
rm(notes.on.successes)

#data to fit the COMBINED model, for tracking consonance
notes.predictor.names = colnames(source.notes)[substr(names(source.notes),1,1)=="X"]
notes = source.notes
notes$totalHeld=rowSums(source.notes[substr(names(source.notes),1,1)=="X"])
#remove initial nodes
notes = subset(source.notes, totalHeld>0)
notes$totalHeld = NULL

notes.successes = notes[rep(row.names(notes), notes$ons),]
notes.successes$ons=NULL
notes.successes$offs=NULL
notes.successes$response=1
notes.fails = notes[rep(row.names(notes), notes$offs),]
notes.fails$ons=NULL
notes.fails$offs=NULL
notes.fails$response=0
notes = rbind(notes.successes, notes.fails)
rm(notes.fails)
rm(notes.successes)
