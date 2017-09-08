all: resources.html resources_slides.html

resources.html: resources.md
	pandoc -s -o resources.html resources.md

resources_slides.html: resources.md
	pandoc -s --webtex -t slidy -o resources_slides.html resources.md

clean:
	rm -rf resources.html
