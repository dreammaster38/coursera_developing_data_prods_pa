## Coursera project assignment for Developing Data Products
---


### Introduction

In this course we should develop a tiny Shiny-App of our own.
I decided to use the data set of the Titanic Disaster from [http://kaggle.com](http://kaggle.com "Kaggle") to build a simple machine learning app.
A user will be able to configure settings like the passenger class, the age and the gander for with a prediction against the titanic data model will be done.
The result will be presented visually as plot and summarized as short text block.
Furthermore some data could be visualized to see who has survived and who not. Within the following sections i'll describe the different parts of this app ans show it's usage.

### Description and usage

Now let's see what sections exists and what you could do/see there. While opening the site the model used for survival prediction will be generated in the background for you. The progress of this action will be shown as textual hint in the upper right.

#### Navigation entries

After starting the app you will see a navigation bar on top of the site. The introduction you're currently reading belongs to the menu entry **Introduction And Usage**.

##### Additional Plots

This section let yo choose from two possible plots showing you the survival and decease of the Titanic passengers

* for gender
* for the three passenger classes

The next section is **Could you have survived?**. Here you can configure the parameters mentioned in the introductional section of this article.

##### Could you have survived?

This is the most interesting section of this shiny app. As stated above you can do a prediction based on the paramters you configured and see if you could have survived the Titanic Disaster.
There are the following parameters you can configure:
* *Select Passenger Class:* The class you could have traveled in (1st class: rich peaople, 2nd class: the middle class, 3rd class: working class)
* *Select Gender:* The gender for prediction choose ether *male* or *female*
* *Select your age:* The age for prediction as slider input, choose between 1 and 99

After you made your configuration press the button *My survical Odds*.

**Important! If you change any value to do a new prediction please don't forget to click on the button *My survical Odds* again!**

##### Output

You will see a text message showing you if you could have survived and the predicted probability. The generated plot shows a scatterplot with your predicted probability in the plot annotated with **YOU**. If you selected *male* in the 'Select gender' input the probability of all male passengers (and yours) is plotted.
Otherwise if you selected *female* the probability of all female passengers (and yours) is plotted.
There is a black line drawn at the 50%-level just for your orientation to show this 50% boundry.

#### Used data set

Within this tabbed page you can find a table with the whole dataset used for prediction including the probability computed for each passenger.
There is no special feature here you can just page through th table pages and sort values as you wish.

### Summary

For known bugs and some other details please see the slides which you can find at


I hope you will enjoy this little Shiny App

November 2014, Thomas Guenther
