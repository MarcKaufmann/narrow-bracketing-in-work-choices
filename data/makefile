##
# Experiment Results
#
# @file
# @version 0.1

all: clean_data.csv summary_outputs means_and_tests

clean_data.csv: clean-data.R
	Rscript clean-data.R

summary_outputs: summary_statistics.R
	Rscript summary_statistics.R

means_and_tests: means_and_tests.R
	Rscript means_and_tests.R

# end
