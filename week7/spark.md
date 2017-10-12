% Spark and sparklyr demonstration
% October 16, 2017
% Chris Paciorek, Department of Statistics and Berkeley Research Computing, UC Berkeley

# 'Big Data'

Big data is [trendy these days](http://i2.wp.com/blog.datacamp.com/wp-content/uploads/2014/03/big-data.jpg). 


Personally, I think some of the hype is justified and some is hype. Large datasets allow us to address questions that we can't with smaller datasets, and they allow us to consider more sophisticated (e.g., nonlinear) relationships than we might with a small dataset. But they do not directly help with the problem of correlation not being causation. 

 - Having medical data on every American still doesn't tell me if higher salt intake causes high blood pressure.
 - Internet transaction data does not tell me if one website feature causes increased viewership or sales. 

One either needs to carry out a designed experiment or think carefully about how to infer causation from observational data. 

Nor does big data help with the problem that an ad hoc 'sample' is not a statistical sample and does not provide the ability to directly infer properties of a population. 

 - A well-chosen smaller dataset may be much more informative than a much larger, more ad hoc dataset. 

However, having big datasets might allow you to select from the dataset in a way that helps get at causation or in a way that allows you to construct a population-representative sample. Finally, having a big dataset also allows you to do a large number of statistical analyses and tests, so multiple testing is a big issue. With enough analyses, something will look interesting just by chance in the noise of the data, even if there is no underlying reality to it. 


# Overview of Hadoop, MapReduce, and Spark

Here we'll talk about a fairly recent development in parallel computing. Traditionally, high-performance computing (HPC) has concentrated on techniques and tools for message passing such as MPI and on developing efficient algorithms to use these techniques.

# MapReduce

A basic paradigm for working with big datasets is the MapReduce paradigm. The basic idea is to store the data in a distributed fashion across multiple nodes and try to do the computation in pieces on the data on each node. Results can also be stored in a distributed fashion.

A key benefit of this is that if you can't fit your dataset on disk on one machine, you generally can on a cluster of machines. And your processing of the dataset can happen in parallel. This is the basic idea of MapReduce.

The basic steps of MapReduce are as follows:

 - read individual data objects (e.g., records/lines from CSVs or individual data files)
 - map: create key-value pairs using the inputs (more formally, the map step takes a key-value pair and returns a new key-value pair)
 - reduce - for each key, do an operation on the associated values and create a result - i.e., aggregate within the values assigned to each key
 - write out the {key,result} pair

An example of key-value pairs is as follows. Suppose you have a dataset of individuals with information on their income and the state in which they live and you want to calculate the average and income within each state. In this case, one starts with a dataset of individual-level rows and uses a map step to set the key to be the state and the value to be income for an individual. Then the reduce step finds the mean and standard deviation of all the values with the same key (i.e., in the same state).

More explicitly the reduce step involves summing income and summing squared income and summing the number of individuals in each state and using those summary statistics to compute average and standard deviation. 

It's actually pretty similar to functionality in dplyr, and dplyr can connect to a Spark instance, while the sparklyr R package allows for use of dplyr syntax. 

# What does can we do with MapReduce?

 - basic database-like operations on datasets: transformation of records, filtering
 - aggregation/summarization by groups
 - run algorithms (e.g., statistical fitting) that can be written as a series of map and reduce steps (e.g., gradient-based optimization, certain linear algebra operations)

# Hadoop and Spark

Hadoop is an infrastructure for enabling MapReduce across a network of machines. The basic idea is to hide the complexity of distributing the calculations and collecting results. Hadoop includes a file system for distributed storage (HDFS), where each piece of information is stored redundantly (on multiple machines). Calculations can then be done in a parallel fashion, often on data in place on each machine thereby limiting the amount of communication that has to be done over the network. Hadoop also monitors completion of tasks and if a node fails, it will redo the relevant tasks on another node. Hadoop is based on Java.

Setting up a Hadoop cluster can be tricky. Hopefully if you're in a position to need to use Hadoop, it will be set up for you and you will be interacting with it as a user/data analyst.

Ok, so what is Spark? You can think of Spark as in-memory Hadoop. Spark allows one to treat the memory across multiple nodes as a big pool of memory. Spark should be faster than Hadoop when the data will fit in the collective memory of multiple nodes. In cases where it does not, Spark will sequentially process through the data, reading and writing to the HDFS.

# Spark: Overview

We'll focus on Spark rather than Hadoop for the speed reasons described above and because I think Spark provides a very nice environment/interface in which to work. Plus it comes out of the (former) AmpLab here at Berkeley. We'll start with the Python interface to Spark and then see a bit of sparklyr.

More details on Spark are in the [Spark programming guide](https://spark.apache.org/docs/latest/rdd-programming-guide.html).

Some key aspects of Spark:

  - Spark can read/write from various locations, but a standard location is the **HDFS**, with read/write done in parallel across the cores of the Spark cluster.
  - A common data structure in Spark is a **Resilient Distributed Dataset (RDD)**, which acts like a sort of distributed data frame. 
  - RDDs are stored in chunks called **partitions**, stored on the different nodes of the cluster (either in memory or if necessary on disk).
  - Spark has a core set of methods that can be applied to RDDs to do operations such as **filtering/subsetting, transformation/mapping, reduction, and others**.
  - The operations are done in **parallel** on the different partitions of the data
  - Some operations such as reduction generally involve a **shuffle**, moving data between nodes of the cluster. This is costly.
  - Recent versions of Spark have distributed **DataFrames** and the ability to run SQL queries on the data.

Note that some headaches with Spark include:

 - whether and how to set the amount of memory available for Spark workers (executor memory) and the Spark master process (driver memory)
 - hard-to-diagnose failures (including out-of-memory issues)

# Getting started

We'll use Spark on Savio. You can also use Spark on XSEDE Bridges (among other XSEDE resources), and via commercial cloud computing providers, as well as on your laptop (but obviously only to experiment with small datasets). The demo works with a dataset of Wikipedia traffic, ~110 GB of zipped data (~500 GB unzipped) from October-December 2008, though for in-class presentation we'll work with a much smaller set of 1 day of data.

The Wikipedia traffic are available  through Amazon Web Services storage. The steps to get it are:

1) Start an AWS EC2 virtual machine that mounts the data onto the VM
2) Install Globus on the VM
3) Transfer the data to Savio via Globus

Details on how I did this are in *get_data.sh*.

# Storing data for use in Spark

In many Spark contexts, the data would be stored in a distributed fashion across the hard drives attached to different nodes of a cluster (i.e., in the HDFS). 

On Savio, Spark is set up to just use the scratch file system, so one wouldn't run the code here, but I'm including it to give a sense for what it's like to work with HDFS.
 
First we would need to get the data from the standard filesystem to the HDFS. Note that the file system commands are like standard UNIX commands, but you need to do `hadoop fs` in front of the command. 

These code is also in *hdfs.sh*.

```
hadoop fs -ls /
hadoop fs -ls /user
hadoop fs -mkdir /user/paciorek/data
hadoop fs -mkdir /user/paciorek/data/wikistats
hadoop fs -mkdir /user/paciorek/data/wikistats/raw
hadoop fs -mkdir /user/paciorek/data/wikistats/dated

hadoop fs -copyFromLocal /global/scratch/paciorek/wikistats/raw/* \
       /user/paciorek/data/wikistats/raw

# check files on the HDFS, e.g.:
hadoop fs -ls /user/paciorek/data/wikistats/raw

## now do some processing with Spark, e.g., preprocess.{sh,py}

# after processing can retrieve data from HDFS as needed
hadoop fs -copyToLocal /user/paciorek/data/wikistats/dated .
```

# Using Spark on Savio

Here are the steps to use Spark on Savio. We'll demo using an interactive job but one could include these commands in the SLURM job script.

```
# do this in an interactive job after running srun or as part of your job script
# e.g.,: srun -A ic_pht32 -p savio2 --nodes=4 -t 1:00:00 --pty bash
module load java spark 
source /global/home/groups/allhands/bin/spark_helper.sh
spark-start
```

The current Spark setup is a bit out of date and will be updated in the next couple months. But for now, we'll have to live with a few shortcomings.

First make sure only the default Python 2.6.6 is loaded.
```
module unload python
```

We can now use Spark via the Python interface interactively. We'll see how to submit batch jobs later.

```
pyspark --master $SPARK_URL --executor-memory 50G
```

# Preprocessing the Wikipedia traffic data

At this point, one complication is that the date-time information on the Wikipedia traffic is embedded in the file names. We'd like that information to be fields in the data files. This is done by running the code in *preprocess.py* in the Python interface to Spark (pyspark). Note that trying to use multiple nodes and to repartition in various ways caused various errors I was unable to diagnose, but the code as is should work albeit somewhat slowly.

In principle one could run the *preprocess.sh* SLURM job script to run *preprocess.py* as a batch submission, but I was having problems getting that to run successfully.

# Spark in action: processing the Wikipedia traffic data

Now we'll do some basic manipulations with the Wikipedia dataset, with the goal of analyzing traffic to Barack Obama's sites during the time around his election as president in 2008. 

  - We'll count the number of lines/observations in our dataset. 
  - then we'll do a filtering step to get only the Barack Obama sites, 
  - then do a map step that creates key-value pairs from each record/observation/row and 
  - then do a reduce that counts the number of views by hour and language, so hour-day-lang will serve as the key,
  - then do a map step to prepare the data so it can be output in a nice format.

The code below is also in *process_data.py*.

Note that Spark uses *lazy evaluation*. Actual computation only happens when one asks for a result to be returned or output written to disk.

First we'll see how we read in the data and filter to the observations (lines / rows) of interest.

```
dir = '/global/scratch/paciorek/wikistats'

### read data and do some check ###

lines = sc.textFile(dir + '/' + 'dated') 

lines.getNumPartitions()  # 16590 in full dataset (192 input files)

# note delayed evaluation
lines.count()  # 9467817626 in full dataset

# watch the UI and watch wwall as computation progresses

testLines = lines.take(10)
testLines[0]
testLines[9]

### filter to sites of interest ###

import re
from operator import add

def find(line, regex = "Barack_Obama", language = None):
    vals = line.split(' ')
    if len(vals) < 6:
        return(False)
    tmp = re.search(regex, vals[3])
    if tmp is None or (language != None and vals[2] != language):
        return(False)
    else:
        return(True)

lines.filter(find).take(100) # pretty quick
    
# not clear if should repartition; will likely have small partitions if not
obama = lines.filter(find).repartition(192) # ~ 18 minutes (but remember lazy evaluation) 
obama.count()  # 433k observations in full dataset
```

Now let's use the mapReduce paradigm to get the aggregate statistics we want.

```
### map-reduce step to sum hits across date-time-language triplets ###
    
def stratify(line):
    # create key-value pairs where:
    #   key = date-time-language
    #   value = number of website hits
    vals = line.split(' ')
    return(vals[0] + '-' + vals[1] + '-' + vals[2], int(vals[4]))

# sum number of hits for each date-time-language value
counts = obama.map(stratify).reduceByKey(add)  # 5 minutes on full dataset
# 128889 in full dataset

### map step to prepare output ###

def transform(vals):
    # split key info back into separate fields
    key = vals[0].split('-')
    return(",".join((key[0], key[1], key[2], str(vals[1]))))

### output to file ###

# have one partition because one file per partition is written out
counts.map(transform).repartition(1).saveAsTextFile(dir + '/' + 'obama-counts') # 5 sec.
```

# Spark monitoring

There are various interfaces to monitor Spark and the HDFS.

  - `http://<master_url>:8080` -- general information about the Spark cluster
  - `http://<master_url>:4040` -- information about the Spark tasks being executed
  - `http://<master_url>:50070` -- information about the HDFS

On Savio, I haven't found a way to view the interfaces in a standard web browser as one would usually do. So we'll have to try to read the raw HTML.

When one runs `spark-start` on Savio, it mentions some log files. If you look in the log file for the master, you should see a line like this that indicates what the `<master_url>` is:

```
17/10/10 22:31:09 INFO MasterWebUI: Started MasterWebUI at http://10.0.5.93:8080
```

# Spark operations


Let's consider some of the core methods we used. 

 - filter(): create a subset
 - map(): take an RDD and apply a function to each element, returning an RDD
 - reduce() and reduceByKey(): take an RDD and apply a reduction operation to the elements, doing the reduction stratified by the key values for reduceByKey(). Reduction functions need to be associative (order across records doesn't matter) and commutative (order of arguments doesn't matter) and take 2 arguments and return 1, all so that they can be done in parallel in a straightforward way.
 - collect(): collect results back to the master
 - cache(): tell Spark to keep the RDD in memory for later use
 - repartition(): rework the RDD so it is divided into the specified number of partitions

Note that all of the various operations are OOP methods applied to either the SparkContext management object or to a Spark dataset, called a Resilient Distributed Dataset (RDD). Here `lines` and `counts` are both RDDs. However the result of `collect()` is just a standard Python object.

Question: how many chunks do you think we want the RDD split into? What might the tradeoffs be?

# Spark DataFrames and SQL queries

In recent versions of Spark, one can work with more structured data objects than RDDs. Spark now provides DataFrames, which are collections of Row objects and behave like distributed versions of R or Pandas dataframes. They can also be queried using SQL syntax.

Here's some example code for using DataFrames. The code is also in *process_data_df.py*.

```
from pyspark.sql import SQLContext, Row
sqlc = SQLContext(sc)

### read the data in and process to create an RDD of Rows ###

dir = '/global/scratch/paciorek/wikistats'

lines = sc.textFile(dir + '/' + 'dated')

def remove_partial_lines(line):
    vals = line.split(' ')
    if len(vals) < 6:
        return(False)
    else:
        return(True)


def create_Row(line):
    p = line.split(' ')
    return(Row(date = int(p[0]), hour = int(p[1]), lang = p[2],  site = p[3],
               hits = int(p[4]), size = int(p[5])))

# a DataFrame is a collection of Rows, so create RDD of Rows

rows = lines.filter(remove_partial_lines).map(create_Row)

### create DataFrame and do some operations on it ###

df = sqlc.createDataFrame(rows)

df.printSchema()

## shades of dplyr and R/Pandas dataframes
df.select('site').show()
df.filter(df['lang'] == 'en').show()
df.groupBy('lang').count().show()
```

And here's how we use SQL with a DataFrame:

```
### use SQL with a DataFrame ###

df.registerTempTable("wikiHits")  # name of 'SQL' table is 'wikiHits'

subset = sqlc.sql("SELECT * FROM wikiHits WHERE lang = 'en' AND
                   site LIKE '%Barack_Obama%'")

subset.take(5)
# [Row(date=20081022, hits=17, hour=230000, lang=u'en', site=u'Media:En-Barack_Obama-article1.ogg', size=145491), Row(date=20081026, hits=41, hour=220000, lang=u'en', site=u'Public_image_of_Barack_Obama', size=1256906), Row(date=20081112, hits=8, hour=30000, lang=u'en', site=u'Electoral_history_of_Barack_Obama', size=141176), Row(date=20081104, hits=13890, hour=110000, lang=u'en', site=u'Barack_Obama', size=2291741206), Row(date=20081104, hits=6, hour=110000, lang=u'en', site=u'Barack_Obama%2C_Sr.', size=181699)]

langSummary = sqlc.sql("SELECT lang, count(*) as n FROM wikiHits
                       GROUP BY lang ORDER BY n desc limit 20") # 38 minutes for full dataset
results = langSummary.collect()
# [Row(lang=u'en', n=3417350075), Row(lang=u'de', n=829077196), Row(lang=u'ja', n=734184910), Row(lang=u'fr', n=466133260), Row(lang=u'es', n=425416044), Row(lang=u'pl', n=357776377), Row(lang=u'commons.m', n=304076760), Row(lang=u'it', n=300714967), Row(lang=u'ru', n=256713029), Row(lang=u'pt', n=212763619), Row(lang=u'nl', n=194924152), Row(lang=u'sv', n=105719504), Row(lang=u'zh', n=98061095), Row(lang=u'en.d', n=81624098), Row(lang=u'fi', n=80693318), Row(lang=u'tr', n=73408542), Row(lang=u'cs', n=64173281), Row(lang=u'no', n=48592766), Row(lang=u'he', n=46986735), Row(lang=u'ar', n=46968973)]
```

# Analysis results

The file *obama_plot.R* does some manipulations to plot the hits as a function of time, shown in
*obamaTraffic.pdf*.

So there you have it -- from big data (500 GB unzipped) to knowledge (a 17 KB file of plots). 

# Other comments

## Running a batch Spark job

We can run a Spark job using Python code as a batch script rather than interactively. Here's an example, which computes the value of Pi  by Monte Carlo simulation. 

```
spark-submit --master $SPARK_URL $SPARK_DIR/examples/src/main/python/pi.py
```

## Python vs. Scala/Java

Spark is implemented natively in Java and Scala, so all calculations in Python involve taking Java data objects converting them to Python objects, doing the calculation, and then converting back to Java. This process is called serialization and takes time, so the speed when implementing your work in Scala (or Java) may be faster. Here's a [small bit of info](http://apache-spark-user-list.1001560.n3.nabble.com/Scala-vs-Python-performance-differences-td4247.html) on that.

# R interfaces to Spark

Both SparkR (from the Spark folks) and sparklyr (from the RStudio folks) allow you to interact with Spark-based data from R. There are some limitations to what you can do (both in what is possible and in what will execute with reasonable speed), so for heavy use of Spark you may want to use Python or even the Scala or Java interfaces.


# sparklyr

sparklyr allows you to interact with data in Spark from R.

You can:

 - use dplyr functionality
 - use distributed apply computations via `spark_apply`.

There are some limitations though:

 - the dplyr functionality translates operations to SQL so there are limited operations one can do, particularly in terms of computations on a given row of data
 - spark_apply() appears to run very slowly, presumably because data is being serialized back and forth between R and Java data structures.

# sparklyr example

I haven't been able to get sparklyr to work on Savio, so time permitting, we'll just demonstrate on my desktop.

Here's some example code, also found in *process.R*.

```
if(!require(sparklyr)) {
    install.packages("sparklyr")
    spark_install(version = "2.2.0")
}

# config.yml has driver-memory set -- need some GB for driver or read_csv will be out-of-memory and/or slow down
readLines('config.yml')

### connect to Spark ###

sc <- spark_connect(master = "local")
# sc <- spark_connect(master = Sys.getenv("SPARK_MASTER")) # non-local 

cols <- c(date = 'numeric', hour = 'numeric', lang = 'character',
          page = 'character', hits = 'numeric', size = 'numeric')
          

## takes a while even with only 1.4 GB (zipped) input data (100 sec.)
## copy from /scratch/users/paciorek/wikistats/dated" to /tmp/wiki 
wiki <- spark_read_csv(sc, "wikistats", "/tmp/wiki",
                       header = FALSE, delimiter = ' ',
                       columns = cols, infer_schema = FALSE)

wiki

### some dplyr operations on the Spark dataset ### 

library(dplyr)

wiki_en <- wiki %>% filter(lang == "en")
head(wiki_en)

table <- wiki %>% group_by(lang) %>% summarize(count = n()) %>% arrange(desc(count))
## note the lazy evaluation: need to look at table to get computation to run
table  

### distributed apply ###

## need to use spark_apply to carry out arbitrary R code 
## however this is _very_ slow, probably because it involves
## serializing objects between java and R
## doing the following on 2 files (4 million records) takes 7 minutes
wiki_plus <- spark_apply(wiki, function(data) {
    data$obama = stringr::str_detect(data$page, "Barack_Obama")
    data
}, columns = c(colnames(wiki), 'obama'))

obama <- collect(wiki_plus %>% filter(obama))

### SQL queries ###

library(DBI)
## reference the Spark table not the R tbl_spark interface object
wiki_en2 <- dbGetQuery(sc, "SELECT * FROM wikistats WHERE lang = 'en' LIMIT 10")

wiki_en2
```



