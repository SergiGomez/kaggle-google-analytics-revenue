noJsonVars <- c('channelGrouping', 'date', 'fullVisitorId',
                'sessionId', 'socialEngagementType', 'visitId', 'visitNumber',
                'visitStartTime')
jsonVars <- c("device", "geoNetwork","totals",
              "trafficSource")

dt_train <- as.data.table(dt_train[, noJsonVars, with = FALSE])
head(dt_no_json)
describe(dt_no_json)
summary(dt_no_json)
