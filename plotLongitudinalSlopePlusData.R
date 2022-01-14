library(lmerTest)
library(tidyverse)
library(tidyr)
library(ggeffects)

# Load data
df = read.csv("/home/jelman/Desktop/AgeBased_HippocampusChange_UCSDonly2.csv")
# Pivot from wide to long
dflong = df %>% select(VETSAID, case, starts_with("cage"), starts_with("adjHippocampus")) %>% 
  pivot_longer(cols=c(-VETSAID, -case), names_to = c(".value","wave"), names_sep="_", values_to = c("Hippocampus","Age",values_drop_ba=TRUE))

# Run mixed effects model
mod = lmer(adjHippocampus ~ cage + (1|case/VETSAID), data=dflong)
summary(mod)

# Calculate rate of change per year
(fixef(mod)[[2]]/fixef(mod)[[1]]) * 100


# Get predicted values from model
preddf = ggpredict(mod, terms="cage")
# Plot predicted values from model
p = ggplot(preddf, aes(x=x, y=predicted)) + 
  geom_line(color="firebrick", size=1) + 
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = .1, fill="firebrick")

# Add datapoints and connect points within subject
p + geom_line(data=dflong, aes(x=cage, y=adjHippocampus, group = VETSAID), alpha=.3) +
  geom_point(data=dflong, aes(x=cage, y=adjHippocampus), alpha=.3) + 
  xlab("Age (centered)") + ylab("Hippocampus") + 
  sjPlot::theme_sjplot(16)
  


################################################################################
# Example of how to plot fixed effects along with predicted 
# subject-specific slopes (as opposed to raw data). This example 
# iuncludes random slopes with nested random intercept:
#
# fit.afqt = lmer(afqt ~ age + (1 + age|VETSAID) + (1|CASE/VETSAID), data=df)
# 
# It should be easy to modify if random slope is dropped or intercept 
# is not nested.
##############################################################################


# Get predicted values from model for fixed effects. 
# If you want variance of the random effects, include type='random'
preddf = ggpredict(fit.afqt, terms="age")
preddf = data.frame(preddf)

# Get predicted values of int and slope for all subjects
# NOTE: This produces combos of random effects (i.e., every combom of CASE and VETSAID)
me <- ggpredict(fit.afqt, terms = c("age","CASE", "VETSAID"), type = "re")
me = data.frame(me)

# We only want combinations of VETSAID and CASE that actually exist, filter matches
vetsaid_case = unique(paste(df$VETSAID, df$CASE, sep="_"))
me$VETSAID_CASE = paste(me$facet, me$group, sep="_")
me = me %>% filter(VETSAID_CASE %in% vetsaid_case)


# Plot individual slopes and then fixed effect estimate with 95% CI on top
p = ggplot() + 
  geom_line(data=me, aes(x=x, y=predicted, group = VETSAID_CASE), alpha=.1) +
  geom_line(data=preddf, aes(x=x, y=predicted), color="firebrick", size=2) + 
  geom_ribbon(data=preddf, aes(x=x, y=predicted, ymin = conf.low, ymax = conf.high), alpha = .5, fill="firebrick") +
  xlab("Age") + ylab("AFQT") + theme_sjplot(16)
