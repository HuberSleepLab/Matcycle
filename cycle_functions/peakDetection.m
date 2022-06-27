function Peaks = peakDetection(Wave, fWave)
% detects peaks in signal based on zero-crossings. Wave should be only
% loosely filtered (e.g. 3-40 Hz). The data gets further filtered just to
% find the zero-crossings. FreqRange should be like [3 12].
% Output includes all the positive peaks and negative peaks between
% zero-crossings. Then MidDown and Up are the midpoints in amplitude
% between consecutive peaks.
% The output is a structure containing all peaks, based on the negative
% peak and following positive peak.

% Part of Matcycle 2022, by Sophia Snipes.

signData = sign(fWave);

% fix rare issue where slope is exactly 0
signData(signData == 0) = 1;
% -2 indicates when the sign goes from 1 to -1
DZC = find(diff(signData) < 0);
UZC = find(diff(signData) > 0);

UZC = UZC + 1;

% Check for earlier initial UZC than DZC
if UZC(1) <= DZC(1)
    UZC(1)=[];
end

% in case the last DZC does not have a corresponding UZC then delete it
if length(DZC) ~= length(UZC)
    DZC(end)=[];
end


%%% Find peaks and troughs between zero crossings
Peaks = peakAdjustment(DZC, UZC, Wave);

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
