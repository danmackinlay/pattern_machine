require("glmnet")

# Am I doing this wrong? I could model odds of each note going on conditional on environemtn.
# Could also model, conditional on environemtn, which note goes on.
# More tractable, I could condition for note-on probabilities given the *number* of simultaneous notes
# this would possibly more interpretable.

# See packages glmnet, penalized, liblineaR, rms
# NB liblineaR has python binding
# NB glmnet and liblineaR do not support interaction terms
# NB glm doesn't support penalised regression.
# nice vignette: http://nlp.stanford.edu/manning/courses/ling289/logistic.pdf
# or traditional AIC style: http://data.princeton.edu/R/glms.html

notes = read.csv("dillpick.csv", header=TRUE)

#data to fit the note REMOVAL model
notes.off = notes[notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off.predictor.names = colnames(notes.off)[substr(names(notes.off),1,1)=="X"]
notes.off$totalHeld=rowSums(notes.off[notes.off.predictor.names])
#remove initial nodes
notes.off = subset(notes.off, totalHeld>1) #is this coherent?
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

#notes.off.fit=penalized(response=notes.off$response, penalized=as.formula(paste("~", paste(notes.off.predictor.names, collapse="+"))), lambda1=0, data=notes.off, model="logistic", trace=TRUE)
## penalized:
#notes.off.fit=penalized(response=notes.off$response, penalized=as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^2")), lambda1=1, data=notes.off, model="logistic", trace=TRUE)
# Finding an optimal cross-validated likelihood
notes.off.opt = optL1(
  response=notes.off$response,
  penalized=as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^2")),
  data=notes.off, model="logistic", trace=TRUE, fold = 10)
coefficients(notes.off.opt$fullfit)
plot(notes.off.opt$predictions)

# Plotting the profile of the cross-validated likelihood
notes.off.prof <- profL1(
  response=notes.off$response,
  penalized=as.formula(paste("~(", paste(notes.off.predictor.names, collapse="+"), ")^2")),
  trace=TRUE, 
  fold = opt$fold, steps=20)
plot(notes.off.prof$lambda, notes.off.prof$cvl, type="l")
plotpath(notes.off.prof$fullfit)


#data to fit the note ADDITION mode.
notes.on = notes[notes$X0==1,]
notes.on[names(notes.on)=="X0"] = NULL
notes.on.predictor.names = colnames(notes.on)[substr(names(notes.on),1,1)=="X"]
notes.on$totalHeld=rowSums(notes.on[notes.on.predictor.name])
#remove terminal nodes
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
notes.predictor.names = colnames(notes)[substr(names(notes),1,1)=="X"]
notes[substr(names(notes),1,1)=="X"]
notes$totalHeld=rowSums(notes[substr(names(notes),1,1)=="X"])
#remove initial nodes
notes = subset(notes, totalHeld>0)
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

# #this would be how to manufacture interaction terms for oneself.
# notes.on.predictor.names = colnames(notes.on)[-ncol(notes.on)]
# notes.on.interaction.names = combn(note.on.predictor.names,2)
# notes.on.interaction.strings = apply(notes.on.interaction.names, 2, function (col) {paste(as.list(col),  collapse="*")})
# notes.on.interactions = apply(notes.on.interaction.names, 2, function (col) {notes.on[,col[1]]*notes.on[,col[2]]})
# colnames(notes.on.interactions) = notes.on.interaction.strings
# # homework: make sparse
# # you would start with
# # notes.on.predictors.sparse = as(data.matrix(notes.on[notes.on.predictor.names]), "sparseMatrix")
