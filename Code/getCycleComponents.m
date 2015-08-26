function [ cycleData ] = getCycleComponents( data, wname )

% operate on individual columns
featureCount = size(data, 2);
obsCount = size(data, 1);
cycleData = zeros(obsCount, featureCount * 3);

for col = 1:featureCount
    series = data(:,col);
    [a0, d0] = dwt(series, wname);
    [a1, d1] = dwt(a0, wname);
    [a2, d2] = dwt(a1, wname);
    [a3, d3] = dwt(a2, wname);
    
    % since these filtered components are all critically sampled, interpolate
    % to restore the correct magnitude and number of points
    originalLength = size(series, 1);
    cycle_4_8 = upcoef('d', d1, wname, 2, originalLength);
    cycle_8_16 = upcoef('d', d2, wname, 3, originalLength);
    cycle_16_32 = upcoef('d', d3, wname, 4, originalLength);
    c1 = ((col-1) * 3) + 1;
    c2 = c1 + 2;
    cycleData(:,c1:c2) = [cycle_4_8 cycle_8_16 cycle_16_32];
    
end

end

