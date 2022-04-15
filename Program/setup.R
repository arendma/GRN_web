#setup script installing nescessary packages if not present
packs = c("BiocManager", "igraph", "shiny", "readxl")
bcpacks = c("GO.db", "topGO")

for (pack in packs) {
  if(!(requireNamespace(pack, quietly=TRUE))) {
    install.packages(pack)
  }
}

for (bcpack in bcpacks) {
  if(!(requireNamespace(bcpack, quietly=TRUE))) {
    library(BiocManager)
    BiocManager::install(bcpack)
  }
}
