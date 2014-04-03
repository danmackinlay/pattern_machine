notes = read.csv("dillpick.csv", header=TRUE)

# neg log likelihood cost
binomial.cost <- function(r, pi=0) {
#   print("r");
#   print(r);
#   print("pi");
#   print(pi);
  return(mean(-log(r*pi+(1-r)*(1-pi))))
}
# Is this better than neg log likelihood?

#data to fit the note REMOVAL model
notes.off = notes[notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off$totalHeld=rowSums(notes.off[substr(names(notes.off),1,1)=="X"])
#remove initial nodes
notes.off = subset(notes.off, totalHeld>1)
notes.off$totalHeld = NULL

#data to fit the note ADDITION mode.
notes.on = notes[notes$X0==1,]
notes.on[names(notes.on)=="X0"] = NULL
notes.on$totalHeld=rowSums(notes.on[substr(names(notes.on),1,1)=="X"])
#remove terminal nodes
notes.on = subset(notes.on, totalHeld>0)
notes.on$totalHeld = NULL

#TODO: regularized fit
#probably glmnet
notes.on.successes = notes.on[rep(row.names(notes.on), notes.on$ons),]
notes.on.successes$ons=NULL
notes.on.successes$offs=NULL
notes.on.successes$result=1
notes.on.fails = notes.on[rep(row.names(notes.on), notes.on$offs),]
notes.on.fails$ons=NULL
notes.on.fails$offs=NULL
notes.on.fails$result=0
notes.on = rbind(notes.on.successes, notes.on.fails)
rm(notes.on.fails)
rm(notes.on.successes)

notes.off.successes = notes.on[rep(row.names(notes.on), notes.on$ons),]
notes.off.successes$ons=NULL
notes.off.successes$offs=NULL
notes.off.successes$result=1
notes.off.fails = notes.on[rep(row.names(notes.on), notes.on$offs),]
notes.off.fails$ons=NULL
notes.off.fails$offs=NULL
notes.off.fails$result=0
notes.off = rbind(notes.off.successes, notes.off.fails)
rm(notes.off.fails)
rm(notes.off.successes)

fit.on = glm(result~(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6)^2, data=notes.on, family="binomial")
fit.off = glm(result~(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6)^2, data=notes.off, family="binomial")

# both these are LOOCV
# fit.on.cv.err <- cv.glm(notes.on, fit.on, binomial.cost, K=nrow(notes.on))$delta
# fit.on.cv.err <- cv.glm(notes.on, fit.on, binomial.cost)$delta
# 11-fold CV, FWIW
fit.on.cv.11.err <- cv.glm(notes.on, fit.on, binomial.cost, K=11)$delta

# However, models fit to the binomial responses instead of boolean responses have 
# defective cross validation - every probability has the same weight regardless of
# how many samples it has. Nasty.

glm.diag.plots(fit.on,glm.diag(fit.on))
