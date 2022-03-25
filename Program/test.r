#Test file retrieving the targets of MADS box regulators in chlamy from the consensus and the g3xcons network
source('netwk_anav2.R')

#Regulator IDs
mads_ids=c('Cre11.g467577', 'Cre06.g253250')

#Consensus network
consensus=read.delim('../Data/consensus0.1.tab')
#PHOT network
phot=read.delim('../Data/gen3x0.1consens.tab')

#extract top 25 targets for the two mads tfs in the consensus network
cons_madstar1=regtarget(consensus,mads_ids[1], 25)
cons_madstar2=regtarget(consensus, mads_ids[2], 25)

#extract all targets of the two mads tfs in the PHOT network
phot_madstar1=regtarget(phot, mads_ids[1])
phot_madstar2=regtarget(phot, mads_ids[2])


#extract the the top 25 coregulators of mads 1 regulator targets and plot the network
#this will create twot plots in pdf format and 1 tsv with label legend for the nodes
#in the parent directory
cons_coreg=regTFls(consensus, cons_madstar1$target, 25, '../test')

#find all coregulators for the single highest ranked target genen of mads2 in the phot network
phot_mads2coreg=regTFs(phot, phot_madstar2$name[1])

