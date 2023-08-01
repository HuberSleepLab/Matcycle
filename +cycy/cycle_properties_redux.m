function Peaks = cycle_properties_redux(Wave, Peaks, fs)
% Identifies various ways to characterize each peak. Based on Cole 2019,
% but relative to the negative peaks rather than positive peaks.
% NOTE: all fieldnames should start lowercase, so I know later on that they
% come from here.

% Part of Matcycle 2022, by Sophia Snipes.

for n = 2:numel(Peaks)-1
    P = Peaks(n);
    if min(Wave(P.MidFallingIdx:P.MidRisingIdx)) < Wave(P.NegPeakIdx) ...
            || P.NegPeakIdx == P.MidRisingIdx || P.NegPeakIdx == P.MidFallingIdx % if peak coincided with edges of zero-crossings
        Peaks(n).truePeak = 0;
    else
        Peaks(n).truePeak = 1;
    end

    Peaks(n).voltageNeg = Wave(P.NegPeakIdx);
    Peaks(n).voltagePos = Wave(P.PosPeakIdx);

    % periods
    Peaks(n).periodNeg = 2*(P.MidRisingIdx - P.MidFallingIdx)/fs;
    Peaks(n).periodPos = 2*(P.NextMidDownID - P.MidRisingIdx)/fs;


    % Amplitude as average between distance to positive peaks surrounding
    % this negative peak.
    decay_amp = Wave(P.PrevPosPeakID) - Wave(P.NegPeakIdx);
    rise_amp = Wave(P.PosPeakIdx) - Wave(P.NegPeakIdx);
    Peaks(n).amplitude = (rise_amp + decay_amp)/2;

end


%%% comparing cycles to each other
for n = 2:numel(Peaks)-1

    % period consistency (fraction of previous peak to next peak)
    P1 = Peaks(n).NegPeakIdx-Peaks(n-1).NegPeakIdx;
    P2 = Peaks(n+1).NegPeakIdx-Peaks(n).NegPeakIdx;


    if isempty(P1)
        P1 = 0;
    end

    % get period as distance between neighboring peaks
    Peaks(n).period = mean([P1, P2])/fs;
end

% remove edge peaks that are empty
Peaks([1 end]) = [];

end
