# Data Analysis for Narrow Bracketing in Effort Choices

Code for data analysis of [our experiment on narrow bracketing in work choices](https://trichotomy.xyz/publication/narrow-bracketing-in-work-choices/narrow-bracketing-in-work-choices.pdf), joint work between [Francesco Fallucchi](https://sites.google.com/site/francescofallucchi/) and [Marc Kaufmann](https://trichotomy.xyz/).

The relevant files can be found in data/:

- `full_raw_data.csv`: what it says on the tin, combines several sheets of the original Excel spreadsheets downloaded from the Lioness server into a single .csv file. The only cleaning performed at this stage:
    1. we dropped columns about time taken on extra tasks that at download from Lioness were spread across multiple columns and hard to clean combine (and are not used in our analysis)
    2. we replaced missing data by `NA` (not available) rather than leaving it blank
    3. we combined data from different sessions into a single data file
    4. we added added session information (date-time)
    5. we do not include information Lioness collects on MTurk experiments, such as worker IDs and payment confirmation
- `clean-data.R`: script to turn the raw data into clean data, saving it as `clean_data.csv` on file. The script expects the file `full_raw_data.csv` to exist. Run via `Rscript clean-data.R` or interactively.
- `clean_data.csv`: the output produced by `clean-data.R`
- `summary_statistics.R`: script to create tables and graphs for summary statistics, attrition, etc, which are primarily found in Section 3 on experimental design.
- `means_and_tests.R`: script to create tables and graphs for treatments comparisons etc. These are mostly used in Section 4 on experimental results, as well as in the appendix on additional results.
- `makefile`: It runs everything for you, assuming you know what a makefile is and how to run it. If you don't, ignore it.

## How to Run the Analysis

**Prerequisites:** You need an installation of [R](https://www.r-project.org/) (the analysis was run both with versions 3.6 and 4.0), as well as quite a few R packages. The easiest way to do this is to open the R project (data/data.Rproj) in [RStudio](https://rstudio.com/), and open the `means_and_tests.R` file. RStudio will helpfully tell you which packages you need to install to run the code, simply click on install those packages. Alternatively just try to run the code as described below and see which packages you are missing and install them. (Ideally we'll simplify this process once our paper gets ready for publication, which should be sometime this decade. Then again, the ideal and real rarely meet.)

**Via `make`:** The easiest way to run our analysis is to clone the repository, change into the data/ folder and run

    $ make

from the cli, assuming you are on Mac or Linux. 

**Via `R`:** From the data/ folder, open an R console or RStudio and run each of the two script files `means_and_tests.R` and `summary_statistics.R` separately. 

Either of these should create a collection of .tex and .png files for tables and graphs used in the paper. The names of the files are hopefully fairly self-descriptive.
