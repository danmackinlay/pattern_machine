library("Matrix")
require(rhdf5)

trim.col = function(mat,n=0){
  trimmed = mat[,(n+1):(ncol(mat)-n)]
  mask = rowSums(mat)>0
  return(list(trimmed=trimmed[mask,], mask = mask))
}

dissect.coefs = function(coefs){
  #horrifically inefficient, but I can't be arsed working out how to do this better in R
  #it's not conceptually well-posed anyway
  scoefmags = (coefs[summary(coefs)$i])[-1]
  coefmags = abs(scoefmags)
  coefnames = rownames(coefs)[summary(coefs)$i][-1]
  coeford = order(coefmags, decreasing=T)
  coefchunks = data.frame()
  for (i in 1:length(coefnames)) {
    for (j in as.vector(str_split(coefnames[[i]], "[:x]")[[1]])) {
      coefchunks = rbind(coefchunks, data.frame(name = j, mag=coefmags[i]))
    }
  }
  coefchunks$name = as.factor(coefchunks$name)
  coefsumm = data.frame()
  for (j in levels(coefchunks$name)) {coefsumm = rbind(coefsumm, data.frame(name=j, mag = sum(coefchunks[coefchunks$name==j,"mag"])))}
  coefsumm=coefsumm[order(coefsumm$mag,decreasing=T),]
  return(list(
    mag.imp=data.frame(
      mag=scoefmags[coeford],
      name=as.factor(coefnames[coeford])), 
    chunks = coefsumm)
  )
}

#triangular feature fn
feat.tri = function(col, x0=1.0, radius=0.25) {
  return(pmax(1.0-abs((col-x0)/radius),0))
}

#peak-differentiable feature fn
feat.sin = function(...) {
  return(sin(pi/2*feat.tri(...)))
}
#everywhere differentiable feature fn
feat.sin2 = function(...) {
  return(sin(pi/2*feat.tri(...))^2)
}
