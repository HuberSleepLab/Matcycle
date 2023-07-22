function Bursts = cycy_remove_overlapping_bursts(Bursts, Min_Peaks)
% identifies bursts with overlap, keeps the largest intact, and chops the
% smaller ones to be outside the large one, until there are no left. Then
% remove all the bursts that are now too small.

% Part of Matcycle 2022, by Sophia Snipes.


if numel(fieldnames(Bursts)) == 0
    return
end

Starts = [Bursts.Start];
Ends = [Bursts.End];
nBursts = numel(Starts);

RM = false(size(Starts));
Done = false(size(Starts));


% loops through starts, finds overlap; leaves the biggest burst intact,
% adjusts the starts and ends of the others so they're outside the burst.
while any(~Done)
    Durations = Ends-Starts;
    Durations(Done) = nan; % ignore all bursts already done

    if ~any(Durations > 0)
        RM(Durations<=0) = true;
        break
    end

    % get largest duration that hasn't been looked at yet
    [~, MainBurst] = max(Durations);
    Done(MainBurst) = true;

    Start_Edge = Starts(MainBurst);
    End_Edge = Ends(MainBurst);

    % get all the overlaps with this large burst
    Overlap_Starts = Starts >= Start_Edge & Starts < End_Edge & ~Done;
    Overlap_Ends = Ends > Start_Edge & Ends <= End_Edge & ~Done;

    % move their starts and ends to the outside of the large burst.
    Starts(Overlap_Starts) = End_Edge;
    Ends(Overlap_Ends) = Start_Edge;
end

Bursts(RM) = [];
Starts(RM) = [];
Ends(RM) = [];



%%% goes through remaining bursts, and removes chopped off peaks, and if
%%% there are no longer 3 cycles left, removes this little burst entirely.
Fields = fieldnames(Bursts);
RM = zeros(size(Starts));
for Indx_B = 1:numel(Bursts)

    % get new boundaries
    Start = Starts(Indx_B);
    End = Ends(Indx_B);

    % see if any peaks are still in the boundaries
    Peaks = Bursts(Indx_B).NegPeakID;
    nPeaks_original = numel(Peaks);
    KeepPeaks = Peaks >= Start & Peaks <= End;

    % if not enough peaks, remove the burst
    if nnz(KeepPeaks) < Min_Peaks
        RM(Indx_B) = 1;
        continue
    end

    % save new start and end times
    Bursts(Indx_B).Start = Start;
    Bursts(Indx_B).End = End;

    % remove information about peaks no longer in burst
    for Indx_F = 1:numel(Fields)
        F = Fields{Indx_F};
        if numel(Bursts(Indx_B).(F)) == nPeaks_original
            Bursts(Indx_B).(F) = Bursts(Indx_B).(F)(KeepPeaks);
        end
    end
end

% remove bursts that are too short
RM = logical(RM);
Bursts(RM) = [];


% reodrer by start time
Starts = [Bursts.Start];
[~, SortedOrder] = sort(Starts, 'ascend');
Bursts = Bursts(SortedOrder);


disp(['Removed ', num2str(nBursts-numel(Bursts)), ' from ', num2str(nBursts), ' bursts'])