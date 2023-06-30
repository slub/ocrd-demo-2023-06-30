# Install by copying (or symlinking) makefiles into a directory
# where all OCR-D workspaces (unpacked BagIts) reside. Then
# chdir to that location.

# Call via:
# `make -f WORKFLOW-CONFIG.mk WORKSPACE-DIRS` or
# `make -f WORKFLOW-CONFIG.mk all` or just
# `make -f WORKFLOW-CONFIG.mk`
# To rebuild partially, you must pass -W to recursive make:
# `make -f WORKFLOW-CONFIG.mk EXTRA_MAKEFLAGS="-W FILEGRP"`
# To get help on available goals:
# `make help`

###
# From here on, custom configuration begins.

info:
	@echo "Read image and create PAGE-XML for it,"
	@echo "then segment pages into text regions and lines with Tesseract,"
	@echo "and (in the same step) recognize lines with model deu."

FULLTEXT:
	ocrd workspace find -G ORIGINAL --download
        ocrd workspace find -G FULLTEXT --download
        xmlstarlet ed --inplace -d //_:Shape FULLTEXT/*

# created by side effect above
ORIGINAL: ;

PAGE: FULLTEXT
PAGE: TOOL = ocrd-fileformat-transform
PAGE: OPTIONS = -P from-to "alto page"

PAGE2: ORIGINAL PAGE
PAGE2: TOOL = ocrd-segment-replace-page
PAGE2: OPTIONS = -P transform_coordinates false

BINARIZED: PAGE2
BINARIZED: TOOL = ocrd-sbb-binarize
BINARIZED: OPTIONS = -P model default-2021-03-09

CROPPED: BINARIZED
CROPPED: TOOL = ocrd-anybaseocr-crop
CROPPED: OPTIONS = -P marginBottom 0.9 -P marginTop 0.1 -P marginRight 0.9 -P marginLeft 0.1

LINES: CROPPED
LINES: TOOL = ocrd-cis-ocropy-segment
LINES: OPTIONS = -P level-of-operation region

REPAIR: LINES
REPAIR: TOOL = ocrd-segment-repair
REPAIR: OPTIONS = -P plausibilize true

DEWARPED: REPAIR
DEWARPED: TOOL = ocrd-cis-ocropy-dewarp

OCR1 OCR2 OCR3 OCR4: DEWARPED
OCR1: TOOL = ocrd-calamari-recognize
OCR1: OPTIONS = -P checkpoint_dir qurator-gt4histocr-1.0 -P textequiv_level glyph
OCR2 OCR3: TOOL = ocrd-tesserocr-recognize
OCR2: OPTIONS = -P model frak2021
OCR3: OPTIONS = -P model GT4HistOCR+Fraktur+frk+Latin+deu -P textequiv_level glyph
OCR4: TOOL = ocrd-kraken-recognize
OCR4: OPTIONS = -P model austriannewspapers.mlmodel

ALIGNED: OCR1 OCR2 OCR3 OCR4
ALIGNED: TOOL = ocrd-cor-asv-ann-align
ALIGNED: OPTIONS = -P method combined

OCRX: ALIGNED
OCRX: TOOL = ocrd-page-transform
OCRX: OPTIONS = -P xsl page-remove-words.xsl

.DEFAULT_GOAL = OCRX

# Down here, custom configuration ends.
###

include Makefile

