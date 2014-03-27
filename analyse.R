notes = read.csv("dillpick.csv", header=TRUE)
fit = glm(cbind(passes, fails=trials-passes)~X0*(X.6 + X.5 + X.4 + X.3 + X.2 + X.1 + X1 + X2 + X3 +X4 + X5 +X6),data=notes, family="binomial")
