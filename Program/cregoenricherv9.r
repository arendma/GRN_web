cregoenricher <- function(samples, universe, category="BP", k=4, nGO=5)  {
  #Function to analyze for GO enrichment in CRE gene sample list, compared to universe. Plots a 
  # plot with the results to the current active graphic device
  #INPUT: 
  # - samples: character vector of unique gene names in the sample
  # - universe: character vector of unique gene names in the universe (all possible
  #             gene names that coudl come up in sample)
  # - category: (optional, default: "BP") Character that gives the type of GO terms
  #             to be analysed. Either "BP" or "MF"
  # - k: (optional, default: 4) the minimum number of genes in the sample set that 
  #       have to be linked to a GO term for it to be considered in enrichment test
  # - nGO: (optional, default: 5) the maximum number of enriched GO terms to plot 
  require(GO.db)
  require(topGO)
  require(readxl)
  ##Input: samples=list of (limma DE result data frames or list of character vectors) 
  #   universe=data frame of expression data (rownames = gene names)
  #   resdir=output directory
  #plots histogram of GO annotations per gene
  #calculates enrichment of MF and BP GO terms in samples for k between 2 and 10 and creates dotplot of enriched terms
  #check for correct category values
  if (!(category %in% c('MF','BP'))) {
    stop('category must be either "MF" or "BP"')
  }
  source('web_ggendotplot.r')
  ##GO enrichment
  #Import C.re. GO terms from file
  annot <- read.delim(file = "../Data/Creinhardtii_281_v5.6.annotation_info.txt",header = T,sep = "\t",row.names = 1,stringsAsFactors = F)
  anno <- sapply(unique(annot$locusName),function(n){return(unique(unlist(strsplit(c(annot$GO[which(annot$locusName==n)]),split = " "))))})
  #They should be unique
  gnames <- unique(names(anno))
  ##check for proper gene names
  if (class(universe) %in% 'data.frame') {universe=rownames(universe)}
  if (sum(!substr(universe,1,3)=='Cre')>0) {
    stop('improper labelled genes in universe!')
  }
  #select only expressed genes (all genes are contained in gnames)
  mygene_name=gnames[which(gnames%in%universe)]
  #Complile list Gene Name -> GO term
  geneGO <- anno[mygene_name]
  


  # read all GO terms and separate MFs and BPs from all terms
  allGo=as.list(GOTERM)
  allgo=names(allGo)[sapply(allGo,function (x) {x@Ontology == category})]

  # separate BP terms of mygene
  mygene_ch=lapply(geneGO,function(x){x[x%in%allgo]})
  # save all ancestores for BP and MF GO terms
  if (category=='BP') {
    GO_ANC=as.list(GOBPANCESTOR)
    } else if (category=='MF') {
    GO_ANC=as.list(GOMFANCESTOR)
  }
  # Add all ancestores of BP terms or MF terms to each gene terms - all term is introduced here
  mygene_go=lapply(mygene_ch,function(x){unique(c(unlist(GO_ANC[x]),x))})
  #Calculate how many genes in the background are annottated
  chckandens <- function(GOlist) {
    ## Takes a list of GO term lists and calculates the ration between non annotated and annotated genes
    #value= a numeric vector of length 3 given the results
    n_gene <- length(GOlist)
    n_noanno <- sum(lapply(GOlist, length)==0)
    res=c(n_gene, n_gene-n_noanno, (n_gene-n_noanno)/n_gene)
    names(res) <- c('tot_genes', 'gens/w anno', 'anno/all')
    return(res)
  }
  n_anno=chckandens(mygene_go)
  print(paste('Ratio of genes with GO information in universe: ', round(n_anno[3], 2), sep=""))
  #write.table(data.frame(x1=names(n_anno), x2=n_anno), file.path(resdir, paste(category,'_annotation_density.txt', sep='')), row.names = F)
  
  #create list GOter -> associated genes
  GO_mygene <- inverseList(mygene_go)
  #remove all term from reversed list
  GO_mygene['all'] <- NULL
  
  #list of Terms/ Functions / Processed named by the GOid
  GO2NAME<- sapply(names(GO_mygene),function(id,allGo)allGo[[id]]@Term,allGo)
  
  ###Import own gene list
  #Import compiled NPQ gene list
  NPQ_goi=read.delim('../Data/NPQ genes.txt')
  NPQ_goi=NPQ_goi[nchar(NPQ_goi$ID5_5)>0,]
  #add an entry with the genes present in the universe - id has to be 10 character long
  GO_mygene=c(GO_mygene, 'OWN:000001'=list(NPQ_goi$ID5_5[NPQ_goi$ID5_5 %in% universe]))
  #Add term to term list
  GO2NAME=c(GO2NAME, 'OWN:000001'='Photoprotective response related')
  #Import compiled CCM list
  CCM_goi=read.delim('../Data/CCM genes.txt')
  CCM_goi=CCM_goi[nchar(CCM_goi$ID5_5)>0,]
  GO_mygene=c(GO_mygene, 'OWN:000002'=list(CCM_goi$ID5_5[CCM_goi$ID5_5 %in% universe]))
  GO2NAME=c(GO2NAME, 'OWN:000002'='Ci Concentration Mechanism related')
  #Import selected nitrogen genes based on schollinger study 
  N2_goi=read_excel('../Data/used_genes_schmollinger_et_al.xlsx')
  GO_mygene=c(GO_mygene, 'OWN:000003'=list(N2_goi$LocusID[N2_goi$LocusID %in% universe]))
  GO2NAME=c(GO2NAME, 'OWN:000003'='Nitrogen starvation response genes')
  
  # #also create an assembled dataframe of important genes to pass it for plotting
  # colnames(N2_goi)[1:2]=c('ID5_5', 'Gene')
  # goi <- rbind(N2_goi[,c('Gene', 'ID5_5')], NPQ_goi[,c('Gene', 'ID5_5')], CCM_goi[,c('Gene', 'ID5_5')])
  # #remove duplicated entries
  # for (g in unique(goi$ID5_5[duplicated(goi$ID5_5)])) {
  #   dupind <- which(goi$ID5_5 %in% g)
  #   goi <- goi[-dupind[2:length(dupind)],]
  # }
  
  
  #shorten GO term names to a max of 35 characters
  df_G2NAME <- data.frame(TERM=names(GO2NAME), NAME=sapply(GO2NAME, function(x){substr(x, 1,35)}))
  #remove duplicates by adding digit
  dups=unique(df_G2NAME$NAME[duplicated(df_G2NAME$NAME)])
  for (dup in dups){
    idx=which(df_G2NAME$NAME %in% dup)
    df_G2NAME$NAME[idx]=paste(df_G2NAME$NAME[idx], 1:length(idx), sep='')
  }

  
  # Unescessary fro phyper: delete
  # #create a character vector of 1 to 1 assignments GO->GENE
  # GO2GENE <- unlist(GO_mygene)
  # #repair GO NAMES
  # names(GO2GENE) <- sapply(names(GO2GENE), function(x){substr(x,1,10)})
  # #create data frame for enricher
  # df_G2GENE <- data.frame(term=names(GO2GENE), name=GO2GENE)
  
  ## alternative implementation using enricher()
  #library(clusterProfiler)
  clPres=list()
  #forloop creates a clPres list where each element [i] for a sample  is a list of enricher results of different [k]
  #clPres[[i]][[k]]= enricher result for sample i with minimum annotated gene threshold of k
  for (i in 1:length(samples)) {
    if(class(samples[[i]])=='data.frame') {genes=samples[[i]]$id
    } else if (class(samples[[i]])=='character') {genes=samples[[i]]
    } else {stop("samples must be a list of either data frames or character vectors")}
    #Create histogram of gene counts for GO terms - this does not tak into account own gene lists
    #dircreater(file.path(resdir, 'hist/'))
    sample_go=lapply(genes,function(x){mygene_go[[x]]})
    names(sample_go)=genes
    countsSample_go=lapply(inverseList(sample_go),length)
    countsSample_go['all'] <- NULL
    # if(sum(duplicated(names(unlist(countsSample_go))))==0) {
    #   logbreaks <- exp(log(max(unlist(countsSample_go)))*(1:20/20))
    #   breaks <- c(0, 1:10, logbreaks[10<logbreaks])
    # }else {
    #   stop('duplicated GO terms detected... this is an internal error -.-')
    # }
    # 
    # #pdf(file.path(resdir, 'hist', paste(category,'_', names(samples)[i], '_hist.pdf', sep='')))
    # plot=hist(unlist(countsSample_go), breaks=breaks, xlim=c(0, 100), main=names(samples)[i])
    # #dev.off()
    
    #test for enrichment using phyper
    GO_sample_idx=relist(unlist(GO_mygene) %in% genes, skeleton = GO_mygene)
    GO_sample = lapply(1:length(GO_mygene), function(x){return(GO_mygene[[x]][GO_sample_idx[[x]]])})
    names(GO_sample)=names(GO_sample_idx)
      #drop GO terms linked to less or equal to k genes
      kGO_sample_idx=GO_sample_idx[sapply(GO_sample_idx,sum)>k]
      enrich.t= function(GOmember,setsize, universe){
        #Calculates GO term enrichment for a single GO term 
        #Input:
          #GOmember: logical vector whose length equals all genes linked to a given GO term in the experimental data where TRUE marks the genes linked to a GO term which are included in the test set
          #setsize: integer giving the size of the analysed gene set
          #Universe: character vector of gene names for all genes included in the experimental data
        #Output:
          #Dataframe 
        #ID=names(GOmember)
        GeneRatio=paste(sum(GOmember),'/', setsize, sep='', collapse='')
        BgRatio=paste(length(GOmember), '/', length(universe), sep='', collapse='')
        #give q-1 since if lower.tail=FALSE phyper returns P[X>x] not P[X>=x]
        pvalue=phyper(q=sum(GOmember)-1, m = length(GOmember), n=length(universe)-length(GOmember), k=setsize, lower.tail=FALSE)
        return(data.frame(GeneRatio, BgRatio, pvalue))
      }
      if (class(samples[[i]])=="data.frame"){
        test_stat=do.call(rbind, lapply(kGO_sample_idx, enrich.t, setsize=dim(samples[[i]])[1], universe=universe))
      }else if (class(samples[[i]])=="character") {
        test_stat=do.call(rbind, lapply(kGO_sample_idx, enrich.t, setsize=length(samples[[i]]), universe=universe))
      }
      geneID=sapply(rownames(test_stat), function(x) {return(paste(GO_sample[[x]], collapse='/'))})
      Count=sapply(rownames(test_stat), function(x) {return(length(GO_sample[[x]]))})
      k_res=data.frame(ID=rownames(test_stat), Description=df_G2NAME[match(rownames(test_stat),df_G2NAME$TERM), 2], test_stat, p.adjust=p.adjust(test_stat$pvalue, method='BH'), geneID , Count)  
      tempres <- k_res[k_res$p.adjust<0.05,]
      #only document results if significantly enriched genes are found
      if(dim(data.frame(tempres))[1] >0) {
        goplot=web_ggendotplot(tempres, nGO = nGO)
        return(tempres)
      } else {
        print('No significantly enriched GO terms found')
      }
    }

  # detach('package:topGO', unload=TRUE)
  # detach('package:GO.db', unload=TRUE)
  # detach('package:ggplot2', unload=TRUE)
}  
