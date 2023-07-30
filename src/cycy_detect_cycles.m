function Cycles = cycy_detect_cycles(ChannelBroadband, ChannelNarrowband)
% detects all cycles in the channel, returned as a struct. A cycle goes
% from positive to positive peak, and includes 1 negative peak.
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