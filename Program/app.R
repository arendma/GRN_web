library(shiny)

source('netwk_anav2.R')

consensus = read.delim('../Data/consensus0.1.tab', stringsAsFactors = FALSE)

# TODO: use all gene IDs (consensus and phot network, source and target nodes)
GeneIds = as.list(unique(consensus$from))

ui <- fluidPage(
    titlePanel("GRN_web"),
    selectInput(
      inputId = "geneID",
      label = "Select gene ID",
      choices = c("Choose one" = "", GeneIds)),
    sliderInput(
      inputId = "num_top_targets",
      label = "Number of targets",
      min = 1,
      max = 100,
      value = 25),
    tableOutput(
      outputId = "topTargets")
)

server <- function(input, output) {
  output$topTargets = renderTable({
    top25Targets = regtarget(consensus, input$geneID, input$num_top_targets)
  })
}

# Run the application 
shinyApp(ui = ui, server = server)
