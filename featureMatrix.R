library("Matrix")
# poor-man's model.matrix
# works on matrices as well as data frames
# does not support the fabulous complexity of "formula"
# DENSE TEST STRING:
# - with(test.mats(),pred.matrix.product(pred.matrix.selfproduct(A, "+"), A, "+"))
# NB - this combination is not the same as "cubing" the formula -
# still get interactions like X1:X1:X2, i.e. with 2 terms the same
# This uses suspiciously much intermediate memory; why?
# TODO implement include.orig in some memory-happy fashion

test.mats = function(){
  r=c(1,2,3,4)
  cA=c(1,2,3,4,5)
  cB=c(6,7,8)
  A=as.matrix(outer(r,cA*10,'+'))
  B=as.matrix(outer(r,cB*10,'+'))*100
  colnames(A)=paste("A",1:ncol(A), sep="")
  colnames(B)=paste("B",1:ncol(B), sep="")
  return(list(A=A,B=B))
}
test.mats.sparse = function(){
  r=c(1,0,2,0,3,0,4.0)
  cA=c(0,1,0,2,0,3,0,4,0,5)
  cB=c(6,0,7,0,8,0)
  A=Matrix(outer(r,cA,'*'), sparse=T)
  B=Matrix(outer(r,cB,'*')*100, sparse=T)
  colnames(A)=paste("A",1:ncol(A), sep="")
  colnames(B)=paste("B",1:ncol(B), sep="")
  return(list(A=A,B=B))
}

pred.matrix.selfproduct = function(A, fn="*", include.self=F, include.orig=F, ...){
  fn = match.fun(fn)
  aCols = 1:ncol(A)
  newcols = combn(aCols,2)
  if (include.self) {
    #Can an element be paired with itself?
    newcols = cbind(rbind(aCols,aCols),newcols)
    newcols = newcols[,order(newcols[2,],newcols[1,])]
  }
  newcolnames = paste(colnames(A)[newcols[1,]],colnames(A)[newcols[2,]],sep=":")
  prod=fn(A[,newcols[1,]],(A[,newcols[2,]]),...)
  colnames(prod)= newcolnames
  return(prod)
}

pred.matrix.product = function(A, B, fn="*", include.orig=F, ...){
  fn = match.fun(fn)
  newcols=expand.grid(Bcol=1:ncol(B),Acol=1:ncol(A))
  prod=fn(A[,newcols$Acol],(B[,newcols$Bcol]), ...)
  colnames(prod)=paste(colnames(A)[newcols$Acol],colnames(B)[newcols$Bcol],sep=":")
  return(prod)
}