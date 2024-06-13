.onLoad <- function(...){
  quietly <- getOption('quietly')
  options(quietly = T)
  pkg_info <- "protodeviser 0.9.8"
  packageStartupMessage(pkg_info)
  options(quietly = quietly)
}
