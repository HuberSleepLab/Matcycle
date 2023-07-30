function Peaks = cycy_detect_peaks(FallingEdgeZeroCrossings, RisingEdgeZeroCrossings, ChannelBroadband)
% identifies new negative peaks based on midpoints in the reference
% Part of Matcycle 2022, by Sophia Snipes.

Peaks = struct();
for n = 1:length(FallingEdgeZeroCrossings)

    % find lowest point between zero crossings
    [NegPeakAmplitude, RelativeNegPeakIdx] = min(ChannelBroadband(FallingEdgeZeroCrossings(n):RisingEdgeZeroCrossings(n)));

    % adjust negative peak index to absolute value in channel signal
    NegPeakIdx = RelativeNegPeakIdx + FallingEdgeZeroCrossings(n) - 1;

    Peaks(n).NegPeakIdx = NegPeakIdx;


    % same for positive peak
    if n < length(FallingEdgeZeroCrossings)
        [PosPeakAmp, PosPeakID] = max(ChannelBroadband(RisingEdgeZeroCrossings(n):FallingEdgeZeroCrossings(n+1)));
        PosPeakID = PosPeakID + RisingEdgeZeroCrossings(n) - 1;
        Peaks(n).PosPeakIdx = PosPeakID;

        %%% Find midpoints (first point that crosses midpoint)

        % after peak
        MidUpAmp = NegPeakAmplitude + (PosPeakAmp-NegPeakAmplitude)/2;
        halfWave = ChannelBroadband(NegPeakIdx:PosPeakID);
        MidUpID = find([halfWave nan] >= MidUpAmp & [nan halfWave] < MidUpAmp, 1, 'first'); % shift by one and see where crossing happens
        if isempty(MidUpID)
            MidUpID = RisingEdgeZeroCrossings(n);
        else
            MidUpID = MidUpID + NegPeakIdx - 1;
        end
        Peaks(n).MidRisingIdx = MidUpID;
    else
        Peaks(n).PosPeakIdx =RisingEdgeZeroCrossings(n)+1;
        Peaks(n).MidRisingIdx = RisingEdgeZeroCrossings(n);
    end

    % before peak
    if n > 1
        PrevPosPeakID = Peaks(n-1).PosPeakIdx;
        PrevPosAmp = ChannelBroadband(PrevPosPeakID);
        MidDownAmp = PrevPosAmp + (NegPeakAmplitude-PrevPosAmp)/2;
        halfWave = ChannelBroadband(PrevPosPeakID:NegPeakIdx);
        MidDownID = find([nan halfWave] > MidDownAmp & [halfWave nan] <= MidDownAmp, 1, 'last');
        if isempty(MidDownID)
            MidDownID = FallingEdgeZeroCrossings(n);
        else
            MidDownID = MidDownID + PrevPosPeakID - 1;
        end
        Peaks(n).MidFallingIdx = MidDownID;
    else
        Peaks(n).MidFallingIdx = FallingEdgeZeroCrossings(n);
    end
end



