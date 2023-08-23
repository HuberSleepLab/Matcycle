function Bursts = remove_overlapping_bursts(Bursts, MinCyclesPerBurst)
% identifies bursts with overlap, keeps the largest intact, and chops the
% smaller ones to be outside the large one, until there are no left. Then
% remove all the bursts that are now too small.

% Part of Matcycle 2022, by Sophia Snipes.
% TODO: only keep chopped off burst if larger than min cycles for that
% criteriaset from which it originates.

if numel(fieldnames(Bursts)) == 0
    return
end

BurstsCountInitial = numel(Bursts);

[Bursts, Starts, Ends] = remove_overlaps(Bursts);
Bursts = adjust_chopped_bursts(Bursts, Starts, Ends, MinCyclesPerBurst);


% reodrer by start time
Starts = [Bursts.Start];
[~, SortedOrder] = sort(Starts, 'ascend');
Bursts = Bursts(SortedOrder);

BurstsCountFinal = numel(Bursts);
disp(['Removed ', num2str(BurstsCountInitial-BurstsCountFinal), ' from ', num2str(BurstsCountInitial), ' bursts'])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [Bursts, Starts, Ends] = remove_overlaps(Bursts)

Starts = [Bursts.Start];
Ends = [Bursts.End];

ToRemove = false(size(Starts));
Visited = false(size(Starts));


% loops through bursts, finds overlap; leaves the biggest burst intact,
% adjusts the starts and ends of the others so they're outside the burst.
while any(~Visited)
    Durations = Ends-Starts;
    Durations(Visited) = nan; % ignore all bursts already done

    if ~any(Durations > 0)
        ToRemove(Durations<=0) = true;
        break
    end

    % get longest duration that hasn't been looked at yet
    [~, LongestBurst] = max(Durations);
    Visited(LongestBurst) = true;

    Start = Starts(LongestBurst);
    End = Ends(LongestBurst);

    % get all the overlaps with this large burst
    OverlapStarts = Starts >= Start & Starts < End & ~Visited;
    OverlapEnds = Ends > Start & Ends <= End & ~Visited;

    if isempty(OverlapStarts) || ~any(OverlapStarts)
        Bursts(LongestBurst).debugUniqueCriteria = 1;
        continue
    else
         Bursts(LongestBurst).debugUniqueCriteria = 0;
    end

    % move their starts and ends to the outside of the large burst.
    Starts(OverlapStarts) = End;
    Ends(OverlapEnds) = Start;
end

Bursts(ToRemove) = [];
Starts(ToRemove) = [];
Ends(ToRemove) = [];
end

function Bursts = adjust_chopped_bursts(Bursts, Starts, Ends, MinCyclesPerBurst)
%%% goes through remaining bursts, and removes chopped off peaks, and if
%%% there are no longer 3 cycles left, removes this little burst entirely.
PropertyLabels = fieldnames(Bursts);
ToRemove = zeros(size(Starts));
for idxBurst = 1:numel(Bursts)

    % get new boundaries
    Start = Starts(idxBurst);
    End = Ends(idxBurst);

    % see if any peaks are still in the boundaries
    Peaks = Bursts(idxBurst).NegPeakIdx;
    PeaksCountOriginal = numel(Peaks);
    PeaksToKeep = Peaks >= Start & Peaks <= End;

    % if not enough peaks, remove the burst
    if nnz(PeaksToKeep) < MinCyclesPerBurst
        ToRemove(idxBurst) = 1;
        continue
    end

    % save new start and end times
    Bursts(idxBurst).Start = Start;
    Bursts(idxBurst).End = End;

    % remove information about peaks no longer in burst
    for Label = PropertyLabels(:)'
        if ~ischar(Bursts(idxBurst).(Label{1})) && numel(Bursts(idxBurst).(Label{1})) == PeaksCountOriginal
            Bursts(idxBurst).(Label{1}) = Bursts(idxBurst).(Label{1})(PeaksToKeep);
        end
    end
end

% remove bursts that are too short
ToRemove = logical(ToRemove);
Bursts(ToRemove) = [];
end