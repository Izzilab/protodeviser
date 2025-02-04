library("jsonlite")
library("seqinr")
library("dplyr")
library("openxlsx")
library("gggenomes")
library("IRanges")
library("rentrez")
library("viridis")
library("protodeviser")

# Scan from UniProt
P08575 <- id.JSON(input = "P08575", database = "uniprot", gradient = "rainbow")

# Scan from NCBI GenPept
NP_002829.3 <- id.JSON(input = "NP_002829.3", database = "ncbi", gradient = "rainbow")
