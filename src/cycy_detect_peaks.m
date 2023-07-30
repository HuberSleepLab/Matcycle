function [NegPeaks, PosPeaks] = cycy_detect_peaks(FallingEdgeZeroCrossings, RisingEdgeZeroCrossings, ChannelBroadband)
% Finds the negative and positive peaks between zero-crossings. NegPeaks
% and PosPeaks are (2 x number of peaks) arrays, with peak indexes in the first
% row, and amplitudes in the second.
%
% Part of Matcycle 2022, by Sophia Snipes.

PeaksCount = size(FallingEdgeZeroCrossings, 2);
NegPeaks = nan([2, PeaksCount]);
PosPeaks = nan([2, PeaksCount]);

for idxPeak = 1:length(FallingEdgeZeroCrossings)
    %%% find negative peaks

    % find lowest point between zero crossings
    [NegPeaks(2, idxPeak), RelativeNegPeakIdx] = min(ChannelBroadband(FallingEdgeZeroCrossings(idxPeak):RisingEdgeZeroCrossings(idxPeak)));

    % adjust negative peak index to absolute value in channel signal
    NegPeaks(1, idxPeak) = RelativeNegPeakIdx + FallingEdgeZeroCrossings(idxPeak) - 1;

    %%% find positive peaks
    if idxPeak < length(FallingEdgeZeroCrossings)
        [PosPeaks(2, idxPeak), RelativePosPeakIdx] = max(ChannelBroadband(RisingEdgeZeroCrossings(idxPeak):FallingEdgeZeroCrossings(idxPeak+1)));
        PosPeaks(1, idxPeak) = RelativePosPeakIdx + RisingEdgeZeroCrossings(idxPeak) - 1;
    else
        % the last cycle needs special treatment:
        % the positive peak is just the point right after the zero-crossing
        PosPeaks(idxPeak) = RisingEdgeZeroCrossings(idxPeak)+1;
    end
end