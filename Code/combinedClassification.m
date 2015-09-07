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

% replace series data with wavelet components
wname = 'coif2';
waveletData = [];
featureCount = size(validData,2);
for col=1:featureCount
    wd = getCycleComponents(validData(:,col), wname, 0);
    waveletData = [waveletData wd];
end
validData = waveletData;

%% PMTK HMMs - can use multivariate Gaussians
cycleStarts = getCycleStarts(validLabels);
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
pctError_MVN_HMM = sum(path ~= validLabels(split+1:end)') / ...
    size(X,2)