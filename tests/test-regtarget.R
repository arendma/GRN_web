# test-regtarget.R

library(testthat)
library(here)
source(here('Program', 'netwk_anav2.R'))

# Load test data
mads_ids <- c('Cre11.g467577', 'Cre06.g253250')
consensus <- read.delim(here('Data', 'consensus0.1.tab'), stringsAsFactors = FALSE)
phot <- read.delim(here('Data', 'gen3x0.1consens.tab'), stringsAsFactors = FALSE)



test_that("regtarget retrieves correct targets from the consensus network", {
  actual_targets_1 <- regtarget(consensus, mads_ids[1])
  actual_targets_2 <- regtarget(consensus, mads_ids[2], 0.5)

  expected_targets_1 <- readRDS(here('tests/expected_outputs/consensus_targets_1.rds'))
  expected_targets_2 <- readRDS(here('tests/expected_outputs/consensus_targets_2.rds'))

  expect_equal(actual_targets_1, expected_targets_1)
  expect_equal(actual_targets_2, expected_targets_2)
})

test_that("regtarget retrieves correct targets from the PHOT network", {
  actual_targets_1 <- regtarget(phot, mads_ids[1])
  actual_targets_2 <- regtarget(phot, mads_ids[2])

  expected_targets_1 <- readRDS(here('tests/expected_outputs/phot_targets_1.rds'))
  expected_targets_2 <- readRDS(here('tests/expected_outputs/phot_targets_2.rds'))

  expect_equal(actual_targets_1, expected_targets_1)
  expect_equal(actual_targets_2, expected_targets_2)
})
