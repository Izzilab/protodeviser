library("jsonlite")
library("seqinr")
library("dplyr")
library("openxlsx")
library("gggenomes")
library("IRanges")
library("rentrez")
library("protodeviser")

# path to CD45 examples
examples <- system.file("webApp/www/cd45/", package = "protodeviser")

# custom table file
custom   <- paste0(examples, "cd45_custom.xlsx")

cd45_hsap <- custom.JSON(protein.length = 1306,
               accession.number = "P08575",
               description = "CD45_HSAP",
               organism = "Homo_sapiens",
               link.url = "https://www.uniprot.org/uniprotkb/P08575/",
               taxid = "9606",
               input.file = custom,
               input.format = "xlsx")
