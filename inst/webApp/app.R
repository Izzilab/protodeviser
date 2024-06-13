#
# ProToDeviser: ShinyApp UI
#

library("markdown")
library("shiny")
library("shinyBS")
library("rclipboard")
#library("shinyjs")
library("DT")

# These are the databases we are using in Tab1
dbs <- c("UniProt", "NCBI GenPept")
names(dbs) <- c("uniprot", "ncbi")

# These are the table formats we accept in Tab2
tbf <- c("Excel (xlsx)", "Comma-separated (csv)", "Tab-separated (tsv)")
names(tbf) <- c("xlsx", "csv", "tsv")

# find paths to markdown files
www <- system.file("webApp/www", package = "protodeviser")

# GUI ----
ui <- fluidPage(title = "ProToDeviseR",
                # needed for custom download icons
                # (https://stackoverflow.com/questions/76554101/r-shiny-change-download-button-image)
                tags$head(tags$link(href="icon.css", rel="stylesheet")),
                sidebarLayout(
                  sidebarPanel(
                    titlePanel("ProToDeviseR Input"),

                    p("ProToDeviseR aims at producing a concise protein-topology scheme, by plotting",
                      strong("regions"), popify(el = img(src="icons/help.png"), title = "Regions", content = "Usually domains or other relatively long, functional parts of the protein.", placement = "bottom"),
                      ",",
                      strong("motifs"), popify(el = img(src="icons/help.png"), title = "Motifs", content = "Usually short liner motifs. Also denoted as motifs are disordered regions, signal peptides and transmembrane regions.", placement = "bottom"),
                      "and",
                      strong("markups"), popify(el = img(src="icons/help.png"), title = "Markups", content = "Usually single-amino acid targes, such as glycosylation, binding, etc.", placement = "bottom"),
                      ", with coordinates proportional to the length of the protein."),

                    hr(),

                    # DO WE WANT A REFRESH BUTTON? I think we do. However, no need of shinyjs to implement it
                    #shinyjs::useShinyjs(),
                    #shinyjs::extendShinyjs(text = "shinyjs.refresh_page = function() { location.reload(); }", functions = "refresh_page"),
                    div(actionButton("refresh", "", icon = tags$i(class = "clear")), style="position:relative; float: right"),
                    bsTooltip(id = "refresh", title = "Reset all input/output", placement = "right"),

                    tabsetPanel(selected = "tab1",
                                type = "pills",

                                # Tab1 ----
                                tabPanel(title = "Protein ID",
                                         value = "tab1", icon = tags$img(src='icons/id.png'),

                                         h3("Retrieve features using a protein ID"),
                                         br(),
                                         span("Enter", strong("UniProt"), tags$a(href="https://www.uniprot.org/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit UniProt knowledgebase", placement = "top")),
                                              "or", strong("NCBI GenPept"), tags$a(href="https://www.ncbi.nlm.nih.gov/protein/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit NCBI GenPept database", placement = "top")),
                                              "identifier (ID) to be searched against the respective database."),
                                         hr(),

                                         # Radio buttons to select UniProt or NCBI database
                                         radioButtons(inputId = "tab1_radio_button",
                                                      label = span("Database",
                                                                   popify(el = img(src="icons/help.png"), title = "Database to be searched with ID", content = "Specify the database your protein ID is from", placement = "top")),
                                                      choiceNames = unname(dbs),
                                                      choiceValues = names(dbs),
                                                      selected = "uniprot",
                                                      inline = T),

                                         uiOutput(outputId = "tab1_examples"),

                                         # Text input box for ID to be searched
                                         textInput(inputId = "tab1_text_in",
                                                   label = "Search with ID:"),

                                         # Choose what to include
                                         checkboxGroupInput(inputId = "tab1_checkbox",
                                                            label = span("Include:",
                                                                         popify(el = img(src="icons/help.png"), title = "Features to include in the results", content = "Select whether to plot Regions, Motifs and/or Markups. If you deselect all (or none were found), only the protein length will be shown.", placement = "top")),
                                                            choiceNames = c("Regions", "Motifs", "Markups"),
                                                            choiceValues = c("regions", "motifs", "markups"),
                                                            selected = c("regions", "motifs", "markups"),
                                                            inline = T),

                                         # Click to submit
                                         actionButton(inputId = "tab1_submit",
                                                      label = "Submit",
                                                      class = "btn-success")
                                ),

                                # Tab3 ----
                                tabPanel(title = "Protein Features",
                                         value = "tab3", icon = tags$img(src='icons/features.png'),
                                         h3("Provide features of your protein"),
                                         br(),
                                         p("Protein name should not be left blank. Protein length", strong("must"), "be specified."),
                                         hr(),

                                         # Name and length input boxes
                                         fluidRow(
                                           column(6, textInput(inputId = "tab3_description_in",
                                                               label = span("Name",
                                                                            popify(el = img(src="icons/help.png"), title = "Protein name", content = "A human-readable name, e.g. CD45, PTPRC, PTPRC_HUMAN. Or, leave as Unknown.", placement = "top")),
                                                               value = "protein"),
                                           ),
                                           column(6, numericInput(inputId = "tab3_length_in",
                                                                  label = span("Length",
                                                                               popify(el = img(src="icons/help.png"), title = "Protein length", content = "Specify length as the number of amino acids, e.g. 1306", placement = "top"),
                                                                               tipify(el = img(src="icons/required.png"), title = "Required", placement = "top")),
                                                                  min = 10, step = 10, value = NULL)
                                           ),

                                           # Optional fields
                                           column(3, textInput(inputId = "tab3_accession_in",
                                                               label = span("ID",
                                                                            popify(el = img(src="icons/help.png"), title = "Protein ID", content = "An identifier, e.g. P08575, NP_002829.3", placement = "top")),
                                                               value = NULL),
                                           ),
                                           column(3, textInput(inputId = "tab3_species_in",
                                                               label = span("Species",
                                                                            popify(el = img(src="icons/help.png"), title = "Species", content = "Species the sequence is from, e.g Homo_sapiens", placement = "top")),
                                                               value = NULL),
                                           ),
                                           column(3, textInput(inputId = "tab3_taxid_in",
                                                               label = span("Taxid",
                                                                            popify(el = img(src="icons/help.png"), title = "Taxa identifier", content = "Species taxid, e.g. 9606", placement = "top")),
                                                               value = NULL),
                                           ),
                                           column(3, textInput(inputId = "tab3_link_in",
                                                               label = span("Link",
                                                                            popify(el = img(src="icons/help.png"), title = "External url", content = "Link to online resource, e.g. www.uniprot.org/uniprotkb/P08575", placement = "top")),
                                                               value = NULL)
                                           )
                                         ),
                                         hr(),
                                         tabsetPanel(
                                           selected = "tab3a",
                                           type = "pills",
                                           tabPanel(
                                             title = "Predicted (raw results)",
                                             value = "tab3a", icon = tags$img(src='icons/predicted.png'),
                                             h3("Upload predicted results."),
                                             p("Results from different protein topology prediction
                                             resources can be provided. See corresponding examples."),
                                             hr(),

                                             # Predicted results input
                                             fluidRow(
                                               # S.M.A.R.T.
                                               column(12, fileInput(inputId = "tab3_SMART.tsv_file_in",
                                                                    label = span(strong("SMART"),
                                                                                 popify(el = img(src="icons/help.png"), title = "SMART results", content = "Upload SMART database predictions. File should be tab-separated text (.tsv).", placement = "top"),
                                                                                 tags$a(href="cd45/cd45_SMART.tsv", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                 tags$a(href="http://smart.embl-heidelberg.de/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit S.M.A.R.T.", placement = "top"))),
                                                                    accept = c(".tsv")
                                               )
                                               ),
                                               # ELM file
                                               column(5, fileInput(inputId = "tab3_ELM.xlsx_file_in",
                                                                   label = span("ELM",
                                                                                popify(el = img(src="icons/help.png"), title = "ELM results", content = "Upload ELM database predictions, as an Excel file (.xlsx).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_ELM.xlsx", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                tags$a(href="http://elm.eu.org/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit E.L.M.", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".xlsx"))
                                               ),
                                               column(4, fileInput(inputId = "tab3_ELM.features.tsv_file_in",
                                                                   label = span("ELM cs.",
                                                                                popify(el = img(src="icons/help.png"), title = "ELM conservation scores", content = "Upload ELM motif conservation scores. File should be tab-separated text (.tsv).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_ELMcs.tsv", target="_blank", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".tsv"))
                                               ),
                                               column(3, numericInput(inputId = "tab3_ELM.score_in",
                                                                      label = span("Score", popify(el = img(src="icons/help.png"), title = "Score threshold", content = "ELM conservation scores cutoff (0-1).", placement = "right")),
                                                                      min = 0, max = 1, step = 0.1, value = 0.5)),

                                               # ANCHOR2
                                               column(9, fileInput(inputId = "tab3_ANCHOR.tsv_file_in",
                                                                   label = span("Anchor2",
                                                                                popify(el = img(src="icons/help.png"), title = "Anchor2 results", content = "Upload Anchor2 data. File should be tab-separated text (.tsv).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_IUPred3.tsv", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                tags$a(href="https://iupred.elte.hu/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit Anchor 2.", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".tsv"))
                                               ),
                                               column(3, numericInput(inputId = "tab3_ANCHOR.cutoff_in",
                                                                      label = span("Score", popify(el = img(src="icons/help.png"), title = "Score threshold", content = "Disorder and Anchor2 score cutoff (0-1).", placement = "right")),
                                                                      min = 0, max = 1, step = 0.1, value = 0.8)),

                                               # NetNGlyc
                                               column(9, fileInput(inputId = "tab3_netNglyc.tsv_file_in",
                                                                   label = span("NetNGlyc",
                                                                                popify(el = img(src="icons/help.png"), title = "NetNGlyc results", content = "Upload NetNGlyc data. File should be tab-separated text (.tsv).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_NetNGlyc.tsv", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                tags$a(href="https://services.healthtech.dtu.dk/services/NetNGlyc-1.0/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit NetNGlyc 1.0.", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".tsv"))
                                               ),
                                               column(3, numericInput(inputId = "tab3_netNglyc.cutoff_in",
                                                                      label = span("Score", popify(el = img(src="icons/help.png"), title = "Score threshold", content = "NetNGlyc score cutoff (0-1).", placement = "right")),
                                                                      min = 0, max = 1, step = 0.1, value = 0.8)),

                                               # NetOGlyc
                                               column(9, fileInput(inputId = "tab3_netOglyc.tsv_file_in",
                                                                   label = span("NetOGlyc",
                                                                                popify(el = img(src="icons/help.png"), title = "NetOGlyc results", content = "Upload NetOGlyc data. File should be General Feature Format tab-separated text (.gff, .tsv).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_NetOGlyc.gff", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                tags$a(href="https://services.healthtech.dtu.dk/services/NetOGlyc-4.0/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit NetOGlyc 4.0.", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".gff", ".tsv"))
                                               ),
                                               column(3, numericInput(inputId = "tab3_netOglyc.cutoff_in",
                                                                      label = span("Score", popify(el = img(src="icons/help.png"), title = "Score threshold", content = "NetOGlyc score cutoff (0-1).", placement = "right")),
                                                                      min = 0, max = 1, step = 0.1, value = 0.8)),

                                               # NetPhos
                                               column(9, fileInput(inputId = "tab3_netPhos.tsv_file_in",
                                                                   label = span("NetPhos",
                                                                                popify(el = img(src="icons/help.png"), title = "NetPhos results", content = "Upload NetPhos data. File should be tab-separated text (TSV).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_NetPhos.tsv", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                tags$a(href="https://services.healthtech.dtu.dk/services/NetPhos-3.1/", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit NetPhos 3.1.", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".tsv"))
                                               ),
                                               column(3, numericInput(inputId = "tab3_netPhos.cutoff_in",
                                                                      label = span("Score", popify(el = img(src="icons/help.png"), title = "Score threshold", content = "NetPhos score cutoff (0-1).", placement = "right")),
                                                                      min = 0, max = 1, step = 0.05, value = 0.95)),

                                               # ScanSite
                                               column(9, fileInput(inputId = "tab3_SCANSITE.tsv_file_in",
                                                                   label = span("ScanSite",
                                                                                popify(el = img(src="icons/help.png"), title = "ScanSite results", content = "Upload ScanSite data. File should be tab-separated text (TSV).", placement = "top"),
                                                                                tags$a(href="cd45/cd45_ScanSite.tsv", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                                                tags$a(href="https://scansite4.mit.edu/#scanProtein", target="_blank", tipify(el = img(src="icons/link.png"), title = "Visit ScanSite.", placement = "top"))),
                                                                   multiple = FALSE,
                                                                   accept = c(".tsv"))
                                               ),
                                               column(3, numericInput(inputId = "tab3_SCANSITE.score_in",
                                                                      label = span("Score", popify(el = img(src="icons/help.png"), title = "Score threshold", content = "ScanSite score cutoff (0-).", placement = "right")),
                                                                      min = 0, step = 0.1, value = 0.5)
                                               ),
                                               column(6),
                                               column(3, numericInput(inputId = "tab3_SCANSITE.percentile_in",
                                                                      label = span("Pth", popify(el = img(src="icons/help.png"), title = "Percentile threshold", content = "ScanSite score cutoff (0-1).", placement = "top")),
                                                                      min = 0, max = 1, step = 0.001, value = 0.001)
                                               ),
                                               column(3, numericInput(inputId = "tab3_SCANSITE.accessibility_in",
                                                                      label = span("Access.", popify(el = img(src="icons/help.png"), title = "Accessibility threshold", content = "ScanSite score cutoff (0-).", placement = "top")),
                                                                      min = 0, step = 0.1,value = 1)
                                               )
                                             ),
                                             hr(),

                                             # Click to submit
                                             actionButton(inputId = "tab3_submit",
                                                          label = "Submit",
                                                          class = "btn-success"),
                                           ),

                                           tabPanel(title = "Predefined (curated table)",
                                                    value = "tab2", icon = tags$img(src='icons/predefined.png'),
                                                    h3("Provide predefined features."),
                                                    p("A manually curated table of protein features should be uploaded."),
                                                    hr(),
                                                    # Upload button for table
                                                    fileInput(inputId = "tab2_file_in",
                                                              label = span("Upload table",
                                                                           popify(el = img(src="icons/help.png"), title = "Table of features", content = "Upload table of features for your protein.", placement = "top"),
                                                                           tags$a(href="cd45/CD45_custom.xlsx", tipify(el = img(src="icons/attachment.png"), title = "Click to download example", placement = "top")),
                                                              ),
                                                              multiple = FALSE,
                                                              accept = c(".xlsx", ".csv", ".tsv"),
                                                    ),

                                                    # Input table file format
                                                    radioButtons(inputId = "tab2_file_format",
                                                                 label = "Table file format",
                                                                 choiceNames = unname(tbf),
                                                                 choiceValues = names(tbf),
                                                                 selected = "xlsx",
                                                                 inline = F),
                                                    hr(),

                                                    # Click to submit (table and box input)
                                                    actionButton(inputId = "tab2_submit",
                                                                 label = "Submit",
                                                                 class = "btn-success")
                                           )


                                         )
                                ))),

                  # Output panel ----
                  mainPanel(
                    tabsetPanel(selected = "out1",
                                tabPanel(title = strong("Table preview"),
                                         div(htmlOutput(outputId = "current_protein_table")),
                                         value = "out1", icon = tags$img(src='icons/spreadsheet.svg',  height='48', width='48'),
                                         uiOutput(outputId = "download_xlsx"),
                                         br(),
                                         #div(tableOutput(outputId = "table_out"), style = "max-height: 96vh; overflow-y: auto;")
                                         # use the more sophisticated table from DT?

                                         #dataTableOutput()` is deprecated as of shiny 1.8.1.
                                         #dataTableOutput("table_out")
                                         DTOutput("table_out")
                                ),
                                tabPanel(title = strong("JSON output"),
                                         div(htmlOutput(outputId = "current_protein_json")),
                                         rclipboardSetup(),
                                         value = "out2", icon = tags$img(src='icons/text.svg',  height='48', width='48'),
                                         uiOutput(outputId = "download_json", style = 'display: inline-block;'),
                                         uiOutput(outputId = "clip", style = 'display: inline-block;'),
                                         bsTooltip(id = "clip", title = "You can paste clipboard contents in the Image generator tab"),
                                         br(),br(),

                                         div(verbatimTextOutput(outputId = "json_out", placeholder = F),
                                             style = "max-height: 72vh; overflow-y: auto;"),
                                         br()
                                         # use codeoutput?
                                         # div(codeOutput("json_out"),
                                         #     style = "max-height: 96vh; overflow-y: auto;"),
                                ),
                                tabPanel(title = strong("Image generator"),
                                         value = "out3", icon = tags$img(src='icons/image_generator.svg',  height='48', width='48'),
                                         htmlOutput(outputId = "pfam_embedded")
                                ),
                                tabPanel(title = "Help",
                                         value = "help", icon = tags$img(src='icons/help-browser.svg',  height='48', width='48'),
                                         htmltools::includeMarkdown(paste0(www, "/","help.md"))
                                ),
                                tabPanel("About",
                                         value = "help", icon = tags$img(src='icons/about.svg',  height='48', width='48'),
                                         htmltools::includeMarkdown(paste0(www, "/","about.md")))
                    )
                  )
                )
)

# SERVER ----
server <- function(input, output, session){

  # entry (file, when saving) name ----
  entry_name <- reactiveValues(e=NULL)

  # table and json preview ----
  tab_table <- reactiveValues(x=NULL)
  tab_json <- reactiveValues(y=NULL)
  tab_protein <- reactiveValues(z=NULL)

  #
  # Tab1 ----
  #

  # change example dynamically
  output$tab1_examples <- renderUI({
    if(input$tab1_radio_button == "uniprot") {
      p("(", "e.g. CD45:", code("P08575"), ")")
    }else{
      p("(", "e.g. CD45:", code("NP_002829.3"), ")")
    }
  })

  # # create JSON and render as text. Decide what to include from the checkbox.
  # tab1_process <- eventReactive(input$tab1_submit, {
  #   if (!is.null(input$tab1_radio_button)) {
  #     id.JSON(input = input$tab1_text_in,
  #             database = input$tab1_radio_button,
  #             regions.on = is.element("regions", input$tab1_checkbox),
  #             motifs.on = is.element("motifs", input$tab1_checkbox),
  #             markups.on = is.element("markups", input$tab1_checkbox))
  #   }else{
  #     id.JSON(input = input$tab1_text_in,
  #             database = input$tab1_radio_button,
  #             regions.on = F,
  #             motifs.on = F,
  #             markups.on = F)
  #   }
  #
  # })

  tab1_process <- eventReactive(input$tab1_submit, {
    if (inherits(try(
      if (!is.null(input$tab1_radio_button)) {
        id.JSON(input = input$tab1_text_in,
                database = input$tab1_radio_button,
                regions.on = is.element("regions", input$tab1_checkbox),
                motifs.on = is.element("motifs", input$tab1_checkbox),
                markups.on = is.element("markups", input$tab1_checkbox))
      }else{
        id.JSON(input = input$tab1_text_in,
                database = input$tab1_radio_button,
                regions.on = F,
                motifs.on = F,
                markups.on = F)
      }
    ), 'try-error')) {
      showNotification("ID not found at database.", type = "error")
      #predict.JSON(protein.length = 1)
      print('{"metadata": [], "length": [0] }')
    }else{
      if (!is.null(input$tab1_radio_button)) {
        id.JSON(input = input$tab1_text_in,
                database = input$tab1_radio_button,
                regions.on = is.element("regions", input$tab1_checkbox),
                motifs.on = is.element("motifs", input$tab1_checkbox),
                markups.on = is.element("markups", input$tab1_checkbox))
      }else{
        id.JSON(input = input$tab1_text_in,
                database = input$tab1_radio_button,
                regions.on = F,
                motifs.on = F,
                markups.on = F)
      }
    }
  })

  tab1_json <- renderText({tab1_process()})

  # get metadata of the protein from JSON
  tab1_length <- eventReactive(input$tab1_submit, {
    fromJSON(tab1_json())[["length"]]
  })
  tab1_description <- eventReactive(input$tab1_submit, {
    fromJSON(tab1_json())[["metadata"]]["description"]
  })
  tab1_url <- eventReactive(input$tab1_submit, {
    fromJSON(tab1_json())[["metadata"]]["link"]
  })
  tab1_organism <- eventReactive(input$tab1_submit, {
    fromJSON(tab1_json())[["metadata"]]["organism"]
  })
  tab1_taxid <- eventReactive(input$tab1_submit, {
    fromJSON(tab1_json())[["metadata"]]["taxid"]
  })

  # create table from JSON
  tab1_table <- eventReactive(input$tab1_submit, {
    if (inherits(try(json.TABLE(fromJSON(tab1_json()))), 'try-error')) {
      emptydf <- data.frame("Empty imput or no regions, motifs or markups to show.")
      colnames(emptydf) <- "No data"
      emptydf
    }else{
      json.TABLE(fromJSON(tab1_json()))
    }
  })

  # report what's in the output, but only upon click
  observeEvent(input$tab1_submit, {
    if (input$tab1_radio_button == "ncbi") {
      tab_protein$z <- paste(br(), img(src="icons/id.png"), strong("Protein ID"), br(),br(),
                             strong("Identifier:"), toupper(gsub(" ", "", input$tab1_text_in)), br(),
                             strong("Database:"), dbs[input$tab1_radio_button], br(),
                             strong("Length:"), tab1_length(), "(aa)", br(),
                             strong("Description:"), tab1_description(), br(),
                             strong("Species:"), tab1_organism(), "[taxid:", tab1_taxid(), "]", br(),
                             strong("Link:"), tags$a(href=tab1_url(), tab1_url()), hr()
      )
    }else{
      tab_protein$z <- paste(br(), img(src="icons/id.png"), strong("Protein ID"), br(),br(),
                             strong("Identifier:"), toupper(gsub(" ", "", input$tab1_text_in)), br(),
                             strong("Database:"), dbs[input$tab1_radio_button], br(),
                             strong("Length:"), tab1_length(), "(aa)", br(),
                             strong("Description:"), tab1_description(), br(),
                             strong("Link:"), tags$a(href=tab1_url(), tab1_url()), hr()
      )
    }
  })

  # Parse input ID as potential file name
  observeEvent(input$tab1_submit, {
    entry_name$e <- input$tab1_text_in
  })

  # Parse table and json upon clicking tab1_submit
  observeEvent(input$tab1_submit, {
    tab_table$x <- tab1_table()
  })

  observeEvent(input$tab1_submit, {
    tab_json$y <- tab1_json()
  })

  # Process input table upon tab2_submit click
  tab2_json_process <- eventReactive(input$tab2_submit, {
    if (inherits(try(
    custom.JSON(protein.length = input$tab3_length_in,
                accession.number = input$tab3_accession_in,
                description = input$tab3_description_in,
                organism = input$tab3_species_in,
                link.url = input$tab3_link_in,
                taxid = input$tab3_taxid_in,
                input.file = input$tab2_file_in$datapath,
                input.format = input$tab2_file_format)
    ), 'try-error')) {
      showNotification("Check input file or protein length.", type = "error")
      #print('{"metadata": [], "length": [] }')
    }else{
      custom.JSON(protein.length = input$tab3_length_in,
                  accession.number = input$tab3_accession_in,
                  description = input$tab3_description_in,
                  organism = input$tab3_species_in,
                  link.url = input$tab3_link_in,
                  taxid = input$tab3_taxid_in,
                  input.file = input$tab2_file_in$datapath,
                  input.format = input$tab2_file_format)
    }
  })

  tab2_json <- renderText({tab2_json_process()})

  # Parse input name as potential file name
  observeEvent(input$tab2_submit, {
    entry_name$e <- input$tab3_description_in
  })

  # create table from JSON
  tab2_out <- eventReactive(input$tab2_submit, {
    if (inherits(try(json.TABLE(fromJSON(tab2_json()))), 'try-error')) {
      showNotification("Empty imput or no regions, motifs or markups to show.", type = "message")
      emptydf <- data.frame("Empty imput or no regions, motifs or markups to show.")
      colnames(emptydf) <- "No data"
      emptydf
    }else{
      json.TABLE(fromJSON(tab2_json()))
    }
  })

  # Parse tab2_out upon clicking tab2_submit
  observeEvent(input$tab2_submit, {
    tab_table$x <- tab2_out()
  })

  # parse json upon clicking submit
  observeEvent(input$tab2_submit, {
    tab_json$y <- tab2_json()
  })

  # report what's in the output, but only upon click
  observeEvent(input$tab2_submit, {
    tab_protein$z <- paste(br(), img(src="icons/features.png"), strong("Protein features"), strong("→"), img(src="icons/predefined.png"), strong("Predefined (curated table)"), br(),br(),
                           strong("Name:"), input$tab3_description_in, br(),
                           strong("Provided length:"), input$tab3_length_in, "(aa)", br(),
                           strong("Accession:"), input$tab3_accession_in, br(),
                           strong("Species:"), input$tab3_species_in, "[taxid:", input$tab3_taxid_in, "]", br(),
                           strong("Link:"), input$tab3_link_in, hr()
    )
  })

  tab3_json_process <- eventReactive(input$tab3_submit, {
    if (inherits(try(
      predicted.JSON(protein.length = input$tab3_length_in,
                     accession.number = input$tab3_accession_in,
                     description = input$tab3_description_in,
                     organism = input$tab3_species_in,
                     link.url = input$tab3_link_in,
                     taxid = input$tab3_taxid_in,
                     SMART.tsv = input$tab3_SMART.tsv_file_in$datapath,
                     ELM.xlsx = input$tab3_ELM.xlsx_file_in$datapath,
                     ELM.features.tsv = input$tab3_ELM.features.tsv_file_in$datapath,
                     ELM.score = input$tab3_ELM.score_in,
                     SCANSITE.tsv = input$tab3_SCANSITE.tsv_file_in$datapath,
                     SCANSITE.score = input$tab3_SCANSITE.score_in,
                     SCANSITE.percentile = input$tab3_SCANSITE.percentile_in,
                     SCANSITE.accessibility = input$tab3_SCANSITE.accessibility_in,
                     ANCHOR.tsv = input$tab3_ANCHOR.tsv_file_in$datapath,
                     ANCHOR.cutoff = input$tab3_ANCHOR.cutoff_in,
                     netNglyc.tsv = input$tab3_netNglyc.tsv_file_in$datapath,
                     netNglyc.cutoff = input$tab3_netNglyc.cutoff_in,
                     netOglyc.tsv = input$tab3_netOglyc.tsv_file_in$datapath,
                     netOglyc.cutoff = input$tab3_netOglyc.cutoff_in,
                     netPhos.tsv = input$tab3_netPhos.tsv_file_in$datapath,
                     netPhos.cutoff = input$tab3_netPhos.cutoff_in)
    ), 'try-error')) {
      showNotification("Check input file or protein length.", type = "error")
      #print('{"metadata": [], "length": [1] }')
    }else{
    predicted.JSON(protein.length = input$tab3_length_in,
                   accession.number = input$tab3_accession_in,
                   description = input$tab3_description_in,
                   organism = input$tab3_species_in,
                   link.url = input$tab3_link_in,
                   taxid = input$tab3_taxid_in,
                   SMART.tsv = input$tab3_SMART.tsv_file_in$datapath,
                   ELM.xlsx = input$tab3_ELM.xlsx_file_in$datapath,
                   ELM.features.tsv = input$tab3_ELM.features.tsv_file_in$datapath,
                   ELM.score = input$tab3_ELM.score_in,
                   SCANSITE.tsv = input$tab3_SCANSITE.tsv_file_in$datapath,
                   SCANSITE.score = input$tab3_SCANSITE.score_in,
                   SCANSITE.percentile = input$tab3_SCANSITE.percentile_in,
                   SCANSITE.accessibility = input$tab3_SCANSITE.accessibility_in,
                   ANCHOR.tsv = input$tab3_ANCHOR.tsv_file_in$datapath,
                   ANCHOR.cutoff = input$tab3_ANCHOR.cutoff_in,
                   netNglyc.tsv = input$tab3_netNglyc.tsv_file_in$datapath,
                   netNglyc.cutoff = input$tab3_netNglyc.cutoff_in,
                   netOglyc.tsv = input$tab3_netOglyc.tsv_file_in$datapath,
                   netOglyc.cutoff = input$tab3_netOglyc.cutoff_in,
                   netPhos.tsv = input$tab3_netPhos.tsv_file_in$datapath,
                   netPhos.cutoff = input$tab3_netPhos.cutoff_in)
    }
  })

  tab3_json <- renderText({tab3_json_process()})

  # Parse input name as potential file name
  observeEvent(input$tab3_submit, {
    entry_name$e <- input$tab3_description_in
  })

  # create table from JSON
  tab3_out <- eventReactive(input$tab3_submit, {
    if (inherits(try(json.TABLE(fromJSON(tab3_json()))), 'try-error')) {
      showNotification("Empty imput or no regions, motifs or markups to show.", type = "message")
      emptydf <- data.frame("Empty imput or no regions, motifs or markups to show.")
      colnames(emptydf) <- "No data"
      emptydf
    }else{
      json.TABLE(fromJSON(tab3_json()))
    }
  })

  # parse table and json upon clicking tab3_submit
  observeEvent(input$tab3_submit, {
    tab_table$x <- tab3_out()
  })

  observeEvent(input$tab3_submit, {
    tab_json$y <- tab3_json()
  })

  # report what's in the output, but only upon click
  observeEvent(input$tab3_submit, {
    tab_protein$z <- paste(br(), img(src="icons/features.png"), strong("Protein features"), strong("→"), img(src="icons/predicted.png"), strong("Predicted (raw results)"), br(),br(),
                           strong("Name:"), input$tab3_description_in, br(),
                           strong("Length:"), input$tab3_length_in, "(aa)", br(),
                           strong("Accession:"), input$tab3_accession_in, br(),
                           strong("Species:"), input$tab3_species_in, "[taxid:", input$tab3_taxid_in, "]", br(),
                           strong("Link:"), input$tab3_link_in, br(),
                           strong("ELM conservation score:"), input$tab3_ELM.score_in, br(),
                           strong("Disorder and Anchor2 cutoff:"), input$tab3_ELM.score_in, br(),
                           strong("NetNGlyc cutoff:"), input$tab3_netNglyc.cutoff_in, br(),
                           strong("NetOGlyc cutoff:"), input$tab3_netOglyc.cutoff_in, br(),
                           strong("NetPhos cutoff:"), input$tab3_netPhos.cutoff_in, br(),
                           strong("ScanSite;"), strong("score:"), input$tab3_SCANSITE.score_in, strong("percentile:"), input$tab3_SCANSITE.percentile_in, strong("accessibility:"), input$tab3_SCANSITE.accessibility_in,
                           hr()
    )
  })

  #
  # Common output ----
  #

  # table preview
  # output$table_out <- renderTable({
  #   tab_table$x}, striped = T, hover = T, na = "N/A")
  output$table_out <- renderDT(tab_table$x,
                               options = list(scrollX = TRUE, iDisplayLength = 25))
  # json preview
  output$json_out <- renderText({
    tab_json$y})

  # Display report in table and json tabs
  output$current_protein_table <- renderText({
    tab_protein$z})
  output$current_protein_json <- renderText({
    tab_protein$z})

  # download JSON file
  output$downloadJSON <- downloadHandler(
    filename = function(){paste0(entry_name$e, ".json")},
    content = function(file){write(tab_json$y, file)}
  )

  # generate JSON download button
  output$download_json <- renderUI({
    if(!is.null(tab_json$y) & !is.null(entry_name$e)) {
      downloadButton("downloadJSON", "Download code (json)", icon = tags$i(class = "download"))
    }
  })

  # download XLSX file
  output$downloadXLSX <- downloadHandler(
    filename = function(){paste0(entry_name$e, ".xlsx")},
    content = function(file){write.xlsx(tab_table$x, file)}
  )

  # generate XLSX download button
  output$download_xlsx <- renderUI({
    if(!is.null(tab_table$x) & !is.null(entry_name$e)) {
      downloadButton("downloadXLSX", "Download table (xlsx)", icon = tags$i(class = "download"))
    }
  })

  #
  # Copy JSON output to clipboard----
  #
  output$clip <- renderUI({
    if (!is.null(tab_json$y)) {
      rclipButton(
        inputId = "clipbtn",
        label = "Copy code box contents to clipboard",
        clipText = tab_json$y,
        icon = tags$i(class = "clipboard"),
        #tooltip = "Copy JSON contents to clipboard",
        #placement = "top",
        #options = list(delay = list(show = 800, hide = 100), trigger = "hover")
      )
    }

  })

  #
  # iFrame for PFAM----
  #

  # Submit generated JSON
  output$pfam_embedded <- renderUI({
    tags$iframe(seamless="seamless",
                src = "pfam/index.html",
                width="100%",
                height=1024,
                frameborder = "no")
  })

  observeEvent(input$refresh, {
    # no need for js, use reload() instead
    #shinyjs::js$refresh_page()
    session$reload()
    #return()
  })

  # # quit if browser (tab) is closed. Disable, since this crashes app upon f5 or browser refresh
  # session$onSessionEnded(function(){
  #   x <- isolate(input$refresh)
  #   if(x == 0) {
  #     stopApp()
  #   }
  # })

}

# Shiny
shinyApp(ui = ui, server = server)
