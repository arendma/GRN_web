library(shiny)
library(writexl)

source('netwk_anav2.R')

# consensus network
consensus = read.delim('../Data/consensus0.1.tab', stringsAsFactors = FALSE)
# PHOT network
phot = read.delim('../Data/gen3x0.1consens.tab', stringsAsFactors = FALSE)

# TODO: use all gene IDs (consensus and phot network, source and target nodes)
GeneIds = as.list(unique(consensus$from))

ui <- fluidPage(
    # app title
    titlePanel("GRN_web"),
    
    # sidebar layout (inputs on the left, output on the right)
    sidebarLayout(
      
      # sidebar panel for inputs on the left
      sidebarPanel(
        selectInput(
          inputId = "geneID",
          label = "Select gene ID",
          choices = c("Choose one" = "", GeneIds)),

        sliderInput(
          inputId = "num_top_targets",
          label = "Number of targets",
          min = 1,
          max = 100,
          value = 10)
      ),
      
      # main panel for outputs on the right
      mainPanel(
        h4("Top targets in consensus network:"),
        downloadButton("downloadConsensusTargets", "Download table"),
        tableOutput(outputId = "consensusTargets"),
        
        h4("Top targets in PHOT network:"),
        downloadButton("downloadPhotTargets", "Download table"),
        tableOutput(outputId = "photTargets")
      )
    )
)

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

  consensusTargets <- reactive({
    regtarget(consensus, input$geneID, input$num_top_targets)
  })
  
  consensusTargetsFilename <- reactive({
    paste("gene_id_", input$geneID, "_top_", input$num_top_targets, "_targets_in_consensus_network", ".xlsx", sep = "")
  })

  output$consensusTargets = renderTable({
    consensusTargets()
  }, digits=targetsTableNumDigits, display=targetsTableFormat)

  output$downloadConsensusTargets <- downloadHandler(
    filename = consensusTargetsFilename,
    content = function(file) {
      write_xlsx(consensusTargets(), file)
    }
  )

  # show phot targets table and allow file download

  photTargets <- reactive({
    regtarget(phot, input$geneID, input$num_top_targets)
  })

  photTargetsFilename <- reactive({
    paste("gene_id_", input$geneID, "_top_", input$num_top_targets, "_targets_in_phot_network", ".xlsx", sep = "")
  })

  output$photTargets = renderTable({
    photTargets()
  }, digits=targetsTableNumDigits, display=targetsTableFormat)

  output$downloadPhotTargets <- downloadHandler(
    filename = photTargetsFilename,
    content = function(file) {
      write_xlsx(photTargets(), file)
    }
  )

}

# Run the shiny app with the options given above
shinyApp(ui = ui, server = server)
