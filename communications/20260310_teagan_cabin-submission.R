library(mc)

draft <- FALSE
test  <- FALSE

to_address   <- c("teagan.oshaughnessy@wetsuweten.ca", "samantha.vincent@wetsuweten.com")
subject_line <- "CABIN data submission - Neexdzii Kwa benthic 2025"

html <- mc_compose("communications/20260310_teagan_cabin-submission_draft.md")

mc_send(
  html    = html,
  to      = to_address,
  subject = subject_line,
  draft   = draft,
  test    = test
)
