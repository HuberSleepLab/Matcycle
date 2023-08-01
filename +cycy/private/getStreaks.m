function [Starts, Ends]  = getStreaks(BinArray, Min_Samples)
% identify starts and ends that make up streaks
% BinArray is ones and zeros, and tries to find streaks of ones

% Part of Matcycle 2022, by Sophia Snipes.

Starts = find(diff(BinArray) == 1);
Ends = find(diff(BinArray) == -1);


if isempty(Starts) || isempty(Ends)
    return
end

% handle edgecase of starting mid-burst
if Ends(1) < Starts(1)
    Ends(1) = [];
end

if Ends(end) < Starts(end)
    Starts(end) = [];
end


% select streaks that have the minimum number of cycles
Streaks = Ends-Starts;
remove = Streaks < Min_Samples;

Starts(remove) = [];
Ends(remove) = [];

Starts = Starts+1; % adjust indexing
