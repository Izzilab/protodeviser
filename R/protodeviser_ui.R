#
# ProToDeviser: Start the actual Shiny app UI
#

# That's a lifesaver
# https://stackoverflow.com/questions/76631670/in-r-package-workflow-how-to-add-image-to-shiny-app

#' ProToDeviseR UI
#'
#' ProToDeviseR main app with graphical user interface (UI)
#'
#' @returns A graphical user interface for ProToDeviser
#' @export
protodeviser_ui <- function(){

  # make sure these are all loaded
  library("jsonlite")
  library("seqinr")
  library("dplyr")
  library("openxlsx")
  library("gggenomes")
  library("IRanges")
  library("rentrez")
  library("shiny")
  library("shinyBS")
  library("rclipboard")
  #library("shinyjs")
  library("DT")

  # where is webApp? Find and run from there
  app_dir <- system.file("webApp", package = "protodeviser")

  if (app_dir == "") {
    stop(
      "Could not find the app directory. Try re-installing `protodeviser`.",
      call. = FALSE
    )
  }

  runApp(appDir = app_dir, launch.browser = T)

}
