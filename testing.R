library(e1071)
library(ggplot2)
library(corrplot)
library(caret)
library(randomForest)
library(doParallel)

trainData <- read.csv("data/train.csv", header=TRUE, stringsAsFactor=FALSE)
testData <- read.csv("data/test.csv", header=TRUE, stringsAsFactor=FALSE)

# first remove unneeded columns
df <- subset(trainData, select = -c(Cabin, Name, PassengerId, Ticket, Embarked, SibSp, Parch, Fare))
df_test <- subset(testData, select = -c(Cabin, Name, PassengerId, Ticket, Embarked, SibSp, Parch, Fare))

# prepare data for correlation plot: make all columns numeric, delete unneeded columns
df2 <- df
df2$Sex[which(df2$Sex == "female")] <- 0
df2$Sex[which(df2$Sex == "male")] <- 1
df2$Age <- impute(matrix(df2$Age), what="mean")[,1]
df2$Sex <- as.numeric(df2$Sex)

correlationMatrix <- cor(df2)
corrplot(correlationMatrix, method = "pie", order = "FPC")

# convert 'Survived' feature to factor and name levels otherwise we get errors during prediction
df$Survived <- factor(df$Survived)
levels(df$Survived) <- c("no", "yes")


# we have 177 entries where the age is missing, so we impute them by the mean
df$Age <- impute(matrix(df$Age), what="mean")[,1]
completeRows <- df[!complete.cases(df),]

set.seed(1972)
# data partitioning into training and cross validation set
trainIndex <- createDataPartition(y = df$Survived, p=0.7, list=FALSE)
df <- df[trainIndex,]
cross <- df[-trainIndex,]

df$Count <- 0
survivalCountForGender <- aggregate(Count ~ Sex + Survived, data=df, FUN=length)

#testMdl <- glm(Survived ~ ., completeRows, family="binomial")
#print(summary(testMdl))
#rfFitControl = trainControl(method='cv', number = 2, repeats = 2, classProbs=TRUE, savePred=T)
#rfFitControl = trainControl(method='cv', number=10, repeats = 2)
rfFitControl = trainControl(method='repeatedcv', number = 10, repeats = 5, classProbs=TRUE)
#rfFitControl = trainControl(method='oob')

# Create clusters for all available cores communicating over sockets
cl <- makeCluster(detectCores() / 2)
registerDoParallel(cl)
set.seed(1972)
rfFit = train(Survived ~., data=df,
              importance = TRUE,
              method = 'rf',
              trControl=rfFitControl,
              preProc=c("center", "scale"),
              #tuneLength = 50,
              allowParallel=TRUE)

# stop all created cluster nodes
stopCluster(cl)

#testMdl = train(Survived ~., data=df, method = 'rf', trControl=testMdlCtl, preProc=c("center", "scale"))
mdlImportance <- varImp(rfFit, scale=FALSE)
print(plot(mdlImportance))
print(mdlImportance)

pred <- predict.train(rfFit, cross)
print(confusionMatrix(pred, cross$Survived))
pred2 <- predict.train(rfFit, cross, "prob")
plotTest <- cbind(cross, pred2["yes"])
plotTest <- cbind(plotTest, fiftyPercent = rep(0.5, nrow(cross)))

fpYes <- plotTest[which(plotTest$Survived=="no" & plotTest$yes >= 0.5),]
fpNo <- plotTest[which(plotTest$Survived=="yes" & plotTest$yes <= 0.5),]

icke <- data.frame(Pclass=1, Sex="female", Age=42)
pred3 <- predict.train(rfFit, icke, "prob")

print(pred3)

p2 <- dPlot(yes ~ Age, groups = 'Sex', data = plotTest, type = 'bubble')
p2$chart(color = c('orange', 'blue'))
p2$xAxis( type = "addMeasureAxis" )
p2$yAxis( type = "addMeasureAxis" )


nP <- nPlot(yes ~ Age, groups = 'Sex', data = plotTest, type = 'scatterChart')
#nP$xAxis(tickFormat = "#!d3.format('.2%')!#")
nP$yAxis(tickFormat = "#!d3.format('.2%')!#")
nP$chart(
  showDistX = TRUE,
  showDistY = TRUE,
  tooltipContent = "#!function(key, x, y, e) {
  return '<h3>Group: ' + key + '<br>' +
  e.point.Age + '</a></h3>';
  }!#")
#plo <- nPlot(Age ~ Survived, group="Sex", data=df, type = "multiBarChart")
#plo$addParams(title = "Breakdown")
#plo$print("chart2")
#plo

plot <- ggplot(plotTest, aes(x=Age, y=yes, shape=Sex, colour=Survived)) +
  geom_point() +
  geom_hline(yintercept=.5) +
  scale_shape_manual(values=c(1,2)) +
  scale_colour_brewer(palette="Set1") +
  geom_point(aes(x=20, y=0.25, colour="green")) +
  annotate("text", x=20.5, y=0.3, label="YOU", family="serif", fontface="italic", colour="darkred", size=3)
print(plot)