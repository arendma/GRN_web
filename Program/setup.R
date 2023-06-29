#setup script installing nescessary packages if not present
options(repos = c(CRAN = "https://cran.rstudio.com/"))

packages = c("igraph", "shiny", "shinybusy", "readxl", "writexl", "ggplot2", "sass", "xtable", "gridExtra", "testthat", "here")
bioc_packages = c("graph", "GO.db", "topGO")

for (pkg in packages) {
  if(!(requireNamespace(pkg, quietly=TRUE))) {
    install.packages(pkg)
  }
}

# Install bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE))
  install.packages("BiocManager")

for (bioc_pkg in bioc_packages) {
  if (!(requireNamespace(bioc_pkg, quietly = TRUE))) {
    BiocManager::install(bioc_pkg)
  }
}
