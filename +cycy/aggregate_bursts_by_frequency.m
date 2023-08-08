function Bursts = aggregate_bursts_by_frequency(AllBursts, EEGBroadband, MinFrequencyRange)
% identifies bursts that occur at the same time that are actually the same
% frequency, aggregates them together. Ignores bursts where there wasn't any overlap.

% Part of Matcycle 2022, by Sophia Snipes.

[nCh, ~] = size(EEGBroadband.data);
BurstsCount = numel(AllBursts);

% reorder bursts by size so that biggest ones always get chosen as
% "reference"
BurstIndexes = 1:BurstsCount;
[AllBurstsSorted, SortedBurstIndexes] = sort_bursts_by_length(AllBursts);

% loops through starts, finds overlap; leaves the biggest burst intact,
% adjusts the starts and ends of the others so they're outside the burst.
SortedStarts = [AllBurstsSorted.Start];
SortedEnds = [AllBurstsSorted.End];
BurstsToRemove = false(BurstsCount, 1); % keep track of bursts that have been aggregated
Bursts = struct();

for idxBurst = 1:BurstsCount

    % skip if already looked at and decided to remove
    if BurstsToRemove(idxBurst)
        continue
    end

    % Identify bursts that overlap in time with the current burst
    OverlappingBurstIndexes = find_overlapping_windows(SortedStarts, SortedEnds, idxBurst);

    % skip if no other channel showed a burst (suspicious!)
    if isempty(OverlappingBurstIndexes)
        BurstsToRemove(idxBurst) = true; % no longer considered a burst
        continue
    end

    % only consider bursts that overlap > 50%
    OverlappingBurstIndexes = keep_only_mostly_overlapping_bursts( ...
        OverlappingBurstIndexes, SortedStarts, SortedEnds, idxBurst);

    FinalOverlappingStartTimes = SortedStarts(OverlappingBurstIndexes);
    FinalOverlappingEndTimes = SortedEnds(OverlappingBurstIndexes);

    if isempty(OverlappingBurstIndexes)
        BurstsToRemove(idxBurst) = true; % no longer considered a burst
        continue
    end


    %%% aggregate bursts based on frequency

    AggregatedBursts = [];
    for idxOverlappers = 1:numel(OverlappingBurstIndexes)
        ReferenceNegPeakIdx = AllBurstsSorted(idxBurst).NegPeakIdx; % get location of all peaks in reference burst

        % identify in reference the peaks that overlap with other burst
        Start_Overlap = max(AllBurstsSorted(idxBurst).Start, FinalOverlappingStartTimes(idxOverlappers));
        End_Overlap = min(AllBurstsSorted(idxBurst).End, FinalOverlappingEndTimes(idxOverlappers));
        Overlap_RefPeaks = ReferenceNegPeakIdx>=Start_Overlap & ReferenceNegPeakIdx<=End_Overlap;

        % identify in reference the mean frequency of the overlapping segment
        Period = AllBurstsSorted(idxBurst).PeriodNeg;
        
        Freq = 1/mean(Period(Overlap_RefPeaks), 'omitnan');

        FreqRange = [Freq-MinFrequencyRange, Freq+MinFrequencyRange];

        % identify overlapping peaks in other burst
        Other_Peaks = AllBurstsSorted(OverlappingBurstIndexes(idxOverlappers)).NegPeakIdx;
        Overlap_OtherPeaks = Other_Peaks>=Start_Overlap & Other_Peaks<=End_Overlap;

        % get frequency of overlapping segment in other burst
        Period = AllBurstsSorted(OverlappingBurstIndexes(idxOverlappers)).period;

        if numel(Period) == 1
            Period = repmat(Period, 1, numel(Overlap_OtherPeaks));
        end

        Freq_Overlap = 1/mean(Period(Overlap_OtherPeaks), 'omitnan');


        % if frequency of overlapping burst is within range, keep
        if Freq_Overlap >= FreqRange(1) && Freq_Overlap <=FreqRange(2)
            AggregatedBursts = cat(2, AggregatedBursts, OverlappingBurstIndexes(idxOverlappers));
        end
    end

    % if there are no channels coherent, same as not having overlap
    if numel(AggregatedBursts)<1
        BurstsToRemove(idxBurst) = true;
        continue
    end

    % include reference burst in list
    AggregatedBursts = cat(2, AggregatedBursts, idxBurst);

    % remove from list of possible bursts all overlapping coherent
    BurstsToRemove(AggregatedBursts) = true;


    %%% assemble new burst's info

    NewB = AllBurstsSorted(idxBurst);
    NewB.BurstID = SortedBurstIndexes(AggregatedBursts);
    NewB.Coh_Burst_Channels = [AllBurstsSorted(AggregatedBursts).Channel];
    NewB.Coh_Burst_Channel_Labels = [AllBurstsSorted(AggregatedBursts).Channel_Label];
    NewB.Coh_Burst_Starts = [AllBurstsSorted(AggregatedBursts).Start];
    NewB.Coh_Burst_Ends = [AllBurstsSorted(AggregatedBursts).End];
    NewB.Coh_Burst_nPeaks = [AllBurstsSorted(AggregatedBursts).nPeaks];
    NewB.Coh_Burst_Signs = [AllBurstsSorted(AggregatedBursts).Sign];
    NewB.Coh_Burst_Frequency = [AllBurstsSorted(AggregatedBursts).Frequency];

    % special info
    NewB.Coh_Burst_amplitude = zeros(1, numel(AggregatedBursts));
    NewB.Coh_Burst_amplitude_sum = zeros(1, numel(AggregatedBursts));
    Coh_Peaks = struct();
    for Indx_C = 1:numel(AggregatedBursts)
        NewB.Coh_Burst_amplitude(Indx_C) = mean(AllBurstsSorted(AggregatedBursts(Indx_C)).amplitude);
        NewB.Coh_Burst_amplitude_sum(Indx_C) = sum(AllBurstsSorted(AggregatedBursts(Indx_C)).amplitude);

        Coh_Peaks(Indx_C).NegPeakIdx = AllBurstsSorted(AggregatedBursts(Indx_C)).NegPeakIdx;
        Coh_Peaks(Indx_C).PosPeakIdx = AllBurstsSorted(AggregatedBursts(Indx_C)).PosPeakIdx;
    end
    NewB.Coh_Burst_Peaks = Coh_Peaks;

    NewB.All_Start = min([NewB.Coh_Burst_Starts, NewB.Start]);
    NewB.All_End = max([NewB.Coh_Burst_Ends, NewB.End]);

    % how many channels involved in burst
    NewB.globality_bursts = numel(unique(NewB.Coh_Burst_Channels))./nCh;

    Bursts = cat_structs(Bursts, NewB);
end

% reorder by start time
SortedStarts = [Bursts.Start];
[~, SortedOrder] = sort(SortedStarts, 'ascend');
Bursts = Bursts(SortedOrder);

disp(['Reduced to ', num2str(numel(Bursts)), ' from ', num2str(BurstsCount), ' bursts'])

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Functions

function [AllBurstsSorted, SortedBurstIndexes] = sort_bursts_by_length(AllBursts)
Starts = [AllBursts.Start];
Ends = [AllBursts.End];

BurstIndexes = 1:numel(Starts);

BurstDurations = Ends-Starts;
[~, BustsOrderByDuration] = sort(BurstDurations, 'descend'); % start from the largest
AllBurstsSorted = AllBursts(BustsOrderByDuration);
SortedBurstIndexes = BurstIndexes(BustsOrderByDuration);
end


function OverlappingBurstIndexes = find_overlapping_windows(Starts, Ends, ReferenceIdx)
BurstIndexes = 1:numel(Starts);
StartReferenceBurst = Starts(ReferenceIdx);
EndReferenceBurst = Ends(ReferenceIdx);

isOverlappingStart = Starts >= StartReferenceBurst & Starts < EndReferenceBurst & BurstIndexes > ReferenceIdx;
isOverlappingEnd = Ends > StartReferenceBurst & Ends <= EndReferenceBurst & BurstIndexes > ReferenceIdx;
OverlappingBurstIndexes = find(isOverlappingStart | isOverlappingEnd);
end


function OverlappingBurstIndexes = keep_only_mostly_overlapping_bursts( ...
    OverlappingBurstIndexes, SortedStarts, SortedEnds, ReferenceIdx)

StartReferenceBurst = Starts(ReferenceIdx);
EndReferenceBurst = Ends(ReferenceIdx);

% get the duration of each burst
OverlappingStartTimes = SortedStarts(OverlappingBurstIndexes);
OverlappingEndTimes = SortedEnds(OverlappingBurstIndexes);
OverlappingBurstDurations = OverlappingEndTimes - OverlappingStartTimes;

% identify 50% of each burst
MinimumOverlapDurations = round(OverlappingBurstDurations*.5); % 50% duration for each burst

% get the amount of time that overlaps with reference
OverlappingStartTimes(OverlappingStartTimes<StartReferenceBurst) = StartReferenceBurst;
OverlappingEndTimes(OverlappingEndTimes>EndReferenceBurst) = EndReferenceBurst;
OverlapDurations = OverlappingEndTimes - OverlappingStartTimes;

% remove bursts that don't overlap enough
NotOverlappingEnough = OverlapDurations < MinimumOverlapDurations;
OverlappingBurstIndexes(NotOverlappingEnough) = [];
end

% TODO rename and check