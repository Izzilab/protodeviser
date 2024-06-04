# ProToDeviseR
[Help](./inst/webApp/www/help.md) :: [About](./inst/webApp/www/about.md)

The **Pro**tein **To**pology **Devise**r is an **R** package for the automatic generation of protein topology code in JSON format. The code can be easily rendered into a graph, by Pfam's custom-domains generator. This excellent tool is **not** developed by us, but is embedded with the program for users' convenience. A table summary is also prepared. 

ProToDeviseR features a fully functional graphical **user interface** (UI), implemented in R Shiny:

|Table preview|Generated JSON code|Image generator|
|:-|:-:|-:|
|![]( ./inst/webApp/www/screenshots/table.png)|![]( ./inst/webApp/www/screenshots/json.png)|![]( ./inst/webApp/www/screenshots/image.png)|

As an **input**, you can use:
* A UniProt identifier or an NCBI GenPept identifier.
* Raw results from several online resources for protein topology prediction
* A user-prepared table of protein topology annotations.

As an **output**, you get:
1. A table summary of protein features.
2. JSON code of protein features, ready to be pasted in the *Image generator* tab.

The protein features are classified as **regions**, **motifs** and **markups** (Figure 1). When searching with a database accession number (ID), all three are enabled by default:
- [x] **Regions**: structured domains, repeats or other relatively long (usually, but not always), functional parts of the protein.
- [x] **Motifs**: short liner motifs, disordered protein parts, signal peptides and transmembrane parts.
- [x] **Markups**: single-amino acid targes, such as glycosylation, phosphorylation, active or binding site, etc.

![](./inst/webApp/www/screenshots/cd45_annotated.svg)  
**Figure 1. Automatic annotation of CD45 protein topology**. Identifier `P08575` was searched against UniProt by ProToDeviseR. Table and JSON code were automatically generated and graphic was rendered in the *Image generator* tab. Regions, motifs and markups are indicated.

## Dependencies and installation
ProToDeviser and its R dependencies can be installed as shown in the code box below. Depending on your system, you may need to also install system dependencies (outside R) required by them. [See external Linux deps here](./inst/webApp/www/deps.md).

```R
# from CRAN
install.packages("jsonlite")
install.packages("seqinr")
install.packages("dplyr")
install.packages("openxlsx")
install.packages("rentrez")
install.packages("shiny")
install.packages("shinyBS")
install.packages("rclipboard")
install.packages("shinyjs")
install.packages("DT")
install.packages("textshaping")
install.packages("ragg")
install.packages("pkgdown")
install.packages("devtools")
install.packages("BiocManager")

# from BioConductor
BiocManager::install("IRanges")

# from GitHub
devtools::install_github("thackl/gggenomes")

# finally, install ProToDeviseR itself
devtools::install_github("izzilab/protodeviser")
```

## Start up the UI
Load the library and run the UI function. To use the app graphically, that's all you need. The [Help](./inst/webApp/www/help.md) tab provides extensive documentation on the user intefrace, including examples.
```R
library("protodeviser")
protodeviser_ui()
```

## Functions
ProToDeviser uses the following command-line functions to generate a JSON topology scheme:
* `id.JSON`: for a protein database identifier (ID).
* `predicted.JSON`: from predicted features for your protein.
* `custom.JSON`: from a (manually prepared) table of features for your protein.

To generate/output features as a table:
* `json.table`: from JSON input of protein features.

## Other places for visualization
ProToDeviser ships a modified version of the domains generator. The official custom domains generator has been [decomissioned](https://xfam.wordpress.com/2022/08/04/pfam-website-decommission/), but the [Domain GFX](https://proteinswebteam.github.io/domain-gfx/) "playground" demo is an alternative place.
