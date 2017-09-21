## @knitr R-linalg

## install.packages('RhpcBLASctl') # not installed by default on BCE
library(RhpcBLASctl)
x <- matrix(rnorm(5000^2), 5000)

blas_set_num_threads(4)
system.time({
   x <- crossprod(x)
   U <- chol(x)
})

##   user  system elapsed 
##  8.316   2.260   2.692 

blas_set_num_threads(1)
system.time({
   x <- crossprod(x)
   U <- chol(x)
})

##   user  system elapsed 
##  6.360   0.036   6.399 


## @knitr foreach

library(doParallel)  # uses parallel package, a core R package

source('rf.R')  # loads in data and looFit()

looFit

nCores <- 4  # to set manually
registerDoParallel(nCores) 

nSub <- 30  # do only first 30 for illustration

result <- foreach(i = 1:nSub) %dopar% {
	cat('Starting ', i, 'th job.\n', sep = '')
	output <- looFit(i, Y, X)
	cat('Finishing ', i, 'th job.\n', sep = '')
	output # this will become part of the out object
}
print(unlist(result[1:5]))

## @knitr parallel_lsApply

library(parallel)
nCores <- 4  # to set manually 
cl <- makeCluster(nCores) 

nSub <- 30
input <- seq_len(nSub) # same as 1:nSub but more robust

## clusterExport(cl, c('x', 'y')) # if the processes need objects
## from master's workspace (not needed here as no global vars used)

## need to load randomForest package within function
## when using par{L,S}apply, hence the TRUE (last) argument
system.time(
	res <- parSapply(cl, input, looFit, Y, X, TRUE) 
)
system.time(
	res2 <- sapply(input, looFit, Y, X)
)


## @knitr mclapply

system.time(
	res <- mclapply(input, looFit, Y, X, mc.cores = nCores) 
)


## @knitr RNG-apply

library(parallel)
library(rlecuyer)
nSims <- 250
taskFun <- function(i){
	val <- runif(1)
	return(val)
}

nCores <- 4
RNGkind()
cl <- makeCluster(nCores)
iseed <- 1
clusterSetRNGStream(cl = cl, iseed = iseed)
RNGkind() # clusterSetRNGStream sets RNGkind as L'Ecuyer-CMRG
## but it doesn't show up here on the master
res <- parSapply(cl, 1:nSims, taskFun)
## now redo with same master seed to see results are the same
clusterSetRNGStream(cl = cl, iseed = iseed)
res2 <- parSapply(cl, 1:nSims, taskFun)
identical(res,res2)
stopCluster(cl)

## @knitr RNGstream

RNGkind("L'Ecuyer-CMRG") 
seed <- 1
set.seed(seed)
## now start M workers 
s <- .Random.seed 
for (i in 1:M) { 
	s <- nextRNGStream(s) 
	# send s to worker i as .Random.seed 
} 

## @knitr RNG-mclapply

library(parallel)
library(rlecuyer)
RNGkind("L'Ecuyer-CMRG")
res <- mclapply(seq_len(nSims), taskFun, mc.cores = nCores, 
    mc.set.seed = TRUE) 
## this also seems to reset the seed when it is run
res2 <- mclapply(seq_len(nSims), taskFun, mc.cores = nCores, 
    mc.set.seed = TRUE) 
identical(res,res2)



