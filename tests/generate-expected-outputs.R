library(here)
source(here('Program', 'netwk_anav2.R'))
source(here('Program', 'cregoenricherv9.r'))
source(here('Program', 'web_ggendotplot.r'))

# Load test data 
mads_ids <- c('Cre11.g467577', 'Cre06.g253250')
consensus <- read.delim(here('Data', 'consensus0.1.tab'), stringsAsFactors = FALSE)
phot <- read.delim(here('Data', 'gen3x0.1consens.tab'), stringsAsFactors = FALSE)

# Generate expected outputs for test-regtarget.R
cons_targets_1 <- regtarget(consensus, mads_ids[1])  
cons_targets_2 <- regtarget(consensus, mads_ids[2], 0.5)
phot_targets_1 <- regtarget(phot, mads_ids[1])   
phot_targets_2 <- regtarget(phot, mads_ids[2])

# Generate expected outputs for suggested tests
coregs <- regulatorTranscriptionFactorList(consensus, cons_targets_1$target[1:25], 0.08, here('test')) 
saveRDS(coregs, here('tests', 'expected_outputs', 'coregulators.rds'))

phot_coregs <- regTFs(phot, mads_ids[1], 0.7) 
saveRDS(phot_coregs, here('tests', 'expected_outputs', 'phot_coregulators.rds'))

go_enrich <- cregoenricher(samples = list(cons_targets_1$target), universe = unique(consensus$to), category = 'BP')  
saveRDS(go_enrich, here('tests', 'expected_outputs', 'go_enrichment.rds'))   

go_plots <- web_ggendotplot(go_enrich)
saveRDS(go_plots, here('tests', 'expected_outputs', 'go_plots.rds'))

pdf(here('tests', 'expected_outputs', 'go_plot.pdf'))  
print_go_enrichment_plot(go_plots)
dev.off()



# Get GO enrichment results
res1 <- cregoenricher(samples = list(cons_targets_1$target), universe = unique(consensus$to), category = 'BP')

# Generate/save plots
enrichment_plots1 <- web_ggendotplot(res1)
saveRDS(enrichment_plots1, here('tests', 'expected_outputs', 'enrichment_plots1.rds'))
