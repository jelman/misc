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
  
