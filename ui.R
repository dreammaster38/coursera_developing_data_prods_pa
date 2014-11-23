
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

# load necessary libraries 
library(shiny)
library(shinyBS)

# building shiny UI
# create a page with navigation bar
# and some panels
require(markdown)
shinyUI(navbarPage("ML from Titanic Disaster", theme = "bootstrap2.min.css", fluid=T, responsive=T,
                   tabPanel("Introduction And Usage",
                      mainPanel(
                        includeMarkdown("usage.md")
                      )
                   ),
                   
                   tabPanel("Additional Plots",
                            # Sidebar with select inputs and a slider
                            sidebarLayout(
                              sidebarPanel(
                                
                                # passenger class input for prediction
                                selectInput("select_plots",
                                            label = h5("Select Plot"), 
                                            choices = list("Please select..." = "none",
                                                           "Plot count of deceased/survived per gender" = 1,
                                                           "Plot count of deceased/survived per Pclass" = 2
                                            ),
                                            selected = "none"
                                ),
                                br(),
                                br(),
                                p("Please select from the possible plots above.",
                                  "If no plot is selected you will see a hint message."
                                  )
                              ),
                              mainPanel(
                                plotOutput("additionalPlots", height = 600, width = 800)
                              )
                            )
                   ),
                   
                   tabPanel("Could you have survived?",                            
                            # Sidebar with select inputs and a slider
                            sidebarLayout(
                              sidebarPanel(
                                
                                # passenger class input for prediction
                                selectInput("select_pclass",
                                            label = h5("Select Passenger Class"), 
                                            choices = list("Please select..." = "none",
                                                           "Passenger Class 1 (Upper)" = 1,
                                                           "Passenger Class 2 (Middle)" = 2,
                                                           "Passenger Class 3 (Lower)" = 3
                                                           ),
                                            selected = "none"
                                ),
                                
                                # gender input for prediction
                                selectInput("select_gender",
                                            label = h5("Select Gender"), 
                                            choices = list("Please select..." = "none",
                                                           "Female" = "female",
                                                           "Male" = "male"),
                                            selected = "none"
                                ),
                                
                                # age input for prediction
                                sliderInput("slider_age",
                                            label = h5("Select your age"),
                                            min = 1,
                                            max = 99,
                                            value = 42,
                                            step = 1
                                ),
                                
                                # Yes, yes, please tell me, could i have survived???
                                bsActionButton("computeBtn",
                                               label = "My survical Odds",
                                               style="primary",
                                               disabled = TRUE
                                ),
                                br(),
                                br(),
                                p("The button 'My survical Odds' will be enabled",
                                  " just right after the model is ready",
                                  " to predict."
                                ),
                                br(),
                                p("<b>Important:</b>if you change any value",
                                  "please don't forget to click on the",
                                  "'My survical Odds' button!")
                              ),
                              
                              # Show a scatter plot of the configured and
                              # afterwards predicted values
                              # show a data table
                              mainPanel(
                                tabsetPanel(
                                  # UI for prediction
                                  tabPanel("Survival Prediction",
                                           fluidRow(
                                             column(
                                               width = 5,
                                               htmlOutput("survivalOdds")
                                             )
                                           ),
                                           br(),
                                           br(),
                                           fluidRow(
                                             column(width = 10, plotOutput("survivalPlots", , height = 600, width = 900))
                                           )
                                  ),
                                  # create a data table out of the model data
                                  # used for prediction and plotting
                                  tabPanel("Used data set",
                                           fluidRow(
                                             column(
                                               width = 12,
                                               htmlOutput("dataTableDescription")
                                             )
                                           ),
                                           br(),
                                           br(),
                                           fluidRow(
                                             column(width = 12,
                                                    htmlOutput("dataTable")
                                             )
                                           )
                                  )
                                )
                              )
                            )
                   )
))