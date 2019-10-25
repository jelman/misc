Meff_based_FDR <- function(data, pi, alpha = 0.05, 
                           method = c("Bonferroni_S", "Bonferroni_E",
                                      "FDR_S", "FDR_E") ) {
    
    # step 1: estimate the effective number of independent tests
    # correlation matrix
    cormat <- cor(data, use = "pairwise.complete.obs")
    # eigenvalues
    ei <- eigen(cormat, only.values = TRUE, symmetric = TRUE)
    v <- ei$values
    # equation 5 (Li and Ji)
    Meff <- sum(as.integer(v >= 1) + (v - as.integer(v)) )
    
    # step 2: data management (sort p values from small to large)
    M <- dim(data)[2]
    i <- 1:M
    pi <- pi[order(pi[,2]),]
    names(pi)[2] <- "p value"

    # step 3: calculate the threshold of each multiple comparison method
    threshold <- matrix(nrow = M, ncol = 4)
    colnames(threshold) <- c("Bonferroni_S", "Bonferroni_E",
                             "FDR_S", "FDR_E")
    threshold[,1] <- 1 - (1 - alpha)^(1/M)
    threshold[,2] <- 1 - (1 - alpha)^(1/Meff) 
    threshold[,3] <- alpha*i/M
    threshold[,4] <- alpha/Meff + (i-1)/(M-1)*(alpha - alpha/Meff)
    threshold <- signif(threshold, digits = 3)

    # step 4: test the significance of each p-values 
    sig_cut_off <- as.numeric(apply(threshold, 2, function(x) {
        which(pi[,2] <= x)[length(which(pi[,2] <= x))] 
        }  ) )
    significance <- matrix(data = FALSE, nrow = M, ncol = 4)
    for(i in 1:4) {
        if (!is.na(sig_cut_off[i]) )
        significance[1:sig_cut_off[i], i] <- TRUE
    }
    colnames(significance) <- paste("Significance based on", colnames(threshold))
    
    # step 5: generate output
    output <- cbind(pi, threshold, significance)
    return(output)
}



