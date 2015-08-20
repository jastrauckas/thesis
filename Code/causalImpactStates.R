library("ggplot2")
library("reshape2")

expenditure_csv <- "C:/cygwin/home/j_ast_000/Thesis/Data/expenditure_real2012_percapita.csv"
stateGDP_csv <- "C:/cygwin/home/j_ast_000/Thesis/Data/gdpByState_ALL_realChainedPct.csv"

expenditureData = read.csv(expenditure_csv, sep=',')
stateGDP = read.csv(stateGDP_csv, sep=',')
stateGDPm = as.matrix(stateGDP)
stateGDPm <- stateGDPm[,-1]

# GDP BY STATE
stateNames <- as.vector(stateGDP[,1])
rownames(stateGDP) <- stateNames
stateGDP <- stateGDP[,-1]
years <- seq(1988, 2014)
colnames(stateGDP) <- years
#plot(years, stateGDP["Alabama",], type="l")
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
contractionYears <- c(1980, 1981, 1982, 1990, 2001, 2008, 2009)
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
i <- 0
for (state in names(controlStates))
{
  i <- i+1
  spendingCol <- allStateExpenditures[,state]
  controlStateExpenditures[,i] <- spendingCol
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
  interventionYear <- bigSpenders[[state]]
  print(interventionYear)
  stateSpending <- allStateExpenditures[,state]
  
}







