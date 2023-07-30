function Cycles = cycy_detect_cycles(ChannelBroadband, ChannelNarrowband)
% detects peaks in narrowband filtered data based on zero-crossings.
% The output is a struct containing all cycles in the channel, from a
% midpoint between positive and negative peaks to the next.
%
% Part of Matcycle 2022, by Sophia Snipes.

[RisingEdgeZeroCrossings, FallingEdgeZeroCrossings] = ...
    cycy_detect_zero_crossings(ChannelNarrowband);

[NegPeaks, PosPeaks] = cycy_detect_peaks(RisingEdgeZeroCrossings, ...
    FallingEdgeZeroCrossings, ChannelBroadband);

NegPeaksCount = numel(NegPeaks);
Cycles = struct();
for idxPeak = 1:NegPeaksCount
    Cycles(idxPeak).NegPeakIdx = NegPeaks(idxPeak);
    Cycles(idxPeak).PrevPosPeakIdx = PosPeaks(idxPeak);
    Cycles(idxPeak).NextPosPeakIdx = PosPeaks(idxPeak+1);
end