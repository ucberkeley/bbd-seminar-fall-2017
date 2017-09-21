## @knitr doMPI

## you should have invoked R as:
## mpirun -machinefile .hosts -np 1 R CMD BATCH --no-save file.R file.out
## unless in a SLURM job, in which case do not use -machinefile or -np

library(Rmpi)
library(doMPI)

cl = startMPIcluster()
## by default will start one fewer slave than elements in .hosts
                                        
registerDoMPI(cl)
print(clusterSize(cl)) # just to check

results <- foreach(i = 1:200) %dopar% {
  out = mean(rnorm(1e6))
}

print('hi')

closeCluster(cl)

mpi.quit()
