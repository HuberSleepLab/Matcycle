function Array = windows2data(Starts, Ends, Pnts)
% converts arrays of start and end points into a time array of 0s and 1s

Array = zeros(1, Pnts);


for Indx_S = 1:numel(Starts)
    Array(Starts(Indx_S):Ends(Indx_S)) = 1;
end

Array = logical(Array);