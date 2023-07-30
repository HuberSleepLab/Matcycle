function Peaks = cycy_detect_peaks(FallingEdgeZeroCrossings, RisingEdgeZeroCrossings, ChannelBroadband)
% identifies new negative peaks based on midpoints in the reference
% Part of Matcycle 2022, by Sophia Snipes.

Peaks = struct();
for idxPeak = 1:length(FallingEdgeZeroCrossings)
    %%% find negative peaks

    % find lowest point between zero crossings
    [NegPeakAmplitude, RelativeNegPeakIdx] = min(ChannelBroadband(FallingEdgeZeroCrossings(idxPeak):RisingEdgeZeroCrossings(idxPeak)));

    % adjust negative peak index to absolute value in channel signal
    NegPeakIdx = RelativeNegPeakIdx + FallingEdgeZeroCrossings(idxPeak) - 1;

    Peaks(idxPeak).NegPeakIdx = NegPeakIdx;

    %%% find positive peaks
    if idxPeak < length(FallingEdgeZeroCrossings)
        [PosPeakAmp, PosPeakID] = max(ChannelBroadband(RisingEdgeZeroCrossings(idxPeak):FallingEdgeZeroCrossings(idxPeak+1)));
        PosPeakID = PosPeakID + RisingEdgeZeroCrossings(idxPeak) - 1;
        Peaks(idxPeak).PosPeakIdx = PosPeakID;
    else 
        % the last cycle needs special treatment:
        % the positive peak is just the point right after the zero-crossing
        Peaks(idxPeak).PosPeakIdx = RisingEdgeZeroCrossings(idxPeak)+1;
    end


    %%% Find midpoints

    % find midpoints between negative and positive zero-crossings
    if idxPeak < length(FallingEdgeZeroCrossings)
        MidUpAmp = NegPeakAmplitude + (PosPeakAmp-NegPeakAmplitude)/2;
        halfWave = ChannelBroadband(NegPeakIdx:PosPeakID);
        MidUpID = find([halfWave nan] >= MidUpAmp & [nan halfWave] < MidUpAmp, 1, 'first'); % shift by one and see where crossing happens
        if isempty(MidUpID)
            MidUpID = RisingEdgeZeroCrossings(idxPeak);
        else
            MidUpID = MidUpID + NegPeakIdx - 1;
        end
        Peaks(idxPeak).MidRisingIdx = MidUpID;
    else
        Peaks(idxPeak).MidRisingIdx = RisingEdgeZeroCrossings(idxPeak);
    end

    % find midpoints between positive and negative zero-crossings
    if idxPeak > 1
        PrevPosPeakID = Peaks(idxPeak-1).PosPeakIdx;
        PrevPosAmp = ChannelBroadband(PrevPosPeakID);
        MidDownAmp = PrevPosAmp + (NegPeakAmplitude-PrevPosAmp)/2;
        halfWave = ChannelBroadband(PrevPosPeakID:NegPeakIdx);
        MidDownID = find([nan halfWave] > MidDownAmp & [halfWave nan] <= MidDownAmp, 1, 'last');
        if isempty(MidDownID)
            MidDownID = FallingEdgeZeroCrossings(idxPeak);
        else
            MidDownID = MidDownID + PrevPosPeakID - 1;
        end
        Peaks(idxPeak).MidFallingIdx = MidDownID;
    else
        Peaks(idxPeak).MidFallingIdx = FallingEdgeZeroCrossings(idxPeak);
    end
end



