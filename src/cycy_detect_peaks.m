function [NegPeaks, PosPeaks] = cycy_detect_peaks(RisingEdgeZeroCrossings, ...
    FallingEdgeZeroCrossings, ChannelBroadband)
% Finds the negative and positive peaks between zero-crossings. NegPeaks
% and PosPeaks are (2 x number of peaks) arrays, with peak indexes in the first
% row, and amplitudes in the second.
% Caution: the first rising edge zero-crossing must come at an earlier
% timepoint than the first falling edge zero-crossing (sequence starts with
% a positive cycle).
%
% Part of Matcycle 2022, by Sophia Snipes.

PeaksCount = size(RisingEdgeZeroCrossings, 2);
PosPeaks = nan([1, PeaksCount]);
NegPeaks = nan([1, PeaksCount-1]);

for idxPeak = 1:PeaksCount

    %%% find positive peaks
    [~, RelativePosPeakIdx] = max(ChannelBroadband(...
        RisingEdgeZeroCrossings(idxPeak):FallingEdgeZeroCrossings(idxPeak)));
    
    PosPeaks(idxPeak) = RelativePosPeakIdx + RisingEdgeZeroCrossings(idxPeak) - 1;


    %%% find negative peaks
    % The signal always ends with a positive peak, so we stop one short
    if idxPeak < PeaksCount
        [~, RelativeNegPeakIdx] = min(ChannelBroadband(...
            FallingEdgeZeroCrossings(idxPeak):RisingEdgeZeroCrossings(idxPeak+1)));
        
        NegPeaks(idxPeak) = RelativeNegPeakIdx + FallingEdgeZeroCrossings(idxPeak) - 1;
    end
end