
dt_orig <- copy(dt_train)

# First quick exploration 
dim(dt_orig)
head(dt_orig)
names(dt_orig)

# Factor variables 
factorVars <- c("channelGrouping","browser","operatingSystem","deviceCategory",
                "country")
dateVars <- c("date")
intVars <- c("visits", "hits", "bounces", "pageviews", "newVisits")
numVars <- "transactionRevenue"
timeVars <- c("visitStartTime")

# Convert format of some variables
dt_train <- convertFormatVars(dt = dt_train, 
                              factorVars = factorVars,
                              dateVars = dateVars, 
                              intVars = intVars,
                              numVars = numVars,
                              timeVars = timeVars)



#saving original values in a vector
# y_train <- dt_train$transactionRevenue

