# Demos OCR-D

## Demo 0 - install ocrd_all or `ocrd/all`

> Install OCR-D locally

### Read https://ocr-d.de/en/setup guide

### Decide for native or Docker installation

### Install (native)

    git clone https://github.com/OCR-D/ocrd_all
    cd ocrd_all
    sudo make deps-ubuntu
    # optionally:
    sudo make deps-cuda
    make all
    . venv/bin/activate
    mkdir -p ~/data
    cd ~/data

### Install (Docker)

    docker pull ocrd/all:maximum
    # or:
    docker pull ocrd/all:maximum-cuda
    mkdir -p ~/data
    docker run -it -v ~/data:/data -v ocrd-models:/models ocrd/all bash

### Download models

    ocrd resmgr list-available
    ocrd resmgr download ocrd-sbb-binarize default-2021-03-09
    ocrd resmgr download ocrd-tesserocr-recognize deu.traineddata
    ocrd resmgr download ocrd-tesserocr-recognize frk.traineddata
    ocrd resmgr download ocrd-tesserocr-recognize GT4HistOCR.traineddata
    ocrd resmgr download ocrd-tesserocr-recognize Fraktur.traineddata
    ocrd resmgr download ocrd-tesserocr-recognize Latin.traineddata
    ocrd resmgr download ocrd-kraken-recognize austriannewspapers.mlmodel

## Demo 1 - create workspace, run Tesseract

> Start with a bunch of images, create workspace, run Tesseract all-in-one

### Browse [Börsenblatt](https://boersenblatt-digital.de)

→ http://digital.slub-dresden.de/id39946221X-18560530

### Copy links for "Einzelseite als Bild herunterladen"

### Download

    wget https://digital.slub-dresden.de/data/kitodo/Brsfded_39946221X-18560530/Brsfded_39946221X-18560530_tif/jpegs/000000{01..16}.tif.original.jpg

### Mkdir and chdir

    mkdir -p demo1
    mv *.jpg demo1
    cd demo1

### Import images into new workspace

    ocrd-import -P . 

### Minimalist workflow

    ocrd process "tesserocr-recognize -I OCR-D-IMG -O OCR-D-OCR-TESS -P segmentation_level region -P textequiv_level word -P find_tables true -P model frak2021"
    # or equivalently:
    ocrd-tesserocr-recognize -I OCR-D-IMG -O OCR-D-OCR-TESS -P segmentation_level region -P textequiv_level word -P find_tables true -P model frak2021

The results are in the `OCR-D-OCR-TESS` file group / directory.

### Inspect results with browse-ocrd and JPageViewer

> Visualize results with [browse-ocrd](https://github.com/hnesk/browse-ocrd/) or [PRImA PageViewer](https://github.com/PRImA-Research-Lab/prima-page-viewer)


## Demo 2 - clone workspace, more complex workflow

→ [Document from SLUB Digital Collection](http://digital.slub-dresden.de/id39946221X-18560530)

> Start with a METS from SLUB, run a more complex workflow on it

### Browse back

### Select the link below "OAI-Identifier" to retrieve the METS XML

→ https://digital.slub-dresden.de/oai/?verb=GetRecord&metadataPrefix=mets&identifier=oai:de:slub-dresden:db:id-39946221X-18560530

### Clone as workspace

    ocrd workspace -d demo2 clone "https://digital.slub-dresden.de/oai/?verb=GetRecord&metadataPrefix=mets&identifier=oai:de:slub-dresden:db:id-39946221X-18560530"

### Inspect available file groups

    ocrd workspace find -k fileGrp -k url -k mimetype

### Download all images in ORIGINAL file group

    ocrd workspace find --file-grp ORIGINAL --download

### Run the same simple workflow as above

Since our file group is called `ORIGINAL`, `OCR-D-IMG` must be replaced with `ORIGINAL` here.

    ocrd-tesserocr-recognize -I ORIGINAL -O TESSERACT -P segmentation_level region -P textequiv_level word -P find_tables true -P model frak2021

The results are in the `TESSERACT` file group / directory.

### Run a (somewhat) suitable workflow

1. Download the existing annotations from ABBYY Cloud and repair them (removing `Shape` elements with wrong coordinates)

        ocrd workspace find -G FULLTEXT --download
        xmlstarlet ed --inplace -d //_:Shape FULLTEXT/*
        # ocrd workspace prune-files # delete all other files (not downloaded)

2. Convert ALTO to PAGE (adding correct image reference)

        ocrd-fileformat-transform -I FULLTEXT -O PAGE -P from-to "alto page"
        ocrd-segment-replace-page -I ORIGINAL,PAGE -O PAGE2 -P transform_coordinates false

3. Binarize and crop

        ocrd-sbb-binarize -I PAGE2 -O BINARIZED -P model default-2021-03-09
        ocrd-anybaseocr-crop -I BINARIZED -O CROPPED -P marginBottom 0.9 -P marginTop 0.1 -P marginRight 0.9 -P marginLeft 0.1

4. Overwrite line segmentation, repair region segmentation

        ocrd-cis-ocropy-segment -I CROPPED -O LINES -P level-of-operation region
        ocrd-segment-repair -I LINES -O REPAIR -P plausibilize true

5. Dewarp on line level

        ocrd-cis-ocropy-dewarp -I REPAIR -O DEWARPED

6. Run multiple OCR models and combine them

        ocrd-calamari-recognize -I DEWARPED -O OCR1 -P checkpoint_dir qurator-gt4histocr-1.0 -P textequiv_level glyph
        ocrd-tesserocr-recognize -I DEARPED -O OCR2 -P model frak2021 -P textequiv_level glyph
        ocrd-tesserocr-recognize -I DEARPED -O OCR3 -P model GT4HistOCR+Fraktur+frk+Latin+deu -P textequiv_level glyph
        ocrd-kraken-recognize -I DEARPED -O OCR4 -P model austriannewspapers.mlmodel
        ocrd-cor-asv-ann-align -I OCR1,OCR2,OCR3,OCR4 -O ALIGNED -P method combined
        ocrd-page-transform -I ALIGNED -O OCRX -P xsl page-remove-words.xsl

The results are in the `OCRX` file group / directory.

## Demo 3 - run various OCR engines on GT and evaluate

> Download GT, process with calamari, evaluate with dinglehopper and ocrd-cor-asv-ann-evaluate

**NOTE** This demo is just to show how to do the evaluation. The choice of OCR
engines, evaluation processors and models is entirely arbitrary and should not
be seen as recommendation.

### Browse to and download from OCR-D GT Repo

* Go to https://github.com/OCR-D/gt_structure_text
* Copy link to https://github.com/OCR-D/gt_structure_text/releases/download/v1.4.8/luz_blitz_1784.ocrd.zip

```sh
wget https://github.com/OCR-D/gt_structure_text/releases/download/v1.4.8/luz_blitz_1784.ocrd.zip
```

### Extract the OCRD-ZIP

Extract the `data` subdirectory of the ZIP (which contains the workspace)

```sh
unzip luz_blitz_1784.ocrd.zip 'data/*'
```

### Run small workflows for OCR results with Tesseract and Calamari, compare output

This workflow uses `ocrd-olena-binarize` (with the `sauvola-ms-split`
algorithm) to binarize the images. The images are processed by two runs with
Tesseract (using `Fraktur_GT4HistOCR` and `deu`) and one run with calamari (using `qurator-gt4histocr-1.0`).

```sh
ocrd process -m data/mets.xml \
  "olena-binarize -I OCR-D-GT-SEG-LINE -O BIN" \
  "tesserocr-recognize -P segmentation_level word -P textequiv_level line -P find_tables true -P model frak2021 -I BIN -O TESS-GT4HIST" \
  "tesserocr-recognize -P segmentation_level word -P textequiv_level line -P find_tables true -P model deu -I BIN -O TESS-DEU" \
  "calamari-recognize -P checkpoint_dir qurator-gt4histocr-1.0 -I BIN -O CALA-GT4HIST"
```

This allows us to compare the files in `TESS-GT4HIST`, `TESS-DEU` and
`CALA-GT4HIST` with each other and with the GT in `OCR-D-GT-SEG-LINE`.

### Compare all the OCR results with the GT using `ocrd-cor-asv-ann-evaluate`

```sh
ocrd-cor-asv-ann-evaluate -m data/mets.xml -I OCR-D-GT-SEG-LINE,TESS-GT4HIST,TESS-DEU,CALA-GT4HIST -O EVAL-ASV -P confusion 20 -P metric Levenshtein
```

The results are JSON files in the `EVAL-ASV` filegroup with line-by-line distance measures between all the engine.

[`data/EVAL-ASV/EVAL-ASV.json`](https://github.com/bertsky/ocrd-demo-2021-05-12/tree/master/demo3/data/EVAL-ASV/EVAL-ASV.json) contains the metrics (CER mean and variance) and top confusion table for the full workspace:

```json
{
  "OCR-D-GT-SEG-LINE,TESS-GT4HIST": {
    "length": 110,
    "distance-mean": 0.0368893299998711,
    "distance-varia": 0.011348232597131346,
    "confusion": "([(20, ('\u2e17', '-')), (6, (0, '*')), (6, (0, ' ')), (5, ('\u017f', 's')), (4, (0, '-')), (4, (0, 'i')), (4, (0, 'e')), (3, ('\u2014', '-')), (3, (0, '.')), (3, (0, 'r')), (2, ('u', 'l')), (2, ('R', 'K')), (2, (0, '\u017f')), (2, (0, 'c')), (2, ('\u2e17', ' ')), (2, (' ', 0)), (1, ('\u201c', 0)), (1, ('t', 'r')), (1, ('.', '-')), (1, ('3', 0))], 4425)"
  },
  "OCR-D-GT-SEG-LINE,TESS-DEU": {
    "length": 110,
    "distance-mean": 0.17129872156596126,
    "distance-varia": 0.03381635236354291,
    "confusion": "([(100, ('f', '\u017f')), (16, (' ', 0)), (15, (',', '.')), (11, ('\u00fc', 'u\u0364')), (10, ('\u00f6', 'o\u0364')), (10, ('f', 0)), (9, ('b', 'd')), (9, ('\u00e4', 'a\u0364')), (9, ('s', '-')), (9, (0, '-')), (8, ('S', 'G')), (8, ('f', 'k')), (7, ('r', 't')), (7, (0, ' ')), (6, ('(', '\u017f')), (6, ('u', 'u\u0364')), (6, ('b', 'h')), (5, (0, '\u017f')), (5, ('M', 0)), (5, (0, 'z'))], 4510)"
  },
  "OCR-D-GT-SEG-LINE,CALA-GT4HIST": {
    "length": 110,
    "distance-mean": 0.05106674581570344,
    "distance-varia": 0.01795657646161947,
    "confusion": "([(20, ('\u2e17', '-')), (17, (0, 'e')), (12, (0, '*')), (11, (0, ' ')), (8, (0, 'l')), (7, (0, 'c')), (7, (0, 'r')), (6, ('e', 'c')), (6, (' ', 0)), (6, (0, 'd')), (5, (0, ',')), (5, (0, 'h')), (5, (0, 'i')), (5, (0, 'n')), (4, ('.', '-')), (4, ('\u017f', 's')), (4, (0, '-')), (4, (0, 'u')), (3, (0, 'S')), (3, (0, 'a'))], 4429)"
  }
}
```

[`data/EVAL-ASV/EVAL-ASV_0003.json`](https://github.com/bertsky/ocrd-demo-2021-05-12/tree/master/demo3/data/EVAL-ASV/EVAL-ASV_0003.json) contains the metrics for each line of page 3.

### Compare Calamari output with GT using `ocrd-dinglehopper`

```sh
ocrd-dinglehopper -m data/mets.xml -P textequiv_level line -I OCR-D-GT-SEG-LINE,CALA-GT4HIST -O EVAL-DINGLE
```

The result are HTML files (Diff View) and JSON files (with CER and WER).

[HTML](https://github.com/bertsky/ocrd-demo-2021-05-12/tree/master/demo3/data/EVAL-DINGLE/EVAL-DINGLE_0003.html) for page 3:

[![](https://github.com/bertsky/ocrd-demo-2021-05-12/raw/master/dinglehopper-0003.png)](https://github.com/bertsky/ocrd-demo-2021-05-12/tree/master/demo3/data/EVAL-DINGLE/EVAL-DINGLE_0003.json)

[JSON](https://github.com/bertsky/ocrd-demo-2021-05-12/tree/master/demo3/data/EVAL-DINGLE/EVAL-DINGLE_0003.json) for page 3:

```json
{
    "gt": "OCR-D-GT-SEG-LINE/OCR-D-GT-SEG-LINE_0003.xml",
    "ocr": "CALA-GT4HIST/CALA-GT4HIST_0003.xml",

    "cer": 0.07770472205618649,
    "wer": 0.1320754716981132,

    "n_characters": 1673,
    "n_words": 265
}
```

### Visualize with browse-ocrd

> Show diff view in browse-ocrd (https://github.com/hnesk/browse-ocrd/tree/diff-view)

![](browse-ocrd.png)

    browse-ocrd data/mets.xml

## Demo 4 - makefiles

> Recreate demo1 and demo2 via equivalent makefiles

### Try to build

    ocrd-make -f demo1.mk demo1
    ocrd-make -f demo2.mk demo2

> make[1]: Entering directory 'demo1'
> make[1]: 'OCR-D-OCR-TESS' is up to date.
> make[1]: Leaving directory 'demo1'
> make[1]: Entering directory 'demo2'
> make[1]: OCRX is up to date.
> make[1]: Leaving directory 'demo2'

### Trigger rebuild

    touch demo1/OCR-D-IMG demo2/ORIGINAL
    ocrd-make -f demo1.mk demo1
    ocrd-make -f demo2.mk demo2

