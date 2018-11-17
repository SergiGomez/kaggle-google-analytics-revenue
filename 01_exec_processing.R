source("00_init.R")

# ---- Load Raw data ----
dt_train <- as.data.table(read.csv(paste0(path.data,'train.csv')))
dt_test <- as.data.table(read.csv(paste0(path.data,'test.csv')))

# ---- Data Pre-processing ----
dt_train <- jsonToDt(dt_train)
dt_test <- jsonToDt(dt_test)
dt_train <- convertFormatVars(dt = dt_train,
                              timeVars = 'date')
dt_test <- convertFormatVars(dt = dt_test,
                              timeVars = 'date')
# Add only those variables that will be needed for EDA
dt_train <- addVarsTime(dt_train)
dt_test <- addVarsTime(dt_test)

# ---- Exploratory Data Analysis ----
basicEda(dt_train, plotEDA = TRUE)
basicEda(dt_test, plotEDA = TRUE)

# ---- Feature Engineering ----
dt_train <- featureExtraction(dt_train)
dt_test <- featureExtraction(dt_test)

# ---- Data Processing ----
dt_train <- dataProcessing(dt_train)
dt_test <- dataProcessing(dt_test)

write.csv(dt_train,'train_set_processed.csv')
write.csv(dt_test,'test_set_processed.csv')


# Restore target to its natural value 
dt_train[, transactionRevenue := transactionRevenue*1000000]

# Order by date
setorder(dt_train, date) 

# changing fullvisitorid to normal number
dtVisitorID <- data.table(fullVisitorId  = unique(dt_train$fullVisitorId))
dtVisitorID[, visitorId := 1:.N]
dt_train <- merge(dt_train,
                  dtVisitorID, 
                  by = "fullVisitorId",
                  all.x = TRUE)
dt_train[, fullVisitorId := NULL]


apply(dt_train, 2, function(x) length(unique(x)))

dtNetDomain <- dt_train[,.(n = .N,
                           pct_sess  = .N*100/nrow(dt_train),
                           rev = sum(transactionRevenue/1e6),
                           pct_rev = sum(transactionRevenue/1e6)*100 /totRevs), .(networkDomain)][order(-pct_rev)]
dtNetDomain[pct_rev > 0.5]
