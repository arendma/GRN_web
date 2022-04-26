library(shiny)
library(writexl)

source('netwk_anav2.R')

# consensus network
consensusNetwork = read.delim('../Data/consensus0.1.tab', stringsAsFactors = FALSE)
# PHOT network
photNetwork = read.delim('../Data/gen3x0.1consens.tab', stringsAsFactors = FALSE)

# TODO: use all gene IDs (consensus and phot network, source and target nodes)
GeneIds = as.list(unique(consensusNetwork$from))

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
          choices = c("Cre11.g467577", GeneIds)),

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
        downloadButton("downloadconsTargets", "Download table"),
        tableOutput(outputId = "consTargets"),
        
        h4("Top targets in PHOT network:"),
        downloadButton("downloadPhotTargets", "Download table"),
        tableOutput(outputId = "photTargets"),
        
        h4("Top coregulators in consensus network:"),
        downloadButton("downloadConsCoregs", "Download table"),
        tableOutput(outputId = "consCoregs"),
        

        h4("Coregulators of the highest ranked target gene in PHOT network:"),
        downloadButton("downloadPhotCoregs", "Download table"),
        tableOutput(outputId = "photCoregsOfHighestRankTarget")
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

  consTargets <- reactive({
    regtarget(consensusNetwork, input$geneID, input$num_top_targets)
  })
  
  consTargetsFname <- reactive({
    paste("gene_id_", input$geneID, "_top_", input$num_top_targets, "_targets_in_consensus_network", ".xlsx", sep = "")
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

  photTargets <- reactive({
    regtarget(photNetwork, input$geneID, input$num_top_targets)
  })

  photTargetsFname <- reactive({
    paste("gene_id_", input$geneID, "_top_", input$num_top_targets, "_targets_in_phot_network", ".xlsx", sep = "")
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


  # Extract the top N coregulators from the consensus network regulator targets
  # and plot the network.
  # This will create twot plots in pdf format and 1 tsv with label legend for the nodes
  # in the parent directory.
  consCoregs <- reactive({
    regTFls(consensusNetwork, consTargets()$target[1:input$num_top_targets], input$num_top_targets, file=NULL)
  })

  output$consCoregs = renderTable({
    consCoregs()
  }, digits=targetsTableNumDigits, display=c('s', 's', 's', 's', 'g', 'g'))

  consCoregsFname <- reactive({
    paste("gene_id_", input$geneID, "_top_", input$num_top_targets, "_coregulators_in_consensus_network", ".xlsx", sep = "")
  })

  output$downloadConsCoregs <- downloadHandler(
    filename = consCoregsFname,
    content = function(file) {
      write_xlsx(consCoregs(), file)
    }
  )

  # Extract all all coregulators for the single highest ranked target gene
  # of the given gene ID in the PHOT network
  photCoregsOfHighestRankTarget <- reactive({
      regTFs(photNetwork, photTargets()$name[1])
  })

  output$photCoregsOfHighestRankTarget = renderTable({
    photCoregsOfHighestRankTarget()
  }, digits=targetsTableNumDigits, display=targetsTableFormat)

  # downloadPhotCoregs
  photCoregsFname <- reactive({
    paste("gene_id_", input$geneID, "_coregulators_of_highest_ranked_target_gene_in_phot_network", ".xlsx", sep = "")
  })

  output$downloadPhotCoregs <- downloadHandler(
    filename = photCoregsFname,
    content = function(file) {
      write_xlsx(photCoregsOfHighestRankTarget(), file)
    }
  )

}

# Run the shiny app with the options given above
shinyApp(ui = ui, server = server)
