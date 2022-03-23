genenamecleanup <- function() {
  #Takes a phytozome geneName.txt file removes the transcript IDs and joins together the genenames for 
  #loci with more than 1 characterized transcript 
  #value: a dataframe with column 'locus' and 'name'
  ####genename <- read.delim('../Data/Creinhardtii_281_v5.5.geneName.txt', header=F, stringsAsFactors = Fl)
  ####colnames(genename)=c('locus', 'name')
  con = file('../Data/Creinhardtii_281_v5.6.geneName.txt', open = 'r')
  gn <- list()
  while (TRUE) {
    line = readLines(con, n=1)
    if (length(line)==0) {break}
    gn <- c(gn, strsplit(line, '\t'))
  }
  close(con)
  locus=sapply(gn, function(x) {return(x[1])})
  name = sapply(gn, function(x) {return(paste(x[2:length(x)], collapse =':'))})
  genename <- data.frame(locus, name)
  prtnclean <- function(prtn) {
    return(gsub("\\.t.*", "", prtn))
  }
  n_genename <- data.frame(locus=sapply(genename$locus,prtnclean), name=genename$name, stringsAsFactors=F)
  collaplsegenen <- function(gndf) {
    resgndf <- gndf
    #take th data frame read in from geneName.txt with removed transcript Ids
    #for each locus that appears more than once
    for (dupgn in unique(gndf$locus[duplicated(gndf$locus)])) {
      idx <- which(resgndf$locus==dupgn)
      #check if all locusses are linked to the same gene name
      if(length(unique(resgndf$name[idx]))>1) {
        #if not concatenate the gene names to one string and link it to the first occurence of the locus
        #print('yes')
        resgndf[idx[1],2] <- paste(as.character(unique(resgndf$name[idx])), collapse=':')
      }
      #remove all other locus occurences
      resgndf <- resgndf[-(idx[2:length(idx)]),]
    }
    return(resgndf)
  }
  collapsed <- collaplsegenen(n_genename)
  return(collapsed)
}
gn_match <- function(x, gndf=phyto_gn) {
  if(x %in% gndf$locus) {
    return(gndf$name[gndf$locus==x])
  }
  else {return(x)}
}

