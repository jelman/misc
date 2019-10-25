library(caret)
library(ROCR)
library(pROC)
library(AUC)


set.seed(144)
true_class <- factor(sample(paste0("Class", 1:2), 
                            size = 1000,
                            prob = c(.2, .8), replace = TRUE))
true_class <- sort(true_class)
class1_probs <- rbeta(sum(true_class == "Class1"), 4, 1)
class2_probs <- rbeta(sum(true_class == "Class2"), 1, 2.5)
test_set <- data.frame(obs = true_class,
                       Class1 = c(class1_probs, class2_probs))
test_set$Class2 <- 1 - test_set$Class1
test_set$pred <- factor(ifelse(test_set$Class1 >= .5, "Class1", "Class2"))

confusionMatrix(data = test_set$pred, reference = test_set$obs, positive="Class1")
twoClassSummary(test_set, lev = levels(test_set$obs))
prSummary(test_set, lev = levels(test_set$obs))


AUC::auc(AUC::roc(test_set$Class2, test_set$obs))
AUC::sensitivity(test_set$Class2, test_set$obs)

rocr.pred = prediction(test_set$Class2, test_set$obs)
performance(rocr.pred, measure = "auc")@y.values[[1]]

pROC::roc(test_set$obs, test_set$Class1)

##########################
data(churn)

df = data.frame(probs=churn$predictions, obs=factor(ifelse(churn$labels==1,"Class1","Class2")), 
                pred=factor(ifelse(churn$predictions>.5,"Class1","Class2")))
df2 = data.frame(probs=churn$predictions2, obs=factor(ifelse(churn$labels==1,"Class1","Class2")), 
                 pred=factor(ifelse(churn$predictions2>.5,"Class1","Class2"))) 

AUC::auc(AUC::roc(1-df$probs, df$obs))
AUC::auc(AUC::roc(1-df2$probs, df$obs))

confusionMatrix(df$pred, reference = df$obs)
twoClassSummary(df, lev=levels(df$obs))

confusionMatrix(df2$pred, reference = df2$obs)
twoClassSummary(df2, lev=levels(df2$obs))


rocr.pred = prediction(df$probs, df$obs, label.ordering = c("Class2","Class1"))
performance(rocr.pred, measure = "auc")@y.values[[1]]

rocr.pred = prediction(df2$probs, df$obs, label.ordering = c("Class2","Class1"))
performance(rocr.pred, measure = "auc")@y.values[[1]]

pROC::roc(df$obs, df$probs)
pROC::roc(df2$obs, df2$probs)

plot(pROC::roc(df$obs, df$probs), col="#1c61b6", print.auc=TRUE, 
     print.auc.y=.5, print.auc.pattern="AUC p<0.05: %.3f")
plot(pROC::roc(df2$obs, df2$probs), col="#008600", print.auc=TRUE, 
     print.auc.y=.4, print.auc.pattern="AUC p<0.01: %.3f", add=TRUE)
