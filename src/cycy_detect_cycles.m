function Cycles = cycy_detect_cycles(ChannelBroadband, ChannelNarrowband)
% detects peaks in narrowband filtered data based on zero-crossings.
% The output is a struct containing all cycles in the channel, from a
% midpoint between positive and negative peaks to the next.
%
% Part of Matcycle 2022, by Sophia Snipes.

[FallingEdgeZeroCrossings, RisingEdgeZeroCrossings] = detect_zero_crossings(ChannelNarrowband);

%%% Find peaks and troughs between zero crossings
Cycles = cycy_detect_peaks(FallingEdgeZeroCrossings, RisingEdgeZeroCrossings, ChannelBroadband);

% final adjustment to positive peaks to make sure they are the largest
% point between midpoints. % TODO also for negative??
for n = 1:numel(Cycles)-1
    [~, PosPeakID] = max(ChannelBroadband(Cycles(n).MidUpID:Cycles(n+1).MidDownID));
    PosPeakID = PosPeakID + Cycles(n).MidUpID - 1;
    Cycles(n).PosPeakID = PosPeakID;
    Cycles(n).NextMidDownID = Cycles(n+1).MidDownID;
    if n>1
        Cycles(n).PrevPosPeakID = Cycles(n-1).PosPeakID;
    end
end

% remove last peak if it's positive peak doesn't exist:
if Cycles(n).PosPeakID > numel(ChannelBroadband)
    Cycles(end) = [];
end
