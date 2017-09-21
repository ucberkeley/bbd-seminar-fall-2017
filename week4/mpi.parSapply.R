## @knitr mpi.parSapply

library(Rmpi)

## on my system, this fails unless explicitly
## ask for one fewer slave than total number of slots across hosts
mpi.spawn.Rslaves(nslaves = mpi.universe.size()-1)

myfun <- function(i) {
      set.seed(i)
      mean(rnorm(1e7))
}

x <- seq_len(25)
# parallel sapply-type calculations on a vector 
system.time(out <- mpi.parSapply(x, myfun))
system.time(out <- mpi.applyLB(x, myfun))

nrows <- 10000
x <- matrix(rnorm(nrows*50), nrow = nrows)
# parallel apply on a matrix
out <- mpi.parApply(x, 1, mean)

mpi.close.Rslaves()
mpi.quit()
