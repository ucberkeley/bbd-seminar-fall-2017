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


# +---------+--------+
# |     lang|   count|
# +---------+--------+
# |       si|  384867|
# |     km.b|   58671|
# |     uk.n|  124705|
# |     az.s|   74966|
# |     hi.s|     442|
# |    bar.s|      75|
# |     fi.b|  619719|
# |    bcl.d|     671|
# |      mzn|  130113|
# |     ce.s|     266|
# |     is.s|  128794|
# |     et.v|     102|
# |roa-rup.s|      19|
# |    got.s|      13|
# |       sk|21222805|
# |     km.d|   94745|
# |     ta.q|   34007|
# |     mr.q|   56915|
# |    lmo.b|     159|
# |     gd.q|     454|
# +---------+--------+

### use SQL with a DataFrame ###

df.registerTempTable("wikiHits")  # name of 'SQL' table is 'wikiHits'

subset = sqlc.sql("SELECT * FROM wikiHits WHERE lang = 'en' AND site LIKE '%Barack_Obama%'")

subset.take(5)
# [Row(date=20081022, hits=17, hour=230000, lang=u'en', site=u'Media:En-Barack_Obama-article1.ogg', size=145491), Row(date=20081026, hits=41, hour=220000, lang=u'en', site=u'Public_image_of_Barack_Obama', size=1256906), Row(date=20081112, hits=8, hour=30000, lang=u'en', site=u'Electoral_history_of_Barack_Obama', size=141176), Row(date=20081104, hits=13890, hour=110000, lang=u'en', site=u'Barack_Obama', size=2291741206), Row(date=20081104, hits=6, hour=110000, lang=u'en', site=u'Barack_Obama%2C_Sr.', size=181699)]

langSummary = sqlc.sql("SELECT lang, count(*) as n FROM wikiHits GROUP BY lang ORDER BY n desc limit 20") # 38 minutes
results = langSummary.collect()
# [Row(lang=u'en', n=3417350075), Row(lang=u'de', n=829077196), Row(lang=u'ja', n=734184910), Row(lang=u'fr', n=466133260), Row(lang=u'es', n=425416044), Row(lang=u'pl', n=357776377), Row(lang=u'commons.m', n=304076760), Row(lang=u'it', n=300714967), Row(lang=u'ru', n=256713029), Row(lang=u'pt', n=212763619), Row(lang=u'nl', n=194924152), Row(lang=u'sv', n=105719504), Row(lang=u'zh', n=98061095), Row(lang=u'en.d', n=81624098), Row(lang=u'fi', n=80693318), Row(lang=u'tr', n=73408542), Row(lang=u'cs', n=64173281), Row(lang=u'no', n=48592766), Row(lang=u'he', n=46986735), Row(lang=u'ar', n=46968973)]

### example of writing out in column-oriented, portable parquet format ###

df.write.parquet(dir + '/' + 'parquet')  # 84 GB (a bit less than gzipped format of 'dated') # 36 minutes

# restart PySpark and read back in to demonstrate reading from parquet
df = sqlc.read.parquet(dir + '/' 'parquet')
