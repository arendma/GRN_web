library(shiny)
options(shiny.host = '0.0.0.0')
options(shiny.port = 8181)

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
          value = 25)
      ),
      
      # main panel for outputs on the right
      mainPanel(
        tableOutput(outputId = "topConsensusTargets"),
        tableOutput(outputId = "topPhotTargets")
      )
    )
)

server <- function(input, output) {
  output$topConsensusTargets = renderTable({
    regtarget(consensus, input$geneID, input$num_top_targets)
  })
  
  output$topPhotTargets = renderTable({
    regtarget(phot, input$geneID, input$num_top_targets)
  })
}

# Run the shiny app with the options given above
shinyApp(ui = ui, server = server)
