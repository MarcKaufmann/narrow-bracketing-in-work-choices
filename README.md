# Data Analysis for Narrow Bracketing in Effort Choices

Code for data analysis of [our experiment on narrow bracketing in work choices](https://trichotomy.xyz/publication/narrow-bracketing-in-effort-choices/narrow-bracketing-in-effort-choices.pdf), joint work between [Francesco Fallucchi](https://sites.google.com/site/francescofallucchi/) and [Marc Kaufmann](https://trichotomy.xyz/).

The relevant files can be found in data/:

- `full_raw_data.csv`: what it says on the tin, combines several sheets of the original Excel spreadsheets downloaded from the Lioness server into a single .csv file. The only cleaning performed at this stage:
    1. we dropped columns about time taken on extra tasks that at download from Lioness were spread across multiple columns and hard to clean combine (and are not used in our analysis)
    2. we replaced missing data by `NA` (not available) rather than leaving it blank
    3. we combined data from different sessions into a single data file
    4. we added added session information (date-time)
    5. we do not include information Lioness collects on MTurk experiments, such as worker IDs and payment confirmation
- `experiment-results.Rmd`: an RMarkdown file interlacing code for data analysis and presentation with the text of our results section
- `exp2latex.R`: creates the tex file `experiment-results.tex` from `experiment-results.Rmd`, as well as all the tables in the rest of the paper. This tex file gets included directly in the paper. Requires Rscript, as well as the `rmarkdown` library (and many more to run the actually analysis code).
- `makefile`: runs the `exp2latex.R` script to generate the tex file

## How to Run the Analysis

**Prerequisites:** You need an installation of [R](https://www.r-project.org/) (the analysis was run both with versions 3.6 and 4.0), as well as quite a few R packages. The easiest way to do this is to open the R project (data/data.Rproj) in [RStudio](https://rstudio.com/), and open the `experiment-results.Rmd` file. RStudio will helpfully tell you which packages you need to install to run the code, simply click on install those packages. Alternatively just try to run the code as described below and see which packages you are missing and install them. (Ideally we'll simplify this process once our paper gets ready for publication, which should be sometime this decade. Then again, the ideal and real rarely meet.)

**Via `make`:** The easiest way to run our analysis is to clone the repository, change into the data/ folder and run

    $ make

from the cli, assuming you are on Mac or Linux. 

**Via `R`:** From the data/ folder, open an R console or RStudio and run the line of code in `exp2latex` (which requires the package `rmarkdown`):

    > rmarkdown::render("experiment-results.Rmd", output_format=rmarkdown::latex_fragment())

Either of these should create the output file `experiment-results.tex` as well as a whole collection of .tex and .png files for tables and graphs used in the paper. The names of the files are hopefully fairly self-descriptive.
