library("ggplot2")
library("reshape2")

expenditure_csv <- "C:/cygwin/home/j_ast_000/Thesis/Data/expenditure_real2012_percapita.csv"
stateGDP_csv <- "C:/cygwin/home/j_ast_000/Thesis/Data/gdpByState_ALL_realChainedPct.csv"

expenditureData = read.csv(expenditure_csv, sep=',')
stateGDP = read.csv(stateGDP_csv, sep=',')
stateGDPm = as.matrix(stateGDP)
stateGDPm <- stateGDPm[,-1]

# GDP BY STATE
stateNames <- stateGDP[,1]
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
yearCount <- 35
stateCount <- length(stateNames)
allStateExpenditures <- matrix(, nrow = yearCount, ncol = stateCount)
for (i in 0:stateCount)
{
  stateName <- stateNames[i]
  print(stateName)
  stateSpending <- subset(expenditureData, State==stateName)
  df <- stateSpending["Total Expenditure"]
  spendingCol <- as.matrix(df)[,1]
  print(length(spendingCol))
  allStateExpenditures[,i] <- spendingCol
}
matplot(allStateExpenditures, type="l")






