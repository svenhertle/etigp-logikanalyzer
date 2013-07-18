TEX_FILES = $(find -iname '*.tex')
BIB_FILES = $(find -iname '*.bib')
IMG_SRCS = $(wildcard abbildungen/*)

all: $(TEX_FILES) $(BIB_FILES) $(IMG_SRCS) Makefile options.tex
	pdflatex gp-vortrag.tex
	pdflatex gp-vortrag.tex
clean:
	rm -f *.aux *.bbl *.blg *.log *.pdf *.toc *.nav *.out *.snm *.vrb
