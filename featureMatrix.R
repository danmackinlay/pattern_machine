# poor-man's model.matrix
# works on matrices as well as data frames
# does not support the fabulous complexity of "formula"
# TODO: fix up colum ordering
# - not quite right for e.g. 
# - with(test.mats(),pred.matrix.product(pred.matrix.squared(A, "+"), A, "+"))
# check preservation of sparseness
test.mats = function(){
  r=c(1,2,3,4)
  cA=c(1,2,3,4,5)
  cB=c(6,7,8)
  A=as.matrix(outer(r,cA*10,'+'))
  B=as.matrix(outer(r,cB*10,'+'))*100
  colnames(A)=paste("A",cA, sep="")
  colnames(B)=paste("B",cB, sep="")
  return(list(A=A,B=B))
}
pred.matrix.squared = function(A, fn="*", include.self=T, ...){
  fn = match.fun(fn)
  aCols = 1:ncol(A)
  #can't use JUST aCols as that misses e.g 3:3
  newcols = combn(aCols,2)
  if (include.self) {
    newcols = cbind(rbind(aCols,aCols),newcols)
    newcols = newcols[,order(newcols[2,],newcols[1,])]
  }
  prod=fn(A[,newcols[1,]],(A[,newcols[2,]]),...)
  colnames(prod)=paste(colnames(A)[newcols[1,]],colnames(A)[newcols[2,]],sep=":")
  return(prod)
}
pred.matrix.product = function(A, B, fn="*", ...){
  fn = match.fun(fn)
  newcols=expand.grid(Acol=1:ncol(A),Bcol=1:ncol(B))
  prod=fn(A[,newcols$Acol],(B[,newcols$Bcol]), ...)
  colnames(prod)=paste(colnames(A)[newcols$Acol],colnames(B)[newcols$Bcol],sep=":")
  return(prod)
}