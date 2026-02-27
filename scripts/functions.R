##funciton ot find a string in your directory from https://stackoverflow.com/questions/45502010/is-there-an-r-version-of-rstudios-find-in-files

fif <- function(what, where=".", in_files="\\.[Rr]$", recursive = TRUE,
                ignore.case = TRUE) {
  fils <- list.files(path = where, pattern = in_files, recursive = recursive)
  found <- FALSE
  file_cmd <- Sys.which("file")
  for (fil in fils) {

    if (nchar(file_cmd) > 0) {
      ftype <- system2(file_cmd, fil, TRUE)
      if (!grepl("text", ftype)[1]) next
    }
    contents <- readLines(fil)
    res <- grepl(what, contents, ignore.case = ignore.case)
    res <- which(res)
    if (length(res) > 0) {
      found <-  TRUE
      cat(sprintf("%s\n", fil), sep="")
      cat(sprintf(" % 4s: %s\n", res, contents[res]), sep="")
    }
  }
  if (!found) message("(No results found)")
}


# write the contents of the NEWS.md file to a RMD file that will be included as an appendix
news_to_appendix <- function(
    md_name = "NEWS.md",
    rmd_name = "2090-report-change-log.Rmd",
    appendix_title = "# Changelog") {

  # Read and modify the contents of the markdown file
  news_md <- readLines(md_name)
  news_md <- stringr::str_replace(news_md, "^#", "###") |>
    stringr::str_replace_all("(^(### .*?$))", "\\1 {-}")

  # Write the title, a blank line, and the modified contents to the Rmd file
  writeLines(
    c(paste0(appendix_title, " {-}"), "", news_md),
    rmd_name
  )
}

my_dt_table <-   function(dat,
                          cols_freeze_left = 3,
                          page_length = 10,
                          col_align = 'dt-right',
                          font_size = '10px'){

  dat %>%
    DT::datatable(
      style = 'bootstrap',
      class = 'cell-border stripe', #'dark' '.table-dark',
      #https://stackoverflow.com/questions/36062493/r-and-dt-show-filter-option-on-specific-columns
      filter = 'top',
      extensions = c("Buttons","FixedColumns", "ColReorder"),
      rownames= FALSE,
      options=list(
        scrollX = TRUE,
        columnDefs = list(list(className = col_align, targets = "_all")), ##just added this
        pageLength = page_length,
        dom = 'lrtipB',
        buttons = c('excel','csv'),
        fixedColumns = list(leftColumns = cols_freeze_left),
        lengthMenu = list(c(5,10,25,50,-1),
                          c(5,10,25,50,"All")),
        colReorder = TRUE,
        #https://stackoverflow.com/questions/44101055/changing-font-size-in-r-datatables-dt
        initComplete = htmlwidgets::JS(glue::glue(
          "function(settings, json) {{ $(this.api().table().container()).css({{'font-size': '{font_size}'}}); }}"
        ))
        #https://github.com/rstudio/DT/issues/1085 - this is not working yet
        #   initComplete = JS(
        #     'function() {$("html").attr("data-bs-theme", "dark");}')
      )
    )
}

ltab_caption <- function(caption_text = my_caption) {
  cat(
    "<table>",
    paste0(
      "<caption>",
      "(#tab:",
      # this is the chunk name!!
      knitr::opts_current$get()$label,
      ")",
      caption_text,
      "</caption>"
    ),
    "</table>",
    sep = "\n"
  )
}

