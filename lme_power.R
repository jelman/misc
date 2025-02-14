# Install and load required packages
if (!require("simr")) install.packages("simr")
if (!require("lme4")) install.packages("lme4")
library(simr)
library(lme4)

# Set seed for reproducibility
set.each(123)

# Create function to simulate twin data
simulate_twin_data <- function(n_pairs, effect_size, sd_within = 1, sd_between = 0.5) {
  # n_pairs: number of twin pairs (500 for 1000 total subjects)
  # effect_size: standardized effect size for the predictor
  # sd_within: within-pair standard deviation
  # sd_between: between-pair standard deviation
  
  # Generate pair IDs
  pair_id <- rep(1:n_pairs, each = 2)
  
  # Generate predictor variable
  x <- rnorm(n_pairs * 2)
  
  # Generate random effects
  pair_effect <- rnorm(n_pairs, 0, sd_between)[pair_id]
  
  # Generate outcome
  y <- effect_size * x + pair_effect + rnorm(n_pairs * 2, 0, sd_within)
  
  # Return data frame
  data.frame(
    pair_id = factor(pair_id),
    x = x,
    y = y
  )
}

# Function to test power for a given effect size
test_power <- function(effect_size, n_pairs = 250, n_sims = 100) {
  # Simulate one dataset for model specification
  dat <- simulate_twin_data(n_pairs, effect_size)
  
  # Fit initial model
  model <- lmer(y ~ x + (1|pair_id), data = dat)
  
  # Specify effect size
  fixef(model)["x"] <- effect_size
  
  # Power analysis
  pow <- powerSim(model, nsim = n_sims, test = fixed("x"))
  
  return(pow)
}

# Search for minimum detectable effect size
effect_sizes <- seq(0.05, 0.3, by = 0.01)
power_results <- data.frame(
  effect_size = effect_sizes,
  power = NA
)

for (i in seq_along(effect_sizes)) {
  power_result <- test_power(effect_sizes[i])
  power_results$power[i] <- summary(power_result)$mean
}

# Plot results
plot(power_results$effect_size, power_results$power,
     type = "b",
     xlab = "Standardized Effect Size",
     ylab = "Power",
     main = "Power Analysis Results")
abline(h = 0.8, col = "red", lty = 2)

# Find minimum detectable effect size
min_effect <- power_results$effect_size[which.min(abs(power_results$power - 0.8))]
cat("Minimum detectable effect size at 80% power:", min_effect)
