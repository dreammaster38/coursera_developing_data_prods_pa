library(e1071)
library(caret)
library(randomForest)
library(doParallel)

set.seed(1972)
#################################################
## import training data
trainRawData <- read.csv("data/train.csv", header=TRUE, stringsAsFactor=FALSE)

# first remove unneeded columns
trainData <- subset(trainRawData, select = -c(Cabin, Name, PassengerId, Ticket, Embarked, SibSp, Parch, Fare))

# convert 'Survived' feature to factor and name levels otherwise we get errors during prediction
trainData$Survived <- factor(trainData$Survived)
levels(trainData$Survived) <- c("No", "Yes")

# we have 177 entries where the age is missing, so we impute them by the mean
trainData$Age <- impute(matrix(trainData$Age), what="mean")[,1]


#################################################

# Do the actual computation here.
# training
numCores <- detectCores() / 2
print(numCores)
if(numCores < 1) {
  numCores <- 1
}
print(numCores)

cl <- makeCluster(numCores)
registerDoParallel(cl)

set.seed(1972)
rfFitControl = trainControl(method='repeatedcv', number = 10, repeats = 2, classProbs=TRUE)
rfFit = train(Survived ~., data=trainData,
              #importance = TRUE,
              method = 'rf',
              trControl=rfFitControl,
              preProc=c("center", "scale"),
              allowParallel=TRUE)

# stop all created cluster nodes
stopCluster(cl)

set.seed(1972)
predictSurvival <- predict.train(rfFit, trainData, "prob")
pred <- predict.train(rfFit, trainData)
plotSurvival <- cbind(trainData, predictSurvival["Yes"])
colnames(plotSurvival) <- c("Survived", "Pclass", "Gender", "Age", "SurvivalProb")
#print(dim(plotSurvival[which(plotSurvival$Gender == "male" & plotSurvival$Survived == "Yes"), ]))
#print(dim(plotSurvival[which(plotSurvival$Gender == "female" & plotSurvival$Survived == "Yes"), ]))
print(confusionMatrix(pred, trainData$Survived))
print(rfFit$finalModel)