# test-regtarget.R

library(testthat)
library(here)
library(png)
source(here('Program', 'netwk_anav2.R'))


# Load test data
mads_ids <- c('Cre11.g467577', 'Cre06.g253250')
consensus <- read.delim(here('Data', 'consensus0.1.tab'), stringsAsFactors = FALSE)
phot <- read.delim(here('Data', 'gen3x0.1consens.tab'), stringsAsFactors = FALSE)
expected_plots <- readRDS(here('tests', 'expected_outputs', 'enrichment_plots1.rds'))

# calculations used by more than one test
#cons_madstar1=regtarget(consensus,mads_ids[1])
actual_cons_targets_1 <- regtarget(consensus, mads_ids[1])
actual_cons_targets_2 <- regtarget(consensus, mads_ids[2], 0.5)
actual_phot_targets_1 <- regtarget(phot, mads_ids[1])
actual_phot_targets_2 <- regtarget(phot, mads_ids[2])


test_that("regtarget retrieves correct targets from the consensus network", {
  expected_cons_targets_1 <- readRDS(here('tests/expected_outputs/consensus_targets_1.rds'))
  expected_cons_targets_2 <- readRDS(here('tests/expected_outputs/consensus_targets_2.rds'))

  expect_equal(actual_cons_targets_1, expected_cons_targets_1)
  expect_equal(actual_cons_targets_2, expected_cons_targets_2)
})

test_that("regtarget retrieves correct targets from the PHOT network", {
  expected_phot_targets_1 <- readRDS(here('tests/expected_outputs/phot_targets_1.rds'))
  expected_phot_targets_2 <- readRDS(here('tests/expected_outputs/phot_targets_2.rds'))

  expect_equal(actual_phot_targets_1, expected_phot_targets_1)
  expect_equal(actual_phot_targets_2, expected_phot_targets_2)
})


test_that("regulatorTranscriptionFactorList returns correct coregulators", {
  actual_coregs <- regulatorTranscriptionFactorList(consensus, actual_cons_targets_1$target[1:25], 0.08, here('test'))
  expected_coregs <- readRDS(here('tests/expected_outputs/coregulators.rds'))
  expect_equal(actual_coregs, expected_coregs)
})


test_that("regTFs returns correct coregulators", {
  actual_coregs <- regTFs(phot, mads_ids[1], 0.7)
  expected_coregs <- readRDS(here('tests/expected_outputs/phot_coregulators.rds'))
  expect_equal(actual_coregs, expected_coregs) 
})


# TODO: outsource this test
source(here('Program', 'cregoenricherv9.r'))
test_that("cregoenricher returns correct GO term enrichment results", {
  actual_res <- cregoenricher(samples = list(actual_cons_targets_1$target), universe = unique(consensus$to), category = 'BP')
  expected_res <- readRDS(here('tests/expected_outputs/go_enrichment.rds'))
  expect_equal(actual_res, expected_res)
})

# TODO: outsource this test
source(here('Program', 'web_ggendotplot.r'))
test_that("web_ggendotplot returns correct plots", {
  #res1=cregoenricher(samples = list(cons_madstar1$target), universe = unique(consensus$to), category = 'BP')
  res1 <- cregoenricher(samples = list(actual_cons_targets_1$target), universe = unique(consensus$to), category = 'BP')
  actual_plots <- web_ggendotplot(res1)
  
  expect_equal(actual_plots$heatmap, expected_plots$heatmap)
  expect_equal(actual_plots$goplot, expected_plots$goplot)
  print("Test passed: web_ggendotplot returns correct plots")
})


test_that("print_go_enrichment_plot prints correct grid plot", {
  pdf(here('tests/test_go_plot.pdf'))
  print_go_enrichment_plot(expected_plots)
  dev.off()
  expected_pdf <- readBin(here('tests/expected_outputs/go_plot.pdf'), what='raw', n=file.info(here('tests/expected_outputs/go_plot.pdf'))$size)
  actual_pdf <- readBin(here('tests/test_go_plot.pdf'), what='raw', n=file.info(here('tests/test_go_plot.pdf'))$size)
  expect_equal(actual_pdf, expected_pdf)
  file.remove(here('tests/test_go_plot.pdf'))
})


