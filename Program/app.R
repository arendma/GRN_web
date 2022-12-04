library(shiny)
library(shinybusy)
library(writexl)
library(ggplot2)

source('netwk_anav2.R')
source('cregoenricherv9.r')
source('web_ggendotplot.r')

# consensus network
consensusNetwork = read.delim('../Data/consensus0.1.tab', stringsAsFactors = FALSE)
# PHOT network
photNetwork = read.delim('../Data/gen3x0.1consens.tab', stringsAsFactors = FALSE)

# TODO: use all gene IDs (consensus and phot network, source and target nodes)
GeneIds = as.list(unique(consensusNetwork$from))

ui <- fluidPage(
  # app title
  titlePanel("GRN_web"),

  # show that we're waiting for results
  shinybusy::add_busy_spinner(spin = "fading-circle", position = "top-right"),

  tabsetPanel(
    id = "tabset",
    tabPanel(
      id = "targets-panel",
      "Top targets and significant enriched GO terms",
      sidebarLayout(
        sidebarPanel(
          selectInput(
            inputId = "geneID",
            label = "Select gene ID",
            choices = c(Choose="", GeneIds)),

          sliderInput(
            inputId = "top_percent_targets",
            label = "Top n targets",
            min = 1,
            max = 100,
            value = 10)
        ), # END sidebarPanel (in tabPanel "top-targets")

        mainPanel(
          h4("Top targets in consensus network:"),
          downloadButton("downloadconsTargets", "Download table"),
          tableOutput(outputId = "consTargets"),

          tags$hr(), # horizontal line
          h4("Top targets in PHOT network:"),
          downloadButton("downloadPhotTargets", "Download table"),
          tableOutput(outputId = "photTargets"),

          tags$hr(), # horizontal line
          h4("Top 5 significant enriched GO terms (in 100% of targets):"),
          plotOutput("enrichedConsGoPlotHeatmap"),
          downloadButton("downloadEnrichedConsTargets", "Download table")
        ) # END tabPanel("top-targets") >> sidebarLayout >> mainPanel
      ) # END tabPanel("top-targets") >> sidebarLayout
    ), # END tabPanel("top-targets")


    tabPanel(
      id = "coregulators-panel",
      "Top coregulators",
      sidebarLayout(
        sidebarPanel(

          # Input: Choose "file upload" or enter gene IDs manually
          radioButtons("geneIdsInputChoice", "Upload gene IDs or enter them manually?",
                       choices = c("upload file" = "upload",
                                   "enter manually" = "text-input"),
                       selected = "text-input"),

          conditionalPanel(
            condition = "input.geneIdsInputChoice == 'upload'",
            fileInput("geneIdsFile",
                      "Choose File to upload (one gene ID per line)",
                      multiple = FALSE,
                      accept = c("text/csv", "text/comma-separated-values,text/plain",
                                 ".csv"))),

          conditionalPanel(
            condition = "input.geneIdsInputChoice == 'text-input'",
            textAreaInput("geneIdsTextInput", "Enter one gene ID per line", rows = 3)
          ),

          # Input: Select network ----
          radioButtons("networkName", "Network",
                       choices = c(consensus = "consensus",
                                   PHOT = "PHOT"),
                       selected = "consensus"),

        ), # END tabPanel(coregulators-panel") >> sidebarLayout >> sidebarPanel

        mainPanel(

          h4(textOutput("coregsTitle")),
          downloadButton("downloadCoregs", "Download table"),
          tableOutput(outputId = "coregs"),

        ) # END tabPanel(coregulators-panel") >> sidebarLayout >> mainPanel
      ) # END tabPanel(coregulators-panel") >> sidebarLayout
    ) # END tabPanel("coregulators-panel")

  ) # END tabsetPanel
) # END fluidPage


server <- function(input, output) {
  # By default, renderTable() formats numbers differently than normal R.
  # Here, we try to emulate normal formatting.
  #
  # targets table has ncol=3, but renderTable adds row names as the first
  # column. Thus, targetsTableFormat contains the formatting for ncol=4.
  # 's': string
  # 'g': print all digits or convert to scientific format
  #      (whatever is shorter)
  targetsTableFormat = c('s', 's', 's', 'g')
  targetsTableNumDigits = 5

  # show consensus targets table and allow file download
  #
  #~ cons_madstar1=regtarget(consensus,mads_ids[1])
  consTargets <- reactive({
    req(input$geneID) # don't try to calculate before user selects gene ID
    regtarget(consensusNetwork, input$geneID, input$top_percent_targets)
  })

  consTargetsFname <- reactive({
    req(input$geneID) # don't try to calculate before user selects gene ID
    paste("gene_id_", input$geneID, "_top_", input$top_percent_targets, "_targets_in_consensus_network", ".xlsx", sep = "")
  })

  output$consTargets = renderTable({
    consTargets()
  }, digits=targetsTableNumDigits, display=targetsTableFormat)

  output$downloadconsTargets <- downloadHandler(
    filename = consTargetsFname,
    content = function(file) {
      write_xlsx(consTargets(), file)
    }
  )

  # show phot targets table and allow file download
  #~ phot_madstar1=regtarget(phot, mads_ids[1])
  photTargets <- reactive({
    req(input$geneID) # don't try to calculate before user selects gene ID
    regtarget(photNetwork, input$geneID, input$top_percent_targets)
  })

  photTargetsFname <- reactive({
    req(input$geneID) # don't try to calculate before user selects gene ID
    paste("gene_id_", input$geneID, "_top_", input$top_percent_targets, "_targets_in_phot_network", ".xlsx", sep = "")
  })

  output$photTargets = renderTable({
    photTargets()
  }, digits=targetsTableNumDigits, display=targetsTableFormat)

  output$downloadPhotTargets <- downloadHandler(
    filename = photTargetsFname,
    content = function(file) {
      write_xlsx(photTargets(), file)
    }
  )


  ########################################################################


  # Extract the top N coregulators from the consensus network regulator targets
  # and plot the network.
  # This will create twot plots in pdf format and 1 tsv with label legend for the nodes
  # in the parent directory.
  output$coregsTitle <- renderText({
    sprintf("Top coregulators in %s network:", input$networkName)})

  coregs <- reactive({
    if (input$geneIdsInputChoice == "upload") {
      tryCatch(
        {
          geneIds <- scan(input$geneIdsFile$datapath, what="", sep='\n')
        },
        error = function(e) {
          # return a safeError if a parsing error occurs
          stop(safeError(e))
        }
      )
    } else { # read / clean up gene IDs from text input field
      rawGeneIdsList <- strsplit(input$geneIdsTextInput, split='\n')
      geneIds <- unlist(lapply(rawGeneIdsList, trimws))
    }

    if (input$networkName == "consensus") {
      network = consensusNetwork
    } else {
      network = photNetwork
    }

    regulatorTranscriptionFactorList(netwk=network,
                                     GOIs=geneIds,
                                     topx=input$top_percent_targets,
                                     file=NULL)
  })

  output$coregs = renderTable({
    if (input$geneIdsInputChoice == "upload") {
      # don't calculate before gene IDs were uploaded
      req(input$geneIdsFile)
    } else {
      # don't calculate before gene IDs were entered into the text box
      req(input$geneIdsTextInput)
    }
    coregs()
  }, digits=targetsTableNumDigits, display=c('s', 's', 's', 's', 'g', 'g'))

  coregsFname <- reactive({
    paste("top_coregulators_in_", network, "_network", ".xlsx", sep = "")
  })

  output$downloadCoregs <- downloadHandler(
    filename = coregsFname,
    content = function(file) {
      write_xlsx(coregs(), file)
    }
  )


  ########################################################################


  # Analyse all targets in the consensus network for enriched GO terms
  #~ res1=cregoenricher(samples = list(cons_madstar1$target), universe = unique(consensus$to), category = 'BP')
  allConsTargets <- reactive({
    req(input$geneID) # don't try to calculate before user selects gene ID
    regtarget(consensusNetwork, input$geneID)
  })

  # avoid error "cannot open file 'Rplots.pdf'" in Docker container
  # when calling cregoenricher()
  pdf(NULL)
  enrichedConsTargets <- reactive({
    # NOTE: I don't know why this req() is necessary, as
    # this reactive environment just calls allConsTargets(),
    # which is another reactive env that already calls req().
    req(input$geneID)
    cregoenricher(samples = list(allConsTargets()$target), universe = unique(consensusNetwork$to), category = 'BP')
  })

  output$enrichedConsTargets = renderTable({
    enrichedConsTargets()
  }, digits=targetsTableNumDigits, display=c('s', 's', 's', 's', 's', 'g', 'g', 's', 'd'))

  output$enrichedConsGoPlotHeatmap <- renderPlot({
    require(grid)
    grid.draw(cbind(ggplotGrob(web_ggendotplot(enrichedConsTargets())$heatmap),
                    ggplotGrob(web_ggendotplot(enrichedConsTargets())$goplot)))
  })

  enrichedConsTargetsFname <- reactive({
    req(input$geneID) # don't try to calculate before user selects gene ID
    paste("gene_id_", input$geneID, "_enriched_go_terms_of_all_targets_in_consensus_network", ".xlsx", sep = "")
  })

  output$downloadEnrichedConsTargets <- downloadHandler(
    filename = enrichedConsTargetsFname,
    content = function(file) {write_xlsx(enrichedConsTargets(), file)}
  )

} # END server()

shinyApp(ui = ui, server = server)
