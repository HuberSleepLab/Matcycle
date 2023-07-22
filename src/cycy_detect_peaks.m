function Peaks = cycy_detect_peaks(DZC, UZC, Wave)
% identifies new negative peaks based on midpoints in the reference
% Part of Matcycle 2022, by Sophia Snipes.

Peaks = struct();
for n = 1:length(DZC)


    % find lowest point between zero crossings in filtered wave
    [NegPeakAmp, NegPeakID] = min(Wave(DZC(n):UZC(n)));

    % adjust negative peak index to absolute value in ref wave
    NegPeakID = NegPeakID + DZC(n) - 1;

    Peaks(n).NegPeakID = NegPeakID;


    % same for positive peak
    if n < length(DZC)
        [PosPeakAmp, PosPeakID] = max(Wave(UZC(n):DZC(n+1)));
        PosPeakID = PosPeakID + UZC(n) - 1;
        Peaks(n).PosPeakID = PosPeakID;

        %%% Find midpoints (first point that crosses midpoint)

        % after peak
        MidUpAmp = NegPeakAmp + (PosPeakAmp-NegPeakAmp)/2;
        halfWave = Wave(NegPeakID:PosPeakID);
        MidUpID = find([halfWave nan] >= MidUpAmp & [nan halfWave] < MidUpAmp, 1, 'first'); % shift by one and see where crossing happens
        if isempty(MidUpID)
            MidUpID = UZC(n);
        else
            MidUpID = MidUpID + NegPeakID - 1;
        end
        Peaks(n).MidUpID = MidUpID;
    else
        Peaks(n).PosPeakID =UZC(n)+1;
        Peaks(n).MidUpID = UZC(n);
    end

    % before peak
    if n > 1
        PrevPosPeakID = Peaks(n-1).PosPeakID;
        PrevPosAmp = Wave(PrevPosPeakID);
        MidDownAmp = PrevPosAmp + (NegPeakAmp-PrevPosAmp)/2;
        halfWave = Wave(PrevPosPeakID:NegPeakID);
        MidDownID = find([nan halfWave] > MidDownAmp & [halfWave nan] <= MidDownAmp, 1, 'last');
        if isempty(MidDownID)
            MidDownID = DZC(n);
        else
            MidDownID = MidDownID + PrevPosPeakID - 1;
        end
        Peaks(n).MidDownID = MidDownID;
    else
        Peaks(n).MidDownID = DZC(n);
    end
end



