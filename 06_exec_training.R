

# ---- Load Processed data ----
dt_train <- as.data.table(read.csv('train_set_processed.csv'))
dt_test <- as.data.table(read.csv('test_set_processed.csv'))

# ---- Splitting Train and Validation ---- 
dt_train[, index := 1:.N]
cat(paste0("Splitting Date between Train and Validation :",
           dt_train[index == round(nrow(dt_train)*0.8,0), date]))
# Train 80%, Val 20% 
valDate <- as.Date("2017-06-01")
train <- dt_train[date < valDate]
val <- dt_train[date >= valDate]

# ---- Data Processing ---- 
# Transform the target to the suitable format for this project
trainTarget <- log1p(train$transactionRevenue)
train[, transactionRevenue := NULL]
valTarget <- log1p(val$transactionRevenue)
val[, transactionRevenue := NULL]
