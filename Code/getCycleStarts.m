function [ starts ] = getCycleStarts( labels )
%GETCYCLESTARTS returns starting indeces for each cycle 
startingStage = labels(1);
starts = [1];
currentCycle = 1;

for ind = 2:length(labels)
    currentStage = labels(ind);
    if currentCycle == 0 && currentStage == startingStage
        currentCycle = 1;
        starts = [starts ind];
        continue;
    end
    if currentCycle == 1 && currentStage ~= startingStage  
        currentCycle = 0;
    end
end
    
end

