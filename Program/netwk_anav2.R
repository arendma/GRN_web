library(here)

source(here('Program', 'genenamecleanupv2.R'))

# Functions to extract prediction from grns

regtarget = function(network, gene_id, top_genes = NULL) {
  # This function takes a data frame 'network' where columns are df[1] = 'from',
  # df[2] = 'to', df[3] = interaction strength (either weight or rank),
  # a JGI Cre5.5 'gene_id', and 'top_genes' which can be an integer of highest ranked genes
  # to return, a float between 0-1 that gives the relative amount of highest
  # ranking genes to return or a list of gene IDs.
  #
  # If a list of gene names is given, all genes above the lowest ranking of these
  # genes is returned. If 'top_genes' = NULL, all results are returned.
  phyto_gene_names =  genenamecleanup()

  # Check if 'weight' column exists, else create it
  if (!('weight' %in% colnames(network))) {
    network$weight = 1 / network[,3]
    warning('No weight column present. Assumed ranks as 3rd network column and appended 1/3rd column as weight.')
  }

  # Filter network based on the gene_id
  results = network[network$from %in% gene_id,]

  # Order the results based on the absolute value of weight
  results = results[order(abs(results$weight), decreasing = TRUE),]

  # Determine the number of top genes to return
  if (is.null(top_genes)) {
    top_genes = nrow(results)
  } else if (is.numeric(top_genes) && top_genes <= 1) {
    top_genes = floor(nrow(results) * top_genes)
  } else if (is.character(top_genes)) {
    indices = sapply(top_genes, function(x) grep(pattern = x, x = results$to)[1])
    if (length(indices) == 0) {
      stop('Error: top_genes not found in results!')
    }
    top_genes = max(indices, na.rm = TRUE)
  }

  # Create the final results data frame
  final_results = data.frame(target = results[1:top_genes, 'to'],
                             name = sapply(results[1:top_genes, 'to'], gn_match, gndf = phyto_gene_names),
                             weight = results[1:top_genes, 'weight'])

  return(final_results)
}


regTFs = function(netwk, target_ID5_5, topx=NULL){
  #Extracts regulators of a single gene
  # Input:
  # netwk: data.frame network where columns are df[1]=from, df[2]=to, df[3], interaction strenth (either weight or rank)
  # target_ID5_5: string a JGI Cre5.5 gene ID of the target
  # topx: integer number of interactions to return if topx=NULL all regulators are returned, if in the range 0-1 the rel. amount of interactions is returned
  # Output: data frame, df[1]=from, df[2]=to, df[3]= weight/rank, df[4] only if df[3] is rank a column wit 1/df[3] is attached as weight and returned
  phyto_gn =  genenamecleanup()
  if(colnames(netwk)[3]!='weight') {
    netwk <- data.frame(netwk, weight = 1/netwk[,3])
    print('Warning! no weight column present assumed ranks as 3rd network column and appended 1/3rd column as weight')
  }
  res=netwk[netwk$to %in% target_ID5_5,]
  res=res[order(abs(res$weight), decreasing=TRUE),]
  if (is.null(topx)) {
    topx=dim(res)[1]
  } else if (topx<=1) {
    topx=floor(dim(res)[1]*topx)
    }else {
    topx=min(dim(res)[1], topx)
  }
  res= data.frame(regulator = res[1:topx, 'from'], name=sapply(res[1:topx, 'from'], gn_match, gndf=phyto_gn),weight= res[1:topx, 'weight'])
  return(res)
}

regulatorTranscriptionFactorList <- function(netwk, GOIs, topx=25,  file=NULL) {
  #Function returns a list of regulators based on a list of genes linked to a biochemical process
  #Input:
  # netwk: data.frame network where columns are df[1]=from, df[2]=to, df[3], interaction strenth (either weight or rank)
  # GOIs: charcater vector of JGI Cre5.5 of targets
  # topx: nubmer of top regulators to consider and return default=25, if this is NULL all entries are returned, if in the range 0-1 the rel. amount of entries is returned
  # file: optional(string with relative path and prefix, if given a tsv with all found regulators and graphs of the networks with topx regulators are saved
  require(igraph)
  phyto_gn =  genenamecleanup()
  if(colnames(netwk)[3]!='weight') {
    netwk <- data.frame(netwk, weight = 1/netwk[,3])
    print('Warning! no weight column present assumed ranks as 3rd network column and appended 1/3rd column as weight')
  }
  #extract all regulatory interactions of GOIs
  subn <- netwk[netwk$to %in% GOIs,]
  #add up invert weights (inverted ranks) of all tfs
  reglist <- t(sapply(unique(subn$from), function(x) {
    res <- c(sum(abs(subn$weight[subn$from %in% x])),sum(subn$from %in% x))
    names(res) <- c('sumweight','no_GOI')
    return(res)
  }))
  reglist<- data.frame(Gene=sapply(rownames(reglist), gn_match, gndf=phyto_gn), ID5_5=rownames(reglist), reglist)

  #sort by inverted rank sum
  reglist<- reglist[order(reglist$sumweight,decreasing=TRUE),]
  if (!(is.null(file))) {
    write.table(reglist, file=paste(file, 'putreg.tsv', sep='', collapse=''), row.names=FALSE, col.names=TRUE, sep='\t')
  }
  if (is.null(topx)) {
    #set topx to maximum if isnull
    topx=nrow(reglist)
  } else if (topx<=1) {
    topx=floor(nrow(reglist)*topx)
  } else if (nrow(reglist)<topx) {
    warning("topx > inferred regulators, returning maximum number of regulators: ", nrow(reglist))
    topx=nrow(reglist)
  }
  topreg <- data.frame(index=1:topx, reglist[1:topx,])
  if (!(is.null(file))) {
  regnet <- graph_from_data_frame(d=netwk[netwk$from %in% topreg$ID5_5 & netwk$to %in% GOIs, ],  directed=T)
  ###do plot with absolut scale
  #save type of note
  vertype <- sapply(V(regnet)$name, function(x) {
    if(x %in% netwk$from) {return('TF')}
    else {return('Gene')}
  })
  V(regnet)$type <- vertype
  V(regnet)$color <- as.factor(V(regnet)$type)
  sizfac <- 15/max(topreg$sumweight)
  #change label size of TFs according to sum of invertedrak
  custom_size <- sapply(V(regnet)$name, function(x) {
    if(x %in% topreg$ID5_5){return(topreg$sumweight[topreg$ID5_5==x]*sizfac)}
    else{return(min(topreg$sumweight)*sizfac)}
  })
  V(regnet)$size <- custom_size
  #only label nodes with known gene names
  V(regnet)$label <- sapply(V(regnet)$name, function(x) {
    if(x %in% topreg$ID5_5){return(topreg$index[topreg$ID5_5==x])}
    else{return(NA)}
  })
  #set edge with according to edge weight
  E(regnet)$width <- E(regnet)$weight*2/max(E(regnet)$weight)
  regnet_layout <- layout_nicely(regnet)
  regnet_layout <- norm_coords(regnet_layout, ymin=-1, ymax=1, xmin=-1, xmax=1)
  pdf(paste(file, 'net.pdf', sep= '',collapse=''))
  plot.igraph(regnet, rescale=FALSE, xlim=(c(-1,1)*2.0), ylim=(c(-1,1)*2.0),layout=regnet_layout*2.0, edge.arrow.mode=0, vertex.label.cex=2)
  dev.off()
  ###do plot with logarithmic scaled weights
  sizfac <- 15/max(log(topreg$sumweight+1))
  #change label size of TFs according to sum of invertedrak
  custom_size <- sapply(V(regnet)$name, function(x) {
    if(x %in% topreg$ID5_5){return(log(topreg$sumweight[topreg$ID5_5==x]+1)*sizfac)}
    else{return(log(min(topreg$sumweight)+1)*sizfac)}
  })
  V(regnet)$size <- custom_size

  #set edge width according to edge weight
  E(regnet)$width <- (log(E(regnet)$weight+1)*2)/log(max(E(regnet)$weight)+1)
  pdf(paste(file, 'lognet.pdf', sep= '',collapse=''))
  plot.igraph(regnet, rescale=FALSE, xlim=(c(-1,1)*2.0), ylim=(c(-1,1)*2.0),layout=regnet_layout*2.0, edge.arrow.mode=0, vertex.label.cex=2)
  dev.off()
  }
  #detach('package:igraph', unload =TRUE)
  return(topreg)
}



