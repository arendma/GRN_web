#deprecated function equal to go_dotplot(..., order='padj')
ggendotplot <- function(enrichResult, nGO=5) {
  if (anyDuplicated(enrichResult$Description)) {
    print(enrichResult$Description[duplicated(enrichResult$Description)])
  }
  #calculate jaccard index of linked genes in each GO set
  jaccard=function(x, y) {
    return(length(intersect(x,y))/length(union(x,y)))
  }
  jaccard_mat=matrix(ncol=length(tempres$geneID), nrow=length(tempres$geneID))
  for (i in 1:length(tempres$geneID)) {
    jaccard_mat[i, i:length(tempres$geneID)]=sapply(strsplit(tempres$geneID[i:length(tempres$geneID)], split='/'), jaccard, y=unlist(strsplit(tempres$geneID[i], split='/')))
    jaccard_mat[i:length(tempres$geneID),i]=jaccard_mat[i, i:length(tempres$geneID)]
  }
  #cluater according to jaccard inex
  d=dist(jaccard_mat, method = 'euclidian')
  cl=hclust(d)
  enrichResult=enrichResult[cl$order,]
  jaccard_mat=jaccard_mat[cl$order,cl$order] 
  plot_tab=data.frame(x=rep(1:nrow(jaccard_mat), each=nrow(jaccard_mat)), y=rep(1:nrow(jaccard_mat), nrow(jaccard_mat)), value=as.vector(jaccard_mat))
  ggplot(plot_tab, aes(x, y, fill=value)) + geom_tile()
  plotdat <-data.frame(desc =factor(enrichResult$Description, levels=unique(enrichResult$Description[order(enrichResult$Count)])), padj =enrichResult$p.adjust,
                       count =enrichResult$Count, Gene_Ratio=sapply(enrichResult$GeneRatio, function(x) {eval(parse(text=x))}))
  xlimits <- c(min(plotdat$Gene_Ratio[1:5])- 0.5*min(plotdat$Gene_Ratio[1:5]), max(plotdat$Gene_Ratio[1:5])+0.3*max(plotdat$Gene_Ratio[1:5]))
  plot <- ggplot(data=plotdat[1:min(dim(plotdat)[1],nGO),], aes(x=Gene_Ratio, y=desc, color=padj, size=count))+ geom_point() + theme_light()  + xlim(xlimits) +
    scale_colour_gradient(low = "red", high = "blue") + theme(text = element_text(size=18),axis.title.y=element_blank()) + scale_size(range=c(9,15))
  return(plot)
}

# go_dotplot = function(enrichResult, sample, goi, nGO=5, order='padj') {
#   #Function to plot a dotplot of GO results ordering after the median LFC of included genes
#   #And a scatterplot of the LFC values of included genes, while marking GOIs
#   source('genenamecleanupv2.r', local=TRUE)  
#   genenamecleanup()
#   if (anyDuplicated(enrichResult$Description)) {
#     print(enrichResult$Description[duplicated(enrichResult$Description)])
#   }
#   goi_lfc=function(ids, sample) {
#     if (!(all(unlist(strsplit(ids, '/')) %in% sample$id ))){
#       stop('Genes that are reported by enricher() are not present in samples[[i]]')
#     }
#     return(median(sample$LFC[sample$id %in% unlist(strsplit(ids, '/'))]))
#   }
#   med_lfc=sapply(enrichResult$geneID, goi_lfc, sample=sample)
#   
#   #decide wether to order by significance of effect size
#   if (order=='LFC'){
#     or_idx=order(med_lfc, decreasing=TRUE)
#   }else if (order=='padj') {
#     or_idx=order(enrichResult$p.adjust)
#   } else {stop('Argument order can only take the values "LFC" or "padj"')}
#   #Assemble dafataframe for GOI dotplot, here description is converted to factor with ordered levels
#   #so that ggplot orders the nGO selected GOIS according to counts numbers when plotting - the actual order of elements in the vector is not changed
#   plotdat <-data.frame(desc =factor(enrichResult$Description, levels=unique(enrichResult$Description[order(enrichResult$Count)])), padj =enrichResult$p.adjust,
#                        count =enrichResult$Count, Gene_Ratio=sapply(enrichResult$GeneRatio, function(x) {eval(parse(text=x))}), med_lfc=med_lfc, genes=enrichResult$geneID)
#   plotdat = plotdat[or_idx,]
#   #Assemble dataframe for scatterplot 
#  
#   xlimits <- c(min(plotdat$Gene_Ratio[1:min(dim(plotdat)[1],nGO)])- 0.5*min(plotdat$Gene_Ratio[1:min(dim(plotdat)[1],nGO)]), max(plotdat$Gene_Ratio[1:min(dim(plotdat)[1],nGO)])+0.3*max(plotdat$Gene_Ratio[1:min(dim(plotdat)[1],nGO)]))
#   plot <- ggplot(data=plotdat[1:min(dim(plotdat)[1],nGO),], aes(x=Gene_Ratio, y=desc, color=padj, size=count))+ geom_point() + theme_light()  + xlim(xlimits) +
#     scale_colour_gradient(low = "red", high = "blue") + theme(text = element_text(size=18),axis.title.y=element_blank()) + scale_size(range=c(9,15))
#   
#   extend_gois=function(description) {
#     #take a GO term as returned by enricher and assemble a talbe with 1st column gene name 2nd column GO term, 3rd column lfc
#     ID5_5=unlist(strsplit(enrichResult$geneID[enrichResult$Description %in% description], '/'))
#     label=sapply(ID5_5, function(id) {if (id %in% goi$ID5_5) {return(goi$Gene[goi$ID5_5 %in%id])} else {return('')}})
#     padj=rep(enrichResult$p.adjust[enrichResult$Description %in% description], length(ID5_5))
#     LFC=sample$LFC[match(ID5_5, sample$id)]
#     desc=rep(description, length(ID5_5))
#     return(data.frame(ID5_5, label, LFC, padj,desc))
#   }
#   plotdat2= lapply(enrichResult$Description[or_idx[1:min(dim(plotdat)[1],nGO)]], extend_gois)
#   plotdat2= do.call(rbind, plotdat2)
#   plotdat2$desc=factor(plotdat2$desc, levels=unique(enrichResult$Description[or_idx[1:min(dim(plotdat)[1],nGO)]]))
#   plot2= ggplot(data=plotdat2, aes(x=desc, y=LFC, fill=padj)) + geom_dotplot(binaxis = "y", stackdir ="center") + theme_light() +
#     scale_fill_gradient(low = "red", high = "blue") + geom_text(aes(label=label)) + theme(axis.text.x=element_text(angle=75, hjust =1))
#   return(list(plot,plot2))
# }