function Peaks = removePeaksinBursts(Peaks, Bursts)
% removes all the peaks that occur during any burst. Also works for peaks.

if numel(fieldnames(Peaks)) == 0 || numel(fieldnames(Bursts)) == 0
    return
end

PeakIds = [Peaks.NegPeakID];

if isfield(Bursts, 'Start') % if Bursts is actually bursts
    Starts = [Bursts.Start];
    Ends = [Bursts.End];

    for Indx_S = 1:numel(Starts)
        PeakIds(PeakIds>Starts(Indx_S) & PeakIds<Ends(Indx_S)) = [];
    end

    Peaks = Peaks(ismember([Peaks.NegPeakID], PeakIds));
else % if bursts is just a peaks thing

    Burst_PeakIDs = [Bursts.NegPeakID];
    Peaks(ismember(PeakIds, Burst_PeakIDs)) = [];
end