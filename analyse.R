notes = read.csv("dillpick.csv", header=TRUE)

# appropriate cost function for logistic binary responses:
binomial.cost <- function(r, pi=0) {
#   print("r");
#   print(r);
#   print("pi");
#   print(pi);
  return(mean(abs(r-pi)>0.5))
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

fit.on = glm(cbind(ons, offs)~(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6)^2, data=notes.on, family="binomial")
fit.off = glm(cbind(ons, offs)~(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6)^2, data=notes.off, family="binomial")

# both these are LOOCV
# fit.on.cv.err <- cv.glm(notes.on, fit.on, binomial.cost, K=nrow(notes.on))$delta
# fit.on.cv.err <- cv.glm(notes.on, fit.on, binomial.cost)$delta
# 11-fold CV, FWIW
fit.on.cv.11.err <- cv.glm(notes.on, fit.on, binomial.cost, K=11)$delta

# However, models fit to the binomial responses instead of boolean responses have 
# defective cross validation - every probability has the same weight regardless of
# how many samples it has. Nasty.

glm.diag.plots(fit.on,glm.diag(fit.on))

#TODO: regularized fit
#probably glmnet


