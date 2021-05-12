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

OCR-D-OCR-TESS: OCR-D-IMG
OCR-D-OCR-TESS: TOOL = ocrd-tesserocr-recognize
OCR-D-OCR-TESS: PARAMS = "segmentation_level": "region", "textequiv_level": "word",\
			 "find_tables": true, "model": "deu"

.DEFAULT_GOAL = OCR-D-OCR-TESS

# Down here, custom configuration ends.
###

include Makefile

