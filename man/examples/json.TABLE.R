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

# CD45 JSON file
P08575 <- paste0(examples, "P08575.json")

# import using `fromJSON`
myjson <- fromJSON(P08575)

# convert to table
table <- json.TABLE(json = myjson)
