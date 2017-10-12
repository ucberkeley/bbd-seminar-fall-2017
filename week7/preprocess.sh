#!/bin/bash
# Job name:
#SBATCH --job-name=preprocess-spark
#
# Account:
#SBATCH --account=ac_scsguest
#
# Partition:
#SBATCH --partition=savio2
#
# Number of processes:
#SBATCH --ntasks=96
#
# Wall clock limit:
#SBATCH --time=1-00:00:00
#
module load java spark
module unload python # 2.7.8 results in problems
source /global/home/groups/allhands/bin/spark_helper.sh
spark-start
# for some reason it is looking in spark tempdir for files
spark-submit --master $SPARK_URL --driver-memory 40G $HOME/spark-fall-2017/preprocess.py > $HOME/spark-fall-2017/preprocess.out
spark-stop

