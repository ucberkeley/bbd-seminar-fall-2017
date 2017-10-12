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
