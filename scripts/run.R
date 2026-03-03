# Load params from index.Rmd
source("scripts/setup.R")
source("scripts/functions.R")

# Read params
yaml <- rmarkdown::yaml_front_matter("index.Rmd")
run_params <- yaml$params

# build the gitbook
{
  # clean the output directory for a fresh build
  unlink("docs", recursive = TRUE)

  rmarkdown::render_site(output_format = 'bookdown::gitbook',
                         encoding = 'UTF-8')
}
