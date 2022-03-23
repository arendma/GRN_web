#setup script installing nescessary packages if not present
packs = c("igraph")
bcpacks = c()

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