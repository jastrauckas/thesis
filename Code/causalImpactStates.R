library("ggplot2")
library("reshape2")
library("CausalImpact")

expenditure_csv <- "C:/cygwin/home/j_ast_000/Thesis/Data/expenditure_real2012_percapita.csv"
stateGDP_csv <- "C:/cygwin/home/j_ast_000/Thesis/Data/gdpByState_ALL_realChainedPct.csv"

expenditureData = read.csv(expenditure_csv, sep=',')
stateGDPData = read.csv(stateGDP_csv, sep=',')
stateGDPm = as.matrix(stateGDPData)
stateGDPm <- stateGDPm[,-1]

# GDP BY STATE
stateNames <- as.vector(stateGDPData[,1])
rownames(stateGDPData) <- stateNames
stateGDPData <- stateGDPData[,-1]
gdpYears <- seq(1988, 2014)
colnames(stateGDPData) <- gdpYears
rownames(stateGDPData) <- stateNames
#plot(gdpYears, stateGDPData["Alabama",], type="l")
x1 <- stateGDPm[1,] # Alabama
x2 <- stateGDPm[2,] # Alaska
x <- cbind(x1, x2)
matplot(x, type="l")

# EXPENDITURE BY STATE
#win.graph() 
colnames(expenditureData) <- c("State", "Year", "Total Revenue", "Total Expenditure", "Expenditure Percent Change")
alaskaSpending <- subset(expenditureData, State=="Alaska")
alabamaSpending <- subset(expenditureData, State=="Alabama")
spending <- cbind(alabamaSpending["Total Expenditure"], alaskaSpending["Total Expenditure"])
spending <- as.matrix(spending)
matplot(spending, type="l")

# look for anomalous spending spikes during a recession
spendingYears <- seq(1978, 2012)
commonYears <- seq(1988, 2012)
yearCount <- length(spendingYears)
stateCount <- length(stateNames)
allStateExpenditures <- matrix(, nrow = yearCount, ncol = stateCount)
for (i in 1:stateCount)
{
  stateName <- stateNames[i]
  stateSpending <- subset(expenditureData, State==stateName)
  #df <- stateSpending["Total Expenditure"]
  df <- stateSpending["Expenditure Percent Change"]
  spendingCol <- as.matrix(df)[,1]
  allStateExpenditures[,i] <- spendingCol
}
colnames(allStateExpenditures) <- stateNames
matplot(spendingYears, allStateExpenditures, type="l")
#hist(allStateExpenditures) # looks pretty normal
flatSpending <- as.vector(allStateExpenditures)
mu <- mean(flatSpending) # 2.04
sigma <- sqrt(var(flatSpending)) # 4.47

# define "high spending increase" as at least one standard deviation above average
bigIncrease <- mu + sigma

# look for states that had a big spending increase DURING A RECESSION
# taken from NBER data
# include any year that included at least 6 months of contraction
#contractionYears <- c(1980, 1981, 1982, 1990, 2001, 2008, 2009)
# we only have GDP data since 1988, though
# and we need to have an intervention point that contains at least some training
# and test data
contractionYears <- c(2001, 2008, 2009)

bigSpenders <- list()
for (i in 1:stateCount)
{
  stateName <- stateNames[i]
  #print(stateName)
  stateSpending <- allStateExpenditures[,i]
  for (y in 1:length(contractionYears))
  {
    year = contractionYears[y]
    yearIndex = year - spendingYears[1]
    #print(stateSpending[yearIndex])
    if (stateSpending[yearIndex] > bigIncrease)
    {
      if (!(stateName %in% names(bigSpenders)))
      {
        bigSpenders[stateName] = year
      }
    }
  }
}
#print(bigSpenders)

# iterate through once more to find states that weren't added to bigSpenders
# these states will serve as controls
controlStates <- list()
for (i in 1:stateCount)
{
  stateName <- stateNames[i]
  if (!(stateName %in% names(bigSpenders)))
  {
    controlStates[stateName] <- TRUE
  }
}

# create control matrix representing spending series for all control states
controlStateCount = length(controlStates)
controlStateExpenditures <- matrix(, nrow = yearCount, ncol = controlStateCount)
controlStateGDPs <- matrix(, nrow = length(gdpYears), ncol = controlStateCount)
i = 0
for (state in names(controlStates))
{
  i <- i+1
  spendingCol <- allStateExpenditures[,state]
  controlStateExpenditures[,i] <- spendingCol
  gdpCol <- t(stateGDPData[state,])
  controlStateGDPs[,i] <- gdpCol
}
colnames(controlStateExpenditures) <- names(controlStates)

# one at a time for the states with "stimulus spending", 
# x is spending time series
# intervention is the year marked in bigSpenders
# y is the gdp time series, and the gdp time series of all states
# in the control group. 
for (state in names(bigSpenders))
{
  print(state)
  rowCount <- length(commonYears)
  colCount <- 1+length(controlStates)
  dataMatrix <- matrix(, nrow = rowCount, ncol = colCount)
  interventionYear <- bigSpenders[[state]]
  print(interventionYear)
  stateSpending <- allStateExpenditures[,state]
  
  # put together the response variable (y)
  # and the control series (x1, ... xn)
  # from the GDP DATA, using the intervention years
  # determined from the expenditure data
  # need a matrix where y is the first column vector
  # x1, x2, ... xn are subsequent column vectors
  extraYears <- tail(gdpYears, 1) - tail(spendingYears, 1)
  stateGDP <- stateGDPData[state, ]
  lastIndex <- length(stateGDP) - extraYears
  stateGDP <- stateGDP[1:lastIndex]
  
  # RESPONSE VARIABLE (y)
  dataMatrix[,1] <- as.matrix(stateGDP)
  
  # CONTROL VARIABLES (x)
  dataMatrix[,2:colCount] <- controlStateGDPs[1:lastIndex,]
  
  # labels
  cn <- c("y", "x1","x2","x3","x4","x5","x6","x7","x8","x9","x10","x11","x12","x13","x14","x15","x16","x17","x18","x19","x20","x21","x22","x23","x24","x25","x26","x27","x28", "x29", "x30", "x31")
  colnames(dataMatrix) <- cn
  
  matplot(dataMatrix, type='l')
  
  # TRAINING/TESTING POINTS
  firstYear <- head(commonYears, 1)
  finalYear <- tail(commonYears, 1)
  intervention <- interventionYear - firstYear
  pre.period <- c(1, intervention-1)
  post.period <- c(intervention, finalYear-firstYear)
  
  # INFERENCE
  impact <- CausalImpact(dataMatrix, pre.period, post.period)
  plot(impact)
}







