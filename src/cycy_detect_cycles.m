function Peaks = cycy_detect_cycles(Wave, fWave)
% detects peaks in signal based on zero-crossings. Wave should be only
% loosely filtered (e.g. 3-40 Hz). The data gets further filtered just to
% find the zero-crossings. FreqRange should be like [3 12].
% Output includes all the positive peaks and negative peaks between
% zero-crossings. Then MidDown and Up are the midpoints in amplitude
% between consecutive peaks.
% The output is a struct containing all peaks, based on the negative
% peak and following positive peak.
%
% Part of Matcycle 2022, by Sophia Snipes.

[FallingEdgeZeroCrossing, RisingEdgeZeroCrossing] = detect_zero_crossings(fWave);

%%% Find peaks and troughs between zero crossings
Peaks = cycy_detect_peaks(FallingEdgeZeroCrossing, RisingEdgeZeroCrossing, Wave);

% final adjustment to positive peaks to make sure they are the largest
% point between midpoints. % TODO also for negative??
for n = 1:numel(Peaks)-1
    [~, PosPeakID] = max(Wave(Peaks(n).MidUpID:Peaks(n+1).MidDownID));
    PosPeakID = PosPeakID + Peaks(n).MidUpID - 1;
    Peaks(n).PosPeakID = PosPeakID;
    Peaks(n).NextMidDownID = Peaks(n+1).MidDownID;
    if n>1
        Peaks(n).PrevPosPeakID = Peaks(n-1).PosPeakID;
    end
end

% remove last peak if it's positive peak doesn't exist:
if Peaks(n).PosPeakID > numel(Wave)
    Peaks(end) = [];
end
