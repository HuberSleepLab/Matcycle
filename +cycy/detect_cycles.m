function Cycles = detect_cycles(ChannelBroadband, ChannelNarrowband)
% detects all cycles in the channel, returned as a struct. A cycle goes
% from positive to positive peak, and includes 1 negative peak.
%
% Part of Matcycle 2022, by Sophia Snipes.

[RisingEdgeZeroCrossings, FallingEdgeZeroCrossings] = ...
    detect_zero_crossings(ChannelNarrowband);

[NegPeaks, PosPeaks] = detect_peaks(RisingEdgeZeroCrossings, ...
    FallingEdgeZeroCrossings, ChannelBroadband);


NegPeaksCount = numel(NegPeaks);
Cycles = struct();
for idxPeak = 1:NegPeaksCount
    Cycles(idxPeak).NegPeakIdx = NegPeaks(idxPeak);
    Cycles(idxPeak).PrevPosPeakIdx = PosPeaks(idxPeak);
    Cycles(idxPeak).NextPosPeakIdx = PosPeaks(idxPeak+1);
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [RisingEdgeCrossings, FallingEdgeCrossings] = detect_zero_crossings(Signal)
% finds all the timepoints in which the signal goes from positive to 
% negative (falling edge zero-crossing) and from negative to positive
% (rising edge zero-crossing).
% Ensures that the first rising edge zero-crossing comes at an earlier
% timepoint than the first falling-edge zero-crossing (ensures that the 
% sequence starts with a positive cycle).

[RisingEdgeCrossings, FallingEdgeCrossings] = detect_crossings(Signal, 0);

% Ensure that the first index is always a rising edge zero-crossing
if RisingEdgeCrossings(1) > FallingEdgeCrossings(1)
    FallingEdgeCrossings(1) = [];
elseif RisingEdgeCrossings(1) == FallingEdgeCrossings(1)
    FallingEdgeCrossings(1) = FallingEdgeCrossings(1)+1;

end

% Ensure that the last index is always a falling edge zero-crossing
RisingEdgeCrossings = RisingEdgeCrossings(1:length(FallingEdgeCrossings));

% remove any crossings that don't have any points inbetween
SameIndex = RisingEdgeCrossings==FallingEdgeCrossings;
RisingEdgeCrossings(SameIndex) = [];
FallingEdgeCrossings(SameIndex) = [];
end


function [NegPeaks, PosPeaks] = detect_peaks(RisingEdgeZeroCrossings, ...
    FallingEdgeZeroCrossings, ChannelBroadband)
% Finds the negative and positive peaks between zero-crossings. NegPeaks
% and PosPeaks are (2 x number of peaks) arrays, with peak indexes in the first
% row, and amplitudes in the second.
% Caution: the first rising edge zero-crossing must come at an earlier
% timepoint than the first falling edge zero-crossing (sequence starts with
% a positive cycle).

PeaksCount = numel(RisingEdgeZeroCrossings);
PosPeaks = nan([1, PeaksCount]);
NegPeaks = nan([1, PeaksCount-1]);

for idxPeak = 1:PeaksCount

    %%% find positive peaks
    [~, RelativePosPeakIdx] = max(ChannelBroadband(...
        RisingEdgeZeroCrossings(idxPeak)+1:FallingEdgeZeroCrossings(idxPeak))); % shift start by 1 so can't be same value as previous neg cycle
    
    PosPeaks(idxPeak) = RelativePosPeakIdx + RisingEdgeZeroCrossings(idxPeak);
   

    %%% find negative peaks
    % The signal always ends with a positive peak, so we stop one short
    if idxPeak < PeaksCount
        [~, RelativeNegPeakIdx] = min(ChannelBroadband(...
            FallingEdgeZeroCrossings(idxPeak)+1:RisingEdgeZeroCrossings(idxPeak+1)));
        
        NegPeaks(idxPeak) = RelativeNegPeakIdx + FallingEdgeZeroCrossings(idxPeak);
    end
end
end