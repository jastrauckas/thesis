clc, clear all, close all 
RELOAD = true;

%% LOAD DATA and select features
% define what's happening in this csv
nLabels = 1; % how many columns at the end are class labels?
startDate = 1947.0;

if RELOAD
    rawData = csvread('../Data/masterData.csv', 3, 1);
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
selections = [2,7,18,19];
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

%% attempt HMM
ds_contraction = prtDataSetClass(ds.getObservationsByClass(0));
rv_contraction = prtRvMvn;
rv_contraction = rv_contraction.mle(ds_contraction.getX);
ds_expansion = prtDataSetClass(ds.getObservationsByClass(1));
rv_expansion = prtRvMvn;
rv_expansion = rv_expansion.mle(ds_expansion.getX);  
nStates = 2;
gaussians = [rv_contraction; rv_expansion];
trGuess = repmat(1/nStates, nStates, nStates);
emitGuess = repmat(1/nStates, 1, nStates);

%% Maybe try this using stats toolbox instead?
seq = validData;
[transProbs,emitProbs] = hmmtrain(seq,trGuess,emitGuess);