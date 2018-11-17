
basicEda <- function(dt, plotEDA = FALSE) {
  
  # correcting transaction revenues, for EDA purposes only
  dt[ , transactionRevenue := transactionRevenue/1e6 ]
  
  # SessionId should be the unique identifier for each observation
  length(unique(dt$sessionId)) == nrow(dt)
  # Check for duplicates in sessionId
  dtSess <- dt[,.(n = .N), .(sessionId)]
  dtSess[ n > 1]
  # Will maybe need to remove duplicate sessions
  
  if (plotEDA) {
    plotNA <- ggplot(NADT,
                     aes(x=reorder(variable, PctMissing), y=PctMissing)) +
      geom_bar(stat='identity', fill='blue') + coord_flip(y=c(0,110)) +
      labs(x="", y="Percent missing") +
      geom_text(aes(label=paste0(NADT$PctMissing, "%"), hjust=-0.1))
    print(plotNA)
  }
  
  # Distribution of the target variable (when it's not zero)
  summary(dt$transactionRevenue[dt$transactionRevenue > 0])
  nrow(dt[ transactionRevenue > 1000]) / nrow(dt[ transactionRevenue > 0])
  # As the distribution of revenues is very right skewed, with the tail reaching 23,000 USD, 
  # below we only displaying the histogram of the transaction with revenues below 1,000 USD.
  if (plotEDA) {
    dt_hist <- dt[transactionRevenue > 0 & transactionRevenue < 1000]
    plotHist <- ggplot(dt_hist, 
                       aes(x=transactionRevenue)) +
      geom_histogram(fill="blue", binwidth=10) +
      scale_x_continuous(breaks= seq(0, 1000, by=100))
    print(plotHist)
  }
  
  # how much time do we have of training data?
  summary(dt$date)
  
  # ---- Time Series Analysis ------
  timeSeriesAnalysis(dt_train, plotEDA = plotEDA)
  
  # ---- Sessions and Revenue Plots ------
  sessAndRevPlots(dt_train, plotEDA = plotEDA)

  # bring the value back for transaction revenues
  dt[ , transactionRevenue := transactionRevenue*1e6 ]
  
}

timeSeriesAnalysis <- function(dt, plotEDA = FALSE) {
  
  # Definition of Time Series table
  ts_sess <- dt[,.(num_sess = .N), .(date)]
  ts_rev <- dt[,.(revenue = sum(transactionRevenue)), .(date)]
  
  if (plotEDA) {
    options(repr.plot.height=6)
    
    plotSess <- ggplot(ts_sess, 
                       aes(x=date, y=num_sess)) + geom_line(col='blue') +
                   # scale_y_continuous(labels=comma) + 
                  geom_smooth(col='red') +
      labs(x="", y="Sessions per Day") + scale_x_date(date_breaks = "1 month",
                                                      date_labels = "%b %d")
  
    plotRev <- ggplot(ts_rev, 
                       aes(x=date, y=revenue)) + geom_line(col='blue') +
      # scale_y_continuous(labels=comma) + 
      geom_smooth(col='red') +
      labs(x="", y="Revenue per Day") + scale_x_date(date_breaks = "1 month",
                                                      date_labels = "%b %d")
    
    grid.arrange(plotSess,plotRev)
    
  }
  

}

plotSessions <- function(dt, factorVariable, topN = NULL) {
  
  dtSess <- dt[, .(n = .N), by = factorVariable]  
  
  setorder(dtSess, -n)
  if (!is.null(topN)) dtSess <- head(dtSess, topN)
  
  plotSess <- ggplot(data = dtSess,
                     aes_string(x = factorVariable,
                         y = "n",
                         fill = factorVariable)) + 
                     geom_bar(stat = 'identity') +
                     labs(x="", y="number of sessions") +
                     theme(legend.position="none",
                           axis.text.x = element_text(angle = 90, hjust = 1)) 
                      
    return(plotSess)
}

# function to plot transactionRevenue for a factorvariable
plotRevenue <- function(dt, factorVariable, topN = NULL) {
  
  dtRev <- dt[, .(rev = sum(transactionRevenue)), by = factorVariable]  
  
  setorder(dtRev, -rev)
  if (!is.null(topN)) dtRev <- head(dtRev, topN)
  
  plotRev <- ggplot(data = dtRev,
                     aes_string(x = factorVariable,
                                y = "rev",
                                fill = factorVariable)) + 
    geom_bar(stat = 'identity') +
    labs(x="", y="Revenues (USD)") +
    theme(legend.position="none", 
          axis.text.x = element_text(angle = 90, hjust = 1))
  
  return(plotRev)

}

sessAndRevPlots <- function(dt, plotEDA = TRUE) {
  
  # correcting transaction revenues, for EDA purposes only
  dt[ , transactionRevenue := transactionRevenue/1e6 ]
  
  options(repr.plot.height=4)
  w1 <- plotSessions(dt, "weekday")
  w2 <- plotRevenue(dt, "weekday")
  grid.arrange(w1, w2)
  
  m1 <- plotSessions(dt, "month")
  m2 <- plotRevenue(dt, "month")
  grid.arrange(m1, m2)
  
  ch1 <- plotSessions(dt, "channelGrouping") 
  ch2 <- plotRevenue(dt, "channelGrouping") 
  grid.arrange(ch1, ch2)
  
  d1 <- plotSessions(dt, "deviceCategory")
  d2 <- plotRevenue(dt, "deviceCategory")
  grid.arrange(d1, d2)
  
  os1 <- plotSessions(dt, "operatingSystem", topN = 20)
  os2 <- plotRevenue(dt, "operatingSystem", topN = 20)
  grid.arrange(os1, os2)
  
  br1 <- plotSessions(dt, "browser", topN = 10)
  br2 <- plotRevenue(dt, "browser", topN = 10)
  grid.arrange(br1, br2)
 
  # bring the value back for transaction revenues
  dt[ , transactionRevenue := transactionRevenue*1e6 ] 
}

countMissings <- function(dt) {
  
  # Missing data 
  NAcol <- which(colSums(is.na(dt)) > 0)
  NAcount <- sort(colSums(sapply(dt[, NAcol, with = F], is.na)),
                  decreasing = TRUE)
  NADT <- data.table(variable = names(NAcount),
                     missing= as.integer(NAcount))
  NADT[, PctMissing := round(missing*100/nrow(dt),3)] 
  
  return(NADT)
}