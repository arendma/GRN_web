web_ggendotplot <- function(enrichResult, nGO=5) {
  #takes the output of the GO enrichment function and creates a plot for it
  #INPUT:
  # - enrichResult: a data frame containing the results of GO enrichment in cluster profiler format
  # - nGO: (optional, default: 5) the maximum number of GO terms to plot
  require(ggplot2)

  if (anyDuplicated(enrichResult$Description)) {
    print(enrichResult$Description[duplicated(enrichResult$Description)])
  }

  enrichResult=enrichResult[order(enrichResult$p.adjust)[1:min(nrow(enrichResult), nGO)],]

  #calculate jaccard index of linked genes in each GO set
  jaccard=function(x, y) {
    return(length(intersect(x,y))/length(union(x,y)))
  }
  jaccard_mat=matrix(ncol=length(enrichResult$geneID), nrow=length(enrichResult$geneID))
  for (i in 1:length(enrichResult$geneID)) {
    jaccard_mat[i, i:length(enrichResult$geneID)]=sapply(strsplit(enrichResult$geneID[i:length(enrichResult$geneID)], split='/'), jaccard, y=unlist(strsplit(enrichResult$geneID[i], split='/')))
    jaccard_mat[i:length(enrichResult$geneID),i]=jaccard_mat[i, i:length(enrichResult$geneID)]
  }

  #cluster according to jaccard index
  d=dist(jaccard_mat, method = 'euclidian')
  cl=hclust(d)
  enrichResult=enrichResult[rev(cl$order),]
  jaccard_mat=jaccard_mat[rev(cl$order),rev(cl$order)]

  plot_tab = data.frame(
    x=rep(enrichResult$Description, each=nrow(jaccard_mat)),
    y=rep(enrichResult$Description, nrow(jaccard_mat)),
    value=as.vector(jaccard_mat))

  hm = ggplot(plot_tab, aes(x, y, fill=value)) +
    geom_tile() +
    labs(fill="Jaccard Idx") +
    scale_x_discrete(limits=enrichResult$Description, position='top') +
    scale_y_discrete(limits=enrichResult$Description) +
    theme(legend.position = "left",
          text=element_text(size=10),
          axis.title=element_blank(),
          axis.text.x=element_text(angle=90, hjust=0))

  plotdat <- data.frame(
    desc=factor(enrichResult$Description, levels=unique(enrichResult$Description)),
    padj=enrichResult$p.adjust,
    count=enrichResult$Count,
    Gene_Ratio=sapply(enrichResult$GeneRatio, function(x) {eval(parse(text=x))}))

  xlimits <- c(min(plotdat$Gene_Ratio)- 0.5*min(plotdat$Gene_Ratio),
               max(plotdat$Gene_Ratio)+0.3*max(plotdat$Gene_Ratio))

  goplot <- ggplot(data=plotdat, aes(x=Gene_Ratio, y=desc, color=padj, size=count)) +
    geom_point() +
    scale_x_continuous(limits = xlimits) +
    theme_light() +
    scale_colour_gradient(low = "red", high = "blue") +
    theme(text=element_text(size=10),
          axis.title.y=element_blank(),
          axis.text.y=element_blank()) +
    scale_size(range=c(9,15))

  result <- list("goplot" = goplot, "heatmap"= hm)
  return(result)
}

print_go_enrichment_plot <- function(go_enrichment_plot) {
  require(grid)

  grid.newpage()
  grid.draw(cbind(ggplotGrob(go_enrichment_plot$heatmap),
                  ggplotGrob(go_enrichment_plot$goplot)))
}

