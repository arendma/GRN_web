#setup script installing nescessary packages if not present
packages = c("igraph", "shiny", "readxl", "writexl", "ggplot2", "remotes", "sass", "xtable", "gridExtra")
bioc_packages = c("graph", "GO.db", "topGO")

for (pkg in packages) {
  if(!(requireNamespace(pkg, quietly=TRUE))) {
    install.packages(pkg)
  }
}

# Install bioconductor packages as binary packages
# instead of compiling them locally. This should be
# much faster.
if(!require('AnVIL')) {
  remotes::install_github("Bioconductor/AnVIL")
}

for (bioc_pkg in bioc_packages) {
  if(!(requireNamespace(bioc_pkg, quietly=TRUE))) {
    library(AnVIL)
    AnVIL::install(bioc_pkg)
  }
}
