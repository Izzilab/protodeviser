.onLoad <- function(...){
  quietly <- getOption('quietly')
  options(quietly = T)
  pkg_info <- "protodeviser 1.01"
  packageStartupMessage(pkg_info)
  options(quietly = quietly)
}
