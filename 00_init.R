## Load libraries
library(data.table)
#library(describe)
library(Hmisc)
library(jsonlite)
library(stringr)
library(lubridate)
library(ggplot2)
library(gridExtra)

## source code of the project
source("02_dataprocessing.R")
source("03_eda.R")

# set path.data as a global path
path.data <<- '/Users/sergigomezpalleja/Downloads/'

# Visualization parameters 
plotEDA <<- F
