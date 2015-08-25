clc, clear all, close all 
RELOAD = true;

%% INITIALIZE
addpath('C:\Users\j_ast_000\Documents\MATLAB\pmtk3-master');
initPmtk3
cd 'C:\cygwin\home\j_ast_000\Thesis\Code'

%% LOAD DATA and select features
% define what's happening in this csv
nLabels = 1; % how many columns at the end are class labels?
startDate = 1947.0;

if RELOAD
    rawData = csvread('../Data/masterData.csv', 2, 1);
    featureCount = size(rawData, 2)-1;
    observationCount = size(rawData, 1);
    featureNames = textread('../Data/masterData.csv', '%s', 'delimiter', ',');
    featureNames = featureNames(2:featureCount + 1);
    classLabels = rawData(:,featureCount + 1);
end

endDate = startDate + (observationCount-1)*0.25;
dates = linspace(startDate, endDate, observationCount);

% which features to use?
%selections = 1:19;
%selections = [2,7,18,19];  % NASDAQ
selections = [2,7,18,20];   % DJIA
selectedNames = featureNames(selections);
data = [];
for i=selections
%     figure
%     plot(dates, rawData(:,i));
%     title(featureNames{i});
    data = [data rawData(:,i)];
end

% see what range of dates we can use for this set of data
[d1, d2, i1, i2] = getValidDateRange(data, dates);
validData = data(i1:i2,:);
validLabels = classLabels(i1:i2);
validLabels(validLabels==1) = 0;
validLabels(validLabels==2) = 1;
rowCount = size(validData,1);

%% LEAVE ONE QUARTER OUT 
% try to figure out which features, if any, look different by class
% Features for whih the null hypothesis is rejected at 5% level:
% GNP def pct: 0.016559
% GNP real pct: 0.000000
% CPI growth: 0.000460
% Unemployment Rate pct: 0.000000
% NASDAQ pct: 0.000000

% for i=1:length(selections)
%     vals = validData(:,i);
%     groups = validLabels(:);
%     p = kruskalwallis(vals, groups, 'off');
%     name = selectedNames(i);
%     name = name{1};
%     fprintf('p val for %s: %f\n', name, p);
%     %title(name)
% end
% 
% dataSet = prtDataSetClass(data(i1:i2,:), classLabels(i1:i2));
% classifier = prtClassFld + prtDecisionMap;
% yOut = classifier.kfolds(dataSet,size(dataSet.X,1));
% %[pfFldKfolds,pdFldKfolds] = prtScoreRoc(yOut);
% %prtScoreRoc(yOut);
% prtScoreConfusionMatrix(yOut)
% prtScorePercentCorrect(yOut)

%% LEAVE ONE CYCLE OUT 
% instead of k-folds, we leave out one entire business cycle?
cycleStarts = getCycleStarts(validLabels);
weightedPctCorrect = 0;
for ind = 1:length(cycleStarts)
    if ind == length(cycleStarts)
        testInds = cycleStarts(ind):rowCount;
        trainingInds = 1:(cycleStarts(ind)-1);
    else
        testInds = cycleStarts(ind):(cycleStarts(ind+1)-1);
        trainingInds = [1:(cycleStarts(ind)-1) (cycleStarts(ind+1)):rowCount];
    end
    trainDS = prtDataSetClass(validData(trainingInds,:), ...
        validLabels(trainingInds));
    testDS = prtDataSetClass(validData(testInds,:), ...
        validLabels(testInds));
    classifier = prtClassFld + prtDecisionMap;
    classifier = classifier.train(trainDS);
    classified = run(classifier, testDS);
    pct = prtScorePercentCorrect(classified);
    weightedPctCorrect = weightedPctCorrect + length(testInds)*pct;
end
pctCorrect = weightedPctCorrect / rowCount;

%% TRAIN ON FULL DATA SET 
ds = prtDataSetClass(validData, validLabels);

%% WAVELETS
% goal is to separate long term trend, cyclical component(s), and high
% frequency noise using multiresolution wavelet analysis
% Baxter and King define the following: 
% Long-term trend -- periodicity > 32 quarters
% Business cycle -- periodicity 4-32 quarters
% High frequency noise -- periodicity > 32 quarters

% reproduce wavelet filter bank on real GNP
gnp = rawData(:,5);
[y1, y2, i1, i2] = getValidDateRange(gnp, dates);
gnpDates = dates(i1:i2);
gnp = gnp(i1:i2);
gnpLabels = classLabels(i1:i2) - 1;
[conStarts, conEnds] = getContractionDates(gnpLabels);

% Perform subsequent single-level wavelet decompositions
% Yogo suggest 17/11 filter -> doiflet with N=2
wname = 'coif2';
[a0, d0] = dwt(gnp, wname);
[a1, d1] = dwt(a0, wname);
[a2, d2] = dwt(a1, wname);
[a3, d3] = dwt(a2, wname);

% since these filtered components are all critically sampled, interpolate
% to restore the correct magnitude and number of points
originalLength = size(gnp, 1);
cycle_4_8 = upcoef('d', d1, wname, 2, originalLength);
cycle_8_16 = upcoef('d', d2, wname, 3, originalLength);
cycle_16_32 = upcoef('d', d3, wname, 4, originalLength);
trend = upcoef('a', a3, wname, 4, originalLength);

figure
plot(gnpDates, gnp, 'linewidth', 1)
hold on
plot(gnpDates, trend, 'g')
plot(gnpDates, cycle_4_8, 'r')
plot(gnpDates, cycle_8_16, 'k')
plot(gnpDates, cycle_16_32, 'c')

legend('GNP', 'trend', '4-8 quarter cycle', '8-16 quarter cycle', '16-32 quarter cycle')
xlabel('Year')
ylabel('Billions of Chained 2009 Dollars')
axis([1946 2015 -1000 18000])
hold off


