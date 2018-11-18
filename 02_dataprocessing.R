jsonToDt <- function(dt){
  
  json_device <- paste("[", paste(dt$device, collapse = ","), "]")
  dt_device <- as.data.table(jsonlite::fromJSON(txt = json_device,
                                      flatten = T))
  
  json_geoNetwork <- paste("[", paste(dt$geoNetwork, collapse = ","), "]")
  dt_geoNetwork <- as.data.table(jsonlite::fromJSON(txt = json_geoNetwork,
                                      flatten = T))
  
  json_totals <- paste("[", paste(dt$totals, collapse = ","), "]")
  dt_totals <- as.data.table(jsonlite::fromJSON(txt = json_totals,
                                          flatten = T))
    
  json_trafficSource <- paste("[", paste(dt$trafficSource, collapse = ","), "]")
  dt_trafficSource <- as.data.table(jsonlite::fromJSON(txt = json_trafficSource,
                                      flatten = T))
    
  dt[, ':='(device = NULL, 
            geoNetwork = NULL,
            totals = NULL,
            trafficSource = NULL)]
  
  dt <- cbind(dt,
              dt_device, 
              dt_geoNetwork,
              dt_totals,
              dt_trafficSource)  
  
  return(dt)
}

convertFormatVars <- function(dt, 
                              factorVars = NULL,
                              dateVars = NULL,
                              intVars = NULL,
                              numVars = NULL,
                              timeVars = NULL) {
  

  if (!is.null(factorVars)) {
    # Converting some character variables into factors
    dt[, (factorVars) := lapply(.SD, as.factor), .SDcols = factorVars]
  }
  
  if (!is.null(dateVars)) {
    # Converting the data variable to the date format
    dt[, (dateVars) := lapply(.SD, ymd), .SDcols = dateVars]
  }

  if (!is.null(numVars)) {
    # First, we need to convert transactionRevenue to numeric
    # as it takes values greater than 1e9, integers can't convert them 
    dt[, (numVars) := lapply(.SD, as.numeric), .SDcols = numVars]
  }
  
  if (!is.null(intVars)) {
    # Converting character variables into integer
    dt[, (intVars) := lapply(.SD, as.integer), .SDcols = intVars]
  }
  
  if (!is.null(timeVars)) {
    
    # converting visit start times to POSIXct
    dt[, (timeVars) := lapply(.SD, funDate),
       .SDcols = timeVars]
  }

# just making sure that format is still data.table
dt <- as.data.table(dt)

return(dt)

}

addVarsTime <- function(dt) {
  
  # New variables relating to time
  # new variable from the Date variable with the wday function of lubridate
  dt[, weekday := wday(date)]
  # new variable: month
  dt[ , month := month(date) ]

  return(dt)
}

featureExtraction <- function(dt) {
  
  varsDtOrig <- copy(colnames(dt))
  
  # Source/Medium is a dimension that combines the dimensions Source and Medium.
  # It is very interesting to see if any of these combinations (e.g. Google/organic,...)
  # is the source/medium with most revenues and, on the other hand, which of those
  # generate a lot of traffic without deliverying high revenues
  dt[, sourceMedium := paste(source, medium, sep="/")]
  #options(repr.plot.height=4)
  #sm1 <- plotSessions(dt, "sourceMedium", topN = 20) 
  #sm2 <- plotRevenue(dt, "sourceMedium", topN = 20) 
  #grid.arrange(sm1, sm2)
  
  printChangeFeatures(dt, varsDtOrig)
    
  return(dt)
  
}

dataProcessing <- function(dt, set = 'train', listVarsToKeep = NULL) {

  varsDtOrig <- copy(colnames(dt))
  
  if (set == 'train') {
    
    # Target Variable: transactionRevenue
    # setting missing values to zero
    dt[ is.na(transactionRevenue), transactionRevenue := as.numeric(0) ]
    
    # ------- Treatment of Missing Values --------
    dtMissings <- countMissings(dt)
    # All those variables with more than 95% of missings are discarded
    varsMissing <- unique(dtMissings[ PctMissing > 95, variable])
    dt[, (varsMissing) := NULL]
    gc() 
  
    # ------------- 1 unique value ---------------
    only1Value <- colnames(dt)[apply(dt, 2, function(x) length(unique(x))) == 1]
    # These variables have only 1 unique value, hence can be removed
    dt[, (only1Value) := NULL]
    gc()
    
  } else if (set == 'test') {
    dt <- as.data.table(dt[, listVarsToKeep, with = FALSE])
  }
  
  # ------- Treatment of Missing Values --------
  # There are variable whose missings mean something, and others where missings
  # represent simply the majority of the observations, which implies that the variable
  # doesn't add any relevant information for the problem at hand
  dt <- changeOrDeleteMissings(dt)
  
  printChangeFeatures(dt, varsDtOrig)
  
  return(dt)

}

changeOrDeleteMissings <- function(dt) {

  # -- isTrueDirect -- 
  cat("Number of isTrueDirect categories: ", length(unique(dt[, isTrueDirect])), " \n")
  # isTrueDirect has 70% Missings and the others are TRUE --> NA should be False then?
  dt[is.na(isTrueDirect), isTrueDirect := FALSE]
  # Change from boolean to dummy variable
  dt[, isTrueDirect_aux := ifelse(isTrueDirect, as.integer(1), as.integer(0))]
  dt[, isTrueDirect := NULL]
  setnames(dt, "isTrueDirect_aux", "isTrueDirect")

  # -- Referral Path -- 
  cat("Number of referralPath categories: ", length(unique(dt[, referralPath])), " \n")
  # There are 1476 different categories, we must narrow them down to only a few
  totRevs <- sum(dt[, transactionRevenue]/1e6)
  dtRef <- dt[,.(n = .N,
                 pct_sess  = .N*100/nrow(dt_train),
                rev = sum(transactionRevenue/1e6),
                pct_rev = sum(transactionRevenue/1e6)*100 /totRevs), 
                .(referralPath)][order(-pct_rev)]
  # NA and '/' account for 97% of revenues, we can get rid of this variable
  dt[, referralPath := NULL]

  # -- Keyword --
  cat("Number of keyword categories: ", length(unique(dt[, keyword])), " \n")
  dtKeyword <- dt[,.(n = .N,
                     pct_sess  = .N*100/nrow(dt_train),
                     rev = sum(transactionRevenue/1e6),
                     pct_rev = sum(transactionRevenue/1e6)*100 /totRevs),
                      .(keyword)][order(-pct_rev)]
  # Same as Referral, NA and '/' account for 96% of revenues, we can get rid of this variable
  dt[, keyword := NULL]

  # -- Bounces --
  cat("Number of bounces categories: ", length(unique(dt[, bounces])), " \n")
  dtBounces <- dt[,.(n = .N,
                     pct_sess  = .N*100/nrow(dt_train),
                     rev = sum(transactionRevenue/1e6),
                     pct_rev = sum(transactionRevenue/1e6)*100 /totRevs), 
                    .(bounces)][order(-pct_rev)]
  # When there is a bounce, there is no revenue
  dtBounces <- dt[,.(n = .N,
                     pct_sess  = .N*100/nrow(dt_train),
                     rev = sum(transactionRevenue/1e6),
                     pct_rev = sum(transactionRevenue/1e6)*100 /totRevs), 
                     .(bounces)][order(-pct_rev)]
  dt[ is.na(bounces), bounces := as.integer(0)]
  dt[, bounces := as.integer(bounces)]

  # -- New Visits --
  cat("Number of newVisits categories: ", length(unique(dt[, newVisits])), " \n")
  dtNV <- dt[,.(n = .N,
                pct_sess  = .N*100/nrow(dt_train),
                rev = sum(transactionRevenue/1e6),
                pct_rev = sum(transactionRevenue/1e6)*100 /totRevs), 
                .(newVisits)][order(-pct_rev)]

  dt[is.na(newVisits), newVisits := as.integer(0)]
  dt[, newVisits := as.integer(newVisits)]

  # -- Page Views --
  cat("Number of pageviews categories: ", length(unique(dt[, pageviews])), " \n")
  # Let's see if the pageViews missing generate revenues
  dtPV <- dt[,.(n = .N,
                pct_sess  = .N*100/nrow(dt_train),
                rev = sum(transactionRevenue/1e6),
                pct_rev = sum(transactionRevenue/1e6)*100 /totRevs), .(pageviews)][order(-pct_rev)]
  #dtPV[is.na(pageviews) | pageviews < 10]
  # No revenues are generated when pageviews is missing --> we will consider missing as if it was 1
  dt[is.na(pageviews), pageviews := 1]
  dt[, pageviews := as.integer(pageviews)]

 # treat values that mean nothing
 # is_na_val <- function(x) x %in% c("not available in demo dataset", "(not provided)",
 #                                  "(not set)", "<NA>", "unknown.unknown",  "(none)")

 return(dt)

}

printChangeFeatures <- function(dt, varsDtOrig){
  
  if (length(colnames(dt)) != length(varsDtOrig)) {
    
    if (length(colnames(dt)) > length(varsDtOrig)) {
      newFeats <- colnames(dt)[!colnames(dt) %in% varsDtOrig]
    } else {
      newFeats <- varsDtOrig[!varsDtOrig %in% colnames(dt)]
    }
    cat("New or Old Features: ", paste0(newFeats, sep = "-"))
  }
}

funDate <- function(x) {
  as.Date(strptime(x, format = '%Y%m%d'))
}