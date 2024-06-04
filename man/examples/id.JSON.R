library("jsonlite")
library("seqinr")
library("dplyr")
library("openxlsx")
library("gggenomes")
library("IRanges")
library("rentrez")
library("protodeviser")

# Scan from UniProt
P08575 <- id.JSON(input = "P08575", database = "uniprot")

# Scan from NCBI GenPept
NP_002829.3 <- id.JSON(input = "NP_002829.3", database = "ncbi")
