
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

# import necessary packages
library(e1071)
library(ggplot2)
library(caret)
library(randomForest)
#library(doParallel)
library(googleVis)
library(shiny)
library(shinyBS)

set.seed(1972)
#################################################
## import training data
trainRawData <- read.csv("data/train.csv", header=TRUE, stringsAsFactor=FALSE)

# first remove unneeded columns
trainData <- subset(trainRawData, select = -c(Cabin, Name, PassengerId, Ticket, Embarked, SibSp, Parch, Fare))

# convert 'Survived' feature to factor and name levels otherwise we get errors during prediction
trainData$Survived <- factor(trainData$Survived)
levels(trainData$Survived) <- c("No", "Yes")
trainData$Sex <- factor(trainData$Sex)

# we have 177 entries where the age is missing, so we impute them by the mean
trainData$Age <- e1071::impute(matrix(trainData$Age), what="mean")[,1]

#################################################

shinyServer(function(input, output, session){
  finalModel <- NULL
  predictSurvival <- NULL
  plotSurvival <- NULL
  reactiveVals <- reactiveValues()
  
  tableOptions <- reactive({
    list(
      page='enable',
      pageSize=20
    )
  })
  
  # Do the actual computation here.
  withProgress(message = 'Generating model.', detail='This could take a while, please stay tuned...', value = 0, {
    # training
    if(is.null(finalModel)) {
      # determine number of CPU cores
      #       numCores <- detectCores() / 2
      #       if(numCores < 1) {
      #         numCores <- 1
      #       }
      #       
      #       cl <- makeCluster(numCores)
      #       registerDoParallel(cl)
      
      # fit model via random forest
      set.seed(1972)
      rfFitControl = trainControl(method='repeatedcv', number = 10, repeats = 2, classProbs=TRUE)
      rfFit = train(Survived ~., data=trainData,
                    #importance = TRUE,
                    method = 'rf',
                    trControl=rfFitControl,
                    preProc=c("center", "scale"),
                    allowParallel=TRUE)
      
      # stop all created cluster nodes
      # stopCluster(cl)
      print("Ready to predict.....")
      finalModel <- rfFit
      
      # predict with 'probability' option
      set.seed(1972)
      predictSurvival <- predict.train(rfFit, trainData, "prob")
      
      # add a column wuth probabilities to the data set for later use
      plotSurvival <- cbind(trainData, predictSurvival["Yes"])
      colnames(plotSurvival) <- c("Survived", "Pclass", "Gender", "Age", "SurvivalProb")
      #print(dim(plotSurvival[which(plotSurvival$Gender == "male" & plotSurvival$Survived == "Yes"), ]))
      #print(dim(plotSurvival[which(plotSurvival$Gender == "female" & plotSurvival$Survived == "Yes"), ]))
    }
  })
  
  # prepare data frame for predicting survival probability outr of selected values
  prepareInputs <- reactive({
    # create a data frame for predicting survival later
    if (input$select_pclass != "none" && input$select_gender != "none") {
      df <- data.frame(Pclass=as.numeric(input$select_pclass), Sex=input$select_gender, Age=as.numeric(input$slider_age))
      return(list(data=df))
    }
    else {
      # validate input and show hint if invalid
      reactiveVals$predictedData <- NULL
      validate(
        need(input$select_pclass != "none", "Please select a passenger class."),
        need(input$select_gender != "none", "Please select a gender.")
      )
      return(NULL)
    }
  })
  
  # visualize some data of the Titanic data set
  output$additionalPlots <- renderPlot({
    validate(
      # validate input
      need(input$select_plots != "none", "Please select a plot.")
    )
    
    # count of passengers survived/deceased by gender
    if(input$select_plots == 1) {
      # prepare individual data frame
      df <- trainData
      df$Count <- 0
      survivalCountForGender <- aggregate(Count ~ Sex + Survived, data=df, FUN=length)
      
      # do plotting...
      plot <- ggplot(data=survivalCountForGender, aes(x=Survived, y=Count, fill=Sex)) +
        geom_bar(stat="identity", position=position_dodge()) +
        xlab("Survival types for each gender") +
        ylab(expression("Number of passengers")) +
        ggtitle(expression("Number of passengers having survived\nand deceased the Titanic Desaster")) +
        theme(plot.title = element_text(color="blue", size=14, vjust=1.0))
      print(plot)
    }
    else if(input$select_plots == 2) {
      # count of passengers survived/deceased by passenger class
      # prepare individual data frame
      df <- trainData
      df$Count <- 0
      df$Pclass <- factor(df$Pclass)
      levels(df$Pclass) <- c("Upper", "Middle", "Lower")
      survivalCountForPclass <- aggregate(Count ~ Survived + Pclass, data=df, FUN=length)
      
      # do plotting...
      plot <- ggplot(data=survivalCountForPclass, aes(x=Survived, y=Count, fill=Pclass)) +
        geom_bar(stat="identity", position=position_dodge()) +
        xlab("Survival types for each passenger class") +
        ylab(expression("Number of passengers")) +
        ggtitle(expression("Number of passengers separated by passenger class having survived\nand deceased the Titanic Desaster")) +
        theme(plot.title = element_text(color="blue", size=14, vjust=1.0))
      print(plot)
    }
  })
  
  output$survivalOdds <- renderText({
    # button click and state
    if(!is.null(finalModel)) {
      updateButton(session, "computeBtn", size = "default", disabled = FALSE)
      input$computeBtn
    }      
    
    # is this necessary???
    isolate({
      # no valid input, do nothing
      if (is.null(prepareInputs())) {
        return()
      }
      
      # get data frame for prediction
      df <- prepareInputs()$data
      
      # Yeah! Predict it baby! :)
      predResult <- predict(rfFit, df)
      predProbs <- predict(rfFit, df, "prob")
      
      df["yVal"] <- predProbs["Yes"]
      reactiveVals$predictedData <- df
      
      s1 <- paste("Could you have survived? <b>", predResult, "</b>!")
      paste(s1, "<br/>with a probability of: <b>",
            predProbs["Yes"] * 100,
            "%</b> that he/she could have survived.",
            "<br/><br/><b>Please note:</b><br/>",
            "Because of improvable accuracy of the model you will see<br/>",
            "some survived passengers as deceased and some desceased as survived.<br/>"
            )
    })
  })
  
  output$survivalPlots <- renderPlot({
    if(!is.null(reactiveVals$predictedData)) {
      # plot the survival probability of male or femal passengers
      # (depends of which gender you have selected in 'Select gender' input)
      # adds your prediction computed from above as point to the plot
      df <- reactiveVals$predictedData
      plotSurvivalByGender <- plotSurvival[which(plotSurvival$Gender == input$select_gender), ]
      
      plot <- ggplot(plotSurvivalByGender, aes(x=Age, y=SurvivalProb, colour=Survived)) +
        geom_point(size=3, position = position_jitter(height = 0, width = 0.05)) +
        geom_hline(yintercept=.5) +
        geom_point(data=df, aes(x=Age, y=yVal), colour="blue", shape=6, size=4, position = position_jitter(height = 0, width = 0.05)) +
        annotate("text", x=(df$Age), y=(df$yVal + 0.06) , label="YOU", family="serif", fontface="bold", colour="darkred", size=6) +
        annotate("text", x=4, y=(0.52) , label="Probability of 50%", family="serif", fontface="bold", colour="darkred", size=4) +
        ylab("Probability of Survival") +
        ggtitle("Probability of the passengers survival per gender and age")
      if(input$select_gender == "male") {
        plot <- plot + xlab("Age of male passengers on the Titanic")
      }
      else if(input$select_gender == "female") {
        plot <- plot + xlab("Age of female passengers on the Titanic")
      }
      
      print(plot)
    }
  })
  
  # show an introducery message for printing the table
  output$dataTableDescription <- renderText({
    paste(
      "<h2>",
      "Data used for Survival predictions",
      "</h2>",
      "This is a data table showing the final data set used for the scatterplot of age per gender against the passengers survival probability",
      "<br/>",
      "as shown on the panel labeled 'Survival Prediction.'",
      "<br/>",
      "Some ages had NA values and i had to impiute them with the mean. I decided not to format them, so you can see that they were imputed."
    )
  })
  
  # plot a table of the used data set via Google visualization package
  output$dataTable <- renderGvis({
    gvisTable(plotSurvival,options=tableOptions())         
  })
})
