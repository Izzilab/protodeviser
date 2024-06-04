#
# ProToDeviser: command line tools
#

library("jsonlite")
library("seqinr")
library("dplyr")
library("openxlsx")
library("gggenomes")
library("IRanges")
library("rentrez")

# Retrieve GenPept from NCBI by accession number
get.NCBI.gp <- function(gp = NULL){
  gp <- toupper(gsub(" ", "", gp))
  gp <- entrez_fetch("protein", id = gp, rettype = "gp")
  gp.tmp <- tempfile(pattern = "NCBI.", tmpdir = tempdir(), fileext = ".gp")
  write(gp, gp.tmp)
  gp <- as.data.frame(read_gbk(gp.tmp))
  file.remove(gp.tmp)
  return(gp)
}

# # Retrieve GFF from UniProt by accession number
# get.UniProt.gff <- function(gff = NULL){
#   gff <- toupper(gff)
#   gff.tmp <- tempfile(pattern = "UniProt.", tmpdir = tempdir(), fileext = ".gff")
#   download.file(url = paste0("https://rest.uniprot.org/uniprotkb/", gff, ".gff"), destfile = gff.tmp)
#   gff <- as.data.frame(read_gff3(gff.tmp))
#   return(gff)
# }

# Retrieve JSON from UniProt by accession number
get.UniProt.json <- function(jsn = NULL){
  jsn <- toupper(gsub(" ", "", jsn))
  jsn.tmp <- tempfile(pattern = "UniProt.", tmpdir = tempdir(), fileext = ".json")
  download.file(url = paste0("https://rest.uniprot.org/uniprotkb/", jsn, ".json"), destfile = jsn.tmp)
  jsn <- fromJSON(jsn.tmp)
  return(jsn)
}

# read a NCBI GenPept file from disk
read.NCBI.gp <- function(gp = NULL){
  df <- as.data.frame(read_gbk(gp))
  return(df)
}

# # read UniProt GFF file from disk
# read.UniProt.gff <- function(gff = NULL){
#   df <- as.data.frame(read_gff3(gff))
#   return(df)
# }

# read UniProt JSON file from disk
read.UniProt.json <- function(jsn = NULL){
  jsn <- fromJSON(jsn.tmp)
  return(df)
}

# read a custom-made table
read.custom <- function(inp = NULL, ft = NULL){
  if (ft == "table") {custom <- read.table(file = inp)}
  else if (ft == "csv") {custom <- read.csv(file = inp)}
  else if (ft == "csv2") {custom <- read.csv2(file = inp)}
  else if (ft == "xlsx") {custom <- read.xlsx(xlsxFile = inp)}
  else {
    print("Please provide a valid file")
    stop()
  }

  custom <- as.data.frame(custom)

  # Accept missing end values for markups
  for (r in 1:nrow(custom)) {
    if (is.null(custom[r,3]) | is.na(custom[r,3])) {
      custom[r,3] <- custom[r,2]
    }
  }
  return(custom)
}

################################################################################
# Extract metadata, size and features ##########################################
################################################################################

# get metadata from NCBI GenPept
metadata.NCBI.gp <- function(gp = NULL){
  e <- gp
  p <- subset(e, e$type == "Protein")
  r <- subset(e, e$type == "region")

  df <- data.frame(accession = p$seq_id,
                   description = p$product,
                   link = paste0("https://www.ncbi.nlm.nih.gov/protein/",
                                 p$seq_id),
                   organism = r$organism,
                   taxid = strsplit(r$dbxref, "\\:")[[1]][2])

  return(df)
}

# Get metadata from UniProtKB GFF3
metadata.UniProt.gff <- function(gff = NULL){
  e <- gff
  p <- subset(e, e$type == "Chain")

  # if there's more than one Chain, pick the longest
  m <- which.max(unlist(subset(e, e$type == "Chain")[3]))
  p <- p[m,]

  df <- data.frame(accession = p$seq_id,
                   description = p$note,
                   link = paste0("https://www.uniprot.org/uniprotkb/", p$seq_id))

  return(df)
}

# Get metadata from UniProtKB JSON
metadata.UniProt.json <- function(jsn = NULL){
  #e <- fromJSON(jsn)
  #p <- jsn$features

  df <- data.frame(accession = jsn$primaryAccession,
                   description = unlist(jsn$uniProtkbId),
                   link = paste0("https://www.uniprot.org/uniprotkb/", jsn$primaryAccession))

  return(df)
}

# Get length of the protein product from NCBI GenPept
length.NCBI.gp <- function(gp = NULL){
  e <- gp
  e <- subset(e, e$type == "Protein")
  e <- e$end
  return(e)
}

# Get length of the protein product from UniProt GFF3
length.UniProt.gff <- function(gff = NULL){
  #TODO: deal with multiple chains present
  e <- gff
  e <- subset(e, e$type == "Chain")
  m <- which.max(unlist(subset(e, e$type == "Chain")[3]))
  e <- e[m,]
  e <- e$end
  return(e)
}

# Get length of the protein product from UniProt JSON
length.UniProt.json <- function(jsn = NULL){
  e <- jsn$sequence$length
  return(e)
}

# Get features from NCBI GenPept
features.NCBI.gp <- function(gp = NULL){
  entry <- gp

  # get data separately and then rbind
  entry.region <- subset(entry, entry$type == "Region")
  entry.site <- subset(entry, entry$type == "Site")

  df.region <- data.frame()
  df.site <- data.frame()

  df.region <- data.frame(type = entry.region$type,
                   start = entry.region$start,
                   end = entry.region$end,
                   text = entry.region$region_name,
                   description = paste0(entry.region$region_name , "|" , "note: ", entry.region$note),
                   scoreName = "N/A",
                   score = "N/A",
                   database = "NCBI:GenPept",
                   accession = entry.region$dbxref,
                   sequence = "N/A",
                   target = "N/A")

  df.site <- data.frame(type = entry.site$type,
                          start = entry.site$start,
                          end = entry.site$end,
                          text = entry.site$region_name,
                          description = paste0(entry.site$site_type , "|" , "note: ", entry.site$note),
                          scoreName = "N/A",
                          score = "N/A",
                          database = "NCBI:GenPept",
                          accession = entry.site$dbxref,
                          sequence = "N/A",
                          target = "N/A")

  df <- rbind(df.region, df.site)

  # Use the nomenclature from the JSON file: regions, motifs and markups (next)
  df$type <- gsub("Region", "regions", x = df[,1])
  df$type <- gsub("Site", "motifs", x = df[,1])

  # If start and end are the same, we have a markup
  for (r in 1:nrow(df)) {
    if(df[r,2] == df[r,3]){df[r,1] <- "markups"}
  }

  # If Region is of type "Disordered"
  for (r in 1:nrow(df)) {
    if(grepl("disorder", df[r,5], ignore.case = T)){df[r,1] <- "motifs"}
  }

  # # If Region is of type "Repeat"
  # for (r in 1:nrow(df)) {
  #   if(grepl("repeat", df[r,5], ignore.case = T)){df[r,1] <- "motifs"}
  # }

  # Simplify the "text" column
  # https://stackoverflow.com/a/7748190
  df$text <- tolower(sapply(strsplit(df$text, "_"), `[`, 1))

  return(df)
}

# Get features from UniProt GFF
features.UniProt.gff <- function(gff = NULL){
  entry <- gff
  uniprot.field <- fields.db$uniprot.field
  entry <- merge(entry, uniprot.field, by = "type")

  # Add "type" and "note" info to "description"
  df <- data.frame(type = entry$by,
                   start = entry$start,
                   end = entry$end,
                   text = gsub("\ [0-9]*$","",entry$note),
                   description = paste0(entry$type, " | ", "note: ", gsub("\ [0-9]*$","",entry$note)),
                   scoreName = "N/A",
                   score = "N/A",
                   database = "UniProtKB",
                   accession = entry$evidence,
                   sequence = "N/A",
                   target = "N/A")

  # If start and end of a site are not the same, but this is not a disulfide bridge, we mark as a motif
  for (r in 1:nrow(df)) {
    if(df[r,1] == "markups" & !isTRUE(grepl("disulf", df[r,5], ignore.case = T)) & df[r,2] < df[r,3]){df[r,1] <- "motifs"}
  }

  # For NCBI "repeats" are classified as Regions, so do the same here
  for (r in 1:nrow(df)) {
    if(df[r,1] == "motifs" & isTRUE(grepl("repeat", df[r,5], ignore.case = T))){df[r,1] <- "regions"}
  }

  # If the regions is actually a motif
  for (r in 1:nrow(df)) {
    if(df[r,1] == "regions" & isTRUE(grepl("motif", df[r,5], ignore.case = T))){df[r,1] <- "motifs"}
  }

  # If Region is of type "Disordered"
  for (r in 1:nrow(df)) {
    if(grepl("disorder", df[r,5], ignore.case = T)){df[r,1] <- "motifs"}
  }

  return(df)
}

# Get features from UniProt GFF
features.UniProt.json <- function(jsn = NULL){
  if(!is.null(jsn$features)){
    entry <- flatten(jsn$features)
    uniprot.field <- fields.db$uniprot.field
    entry <- merge(entry, uniprot.field, by = "type")

    # Add "type" and "note" info to "description"
    df <- data.frame(type = entry$by,
                     start = entry$location.start.value,
                     end = entry$location.end.value,
                     text = gsub("\ [0-9]*$","",entry$description),
                     description = paste0(entry$type, " | ", "note: ", gsub("\ [0-9]*$","",entry$description)),
                     scoreName = "N/A",
                     score = "N/A",
                     database = "UniProtKB",
                     accession = "N/A",
                     sequence = "N/A",
                     target = "N/A")

    # If start and end of a site are not the same, but this is not a disulfide bridge, we mark as a motif
    for (r in 1:nrow(df)) {
      if(df[r,1] == "markups" & !isTRUE(grepl("disulf", df[r,5], ignore.case = T)) & df[r,2] < df[r,3]){df[r,1] <- "motifs"}
    }

    # For NCBI "repeats" are classified as Regions, so do the same here
    for (r in 1:nrow(df)) {
      if(df[r,1] == "motifs" & isTRUE(grepl("repeat", df[r,5], ignore.case = T))){df[r,1] <- "regions"}
    }

    # If the regions is actually a motif
    for (r in 1:nrow(df)) {
      if(df[r,1] == "regions" & isTRUE(grepl("motif", df[r,5], ignore.case = T))){df[r,1] <- "motifs"}
    }

    # If Region is of type "Disordered"
    for (r in 1:nrow(df)) {
      if(grepl("disorder", df[r,5], ignore.case = T)){df[r,1] <- "motifs"}
    }

    return(df)
  }else{
    # In case no features are found...
    return(NULL)
  }

}

################################################################################
# Features preparation #########################################################
################################################################################

# Colour motifs, including signal peptide and transmembrane
motifs.style <- function(entry = NULL){
  note <- subset(entry, entry$type == "motifs")
  note <- data.frame(type = "motifs", description = unique(note$description))

  signal_peptide      <- data.frame(type = "motifs", text = "signal_peptide",      colour = "#FF0000")
  transmembrane       <- data.frame(type = "motifs", text = "transmembrane",       colour = "#0033FF")
  coiled_coil         <- data.frame(type = "motifs", text = "coiled_coil",         colour = "#F0FF00")
  low_complexity      <- data.frame(type = "motifs", text = "low_complexity",      colour = "#F700A4")
  disordered_region   <- data.frame(type = "motifs", text = "disordered_region",   colour = "#F3F2DC")
  disor_region_bind   <- data.frame(type = "motifs", text = "disor_region_bind",   colour = "#DCDCA9")
  charged_polar_reg   <- data.frame(type = "motifs", text = "charged_polar_reg",   colour = "#660099")

  phosphorylation     <- data.frame(type = "motifs", text = "phosphorylation",     colour = "#edd400")
  glycosylation       <- data.frame(type = "motifs", text = "glycosylation",       colour = "#fcaf3e")
  lipidation          <- data.frame(type = "motifs", text = "lipidation",          colour = "#729fcf")
  cleavage            <- data.frame(type = "motifs", text = "cleavage",            colour = "#555753")
  degradation         <- data.frame(type = "motifs", text = "degradation",         colour = "#000000")
  targeting           <- data.frame(type = "motifs", text = "targeting",           colour = "#c17d11")
  nuclear_related     <- data.frame(type = "motifs", text = "nuclear_related",     colour = "#ad7fa8")
  docking_ligand      <- data.frame(type = "motifs", text = "docking_ligand",      colour = "#4e9a06")
  activity_regulation <- data.frame(type = "motifs", text = "activity_regulation", colour = "#ef2929")

  other               <- data.frame(type = "motifs", text = "other",               colour = "#C2C2C2")

  # Scan motifs and classify them
  df <- data.frame()
  for (r in 1:nrow(note)) {
    if (isTRUE(grepl("trans", note[r,2], ignore.case = T)) & grepl("membr", note[r,2], ignore.case = T)){
      df.l <- data.frame(cbind(transmembrane, description = note[r,2]))

      } else if (isTRUE(grepl("disorder", note[r,2], ignore.case = T)) & grepl("bind", note[r,2], ignore.case = T)){
      df.l <- data.frame(cbind(disor_region_bind, description = note[r,2]))

      } else if (isTRUE(grepl("disorder", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(disordered_region, description = note[r,2]))

      } else if (isTRUE(grepl("coiled", note[r,2], ignore.case = T)) & grepl("coil", note[r,2], ignore.case = T)){
      df.l <- data.frame(cbind(coiled_coil, description = note[r,2]))

      } else if (isTRUE(grepl("low", note[r,2], ignore.case = T)) & grepl("complex", note[r,2], ignore.case = T)){
      df.l <- data.frame(cbind(low_complexity, description = note[r,2]))

      } else if (isTRUE(grepl("basic", note[r,2], ignore.case = T) | grepl("acidic", note[r,2], ignore.case = T) | grepl("charged", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(charged_polar_reg, description = note[r,2]))

      } else if (isTRUE(grepl("polar", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(charged_polar_reg, description = note[r,2]))

      } else if (isTRUE(grepl("ser", note[r,2], ignore.case = T) | grepl("s-", note[r,2], ignore.case = T)) & isTRUE(grepl("phospho", note[r,2], ignore.case = T) | grepl("kinase", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

      } else if (isTRUE(grepl("thr", note[r,2], ignore.case = T) | grepl("t-", note[r,2], ignore.case = T)) & isTRUE(grepl("phospho", note[r,2], ignore.case = T) | grepl("kinase", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

      } else if (isTRUE(grepl("tyr", note[r,2], ignore.case = T) | grepl("y-", note[r,2], ignore.case = T)) & isTRUE(grepl("phospho", note[r,2], ignore.case = T) | grepl("kinase", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

      } else if (isTRUE(grepl("phospho", note[r,2], ignore.case = T) & isTRUE(grepl("kinase", note[r,2], ignore.case = T) | grepl("site", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

      } else if (isTRUE(grepl("phosphorylation", note[r,2], ignore.case = T))){
        df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

      } else if (isTRUE(grepl("glycosaminoglycan", note[r,2], ignore.case = T) | grepl("mucopolysaccharide", note[r,2], ignore.case = T))) {
      df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

      } else if (isTRUE(grepl("O-", note[r,2], ignore.case = T)) & isTRUE(grepl("fucos", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

      } else if (isTRUE(grepl("C-", note[r,2], ignore.case = T)) & isTRUE(grepl("mannos", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

      } else if (isTRUE(grepl("N-", note[r,2], ignore.case = T)) & isTRUE(grepl("glyco", note[r,2], ignore.case = T) | grepl("link", note[r,2], ignore.case = T))) {
      df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

      } else if (isTRUE(grepl("O-", note[r,2], ignore.case = T)) & isTRUE(grepl("glyco", note[r,2], ignore.case = T) | grepl("link", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

      } else if (isTRUE(grepl("glycosylation", note[r,2], ignore.case = T))){
        df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

    } else if (isTRUE(grepl("prenyl", note[r,2], ignore.case = T) | grepl("isopren", note[r,2], ignore.case = T) | grepl("farnes", note[r,2], ignore.case = T) | grepl("geranyl", note[r,2], ignore.case = T) | grepl("dolichol", note[r,2], ignore.case = T) | grepl("caax", note[r,2], ignore.case = T))){
      df.l <- cbind(lipidation, description = note[r,2])

    } else if (isTRUE(grepl("acylat", note[r,2], ignore.case = T) | grepl("myrist", note[r,2], ignore.case = T) | grepl("palmit", note[r,2], ignore.case = T))){
      df.l <- cbind(lipidation, description = note[r,2])

    } else if (isTRUE(grepl("gpi", note[r,2], ignore.case = T) | grepl("glycosylphosphatidylinositol", note[r,2], ignore.case = T) | grepl("phosphoethanolamine", note[r,2], ignore.case = T))){
      df.l <- cbind(lipidation, description = note[r,2])

    } else if (isTRUE(grepl("lipid", note[r,2], ignore.case = T))){
      df.l <- cbind(lipidation, description = note[r,2])

    } else if (isTRUE(grepl("sumo", note[r,2], ignore.case = T))){
      df.l <- cbind(targeting, description = note[r,2])

    } else if (isTRUE(grepl("cleave", note[r,2], ignore.case = T) | grepl("cleavage", note[r,2], ignore.case = T))){
      df.l <- cbind(cleavage, description = note[r,2])

    } else if (isTRUE(grepl("degrad", note[r,2], ignore.case = T) | grepl("degron", note[r,2], ignore.case = T) | grepl("destruct", note[r,2], ignore.case = T))){
      df.l <- cbind(degradation, description = note[r,2])

    } else if (isTRUE(grepl("absorb", note[r,2], ignore.case = T) | grepl("absorption", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(targeting, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)) & isTRUE(grepl("locali", note[r,2], ignore.case = T) | grepl("import", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)) & isTRUE(grepl("export", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)) & isTRUE(grepl("receptor", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("zinc", note[r,2], ignore.case = T) & grepl("finger", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("dna", note[r,2], ignore.case = T) & grepl("bind", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("ligand", note[r,2], ignore.case = T) & grepl("bind", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(docking_ligand, description = note[r,2]))

    } else if (isTRUE(grepl("ligand", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(docking_ligand, description = note[r,2]))

    } else if (isTRUE(grepl("bind", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(docking_ligand, description = note[r,2]))

    } else if (isTRUE(grepl("sort", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(targeting, description = note[r,2]))

    } else if (isTRUE(grepl("target", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(targeting, description = note[r,2]))

    } else if (isTRUE(grepl("docking", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(docking_ligand, description = note[r,2]))

    } else if (isTRUE(grepl("interact", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(docking_ligand, description = note[r,2]))

    } else if (isTRUE(grepl("co", note[r,2], ignore.case = T) & grepl("factor", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(activity_regulation, description = note[r,2]))

    } else if (isTRUE(grepl("activ", note[r,2], ignore.case = T) & grepl("site", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(activity_regulation, description = note[r,2]))

    } else if (isTRUE(grepl("catal", note[r,2], ignore.case = T) & grepl("activ", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(activity_regulation, description = note[r,2]))

    } else if (isTRUE(grepl("activ", note[r,2], ignore.case = T) & grepl("regulat", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(activity_regulation, description = note[r,2]))

    } else if (isTRUE(grepl("activity", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(activity_regulation, description = note[r,2]))

    } else if (isTRUE(grepl("sign", note[r,2], ignore.case = T) & grepl("pep", note[r,2], ignore.case = T)) | isTRUE(grepl("Signal", note[r,2], ignore.case = T))){
        df.l <- data.frame(cbind(signal_peptide, description = note[r,2]))

    } else {
      df.l <- data.frame(cbind(other, description = note[r,2]))
    }
    df <- rbind(df, df.l)
  }

  df[is.na(df$colour),][,3] <- as.data.frame(rainbow(nrow(subset(df, df$text == "other"))))

  return(df)
}

# Determine the colours, shape and position of markups. Fix the most common/generic
# ones.
markups.style <- function(entry = NULL){
  note <- subset(entry, entry$type == "markups")
  note <- data.frame(type = "markups", description = unique(note$description))

  # Define some common PTMs here. Anything else is positioned on the bottom, in grey with diamond head style.
  # Disulphide bonds have "headStyle" ignored, unless it is inter-molecular bond with just "start" coordinates.

  PhosphoSerine       <- data.frame(type = "markups", text = "Phospho-Serine",      colour = "#edd400", lineColour = "#edd400", v_align = "bottom", headStyle = "circle")
  PhosphoThreonine    <- data.frame(type = "markups", text = "Phospho-Threonine",   colour = "#edd400", lineColour = "#edd400", v_align = "bottom", headStyle = "square")
  PhosphoTyrosine     <- data.frame(type = "markups", text = "Phospho-Tyrosine",    colour = "#edd400", lineColour = "#edd400", v_align = "bottom", headStyle = "diamond")
  phosphorylation     <- data.frame(type = "markups", text = "phosphorylation",     colour = "#edd400", lineColour = "#edd400", v_align = "bottom", headStyle = "line")

  N_glycosylation     <- data.frame(type = "markups", text = "N-glycosylation",     colour = "#fcaf3e", lineColour = "#fcaf3e", v_align = "top",    headStyle = "line")
  O_glycosylation     <- data.frame(type = "markups", text = "O-glycosylation",     colour = "#fcaf3e", lineColour = "#555753", v_align = "top",    headStyle = "line")
  glycosaminoglycan   <- data.frame(type = "markups", text = "Glycosaminoglycan",   colour = "#555753", lineColour = "#fcaf3e", v_align = "top",    headStyle = "line")
  C_mannosylation     <- data.frame(type = "markups", text = "C-mannosylation",     colour = "#fcaf3e", lineColour = "#fcaf3e", v_align = "top",    headStyle = "diamond")
  O_fucosylation      <- data.frame(type = "markups", text = "O-fucosylation",      colour = "#fcaf3e", lineColour = "#fcaf3e", v_align = "top",    headStyle = "square")
  glycosylation       <- data.frame(type = "markups", text = "glycosylation",       colour = "#fcaf3e", lineColour = "#fcaf3e", v_align = "top",    headStyle = "circle")

  hydroxylation       <- data.frame(type = "markups", text = "hydroxylation",       colour = "#555753", lineColour = "#fcaf3e", v_align = "top",    headStyle = "circle")
  sulfation           <- data.frame(type = "markups", text = "sulfation",           colour = "#555753", lineColour = "#edd400", v_align = "top",    headStyle = "square")
  isomerization       <- data.frame(type = "markups", text = "isomerization",       colour = "#babdb6", lineColour = "#babdb6", v_align = "top",    headStyle = "diamond")

  acetylation         <- data.frame(type = "markups", text = "acetylation",         colour = "#8AE234", lineColour = "#8AE234", v_align = "top",    headStyle = "line")
  methylation         <- data.frame(type = "markups", text = "methylation",         colour = "#8AE234", lineColour = "#8AE234", v_align = "top",    headStyle = "circle")
  amidation           <- data.frame(type = "markups", text = "amidation",           colour = "#8AE234", lineColour = "#8AE234", v_align = "top",    headStyle = "square")
  pyrrolidone         <- data.frame(type = "markups", text = "pyrrolidone",         colour = "#8AE234", lineColour = "#8AE234", v_align = "top",    headStyle = "diamond")

  prenylated          <- data.frame(type = "markups", text = "prenylated",          colour = "#729fcf", lineColour = "#729fcf", v_align = "top",    headStyle = "circle")
  acylated            <- data.frame(type = "markups", text = "acylated",            colour = "#729fcf", lineColour = "#729fcf", v_align = "top",    headStyle = "square")
  gpi                 <- data.frame(type = "markups", text = "gpi",                 colour = "#729fcf", lineColour = "#729fcf", v_align = "top",    headStyle = "diamond")
  lipidation          <- data.frame(type = "markups", text = "lipidation",          colour = "#729fcf", lineColour = "#729fcf", v_align = "top",    headStyle = "line")

  cleavage            <- data.frame(type = "markups", text = "cleavage",            colour = "#555753", lineColour = "#555753", v_align = "top",    headStyle = "square")
  degradation         <- data.frame(type = "markups", text = "degradation",         colour = "#000000", lineColour = "#000000", v_align = "top",    headStyle = "diamond")

  sumo                <- data.frame(type = "markups", text = "sumo",                colour = "#c17d11", lineColour = "#babdb6", v_align = "top",    headStyle = "square")
  ubiquitin           <- data.frame(type = "markups", text = "ubiquitin",           colour = "#c17d11", lineColour = "#babdb6", v_align = "top",    headStyle = "diamond")
  targeting           <- data.frame(type = "markups", text = "targeting",           colour = "#c17d11", lineColour = "#c17d11", v_align = "bottom", headStyle = "circle")
  sorting             <- data.frame(type = "markups", text = "sorting",             colour = "#c17d11", lineColour = "#c17d11", v_align = "bottom", headStyle = "diamond")
  retaining           <- data.frame(type = "markups", text = "retaining",           colour = "#c17d11", lineColour = "#c17d11", v_align = "bottom", headStyle = "square")
  absorption          <- data.frame(type = "markups", text = "absorption",          colour = "#c17d11", lineColour = "#c17d11", v_align = "bottom", headStyle = "arrow")

  diSulfide_bridge    <- data.frame(type = "markups", text = "diSulfide_bridge",    colour = "#babdb6", lineColour = "#babdb6", v_align = "top",    headStyle = "square")
  cross_link          <- data.frame(type = "markups", text = "cross_link",          colour = "#babdb6", lineColour = "#babdb6", v_align = "top",    headStyle = "line")

  nuclear_import      <- data.frame(type = "markups", text = "nuclear_import",      colour = "#ad7fa8", lineColour = "#ad7fa8", v_align = "bottom", headStyle = "square")
  nuclear_export      <- data.frame(type = "markups", text = "nuclear_export",      colour = "#ad7fa8", lineColour = "#ad7fa8", v_align = "bottom", headStyle = "diamond")
  nuclear_receptor    <- data.frame(type = "markups", text = "nuclear_receptor",    colour = "#ad7fa8", lineColour = "#ad7fa8", v_align = "bottom", headStyle = "circle")
  nuclear_related     <- data.frame(type = "markups", text = "nuclear_related",     colour = "#ad7fa8", lineColour = "#ad7fa8", v_align = "bottom", headStyle = "line")

  # TODO: top or bottom?? Especially for arrows.
  dna_binding         <- data.frame(type = "markups", text = "dna_binding",         colour = "#ad7fa8", lineColour = "#ad7fa8", v_align = "bottom", headStyle = "arrow")
  binding_site        <- data.frame(type = "markups", text = "binding_site",        colour = "#4e9a06", lineColour = "#4e9a06", v_align = "bottom", headStyle = "arrow")
  ligand_binding      <- data.frame(type = "markups", text = "ligand_binding",      colour = "#4e9a06", lineColour = "#4e9a06", v_align = "bottom", headStyle = "square")
  ligand_site         <- data.frame(type = "markups", text = "ligand_site",         colour = "#4e9a06", lineColour = "#555753", v_align = "bottom", headStyle = "square")
  docking             <- data.frame(type = "markups", text = "docking",             colour = "#4e9a06", lineColour = "#4e9a06", v_align = "bottom", headStyle = "diamond")
  interacts_with      <- data.frame(type = "markups", text = "interacts_with",      colour = "#4e9a06", lineColour = "#555753", v_align = "bottom", headStyle = "arrow")

  flavin_binding      <- data.frame(type = "markups", text = "flavin_binding",      colour = "#ef2929", lineColour = "#555753", v_align = "bottom", headStyle = "arrow")
  cofactor            <- data.frame(type = "markups", text = "cofactor",            colour = "#ef2929", lineColour = "#ef2929", v_align = "bottom", headStyle = "arrow")
  active_site         <- data.frame(type = "markups", text = "active_site",         colour = "#ef2929", lineColour = "#ef2929", v_align = "bottom", headStyle = "square")
  catalytic_activity  <- data.frame(type = "markups", text = "catalytic_activity",  colour = "#ef2929", lineColour = "#ef2929", v_align = "bottom", headStyle = "diamond")
  activity_regulation <- data.frame(type = "markups", text = "activity_regulation", colour = "#ef2929", lineColour = "#ef2929", v_align = "bottom", headStyle = "circle")

  other               <- data.frame(type = "markups", text = "other",               colour = "#CACACA", lineColour = "#CACACA", v_align = "bottom", headStyle = "arrow")

  # Scan markups and classify them
  df <- data.frame()
  for (r in 1:nrow(note)) {
      if (isTRUE(grepl("ser", note[r,2], ignore.case = T) | grepl("S-", note[r,2], ignore.case = F)) & isTRUE(grepl("phospho", note[r,2], ignore.case = T) | grepl("kinase", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(PhosphoSerine, description = note[r,2]))

    } else if (isTRUE(grepl("thr", note[r,2], ignore.case = T) | grepl("T-", note[r,2], ignore.case = F)) & isTRUE(grepl("phospho", note[r,2], ignore.case = T) | grepl("kinase", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(PhosphoThreonine, description = note[r,2]))

    } else if (isTRUE(grepl("tyr", note[r,2], ignore.case = T) | grepl("Y-", note[r,2], ignore.case = F)) & isTRUE(grepl("phospho", note[r,2], ignore.case = T) | grepl("kinase", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(PhosphoTyrosine, description = note[r,2]))

    } else if (isTRUE(grepl("phosphorylation", note[r,2], ignore.case = T) & isTRUE(grepl("kinase", note[r,2], ignore.case = T) | grepl("site", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

    } else if (isTRUE(grepl("phosphorylation", note[r,2], ignore.case = T) )){
      df.l <- data.frame(cbind(phosphorylation, description = note[r,2]))

    } else if (isTRUE(grepl("glycosaminoglycan", note[r,2], ignore.case = T) | grepl("mucopolysaccharide", note[r,2], ignore.case = T))) {
      df.l <- data.frame(cbind(glycosaminoglycan, description = note[r,2]))

    } else if (isTRUE(grepl("O-", note[r,2], ignore.case = T)) & isTRUE(grepl("fucos", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(O_fucosylation, description = note[r,2]))

    } else if (isTRUE(grepl("C-", note[r,2], ignore.case = T)) & isTRUE(grepl("mannos", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(C_mannosylation, description = note[r,2]))

    } else if (isTRUE(grepl("N-", note[r,2], ignore.case = T)) & isTRUE(grepl("glyco", note[r,2], ignore.case = T) | grepl("link", note[r,2], ignore.case = T))) {
      df.l <- data.frame(cbind(N_glycosylation, description = note[r,2]))

    } else if (isTRUE(grepl("O-", note[r,2], ignore.case = T)) & isTRUE(grepl("glyco", note[r,2], ignore.case = T) | grepl("link", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(O_glycosylation, description = note[r,2]))

    } else if (isTRUE(grepl("O-", note[r,2], ignore.case = T)) & isTRUE(grepl("GalNAc", note[r,2], ignore.case = T) | grepl("mucin", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(O_glycosylation, description = note[r,2]))

    } else if (isTRUE(grepl("glycosylation", note[r,2], ignore.case = T) | grepl("mucopolysaccharide", note[r,2], ignore.case = T))) {
      df.l <- data.frame(cbind(glycosylation, description = note[r,2]))

    } else if (isTRUE(grepl("disulf", note[r,2], ignore.case = T))){
      df.l <- cbind(diSulfide_bridge, description = note[r,2])

    } else if (isTRUE(grepl("prenyl", note[r,2], ignore.case = T) | grepl("isopren", note[r,2], ignore.case = T) | grepl("farnes", note[r,2], ignore.case = T) | grepl("geranyl", note[r,2], ignore.case = T) | grepl("dolichol", note[r,2], ignore.case = T) | grepl("caax", note[r,2], ignore.case = T))){
      df.l <- cbind(prenylated, description = note[r,2])

    } else if (isTRUE(grepl("acylat", note[r,2], ignore.case = T) | grepl("myrist", note[r,2], ignore.case = T) | grepl("palmit", note[r,2], ignore.case = T))){
      df.l <- cbind(acylated, description = note[r,2])

    } else if (isTRUE(grepl("gpi", note[r,2], ignore.case = T) | grepl("glycosylphosphatidylinositol", note[r,2], ignore.case = T) | grepl("phosphoethanolamine", note[r,2], ignore.case = T))){
      df.l <- cbind(gpi, description = note[r,2])

    } else if (isTRUE(grepl("lipid", note[r,2], ignore.case = T))){
      df.l <- cbind(lipidation, description = note[r,2])

    } else if (isTRUE(grepl("sumo", note[r,2], ignore.case = T))){
      df.l <- cbind(sumo, description = note[r,2])

    } else if (isTRUE(grepl("ubiquitin", note[r,2], ignore.case = T))){
      df.l <- cbind(ubiquitin, description = note[r,2])

    } else if (isTRUE(grepl("methyl", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(methylation, description = note[r,2]))

    } else if (isTRUE(grepl("acetyl", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(acetylation, description = note[r,2]))

    } else if (isTRUE(grepl("amide", note[r,2], ignore.case = T) | grepl("amidation", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(amidation, description = note[r,2]))

    } else if (isTRUE(grepl("pyrrolidone", note[r,2], ignore.case = T) | grepl("pyroglutamic", note[r,2], ignore.case = T) | grepl("pyroglutamate", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(pyrrolidone, description = note[r,2]))

    } else if (isTRUE(grepl("hydroxy", note[r,2], ignore.case = T) & isTRUE(grepl("proline", note[r,2], ignore.case = T) | grepl("lysine", note[r,2], ignore.case = T) | grepl("phenylalanine", note[r,2], ignore.case = T) | grepl("arginine", note[r,2], ignore.case = T) | grepl("asparagine", note[r,2], ignore.case = T) | grepl("aspartate", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(hydroxylation, description = note[r,2]))

    } else if (isTRUE(grepl("hydroxylation", note[r,2]))){
      df.l <- data.frame(cbind(hydroxylation, description = note[r,2]))

    } else if (isTRUE(grepl("sulphotyr", note[r,2], ignore.case = T) | grepl("sulphothr", note[r,2], ignore.case = T) | grepl("sulphoser", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(sulfation, description = note[r,2]))

    } else if (isTRUE(grepl("sulfation", note[r,2]))){
      df.l <- data.frame(cbind(sulfation, description = note[r,2]))

    } else if (isTRUE(grepl("flavin", note[r,2], ignore.case = T) | grepl("flavo", note[r,2], ignore.case = T) | grepl("fmn", note[r,2], ignore.case = T) | grepl("fad", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(flavin_binding , description = note[r,2]))

    } else if (isTRUE(grepl("cleave", note[r,2], ignore.case = T) | grepl("cleavage", note[r,2], ignore.case = T))){
      df.l <- cbind(cleavage, description = note[r,2])

    } else if (isTRUE(grepl("degrad", note[r,2], ignore.case = T) | grepl("degron", note[r,2], ignore.case = T) | grepl("destruct", note[r,2], ignore.case = T))){
      df.l <- cbind(degradation, description = note[r,2])

    } else if (isTRUE(grepl("absorb", note[r,2], ignore.case = T) | grepl("absorption", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(absorption, description = note[r,2]))

    } else if (isTRUE(grepl("cross", note[r,2], ignore.case = T) & grepl("link", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(cross_link, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)) & isTRUE(grepl("locali", note[r,2], ignore.case = T) | grepl("import", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_import, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)) & isTRUE(grepl("export", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_export, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)) & isTRUE(grepl("receptor", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_receptor, description = note[r,2]))

    } else if (isTRUE(grepl("nucleus", note[r,2], ignore.case = T) | (grepl("nuclear", note[r,2], ignore.case = T)))){
      df.l <- data.frame(cbind(nuclear_related, description = note[r,2]))

    } else if (isTRUE(grepl("dna", note[r,2], ignore.case = T) & grepl("bind", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(dna_binding, description = note[r,2]))

    } else if (isTRUE(grepl("ligand", note[r,2], ignore.case = T) & grepl("bind", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(ligand_binding, description = note[r,2]))

    } else if (isTRUE(grepl("ligand", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(ligand_site, description = note[r,2]))

    } else if (isTRUE(grepl("bind", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(binding_site, description = note[r,2]))

    } else if (isTRUE(grepl("sort", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(sorting, description = note[r,2]))

    } else if (isTRUE(grepl("retain", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(retaining, description = note[r,2]))

    } else if (isTRUE(grepl("target", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(targeting, description = note[r,2]))

    } else if (isTRUE(grepl("docking", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(docking, description = note[r,2]))

    } else if (isTRUE(grepl("interact", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(interacts_with, description = note[r,2]))

    } else if (isTRUE(grepl("co", note[r,2], ignore.case = T) & grepl("factor", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(cofactor, description = note[r,2]))

    } else if (isTRUE(grepl("activ", note[r,2], ignore.case = T) & grepl("site", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(active_site, description = note[r,2]))

    } else if (isTRUE(grepl("catal", note[r,2], ignore.case = T) & grepl("activ", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(catalytic_activity, description = note[r,2]))

    } else if (isTRUE(grepl("activ", note[r,2], ignore.case = T) & grepl("regulat", note[r,2], ignore.case = T))){
      df.l <- data.frame(cbind(activity_regulation, description = note[r,2]))

    # I don't like grepping just a letter, so leave last
    } else if (isTRUE(grepl("D-", note[r,2]))){
      df.l <- data.frame(cbind(isomerization, description = note[r,2]))

    } else if (isTRUE(grepl("isomerization", note[r,2]))){
      df.l <- data.frame(cbind(isomerization, description = note[r,2]))

    } else {
      df.l <- data.frame(cbind(other, description = note[r,2]))
    }

    df <- rbind(df, df.l)
  }

  # Colour the NA from "other", if any
  # https://stackoverflow.com/a/8161878
  #df[is.na(df$colour),][,3] <- as.data.frame(rainbow(nrow(subset(df, df$text == "other"))))

  return(df)
}

# Determine regions (a.k.a "domains") shape: arrow (big), curved (medium) or straight (small)
# region x, region y, type t
regions.style <- function(x, y, t){

  region_size <- as.numeric(y) - as.numeric(x)
  #set.seed(1)

  # TODO: classify regions and Domains, similarly to repeats??
  if (isTRUE(grepl("repeat", t, ignore.case = T))) {
    style = "jagged"
    } else if (region_size >= 200) {
      style = "arrow"
    } else if ((region_size <= 200) & (region_size >= 35)) {
      style = "curved"
    } else if (region_size < 35) {
      style = "straight"
    } else {
      style = "straight"
    }

  return(style)
}

# Write a data frame with regions (domains) and determine their shapes and colours.
prepare.regions <- function(entry = NULL){

  # Create rainbow gradient of features, by "regions". use name (4), not description (5)
  note <- unique(subset(entry, entry[, 1] == "regions")[, 4])
  set.seed(1)
  regions.paint <- data.frame(note = note, paint = rainbow(length(note)))

  # Regions (domains)
  regions <- subset(entry, entry$type == "regions")
  df.regions <- data.frame()
  for (r in 1:nrow(regions)) {

    # set colour and style of the domain
    paint <- regions.paint$paint[match(regions[r,4], regions.paint$note)]
    style <- regions.style(regions[r,2], regions[r,3], regions[r,5])

    df.regions.l <- data.frame(type = regions[r,4],
                               start = as.numeric(regions[r,2]),
                               end = as.numeric(regions[r,3]),
                               text = regions[r,4],
                               description = regions[r,5],
                               colour = paint,
                               scoreName = regions[r,6],
                               score = regions[r,7],
                               sequence = regions[r,10],
                               database = regions[r,8],
                               accession = regions[r,9],
                               display = NA,
                               startStyle = style,
                               endStyle = style,
                               target = regions[r,11])

    df.regions <- rbind(df.regions, df.regions.l)
  }
  return(df.regions)
}

# Write a data frame with motifs and set their colours.
prepare.motifs <- function(entry = NULL){
  motifs <- subset(entry, entry$type == "motifs")
  styles.motifs <- motifs.style(entry)
  df.motifs <- data.frame()
  for (r in 1:nrow(motifs)) {

    # get info for this particular motif
    style <- styles.motifs[match(motifs[r,5], styles.motifs[,4]),]

    df.motifs.l <- data.frame(type = style$text,
                              start = as.numeric(motifs[r,2]),
                              end = as.numeric(motifs[r,3]),
                              text = NA,
                              description = motifs[r, 5],
                              colour = style$colour,
                              scoreName = motifs[r,6],
                              score = motifs[r,7],
                              sequence = motifs[r,10],
                              database = motifs[r,8],
                              accession = motifs[r,9],
                              display = "true",
                              target = motifs[r,11])

    df.motifs <- rbind(df.motifs, df.motifs.l)
  }
  return(df.motifs)
}

# Write a data frame of markups and set their shapes, positions and colours
prepare.markups <- function(entry = NULL){
  markups <- subset(entry, entry$type == "markups")
  styles.markups <- markups.style(entry)
  df.markups <- data.frame()
  for (r in 1:nrow(markups)) {

    # get info for this particular markup
    style <- styles.markups[match(markups[r,5], styles.markups[,7]),]

    # Do not parse "end" coordinates if start and end are the same
    if((markups[r,2] == markups[r,3])){stop = NA}else{stop = as.numeric(markups[r,3])}

    df.markups.l <- data.frame(type = style$text,
                               start = as.numeric(markups[r,2]),
                               end = stop,
                               text = style$text,
                               description = markups[r,5],
                               colour = style$colour,
                               scoreName = markups[r,6],
                               score = markups[r,7],
                               sequence = markups[r,10],
                               database = markups[r,8],
                               accession = markups[r,9],
                               display = "true",
                               lineColour = style$lineColour,
                               v_align = style$v_align,
                               headStyle = style$headStyle,
                               target = markups[r,11])

    df.markups <- rbind(df.markups, df.markups.l)
  }
  return(df.markups)
}

# Add features up into a list
prepare.features <- function(entry = NULL){

  # empty list to add them up one by one if they exist
  li <- list()

  # TODO: change the wayy df is added to list? using $dfname?
  if (isTRUE(setequal(intersect("regions", entry$type), "regions"))) {
    df.regions <- prepare.regions(entry)
    li[["regions"]] <- df.regions
  }else{
    li[["regions"]] <- data.frame()
  }

  if (isTRUE(setequal(intersect("markups", entry$type), "markups"))) {
    df.markups <- prepare.markups(entry)
    li[["markups"]] <- df.markups
  }else{
    li[["markups"]] <- data.frame()
  }

  if (isTRUE(setequal(intersect("motifs", entry$type), "motifs"))) {
    df.motifs <- prepare.motifs(entry)
    li[["motifs"]] <- df.motifs
  }else{
    li[["motifs"]] <- data.frame()
  }

  return(li)
}

################################################################################
# Prepare features as nested data frames #######################################
################################################################################

# Regions (a.k.a. "domains") section.
add.regions <- function(db = NULL){
  df <- data.frame()
  for (r in 1:nrow(db)) {
    df.local <- data.frame(text = db[r,4],
                           start = db[r,2],
                           end = db[r,3],
                           startStyle = db[r,13],
                           endStyle = db[r,14],
                           colour = db[r,6])

    # add metadata sublist per domain
    df.meta <- data.frame(description = db[r,5],
                          scoreName = db[r,7],
                          score = db[r,8],
                          database = db[r,10],
                          start = db[r,2],
                          end = db[r,3],
                          accession = db[r,11],
                          identifier = db[r,1],
                          fix.empty.names = T)

    df.local$metadata <- df.meta

    df <- rbind(df, df.local)
  }
  return(df)
}

# Motifs section.
add.motifs <- function(db = NULL){
  df <- data.frame()
  for (r in 1:nrow(db)) {
    df.local <- data.frame(type = db[r,1],
                           start = db[r,2],
                           end = db[r,3],
                           colour = db[r,6],
                           display = db[r,12])

    df.meta <- data.frame(description = db[r,5],
                          scoreName = db[r,7],
                          score = db[r,8],
                          database = db[r,10],
                          sequence = db[r,9],
                          type = db[r,1],
                          start = db[r,2],
                          end = db[r,3])

    df.local$metadata <- df.meta

    df <- rbind(df, df.local)
  }
  return(df)
}

# Markups section.
add.markups <- function(db = NULL){
  df <- data.frame()
  for (r in 1:nrow(db)) {
    df.local <- data.frame(type = db[r,1],
                           start = db[r,2],
                           end = db[r,3],
                           colour = db[r,6],
                           lineColour = db[r,13],
                           v_align = db[r,14],
                           headStyle = db[r,15],
                           display = db[r,12])

    df.meta <- data.frame(description = db[r,5],
                          scoreName = db[r,7],
                          score = db[r,8],
                          database = db[r,10],
                          target = db[r,16],
                          residue = NA,
                          type = db[r,1],
                          start = db[r,2],
                          end = db[r,3])

    df.local$metadata <- df.meta

    df <- rbind(df, df.local)
  }
  return(df)
}

# Create final scheme, by adding features (if they exist or are desired) as nested tables to list
add.features <- function(meta = NULL, length = NULL, prep = NULL, regions.on = TRUE, motifs.on = TRUE, markups.on = TRUE){
  scheme <- list()
  scheme$metadata <- meta
  scheme$length <- length

  if (!length((prep[["regions"]])) == 0 & regions.on == T) {
    scheme$regions <- add.regions(prep[["regions"]])
  }else{
    scheme$regions <- NULL
  }

  if (!length((prep[["motifs"]])) == 0 & motifs.on == T) {
    scheme$motifs <- add.motifs(prep[["motifs"]])
  }else{
    scheme$motifs <- NULL
  }

  if (!length((prep[["markups"]])) == 0 & markups.on == T) {
    scheme$markups <- add.markups(prep[["markups"]])
  }else{
    scheme$markups <- NULL
  }
  return(scheme)
}

################################################################################
# Predicted features ###########################################################
################################################################################

# Metadata, to be filled by user
metadata.custom <- function(accession.num = NULL,
                            description = NULL,
                            organism = NULL,
                            link.url = NULL,
                            taxid = NULL){

  df <- data.frame(accession = accession.num,
                   description = description,
                   link.url = link.url,
                   organism = organism,
                   taxid = taxid)

  return(df)
}

# Process SMART database results
process.SMART <- function(smart.tsv = NULL){
  smart <- read.table(smart.tsv, header = F, sep = "\t")
  smart.descriptions <- fields.db$smart.descriptions

  df <- data.frame()
  for (r in 1:nrow(smart)) {

    if (smart[r,1] == "signal peptide" |
        smart[r,1] == "low complexity" |
        smart[r,1] == "intrinsic disorder" |
        smart[r,1] == "transmembrane region") {
      tp <- "motifs"
      ds <- "N/A"
      ac <- "N/A"
      sc <- "N/A"
    } else if(smart[r,2] == smart[r,3]) {
      tp <- "markups"
      ds <- "N/A"
      ac <- "N/A"
      sc <- "N/A"
    } else {
      tp <- "regions"
      description <- smart.descriptions[match(smart[r,1], smart.descriptions[,1]),]
      ds <- description$DEFINITION
      ac <- description$ACC
      sc <- smart[r,4]
    }

    df.l <- data.frame(type = tp,
                       start = smart[r,2],
                       end = smart[r,3],
                       text = smart[r,1],
                       description = smart[r,1],
                       scoreName = "e-value",
                       score = sc,
                       database = "S.M.A.R.T.",
                       accession = ac,
                       sequence = "N/A",
                       target = "N/A")
    df <- rbind(df, df.l)
  }

  return(df)
}

# function to fill NA (https://stackoverflow.com/a/55164607)
fill_NA <- function(x) {
  which.na <- c(which(!is.na(x)), length(x) + 1)
  values <- na.omit(x)

  if (which.na[1] != 1) {
    which.na <- c(1, which.na)
    values <- c(values[1], values)
  }

  diffs <- diff(which.na)
  return(rep(values, times = diffs))
}

# Process ELM database results
process.ELM <- function(elm.xlsx = NULL, elm.scores = NULL, cutoff = 0.5){
  elm <- read.xlsx(elm.xlsx)
  elm.classes <- fields.db$elm.classes

  elm <- subset(elm, !is.na(elm[, 3]))
  elm <- elm[, 1:3]
  elm[, 3] <- gsub(" \\[A\\]", "", elm[, 3])

  # transform list to a dataframe
  position <- strsplit(elm[, 3], "-")
  position <- as.data.frame(t(sapply(position, FUN = c)))
  elm$start <- position[,1]
  elm$end <- position[,2]
  elm <- elm[, c(1,2,4,5)]

  elm$Elm.Name <- fill_NA(elm$Elm.Name)

  # process conservation scores. In case no cons scores are provided, put "N/A"
  if (!is.null(elm.scores)) {
    cs <- readLines(elm.scores)
    cs <- grep("^CS=", cs, value = T)
    cs <- strsplit(cs, "\t")

    cf <- data.frame()
    for (e in 1:length(cs)) {
      cf.l <- data.frame(Elm.Name = unlist(strsplit(cs[[e]][6], " regular expression match")),
                         score = unlist(as.numeric(gsub("[^0-9]", "", cs[[e]][1]))/100),
                         start = unlist(cs[[e]][4]),
                         end = unlist(cs[[e]][5]))
      cf <- rbind(cf, cf.l)
    }
    cf <- subset(cf, cf$score >= cutoff)
    elm <- merge(elm, cf)
  }else{
    elm <- data.frame(Elm.Name = elm[,1], start = elm[,3], end = elm[,4], Instances = elm[,2], score = "N/A")
  }
#return(elm)
  # write it up
  if (nrow(elm != 0)){
    df <- data.frame()
    for (r in 1:nrow(elm)) {
      description <- elm.classes[match(elm[r,1], elm.classes[,2]),]
      df.l <- data.frame(type = "motifs",
                         start = elm[r,2],
                         end = elm[r,3],
                         text = elm[r,1],
                         description = description$FunctionalSiteName,
                         scoreName = "Conservation Score",
                         score = elm[r,5],
                         database = "E.L.M",
                         accession = description$Accession,
                         sequence = elm[r,4],
                         target = "N/A")
      df <- rbind(df, df.l)
    }
    return(df)
  }else{
    return(NULL)
  }
}

# Process UIPred3/ANCHOR2 results
process.ANCHOR <- function(anchor.tsv = NULL, cutoff = 0.5){
  anchor <- read.table(anchor.tsv, skip = 8, header = F)
  colnames(anchor) <- c("Position", "Residue", "IUPred.score", "Anchor.score", "Exp.dis")
  sub.an <- subset(anchor, anchor[, 3] > cutoff)
  sub.iu.an <- subset(sub.an, sub.an[, 4] > cutoff)

  # make sure there's data above threshold (https://stackoverflow.com/a/43234061)
  if (nrow(sub.iu.an != 0)) {
    # Define start and end positions (https://stackoverflow.com/a/23095527)
    sort.dbs <- unname(tapply(sub.iu.an$Position, cumsum(c(1, diff(sub.iu.an$Position)) != 1), range))
    sort.dbs <- as.data.frame(t(sapply(sort.dbs, FUN = c)))
    colnames(sort.dbs) <- c("start", "end")

    # can be done with a single df, but let's have the flexibility of a loop
    df <- data.frame()
    for (r in 1:nrow(sort.dbs)) {
      df.l <- data.frame(type = "motifs",
                         start = sort.dbs[r,1],
                         end = sort.dbs[r,2],
                         text = "IDBS",
                         description = "Intrinsically disordered binding site",
                         scoreName = "threshold",
                         score = paste(">", cutoff),
                         database = "IUPred3..ANCHOR2",
                         accession = "N/A",
                         sequence = "N/A",
                         target = "N/A")
      df <- rbind(df, df.l)
    }
    return(df)
  }else{
    return(NULL)
  }
}

# Process NetNGlyc results
process.NetNGlyc <- function(netnglyc.tsv = NULL, cutoff = 0.5){
  nglyc <- read.table(netnglyc.tsv)
  nglyc <- subset(nglyc, nglyc[, 4] > cutoff)

  if (nrow(nglyc != 0)) {
    df <- data.frame(type = "markups",
                     start = nglyc[,2],
                     end = nglyc[,2],
                     text = "NGlyc",
                     description = "N-glycosylation site",
                     scoreName = "threshold",
                     score = nglyc[,4],
                     database = "NetNGlyc",
                     accession = "N/A",
                     sequence = nglyc[,3],
                     target = "N/A")

    return(df)
  }else{
    return(NULL)
  }
}

# Process NetOGlyc results
process.NetOGlyc <- function(netoglyc.tsv = NULL, cutoff = 0.5){
  oglyc <- read.table(netoglyc.tsv)
  oglyc <- subset(oglyc, oglyc[, 6] > cutoff)

  if (nrow(oglyc != 0)) {
    df <- data.frame(type = "markups",
                     start = oglyc[,4],
                     end = oglyc[,4],
                     text = "OGlyc",
                     description = "O-glycosylation site",
                     scoreName = "threshold",
                     score = oglyc[,6],
                     database = "NetNGlyc",
                     accession = "N/A",
                     sequence = "N/A",
                     target = "N/A")

    return(df)
  }else{
    return(NULL)
  }
}

# Process NetPhos results
process.NetPhos <- function(netphos.tsv = NULL, cutoff = 0.5){
  phos <- read.table(netphos.tsv, skip = 2, header = F, comment.char = "/", fill = T)
  phos <- phos[, 2:8]
  phos <- na.omit(phos)
  phos <- subset(phos, phos[, 7] == "YES" & phos[, 5] > cutoff)

  if (nrow(phos != 0)) {
    positions <- phos[ ,2]
    dup.df <- data.frame()
    for (m in positions) {
      dup <- t(subset(phos, phos[, 2] == m))
      dup.l <- data.frame(type = "markups",
                          start = dup[2,1],
                          end = dup[2,1],
                          text = paste0(dup[3,1], "phos"),
                          description = paste0(dup[3,1], "-phosphorylation site"),
                          scoreName = "threshold",
                          score = toString(dup[5,]),
                          database = "NetPhos",
                          accession = "N/A",
                          sequence = dup[3,1],
                          target = toString(dup[6, ]))

      dup.df <- rbind(dup.df, dup.l)
    }
    return(unique(dup.df))
  }else{
    return(NULL)
  }
}

# Process ScanSite results
process.ScanSite <- function(scansite.tsv = NULL, score = 0.5, percentile = 0, accessibility = 1){
  scnsi <- read.table(scansite.tsv, skip = 1, header = F, sep = "\t")
  scnsi <- subset(scnsi, scnsi[,5] < score & scnsi[,6] > percentile & scnsi[,10] > accessibility)

    if (nrow(scnsi != 0)) {
      positions <- as.numeric(gsub("[^0-9]", "", scnsi[ ,8]))
      #residues <- gsub("[^A-Z]", "", scnsi[ ,8])
      #return(residues)
      dup.df <- data.frame()
      for (m in positions) {
        dup <- t(subset(scnsi, as.numeric(gsub("[^0-9]", "", scnsi[ ,8])) == m))

        if (substring(dup[9,1], 8, 8)  == "s" & (grepl("kinase", dup[4,1], ignore.case = T) | grepl("Phosphoserine/threonine", dup[4,1], ignore.case = T))){
          txt = "Sphos"
          dsc = "S-phosphorylation site"
        }else if (substring(dup[9,1], 8, 8)  == "t" & (grepl("kinase", dup[4,1], ignore.case = T) | grepl("Phosphoserine/threonine", dup[4,1], ignore.case = T))){
          txt = "Tphos"
          dsc = "T-phosphorylation site"
        }else if (substring(dup[9,1], 8, 8)  == "y" & (grepl("kinase", dup[4,1], ignore.case = T) | grepl("Phosphotyrosine", dup[4,1], ignore.case = T))){
          txt = "Yphos"
          dsc = "Y-phosphorylation site"
        }else{
          txt = "other"
          dsc = toString(dup[4,])
        }

        dup.l <- data.frame(type = "markups",
                         start = as.numeric(gsub("[^0-9]", "", dup[8,1])),
                         end = as.numeric(gsub("[^0-9]", "", dup[8,1])),
                         text = txt,
                         description = dsc,
                         scoreName = "score/percentile/accessibility",
                         score = toString(paste(dup[5,], dup[6,], dup[10,])),
                         database = "ScanSite",
                         accession = toString(dup[2,]),
                         sequence = dup[9,1],
                         target = toString(dup[3,]))

        dup.df <- rbind(dup.df, dup.l)
      }
    return(unique(dup.df))
  }else{
    return(NULL)
  }
}

################################################################################
# Main functions: generate topology organisation file in Pfam's (legacy) JSON ##
################################################################################
#' Generate JSON for a protein database identifier (ID).
#'
#' Search database (UniProt or NCBI GenPept) with submitted protein identifier
#' (database accession number) and extract protein features from the respective
#' database. Generates topology organisation scheme file in Pfam's JSON format.
#'
#' @param input database accession number (identifier)
#' @param database database to be searched: UniProt or NCBI GenPept.
#' @param offline whether to search the database directly online (default) or use a local file.
#' @param regions.on shall we include regions in the results (default is TRUE).
#' @param motifs.on shall we include motifs in the results (default is TRUE).
#' @param markups.on shall we include markups in the results (default is TRUE).
#'
#' @example man/examples/id.JSON.R
#'
#' @returns Generates topology organisation scheme file in Pfam's JSON format.
#'
#' @export
id.JSON <- function(input = NULL, database = NULL, offline = FALSE, regions.on = TRUE, motifs.on = TRUE, markups.on = TRUE){
  db <- tolower(database)

  # which database are we using? Check if input.file is from disk or retrieved?
  if (isTRUE(db == "ncbi")){
    if (isTRUE(offline)) {input.file <- read.NCBI.gp(input)}else{input.file <- get.NCBI.gp(input)}
    meta <- metadata.NCBI.gp(input.file)
    length <- length.NCBI.gp(input.file)
    features <- features.NCBI.gp(input.file)

  }else if (isTRUE(db == "uniprot")){
    if (isTRUE(offline)) {input.file <- read.UniProt.json(input)}else{input.file <- get.UniProt.json(input)}
    # if (isTRUE(offline)) {input.file <- read.UniProt.gff(input)}else{input.file <- get.UniProt.gff(input)}
    # meta <- metadata.UniProt.gff(input.file)
    # length <- length.UniProt.gff(input.file)
    # features <- features.UniProt.gff(input.file)

    meta <- metadata.UniProt.json(input.file)
    length <- length.UniProt.json(input.file)
    features <- features.UniProt.json(input.file)
  }else {
    print("Please specify a valid database")
    stop()
  }

  prep <- prepare.features(entry = features)
  scheme <- add.features(meta, length, prep, regions.on, motifs.on, markups.on)
  scheme <- toJSON(scheme, pretty = T)
  #validate(scheme)
  return(scheme)
}

#' Generate JSON from predicted features for your protein.
#'
#' Process protein features predicted at different online resources. These are:
#' SMART, ELM, IUPred3/Anchor2, NetNGlyc, NetOGlyc, NetPhos and ScanSites. Cut-
#' off values for scores can be specified. Metadata, such as protein length
#' (required) and (optionally) protein name and other info should be provided by
#' the user. Generates topology organisation scheme file in Pfam's JSON format.
#'
#' @param protein.length integer. Protein length as a number of amino acids.
#' @param accession.number accession number (optional).
#' @param description short description/name of your protein
#' @param organism organism your protein is from
#' @param link.url web-link to online resource
#' @param taxid organism taxa ID
#' @param SMART.tsv SMART database results file
#' @param ELM.xlsx ELM database results file
#' @param ELM.features.tsv ELM conservation scores file
#' @param ELM.score ELM conservation scores cutoff
#' @param SCANSITE.tsv ScanSite results file
#' @param SCANSITE.score ScanSite scores cutoff
#' @param SCANSITE.percentile ScanSite percentile cutoff
#' @param SCANSITE.accessibility ScanSite accessibility cutoff
#' @param ANCHOR.tsv IUPred/Anchor2 results file
#' @param ANCHOR.cutoff IUPred/Anchor2 scores cutoff
#' @param netNglyc.tsv NetNGlyc results file
#' @param netNglyc.cutoff NetNGlyc scores cutoff
#' @param netOglyc.tsv NetOGlyc results file
#' @param netOglyc.cutoff NetOGlyc scores cutoff
#' @param netPhos.tsv NetPhos results file
#' @param netPhos.cutoff NetPhos scores cutoff
#'
#' @example man/examples/predicted.JSON.R
#'
#' @returns Generates topology organisation scheme file in Pfam's JSON format.
#'
#' @export
predicted.JSON <- function(protein.length = NULL,
                         accession.number = NULL,
                         description = NULL,
                         organism = NULL,
                         link.url = NULL,
                         taxid = NULL,
                         SMART.tsv = NULL,
                         ELM.xlsx = NULL,
                         ELM.features.tsv = NULL,
                         ELM.score = NULL,
                         SCANSITE.tsv = NULL,
                         SCANSITE.score = NULL,
                         SCANSITE.percentile = NULL,
                         SCANSITE.accessibility = NULL,
                         ANCHOR.tsv = NULL,
                         ANCHOR.cutoff = NULL,
                         netNglyc.tsv = NULL,
                         netNglyc.cutoff = NULL,
                         netOglyc.tsv = NULL,
                         netOglyc.cutoff = NULL,
                         netPhos.tsv = NULL,
                         netPhos.cutoff = NULL){

  # do not accept length below 1
  if (!is.numeric(protein.length) | isTRUE(protein.length < 1) | is.null(protein.length) | is.na(protein.length)) {
    #protein.length <- 0
    stop("Error! Check length! \n")
  }

  meta <- metadata.custom(accession.number,
                          description,
                          organism,
                          link.url,
                          taxid)

  length <- protein.length

  # anything empty?
  if (is.null(SMART.tsv)){
    smart.df <- NULL
    cat("SMART.tsv is empty, skipping. \n")
  }else{
    smart.df <- process.SMART(SMART.tsv)
    cat("SMART.tsv loaded succesfully.\n")
  }

  if (is.null(ELM.xlsx)){
    elm.df <- NULL
    cat("ELM.xlsx is empty, skipping.\n")
  }else{
    elm.df <- process.ELM(ELM.xlsx, ELM.features.tsv, ELM.score)
    cat("ELM.xlsx loaded succesfully.\n")
  }

  if (is.null(ANCHOR.tsv)){
    anchor.df <- NULL
    cat("ANCHOR.tsv is empty, skipping.\n")
  }else{
    anchor.df <- process.ANCHOR(ANCHOR.tsv, ANCHOR.cutoff)
    cat("ANCHOR.tsv loaded succesfully.\n")
  }

  if (is.null(SCANSITE.tsv)){
    scnsci.df <- NULL
    cat("SCANSITE.tsv is empty, skipping.\n")
  }else{
    scnsci.df <- process.ScanSite(SCANSITE.tsv, SCANSITE.score, SCANSITE.percentile, SCANSITE.accessibility)
    cat("SCANSITE.tsv loaded succesfully.\n")
  }

  if (is.null(netNglyc.tsv)){
    nglyc.df <- NULL
    cat("netNglyc.tsv is empty, skipping.\n")
  }else{
    nglyc.df <- process.NetNGlyc(netNglyc.tsv, netNglyc.cutoff)
    cat("netNglyc.tsv loaded succesfully.\n")
  }

  if (is.null(netOglyc.tsv)){
    oglyc.df <- NULL
    cat("netOglyc.tsv is empty, skipping.\n")
  }else{
    oglyc.df <- process.NetOGlyc(netOglyc.tsv, netOglyc.cutoff)
    cat("netOglyc.tsv loaded succesfully.\n")
  }

  if (is.null(netPhos.tsv)){
    phos.df <- NULL
    cat("netPhos.tsv is empty, skipping.\n")
  }else{
    phos.df <- process.NetPhos(netPhos.tsv, netPhos.cutoff)
    cat("netPhos.tsv loaded succesfully.\n")
  }

  features <- rbind(smart.df, elm.df, anchor.df, nglyc.df, oglyc.df, phos.df, scnsci.df)

  prep <- prepare.features(entry = features)
  scheme <- add.features(meta, length, prep)
  scheme <- toJSON(scheme, pretty = T)
  #validate(scheme)
  return(scheme)
}

#' Generate JSON from a (manually prepared) table of features for your protein.
#'
#' Process a table of features of your protein of interest. Typically, that's a
#' manually curated list of features, summarized in a spreadsheet, which can be
#' imported. Generates topology organisation scheme file in Pfam's JSON format.
#'
#' @param protein.length integer. Protein length as a number of amino acids.
#' @param accession.number accession number (optional).
#' @param description short description/name of your protein
#' @param organism organism your protein is from
#' @param link.url web-link to online resource
#' @param taxid organism taxa ID
#' @param input.file input file (curated table with features)
#' @param input.format format of the table: XLSX, CSV, TSV
#'
#' @example man/examples/custom.JSON.R
#'
#' @returns Generates topology organisation scheme file in Pfam's JSON format.
#'
#' @export
custom.JSON <- function(protein.length = NULL,
                             accession.number = NULL,
                             description = NULL,
                             organism = NULL,
                             link.url = NULL,
                             taxid = NULL,
                             input.file = NULL,
                             input.format = NULL){

  # do not accept length below 1
  if (!is.numeric(protein.length) | isTRUE(protein.length < 1) | is.null(protein.length) | is.na(protein.length)) {
    #protein.length <- 0
    stop("Error! Check length! \n")
  }

  meta <- metadata.custom(accession.number,
                          description,
                          organism,
                          link.url,
                          taxid)

  length <- protein.length

  if (is.null(input.file)){
    features <- NULL
  }else{
    features <- read.custom(inp = input.file, ft = input.format)
  }

  prep <- prepare.features(entry = features)
  scheme <- add.features(meta, length, prep)
  scheme <- toJSON(scheme, pretty = T)
  #validate(scheme)
  return(scheme)
}

#' Generate a table from JSON input of protein features.
#'
#' Create a simple table from JSON (e.g. files saved on disk). Useful to compare
#' different annotations from different sources for the same protein. Only features
#' are exported, no metadata.
#'
#' @param json JSON input to be written as a table
#'
#' @example man/examples/json.TABLE.R
#'
#' @returns A table generated from a JSON input.
#'
#' @export
json.TABLE <- function(json = NULL){
  # TODO: fix empty cells!
  df <- data.frame()
  for (i in 3:length(json)) {

    if(names(json[i]) == "regions"){
      df.l <- data.frame(type = names(json[i]),
                         start = json[[i]][,2],
                         end = json[[i]][,3],
                         text = json[[i]][,1],
                         description = json[[i]][,7][,1],
                         scoreName = json[[i]][,7][,2],
                         score = json[[i]][,7][,3],
                         database = json[[i]][,7][,4],
                         accession = NA,
                         sequence = NA,
                         target = NA)
    }else if(names(json[i]) == "motifs"){
      df.l <- data.frame(type = names(json[i]),
                         start = json[[i]][,2],
                         end = json[[i]][,3],
                         text = json[[i]][,1],
                         description = json[[i]][,6][,1],
                         scoreName = json[[i]][,6][,2],
                         score = json[[i]][,6][,3],
                         database = json[[i]][,6][,4],
                         accession = NA,
                         sequence = NA,
                         target = NA)
    }else if(names(json[i]) == "markups"){
      if (colnames(json$markups[3]) == "end") {
        df.l <- data.frame(type = names(json[i]),
                           start = json[[i]][,2],
                           end = json[[i]][,3],
                           text = json[[i]][,1],
                           description = json[[i]][,9][,1],
                           scoreName = json[[i]][,9][,2],
                           score = json[[i]][,9][,3],
                           database = json[[i]][,9][,4],
                           accession = NA,
                           sequence = NA,
                           target = NA)
        }else{
          df.l <- data.frame(type = names(json[i]),
                             start = json[[i]][,2],
                             end = NA,
                             text = json[[i]][,1],
                             description = json[[i]][,8][,1],
                             scoreName = json[[i]][,8][,2],
                             score = json[[i]][,8][,3],
                             database = json[[i]][,8][,4],
                             accession = NA,
                             sequence = NA,
                             target = NA)
        }
    }
    df <- rbind(df, df.l)
  }
  return(df)
}
