function [ first, last, i1, i2] = getValidDateRange( data, dates )
%UNTITLED find first and last date that are not blank/0
%   dates is the numberic vector of dates that apply to the full raw
%   dataset
%   data is the raw dataset

if size(data,1) ~= length(dates)
    error('Length of date vector much match number of rows in data'); 
end

[rowCount, colCount] = size(data);
minRow = 0;
maxRow = rowCount;

for c = 1:colCount
    series = data(:,c);
    firstGoodRow = find(series, 1, 'first');
    lastGoodRow = find(series, 1, 'last');
    if firstGoodRow > minRow
        minRow = firstGoodRow;
    end
    if lastGoodRow < maxRow
        maxRow = lastGoodRow;
    end
end

first = dates(minRow);
last = dates(maxRow);
i1 = minRow;
i2 = maxRow;

end