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

DEFAULT:
	ocrd workspace find --file-grp DEFAULT --download

OCR-D-BIN: DEFAULT
OCR-D-BIN: TOOL = ocrd-cis-ocropy-binarize

OCR-D-CROP: OCR-D-BIN
OCR-D-CROP: TOOL = ocrd-anybaseocr-crop

OCR-D-BIN2: OCR-D-CROP
OCR-D-BIN2: TOOL = ocrd-skimage-binarize
OCR-D-BIN2: PARAMS = "method": "li"

DEN = OCR-D-BIN-DENOISE
$(DEN): OCR-D-BIN2
$(DEN): TOOL = ocrd-skimage-denoise
$(DEN): PARAMS = "level-of-operation": "page"

DESK = $(DEN)-DESKEW
$(DESK): OCR-D-BIN-DENOISE
$(DESK): TOOL = ocrd-tesserocr-deskew
$(DESK): PARAMS = "operation_level": "page"

OCR-D-SEG: $(DESK)
OCR-D-SEG: TOOL = ocrd-cis-ocropy-segment
OCR-D-SEG: PARAMS = "level-of-operation": "page"

OCR-D-SEG-LINE-RESEG-DEWARP: OCR-D-SEG
OCR-D-SEG-LINE-RESEG-DEWARP: TOOL = ocrd-cis-ocropy-dewarp

OCR-D-OCR: OCR-D-SEG-LINE-RESEG-DEWARP
OCR-D-OCR: TOOL = ocrd-calamari-recognize
OCR-D-OCR: PARAMS = "checkpoint_dir": "qurator-gt4histocr-1.0"

.DEFAULT_GOAL = OCR-D-OCR

# Down here, custom configuration ends.
###

include Makefile

