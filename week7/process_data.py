dir = '/global/scratch/paciorek/wikistats'

### read data and do some check ###

lines = sc.textFile(dir + '/' + 'dated') 

lines.getNumPartitions()  # 16590 (192 input files)

# note delayed evaluation
lines.count()  # 9467817626

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
obama.count()  # 433k observations  

# how would I pass additional arguments to the function used for filtering?
# this is (apparently) a bad idea if used with take() as induces a
# lot more processing than without wrapping
if False:
    def findWrap(line):
        find(line, regex = "Barack_Obama", language = "en")
        
    obama_en = lines.filter(findWrap)

### map-reduce step to sum hits across date-time-language triplets ###
    
def stratify(line):
    # create key-value pairs where:
    #   key = date-time-language
    #   value = number of website hits
    vals = line.split(' ')
    return(vals[0] + '-' + vals[1] + '-' + vals[2], int(vals[4]))

# sum number of hits for each date-time-language value
counts = obama.map(stratify).reduceByKey(add)  # 5 minutes
# 128889

### map step to prepare output ###

def transform(vals):
    # split key info back into separate fields
    key = vals[0].split('-')
    return(",".join((key[0], key[1], key[2], str(vals[1]))))

### output to file ###

# have one partition because one file per partition is written out
counts.map(transform).repartition(1).saveAsTextFile(dir + '/' + 'obama-counts') # 5 sec.

