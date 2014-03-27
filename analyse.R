notes = read.csv("dillpick.csv", header=TRUE)
notes_on = notes[notes$X0==1,]
notes_off = notes[notes$X0==0,]
fit_on = glm(cbind(ons, offs)~(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6)^2, data=notes_on, family="binomial")
fit_off = glm(cbind(ons, offs)~(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6)^2, data=notes_off, family="binomial")
