function Peaks = removeOverlapPeaks(Peaks)
% identifies peaks that overlap and removes

if numel(fieldnames(Peaks)) == 0
    return
end

PeakIds = [Peaks.NegPeakID];
[~, FirstCase, ~] = unique(PeakIds);

Peaks = Peaks(FirstCase);

disp(['Removing ', num2str(numel(PeakIds)-numel(FirstCase)), ' duplicate peaks'])