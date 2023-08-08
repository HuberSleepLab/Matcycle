function Bursts = aggregate_bursts_by_frequency(AllBursts, EEGBroadband, MinFrequencyRange)
% identifies bursts that occur at the same time that are actually the same
% frequency, aggregates them together. Ignores bursts where there wasn't any overlap.

% Part of Matcycle 2022, by Sophia Snipes.

[ChannelCount, ~] = size(EEGBroadband.data);
BurstsCount = numel(AllBursts);

% reorder bursts by size so that biggest ones always get chosen first as
% "reference"
[AllBurstsSorted, SortedBurstIndexes] = sort_bursts_by_length(AllBursts);

% loops through starts, finds overlap; leaves the biggest burst intact,
% adjusts the starts and ends of the others so they're outside the burst.
SortedStarts = [AllBurstsSorted.Start];
SortedEnds = [AllBurstsSorted.End];
HasBeenEvaluated = false(BurstsCount, 1); % keep track of bursts that have been aggregated
Bursts = struct();

for idxBurst = 1:BurstsCount

    % skip if already looked at and decided to remove
    if HasBeenEvaluated(idxBurst)
        continue
    end

    % Identify bursts that overlap in time with the current burst
    OverlappingBurstIndexes = find_overlapping_windows(SortedStarts, SortedEnds, idxBurst);

    % skip if no other channel showed a burst
    if isempty(OverlappingBurstIndexes)
        HasBeenEvaluated(idxBurst) = true;
        continue
    end

    % only consider bursts that overlap > 50%
    OverlappingBurstIndexes = keep_only_mostly_overlapping_bursts( ...
        OverlappingBurstIndexes, SortedStarts, SortedEnds, idxBurst);

    if isempty(OverlappingBurstIndexes)
        HasBeenEvaluated(idxBurst) = true;
        continue
    end

    % aggregate bursts based on frequency
    AggregatedBurstIndexes = aggregate_by_frequency(AllBurstsSorted, ...
        SortedStarts, SortedEnds, OverlappingBurstIndexes, MinFrequencyRange, idxBurst);

    % if there are no channels coherent, same as not having overlap
    if numel(AggregatedBurstIndexes)<1
        HasBeenEvaluated(idxBurst) = true;
        continue
    end

    % include reference burst in list
    AggregatedBurstIndexes = cat(2, AggregatedBurstIndexes, idxBurst);

    % remove from list of possible bursts all overlapping coherent
    HasBeenEvaluated(AggregatedBurstIndexes) = true;

    % assemble new burst's info
    Burst = assemble_burst_metadata(AllBurstsSorted, AggregatedBurstIndexes, SortedBurstIndexes, ChannelCount);
    Bursts = cat_structs(Bursts, Burst);
end

Bursts = sort_bursts_by_start(Bursts);

disp(['Reduced to ', num2str(numel(Bursts)), ' from ', num2str(BurstsCount), ' bursts'])
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Functions

%%%
function [BurstsSorted, SortedBurstIndexes] = sort_bursts_by_length(Bursts)
Starts = [Bursts.Start];
Ends = [Bursts.End];

BurstIndexes = 1:numel(Starts);

BurstDurations = Ends-Starts;
[~, BustsOrderByDuration] = sort(BurstDurations, 'descend'); % start from the largest
BurstsSorted = Bursts(BustsOrderByDuration);
SortedBurstIndexes = BurstIndexes(BustsOrderByDuration);
end


%%%
function BurstsSorted = sort_bursts_by_start(Bursts)
BurstStarts = [Bursts.Start];
[~, SortedOrder] = sort(BurstStarts, 'ascend');
BurstsSorted = Bursts(SortedOrder);
end


%%%
function OverlappingBurstIndexes = find_overlapping_windows(Starts, Ends, ReferenceIdx)
BurstIndexes = 1:numel(Starts);
StartReferenceBurst = Starts(ReferenceIdx);
EndReferenceBurst = Ends(ReferenceIdx);

isOverlappingStart = Starts >= StartReferenceBurst & Starts < EndReferenceBurst & BurstIndexes > ReferenceIdx;
isOverlappingEnd = Ends > StartReferenceBurst & Ends <= EndReferenceBurst & BurstIndexes > ReferenceIdx;
OverlappingBurstIndexes = find(isOverlappingStart | isOverlappingEnd);
end


%%%
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


%%%
function AggregatedBurstIndexes = aggregate_by_frequency(Bursts, ...
    Starts, Ends, OverlappingBurstIndexes, MinFrequencyRange, ReferenceIdx)

FinalOverlappingStartTimes = Starts(OverlappingBurstIndexes);
FinalOverlappingEndTimes = Ends(OverlappingBurstIndexes);

ReferenceNegPeakIdx = Bursts(ReferenceIdx).NegPeakIdx; % get location of all peaks in reference burst

AggregatedBurstIndexes = [];
for idxOverlapper = 1:numel(OverlappingBurstIndexes)

    % identify in reference the cycles that overlap with other burst
    StartOverlap = max(Bursts(ReferenceIdx).Start, FinalOverlappingStartTimes(idxOverlapper));
    EndOverlap = min(Bursts(ReferenceIdx).End, FinalOverlappingEndTimes(idxOverlapper));
    Overlap_RefPeaks = ReferenceNegPeakIdx>=StartOverlap & ReferenceNegPeakIdx<=EndOverlap;

    % identify in reference the mean frequency of the overlapping segment
    ReferencePeriod = Bursts(ReferenceIdx).PeriodNeg;
    ReferenceFrequency = 1/mean(ReferencePeriod(Overlap_RefPeaks), 'omitnan');

    FrequencyRange = [ReferenceFrequency-MinFrequencyRange, ReferenceFrequency+MinFrequencyRange];

    % identify overlapping peaks in the overlapping burst
    OverlapperNegPeakIdx = Bursts(OverlappingBurstIndexes(idxOverlapper)).NegPeakIdx;
    OverlappingOverlapperPeakIdx = OverlapperNegPeakIdx>=StartOverlap & OverlapperNegPeakIdx<=EndOverlap;

    % get frequency of overlapping segment in other burst
    OverlapperPeriod = Bursts(OverlappingBurstIndexes(idxOverlapper)).PeriodNeg;
    OverlapperFrequency = 1/mean(OverlapperPeriod(OverlappingOverlapperPeakIdx), 'omitnan');

    % if frequency of overlapping burst is within range, keep
    if OverlapperFrequency >= FrequencyRange(1) && OverlapperFrequency <=FrequencyRange(2)
        AggregatedBurstIndexes = cat(2, AggregatedBurstIndexes, OverlappingBurstIndexes(idxOverlapper));
    end
end
end


%%%
function Burst = assemble_burst_metadata(AllBursts, AggregatedBurstIndexes, BurstIndexes, ChannelCount)

% transfer metadata from aggregated bursts
Burst = AllBursts(idxBurst);
Burst.ClusterBurstsIdx = BurstIndexes(AggregatedBurstIndexes);
Burst.ClusterChannelIndexes = [AllBursts(AggregatedBurstIndexes).ChannelIndex];
Burst.ClusterChannelLabels = [AllBursts(AggregatedBurstIndexes).ChannelIndexLabel];
Burst.ClusterStarts = [AllBursts(AggregatedBurstIndexes).Start];
Burst.ClusterEnds = [AllBursts(AggregatedBurstIndexes).End];
Burst.ClusterCycleCounts = [AllBursts(AggregatedBurstIndexes).CycleCount];
Burst.ClusterSigns = [AllBursts(AggregatedBurstIndexes).Sign];
Burst.ClusterFrequency = [AllBursts(AggregatedBurstIndexes).Frequency];

% summarize cycle information about aggregated bursts
Burst.ClusterAmplitude = zeros(1, numel(AggregatedBurstIndexes));
Burst.ClusterAmplitudeSum = zeros(1, numel(AggregatedBurstIndexes));
ClusterPeaks = struct();
for Indx_C = 1:numel(AggregatedBurstIndexes)
    Burst.ClusterAmplitude(Indx_C) = mean(AllBursts(AggregatedBurstIndexes(Indx_C)).Amplitude);
    Burst.ClusterAmplitudeSum(Indx_C) = sum(AllBursts(AggregatedBurstIndexes(Indx_C)).Amplitude);

    ClusterPeaks(Indx_C).NegPeakIdx = AllBursts(AggregatedBurstIndexes(Indx_C)).NegPeakIdx;
    ClusterPeaks(Indx_C).PosPeakIdx = AllBursts(AggregatedBurstIndexes(Indx_C)).PosPeakIdx;
end

Burst.ClusterPeaks = ClusterPeaks;

Burst.ClusterStart = min([Burst.ClusterStarts, Burst.Start]);
Burst.ClusterEnd = max([Burst.ClusterEnds, Burst.End]);

% how many channels involved in burst
Burst.ClusterGlobality = numel(unique(Burst.ClusterChannels))./ChannelCount;

end