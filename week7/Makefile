all: spark.html spark_slides.html

spark.html: spark.md
	pandoc -s -o spark.html spark.md

spark_slides.html: spark.md
	pandoc -s --webtex -t slidy -o spark_slides.html spark.md

clean:
	rm -rf spark.html
