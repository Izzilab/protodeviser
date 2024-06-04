library("jsonlite")
library("seqinr")
library("dplyr")
library("openxlsx")
library("gggenomes")
library("IRanges")
library("rentrez")
library("protodeviser")

# path to CD45 examples of predicted results
examples <- system.file("webApp/www/cd45/", package = "protodeviser")

# files to submit to function
cd45_SMART    <- paste0(examples, "cd45_SMART.tsv")
cd45_ELM      <- paste0(examples, "cd45_ELM.xlsx")
cd45_ELM_cs   <- paste0(examples, "cd45_ELMcs.tsv")
cd45_SCANSITE <- paste0(examples, "cd45_ScanSite.tsv")
cd45_ANCHOR   <- paste0(examples, "cd45_IUPred3.tsv")
cd45_netNglyc <- paste0(examples, "cd45_NetNGlyc.tsv")
cd45_netOglyc <- paste0(examples, "cd45_NetOGlyc.gff")
cd45_netPhos  <- paste0(examples, "cd45_NetPhos.tsv")

cd45_predicted <- predicted.JSON(protein.length = 1306,
               accession.number = "P08575",
               description = "CD45_HSAP",
               organism = "Homo_sapiens",
               link.url = "https://www.uniprot.org/uniprotkb/P08575/",
               taxid = "9606",
               SMART.tsv = cd45_SMART,
               ELM.xlsx = cd45_ELM,
               ELM.features.tsv = cd45_ELM_cs,
               ELM.score = 0.5,
               SCANSITE.tsv = cd45_SCANSITE,
               SCANSITE.score = 0.5,
               SCANSITE.percentile = 0.001,
               SCANSITE.accessibility = 1,
               ANCHOR.tsv = cd45_ANCHOR,
               ANCHOR.cutoff = 0.8,
               netNglyc.tsv = cd45_netNglyc,
               netNglyc.cutoff = 0.9,
               netOglyc.tsv = cd45_netOglyc,
               netOglyc.cutoff = 0.9,
               netPhos.tsv = cd45_netPhos,
               netPhos.cutoff = 0.95)
