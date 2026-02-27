Custom template for New Graph Environment Ltd. reporting

## Quick Start

**Local build:**
```r
renv::restore()  # First time only - install packages
Rscript scripts/setup_docs.R build
```

**GitHub Actions:** Pushes to `main` auto-build and deploy to GitHub Pages.

## Dependencies

Managed with [renv](https://rstudio.github.io/renv/). The `renv.lock` file locks all package versions.

```r
renv::restore()   # Install packages from lockfile
renv::install()   # Add new packages
renv::snapshot()  # Update lockfile after changes
```

## Build Scripts

- `scripts/setup_docs.R clean` - Clear docs/
- `scripts/setup_docs.R build` - Build the book
- `scripts/run.R` - Manual build with PDF (requires Zotero for bibliography)

## Password-Protected Mode

Set in `index.Rmd`:
```yaml
params:
  password_protected: TRUE
  password_dir: 'your_secret_hash'
```

Builds report to `docs/<password_dir>/` with landing page at `docs/index.html`.

## Version History

Track changes in [`NEWS.md`](NEWS.md)

---

Adapted from [bookdown](https://github.com/rstudio/bookdown). See [Get Started](https://bookdown.org/yihui/bookdown/get-started.html) for more.

So if we want to use this repo to update specific files in existing repos generated from the template we need to can do the following from the production report.  NEED TO TEST A BUNCH.  See https://stackoverflow.com/questions/24815952/git-pull-from-another-repository:

    git remote add upstream https://github.com/NewGraphEnvironment/mybookdown-template.git
    git config remote.upstream.pushurl "maybe dont push to the template from here bud"
    git fetch upstream
    git checkout upstream/master -- path/to/file
    
    
In order to avoid commit huge files run this every once and a while https://stackoverflow.com/questions/4035779/gitignore-by-file-size
https://stackoverflow.com/questions/37768376/remove-duplicate-lines-and-overwrite-file-in-same-command

    find . -size +50M | sed 's|^\./||g' >> .gitignore; awk '!seen[$0]++' .gitignore | sponge .gitignore
    
    
This is a common move to deal with repeated headers in pagedown knitr table outputs when the page breaks.  If we don't have an extra `<br>`

`r if(params$gitbook_on){knitr::asis_output("<br>")} else knitr::asis_output("\\pagebreak<br>")`
    

   
