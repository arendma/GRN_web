#Test file retrieving the targets of MADS box regulators in chlamy from the consensus and the g3xcons network
source('netwk_anav2.R')
source('cregoenricherv9.r')
source('web_ggendotplot.r')

#Regulator IDs
mads_ids=c('Cre11.g467577', 'Cre06.g253250')

#Consensus network
consensus=read.delim('../Data/consensus0.1.tab', stringsAsFactors = FALSE)
#PHOT network
phot=read.delim('../Data/gen3x0.1consens.tab', stringsAsFactors = FALSE)

#extract all targets for the first mads tfs in the consensus network
cons_madstar1=regtarget(consensus,mads_ids[1])
#extract top 50% of targets for the first mads tfs
cons_madstar2=regtarget(consensus, mads_ids[2])

#extract all targets of the two mads tfs in the PHOT network
phot_madstar1=regtarget(phot, mads_ids[1], 0.5)
phot_madstar2=regtarget(phot, mads_ids[2])

#add arabidopsis besthits


#extract the the top 25 coregulators of mads 1 regulator targets and plot the network
#this will create twot plots in pdf format and 1 tsv with label legend for the nodes
#in the parent directory (i.e. testlognet.pdf, testnet.pdf and testputreg.tsv)
cons_coreg = regulatorTranscriptionFactorList(consensus, cons_madstar1$target[1:25], 0.08, '../test')

#find 70% of all coregulators for the single highest ranked target genen of mads2 in the phot network
phot_mads2coreg=regTFs(phot, phot_madstar2$name[1], 0.7)

# avoid error "cannot open file 'Rplots.pdf'" in Docker container
# NOTE: remove this line to see the plots!
pdf(NULL)

## Analyse all targets in the consensus network for GO terms enriched
res1=cregoenricher(samples = list(cons_madstar1$target), universe = unique(consensus$to), category = 'BP')
##plots the top 5 most significantly enriched GO terms
enrichment_plots1 = web_ggendotplot(res1)

### draw enrichment plots in a grid
print_go_enrichment_plot(enrichment_plots1)

res2=cregoenricher(samples = list(cons_madstar2$target), universe = unique(consensus$to), category = 'BP')
enrichment_plots2 = web_ggendotplot(res2)
