require("glmnet")

notes = read.csv("dillpick.csv", header=TRUE)

# neg log likelihood cost
binomial.cost <- function(r, pi=0) {
#   print("r");
#   print(r);
#   print("pi");
#   print(pi);
  return(sum(-log(r*pi+(1-r)*(1-pi))))
}
# Is this better than neg log likelihood?

#data to fit the note REMOVAL model
notes.off = notes[notes$X0==0,]
notes.off[names(notes.off)=="X0"] = NULL
notes.off$totalHeld=rowSums(notes.off[substr(names(notes.off),1,1)=="X"])
#remove initial nodes
notes.off = subset(notes.off, totalHeld>1)
notes.off$totalHeld = NULL

notes.off.successes = notes.off[rep(row.names(notes.off), notes.off$ons),]
notes.off.successes$ons=NULL
notes.off.successes$offs=NULL
notes.off.successes$result=1
notes.off.fails = notes.off[rep(row.names(notes.off), notes.off$offs),]
notes.off.fails$ons=NULL
notes.off.fails$offs=NULL
notes.off.fails$result=0
notes.off = rbind(notes.off.successes, notes.off.fails)
rm(notes.off.fails)
rm(notes.off.successes)


#data to fit the note ADDITION mode.
notes.on = notes[notes$X0==1,]
notes.on[names(notes.on)=="X0"] = NULL
notes.on$totalHeld=rowSums(notes.on[substr(names(notes.on),1,1)=="X"])
#remove terminal nodes
notes.on = subset(notes.on, totalHeld>0)
notes.on$totalHeld = NULL

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

fit.on = cv.glmnet(as.matrix(notes.on[,-(ncol(notes.on))]),notes.on[,(ncol(notes.on))], family="binomial", alpha=1)
fit.off = cv.glmnet(as.matrix(notes.off[,-(ncol(notes.off))]),notes.off[,(ncol(notes.off))], family="binomial", alpha=1)

#glm.diag.plots(fit.on,glm.diag(fit.on))
