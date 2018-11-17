

# keeping vector of categorical features for LGB
categorical_feature <- names(Filter(is.factor, train))

#Label encoding
all <- all %>% 
  mutate_if(is.factor, as.integer) %>% 
  glimpse()

set.seed(123)

lgb.train = lgb.Dataset(data = as.matrix(train),
						label = trainLabel, 
						categorical_feature = categorical_feature)

lgb.val = lgb.Dataset( data = as.matrix(val),
	                     label = valLabel, 
	                     categorical_feature = categorical_feature)

params <- list(objective="regression",
               metric="rmse",
               learning_rate=0.01)

# Training
lgb.model <- lgb.train(params = params,
                       data = lgb.train,
                       valids = list(val = lgb.val),
                       learning_rate=0.01,
                       nrounds=1000,
                       verbose=1,
                       early_stopping_rounds=50,
                       eval_freq=100
                      )

tree_imp <- lgb.importance(lgb.model, percentage = TRUE)
 lgb.plot.importance(tree_imp, top_n = 50, measure = "Gain")

 # Prediction over test
 pred <- predict(lgb.model, as.matrix(test))
 setnames(pred, "XXXX", "y")
 pred[, y := expm1(y)]
 pred[ y < 0, y := 0]

 # Prepare submission 
 submission <- as.data.table(read_csv("../input/sample_submission.csv"))
 submission <- merge(submission, pred, by = 'fullVisitorId', all.x = TRUE)
 submission[, PredictedLogRevenue := round(y, 5)]
 submission[, y := NULL]
 #write_csv(paste0("Lightgbm",round(lgb.model$best_score,5),".csv"))