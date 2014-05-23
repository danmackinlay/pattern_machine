library("Matrix")
#library("LiblineaR")
library("glmnet")
library("stringr")
library("jsonlite")
#disable parallelism for now because of ram shortage
#require(doMC)
#registerDoMC(cores=2)
require(rhdf5)
source("featureMatrix.R")

#TODO: I have a lot of data here;
# should probably throw over CV and do straight training/prediction split
# todo: fits should know own AND NEIGHBOURS' base rates
# remove rows, and disambiguate what remains. (trimming columns leads to spurious duplicates with 0 notes in)
# Add a logical feature specifying bar position; possibly fit separate models for each

# Bonus datasets I jsut noticed on http://deeplearning.net/datasets/
# Piano-midi.de: classical piano pieces (http://www.piano-midi.de/)
# Nottingham : over 1000 folk tunes (http://abc.sourceforge.net/NMD/)
# MuseData: electronic library of classical music scores (http://musedata.stanford.edu/)
# JSB Chorales: set of four-part harmonized chorales (http://www.jsbchorales.net/index.shtml)

# see also the deep learning approach: http://deeplearning.net/tutorial/rnnrbm.html#rnnrbm andd
# http://www-etud.iro.umontreal.ca/~boulanni/ICML2012.pdf

# Deep learning feels like overkill, but i feel like i could do som unprincipled feature construction;
# we suspect marginal changes in features have a linear effect, fine
# but we also suspect that interaction terms are critical;
# can we manufacture some hopefully-good features without an exhuastive, expensive, simultaneous optimisation over all of them?
# Naive approach: walk through term-interactio space, discrectized. Start with one predictor, and add additional predictors randomly (greedily) if the combination has improved deviance wrt the mean. it "feels" like features shoudl be positive or negative
# # If i wanted features that did not naturally look discrete i coudl fit minature linear models to each combination?
# # Or make features that correspond to being "near" some value
# # it seems like boolean opeartions on features should also be allowed - intersections and unions and such
# # this could be  naturally accomplished by generating each generation of eatures from the previous and ditching the crappy ones. This feels dangerously close to evolutionary algorithms, or maybe random forests or somesuch. vectorisable tho.
# I could always give up and infer hidden markov states. sigh.

###settings
# how many observations we throw out (oversampling of cases means the data set blows up)
row.thin.factor = 6
# how many we cut off the edge of note neighbourhood
col.trim.count = 0

#function to trim rows from a sparse matrix (also removes entirely rows which are all 0, which is only appropriate for this particular model.)
trim.col = function(mat,n=0){
  trimmed = mat[,(n+1):(ncol(mat)-n)]
  mask = rowSums(mat)>0
  return(list(trimmed=trimmed[mask,], mask = mask))
}

#can't work out how to extract this as attribute, although should as it is data-dependent
max.age = 1.5

#local settings
radius = 0.125

# Am I doing this wrong? I could model odds of each note sounding conditional on environment.
# Could also model, conditional on environment, which note goes on.
# More tractable, I could condition for note-on probabilities given the *number* of simultaneous notes
# this would possibly more interpretable. But I would lose a lot of speed when I throw out sparsity.
# should try and attribute amt of error to each song

# See packages glmnet, liblineaR, rms
# NB liblineaR has python binding
# if we wished to use non penalized regression, could go traditional AIC style: http://data.princeton.edu/R/glms.html
# OR even do hierarchical penalised regression using http://cran.r-project.org/web/packages/glinternet/index.html
# For now
# see http://www.stanford.edu/~hastie/glmnet/glmnet_alpha.html for an excellent guide
# and http://www.jstatsoft.org/v33/i01/paper

#if this DOESN'T work, could go to a discrete PGM model, such as
# http://cran.r-project.org/web/packages/catnet/vignettes/catnet.pdf
# https://r-forge.r-project.org/R/?group_id=1487
# gRaphHD http://www.jstatsoft.org/v37/i01/
# http://www.bnlearn.com/
# but let's stay simple.

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

coefs.as.json <- function (coefs.matrix) {
  coef.list = list()
  for (n in row.names(coefs.matrix)) {
    if (coefs.matrix[n,] !=0) coef.list[n] = coefs.matrix[n,]
  }
  return(toJSON(coef.list, simplifyVector=TRUE, pretty = TRUE, digits=8))
}

#triangular feature fn
feat.tri = function(col, x0=1.0, radius=0.25) {
  return(pmax(1.0-abs((col-x0)/radius),0))
}

#peak-differntiable feature fn
feat.sin = function(...) {
  return(sin(pi/2*feat.tri(...)))
}
#everywhere differntiable feature fn
feat.sin2 = function(...) {
  return(sin(pi/2*feat.tri(...))^2)
}

basic.obs.matrix = function () {
  #should i use the obsids as names here?
  fmat = sparseMatrix(
      i=notes.obsid,
      j=notes.p,
      x=notes.recence,
      dims=notes.dims,
      index1=F
  )
  colnames(fmat)=paste(notes.colnames$rname)
  return(fmat)
}

feature.matrix = function (sourceSparseMat, x0=1.0, radius=0.25, f.num=0) {
  feat.val = feat.tri(sourceSparseMat@x, max.age, radius)
  #should i use the obsids as names here?
  fmat = drop0(sparseMatrix(
    i=sourceSparseMat@i,
    p=sourceSparseMat@p,
    x=feat.val,
    dims=sourceSparseMat@Dim,
    index1=F
  ))
  colnames(fmat)=paste(notes.colnames$rname,f.num, sep='xF')
  return(fmat)
}

#load actual data
notes.obsdata = h5read("rag-11.h5", "/note_meta")
notes.obsdata$file = as.factor(notes.obsdata$file)
notes.obsid = as.vector(h5read("rag-11.h5", '/v_obsid'))
notes.p = as.vector(h5read("rag-11.h5", '/v_p'))
notes.recence = as.vector(h5read("rag-11.h5", '/v_recence'))
notes.dims = c(max(notes.obsid)+1, max(notes.p)+1)
notes.colnames = h5read("rag-11.h5", "/col_names")

#hist(notes.recence, breaks=seq(0,1.56,1/64)-1/128)
#THIS IS NOW A MESS AND COLUMN TRIMMING IS TEMPORARILY NOT SUPPORTED
notes.base.f = basic.obs.matrix()

if (row.thin.factor>1) {
  n = nrow(notes.base.f)
  samp = sample.int(n,floor(n/row.thin.factor))
  notes.base.f = notes.base.f[samp,]
  notes.obsdata = notes.obsdata[samp,]
}
if (col.trim.count>0) {
  trimmed = trim.col(notes.base.f)
  notes.base.f = trimmed$trimmed
  notes.obsdata = notes.obsdata[trimmed$mask,]
}
notes.f0 = feature.matrix(notes.base.f, max.age, radius, 0)
notes.f4 = feature.matrix(notes.base.f, max.age-4*radius, radius, 4)
notes.f = cBind(notes.f0, pred.matrix.squared(notes.f0))
notes.f = cBind(notes.f, notes.f4, pred.matrix.product(notes.f, notes.f4))
notes.f = cBind(notes.f, pred.matrix.cubed(notes.f0))
#A mere 8000 columns.

notes.response=as.matrix(notes.obsdata$result)

notes.fit.time = system.time( #note this only works for <- assignment!
  notes.fit <- cv.glmnet(
    notes.f,
    notes.response,
    family="binomial",
    type.logistic="modified.Newton",
    alpha=1,
    #parallel=TRUE,
    foldid=unclass(notes.obsdata$file)
  )
)
print(notes.fit.time)

h <- file("coef-cont.json", "w")
cat(coefs.as.json(coef(notes.fit, s="lambda.1se")), file=h)
close(h)
