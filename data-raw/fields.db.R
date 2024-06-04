# Code to prepare fields.db dataset ----

# input and output data folders
dataraw <- system.file("extdata", package = "protodeviser")
datarda <- system.file("data", package = "protodeviser")

# input SMART, ELM and UniProt features specifications
smart.descriptions <- read.csv(paste0(dataraw, "/", "smart_descriptions.csv"), header = T)
elm.classes <- read.csv(paste0(dataraw, "/", "elm_classes.tsv"), header = T, skip = 5, sep = "\t")
uniprot.field <- read.csv(paste0(dataraw, "/", "uniprot_return_fields_classified.csv"))

fields.db <- list()
fields.db$smart.descriptions <- smart.descriptions
fields.db$elm.classes <- elm.classes
fields.db$uniprot.field <- uniprot.field

save(fields.db, file = paste0(datarda, "/", "fields.db.rda"))
