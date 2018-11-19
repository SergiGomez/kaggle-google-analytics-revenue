source("00_init.R")

# ---- Load Raw data ----
dt_train <- as.data.table(read.csv(paste0(path.data,'train.csv')))
dt_test <- as.data.table(read.csv(paste0(path.data,'test.csv')))

# ---- Data Pre-processing ----
dt_train <- jsonToDt(dt_train)
dt_test <- jsonToDt(dt_test)

dt_train_orig <- copy(dt_train)

dt_train <- convertFormatVars(dt = dt_train,
                              numVars = 'transactionRevenue',
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

# Order by date
setorder(dt_train, date) 

# --- sampling to reduce memory usage ---
set.seed(123)
dt_train_sample <- dt_train[, .SD[sample(.N, round(.N*0.1))]]

dt_train_sample[, set := sample(c(1,0), size = nrow(dt_train_sample),
                                   replace = TRUE,prob = c(0.8,0.2))]

dt_train_processed <- dt_train_sample[set == 1] [, set := NULL]
dt_test_processed <- dt_train_sample[set == 0] [, set := NULL]

write.csv(dt_train_processed,'train_set_processed.csv')
write.csv(dt_test_processed,'test_set_processed.csv')



