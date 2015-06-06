clc, clear all, close all

RELOAD = true;

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
selections = [1,2,7,16,17];
data = [];
for i=selections
%     figure
%     plot(dates, rawData(:,i));
%     title(featureNames{i});
    data = [data rawData(:,i)];
end

k = 4;
idx = kmeans(data,k);



