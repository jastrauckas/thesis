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

%% WAVELET DECOMPOSITION
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
% Yogo suggest 17/11 filter -> coiflet with N=2
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
plot(gnpDates, gnp, 'k', 'linewidth', 1)
hold on
plot(gnpDates, trend, 'b')
plot(gnpDates, cycle_4_8, 'g')
plot(gnpDates, cycle_8_16, 'm')
plot(gnpDates, cycle_16_32, 'r')

legend('GNP', 'trend', '4-8 quarter cycle', '8-16 quarter cycle', '16-32 quarter cycle')
xlabel('Year')
ylabel('Billions of Chained 2009 Dollars')

ymin = -1000;
ymax = 18000;
axis([1946 2015 ymin ymax])
ymid = ((ymax-ymin)/2) + ymin;
yheight = (ymax-ymin);
for ind = 1:size(conStarts, 2)
    first = gnpDates(conStarts(ind));
    last = gnpDates(conEnds(ind));
    duration = last-first;
    center = (duration/2) + first;
    %rectangle('Position', [center, ymin, duration, yheight])
    p = patch([first last last first], [ymin ymin ymax ymax], 'c');
    set(p,'FaceAlpha',0.2);
    set(p,'EdgeAlpha',0.2);
    set(p, 'EdgeColor', 'c');
end
hold off

%% WAVELET CLASSIFICATION (LEAVE ONE CYCLE OUT)
% use the time-aligned output levels of the wavelet decomposition
% components to classify expansion/contraction
rowCount = size(gnpLabels,1);
cycleData = [cycle_4_8 cycle_8_16 cycle_16_32];
cycleStarts = getCycleStarts(gnpLabels);
weightedPctCorrect = 0;
for ind = 1:length(cycleStarts)
    if ind == length(cycleStarts)
        testInds = cycleStarts(ind):rowCount;
        trainingInds = 1:(cycleStarts(ind)-1);
    else
        testInds = cycleStarts(ind):(cycleStarts(ind+1)-1);
        trainingInds = [1:(cycleStarts(ind)-1) (cycleStarts(ind+1)):rowCount];
    end
    trainDS = prtDataSetClass(cycleData(trainingInds,:), ...
        gnpLabels(trainingInds));
    testDS = prtDataSetClass(cycleData(testInds,:), ...
        gnpLabels(testInds));
    classifier = prtClassFld + prtDecisionMap;
    classifier = classifier.train(trainDS);
    classified = run(classifier, testDS);
    pct = prtScorePercentCorrect(classified);
    weightedPctCorrect = weightedPctCorrect + length(testInds)*pct;
end
waveletPctCorrect = weightedPctCorrect / rowCount; % GNP ONLY

% Try using multiple time series that worked well before
% LEAVE ONE CYCLE OUT 
% which features to use?
%selections = 1:19;
%selections = [2,7,18,19];  % NASDAQ
%selections = [2,7,18,20];   % DJIA
%selections = [5,17,18,20]; % KEEP
%selections = [5,18,20];  
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
waveletData = [];
featureCount = size(validData,2);
for col=1:featureCount
    wd = getCycleComponents(validData(:,col), wname, 0);
    waveletData = [waveletData wd];
end
% ONLY FOR CONTROL COMPARISON:
%waveletData = validData;

validLabels = classLabels(i1:i2);
validDates = dates(i1:i2);
validLabels(validLabels==1) = 0;
validLabels(validLabels==2) = 1;
rowCount = size(validData,1);

iterations = 1:10;
pcts = zeros(1, size(iterations,2));
hmmPcts = pcts;
for ii = iterations
    labels = validLabels(ii:rowCount);
    data = waveletData(1:rowCount-(ii-1), :);
    rows = rowCount - (ii-1);
    cycleStarts = getCycleStarts(labels);
    weightedPctCorrect = 0;
    for ind = 1:length(cycleStarts)
        if ind == length(cycleStarts)
            testInds = cycleStarts(ind):rows;
            trainingInds = 1:(cycleStarts(ind)-1);
        else
            testInds = cycleStarts(ind):(cycleStarts(ind+1)-1);
            trainingInds = [1:(cycleStarts(ind)-1) (cycleStarts(ind+1)):rows];
        end
        trainDS = prtDataSetClass(data(trainingInds,:), ...
            labels(trainingInds));
        testDS = prtDataSetClass(data(testInds,:), ...
            labels(testInds));
        
        % normalize
        zmuv = prtPreProcZmuv;
        zmuv = zmuv.train(trainDS);
        trainDS = zmuv.run(trainDS);
        zmuv = prtPreProcZmuv;
        zmuv = zmuv.train(testDS);
        testDS = zmuv.run(testDS);
        
        % create classifier
        %classifier = prtClassFld + prtDecisionMap; % FISHER'S
        classifier = prtClassFld + prtDecisionBinaryMinPe;
        %classifier = prtClassLibSvm + prtDecisionMap;
        %classifier = prtClassKnn + prtDecisionMap;
        classifier = classifier.train(trainDS);
        classified = run(classifier, testDS);
        pct = prtScorePercentCorrect(classified);
        weightedPctCorrect = weightedPctCorrect + length(testInds)*pct;
    end
    pctCorrect = weightedPctCorrect / rows;
    pcts(ii) = pctCorrect;
    
    
    %% PMTK HMMs - can use multivariate Gaussians
    d = size(data, 2);
    nstates = 2;
    
    % now, without incest!
    targetIndex = 5 * round(size(validLabels, 1) / 8);
    while labels(targetIndex) ~= labels(1)
        targetIndex = targetIndex + 1;
    end
    split = targetIndex;
    
    Z = {labels(1:targetIndex)' + 1};
    Y = {data(1:targetIndex,:)'};
    X = data(targetIndex+1:end,:)';
    model3 = hmmFitFullyObs(Z, Y, 'gauss');
    
    % use Viterbi to predict state sequence
    path = hmmMap(model3, X) - 1;
    pctError_MVN_HMM = sum(path ~= labels(split+1:end)') / ...
        size(X,2);
    hmmPcts(ii) = 1 - pctError_MVN_HMM;
end

%% Plot results
figure 
years = 1:size(pcts,2);
years = years/4;
plot(years, pcts, 'bx-')
title('Classification of future cycle phases')
ylabel('Binary phase classification accuracy')
xlabel('Prediction lookahead (years)')
hold on 
plot(years, hmmPcts, 'ro-');
hold off
legend('LDA','HMM')