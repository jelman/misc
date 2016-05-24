lm.beta.lmer <- function(mod) {
  b <- fixef(mod)[-1]            ## fixed-effect coefs, sans intercept
  sd.x <- apply(mod at X[,-1],2,sd) ## pull out model (design) matrix,
                                 ## drop intercept column, calculate
                                 ## sd of remaining columns
  sd.y <- sd(mod at y)              ## sd of response
  b*sd.x/sd.y
}