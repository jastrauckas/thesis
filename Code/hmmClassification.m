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
%selections = [2,7,18,19];  % NASDAQ = BEST
%selections = [2,7,18,20];   % DJIA
selections = [5,18];
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
% Need to bin emission values and compute by hand the ML estimates for the 
% transition and emission matrix. Probably want roughly the same amount of
% data in each bin

%% dicretize the data 
% CAIM isn't really working, sadly 
%C = 1; % one class label
%[discData,discSet] = CAIM_Discretization(origData,C);

% discData = zeros(size(validData));
% n = 8;
% for c = 1:size(validData, 2)
%     col = validData(:,c);
%     maxVal = max(col);
%     minVal = min(col);
%     edges = linspace(minVal, maxVal, n);
%     discCol = discretize(col, edges);
%     discData(:,c) = discCol;
% end

%% make ML estimates of transition and emission matrices

% % Make the transition matrix
% obsCount = size(validLabels, 1);
% transitionMatrix = zeros(2,2);
% for n = 1:obsCount-1
%     currLabel = validLabels(n);
%     nextLabel = validLabels(n+1);
%     if currLabel == 0 && nextLabel == 0 
%         transitionMatrix(1,1) = transitionMatrix(1,1) + 1;
%     elseif currLabel == 0 && nextLabel == 1
%         transitionMatrix(1,2) = transitionMatrix(1,2) + 1;
%     elseif currLabel == 1 && nextLabel == 1
%         transitionMatrix(2,2) = transitionMatrix(2,2) + 1;
%     elseif currLabel == 1 && nextLabel == 0
%         transitionMatrix(2,1) = transitionMatrix(2,1) + 1;
%     end
% end
% transitionMatrix = transitionMatrix/size(validData,1);
% 
% % Make the emissions matrix 
% % for now, just use feature 1
% featNum = 1;
% emissionMatrix = zeros(2,n-1);
% for r = 1:size(discData, featNum)
%     emission = discData(r, featNum);
%     class = validLabels(r);
%     emissionMatrix(class+1,emission) = emissionMatrix(class+1,emission)+1;
% end
% % each row should sum to 1
% emissionMatrix(1,:) = emissionMatrix(1,:)/sum(emissionMatrix(1,:));
% emissionMatrix(2,:) = emissionMatrix(2,:)/sum(emissionMatrix(2,:));
% 
% %% Now that we have the hmm model, see how well it performs
% % for now, this is totally incest
% states = hmmviterbi(discData(:,featNum), transitionMatrix, emissionMatrix);
% states = states-1;
% states = ~states;
% pctError_1D_HMM = sum(states' == validLabels) / size(states,2); % reverse labels
% % this *kind of* worked with one variable, so let's consider a better HMM
% % model

%% PMTK HMMs - can use multivariate Gaussians
d = size(validData, 2);
nstates = 2;
Z = {validLabels' + 1};
Y = {validData'};
X = Y{1}; % I'm the worst 
model2 = hmmFitFullyObs(Z, Y, 'gauss');

% use Viterbi to predict state sequence
path = hmmMap(model2, X) - 1;
pctError_MVN_HMM = sum(path ~= validLabels') / size(validLabels,1)

% now, without incest!
targetIndex = 5 * round(size(validLabels, 1) / 8);
while validLabels(targetIndex) ~= validLabels(1)
    targetIndex = targetIndex + 1;
end
split = targetIndex;

Z = {validLabels(1:targetIndex)' + 1};
Y = {validData(1:targetIndex,:)'};
X = validData(targetIndex+1:end,:)';
model3 = hmmFitFullyObs(Z, Y, 'gauss');

% use Viterbi to predict state sequence
path = hmmMap(model3, X) - 1;
pctError_MVN_HMM = sum(path ~= validLabels(targetIndex+1:end)') / ...
    size(X,2)