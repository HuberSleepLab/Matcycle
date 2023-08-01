function Bursts = aggregate_bursts_by_frequency(AllBursts, EEG, MinFreqRange)
% identifies bursts that occur at the same time that are actually the same
% frequency, aggregates them together. Ignores bursts where there wasn't any overlap.

% Part of Matcycle 2022, by Sophia Snipes.

[nCh, ~] = size(EEG.data);

% reorder bursts by size so that biggest ones always get chosen as
% "reference"

Starts = [AllBursts.Start];
Ends = [AllBursts.End];
BurstID = 1:numel(AllBursts);
Durations = Ends-Starts;
[~, Order] = sort(Durations, 'descend'); % start from the largest
AllBursts = AllBursts(Order);
BurstID = BurstID(Order);

% loops through starts, finds overlap; leaves the biggest burst intact,
% adjusts the starts and ends of the others so they're outside the burst.

Starts = [AllBursts.Start];
Ends = [AllBursts.End];
nBursts = numel(Starts);
RM = false(nBursts, 1); % keep track of bursts that have been aggregated
Indexes = 1:nBursts;
Bursts = struct();

for Indx_B = 1:nBursts

    % skip if already looked at and decided to remove
    if RM(Indx_B)
        continue
    end

    Start_Edge = Starts(Indx_B);
    End_Edge = Ends(Indx_B);

    %     if Start_Edge <126*fs && End_Edge > 126*fs
    %         a=1
    %     end



    %%% get all the smaller bursts that overlap with this large burst
    Overlap_Starts = Starts >= Start_Edge & Starts < End_Edge & Indexes > Indx_B;
    Overlap_Ends = Ends > Start_Edge & Ends <= End_Edge & Indexes > Indx_B;
    Overlap = find(Overlap_Starts | Overlap_Ends);

    % skip if no other channel showed a burst (suspicious!)
    if isempty(Overlap)
        RM(Indx_B) = true; % no longer considered a burst
        continue
    end

    %%% only consider bursts that overlap > 50%

    % get the duration of each burst
    Starts_O_temp = Starts(Overlap);
    Ends_O_temp = Ends(Overlap);
    Total_Durations = Ends_O_temp - Starts_O_temp;

    % identify how much of that burst is needed to reach 50%
    Threshold_Durations = round(Total_Durations*.5); % 50% duration for each burst

    % get the amount of time that overlaps with reference
    Starts_O_temp(Starts_O_temp<Start_Edge) = Start_Edge;
    Ends_O_temp(Ends_O_temp>End_Edge) = End_Edge;
    Overlap_Durations = Ends_O_temp - Starts_O_temp;

    % remove bursts that don't overlap enough
    Remove_Overlaps = Overlap_Durations < Threshold_Durations;
    Overlap(Remove_Overlaps) = [];
    Starts_O = Starts(Overlap);
    Ends_O = Ends(Overlap);

    if isempty(Overlap)
        RM(Indx_B) = true; % no longer considered a burst
        continue
    end


    %%% aggregate bursts based on frequency

    Coh_Bursts = [];
    for Indx_O = 1:numel(Overlap)
        Ref_Peaks = AllBursts(Indx_B).NegPeakIdx; % get location of all peaks in reference burst

        % identify in reference the peaks that overlap with other burst
        Start_Overlap = max(AllBursts(Indx_B).Start, Starts_O(Indx_O));
        End_Overlap = min(AllBursts(Indx_B).End, Ends_O(Indx_O));
        Overlap_RefPeaks = Ref_Peaks>=Start_Overlap & Ref_Peaks<=End_Overlap;

        % identify in reference the mean frequency of the overlapping segment
        Period = AllBursts(Indx_B).period;

        if numel(Period) == 1 % because of stupid hack earlier, that reduces to 1 if they're all the same
            Period = repmat(Period, 1, numel(Overlap_RefPeaks));
        end

        Freq = 1/mean(Period(Overlap_RefPeaks), 'omitnan');

        FreqRange = [Freq-MinFreqRange, Freq+MinFreqRange];

        % identify overlapping peaks in other burst
        Other_Peaks = AllBursts(Overlap(Indx_O)).NegPeakIdx;
        Overlap_OtherPeaks = Other_Peaks>=Start_Overlap & Other_Peaks<=End_Overlap;

        % get frequency of overlapping segment in other burst
        Period = AllBursts(Overlap(Indx_O)).period;

        if numel(Period) == 1
            Period = repmat(Period, 1, numel(Overlap_OtherPeaks));
        end

        Freq_Overlap = 1/mean(Period(Overlap_OtherPeaks), 'omitnan');


        % if frequency of overlapping burst is within range, keep
        if Freq_Overlap >= FreqRange(1) && Freq_Overlap <=FreqRange(2)
            Coh_Bursts = cat(2, Coh_Bursts, Overlap(Indx_O));
        end
    end

    % if there are no channels coherent, same as not having overlap
    if numel(Coh_Bursts)<1
        RM(Indx_B) = true;
        continue
    end

    % include reference burst in list
    Coh_Bursts = cat(2, Coh_Bursts, Indx_B);

    % remove from list of possible bursts all overlapping coherent
    RM(Coh_Bursts) = true;


    %%% assemble new burst's info

    NewB = AllBursts(Indx_B);
    NewB.BurstID = BurstID(Coh_Bursts);
    NewB.Coh_Burst_Channels = [AllBursts(Coh_Bursts).Channel];
    NewB.Coh_Burst_Channel_Labels = [AllBursts(Coh_Bursts).Channel_Label];
    NewB.Coh_Burst_Starts = [AllBursts(Coh_Bursts).Start];
    NewB.Coh_Burst_Ends = [AllBursts(Coh_Bursts).End];
    NewB.Coh_Burst_nPeaks = [AllBursts(Coh_Bursts).nPeaks];
    NewB.Coh_Burst_Signs = [AllBursts(Coh_Bursts).Sign];
    NewB.Coh_Burst_Frequency = [AllBursts(Coh_Bursts).Frequency];

    % special info
    NewB.Coh_Burst_amplitude = zeros(1, numel(Coh_Bursts));
    NewB.Coh_Burst_amplitude_sum = zeros(1, numel(Coh_Bursts));
    Coh_Peaks = struct();
    for Indx_C = 1:numel(Coh_Bursts)
        NewB.Coh_Burst_amplitude(Indx_C) = mean(AllBursts(Coh_Bursts(Indx_C)).amplitude);
        NewB.Coh_Burst_amplitude_sum(Indx_C) = sum(AllBursts(Coh_Bursts(Indx_C)).amplitude);

        Coh_Peaks(Indx_C).NegPeakIdx = AllBursts(Coh_Bursts(Indx_C)).NegPeakIdx;
        Coh_Peaks(Indx_C).PosPeakIdx = AllBursts(Coh_Bursts(Indx_C)).PosPeakIdx;
    end
    NewB.Coh_Burst_Peaks = Coh_Peaks;

    NewB.All_Start = min([NewB.Coh_Burst_Starts, NewB.Start]);
    NewB.All_End = max([NewB.Coh_Burst_Ends, NewB.End]);

    % how many channels involved in burst
    NewB.globality_bursts = numel(unique(NewB.Coh_Burst_Channels))./nCh;

    Bursts = cat_structs(Bursts, NewB);
end

% reorder by start time
Starts = [Bursts.Start];
[~, SortedOrder] = sort(Starts, 'ascend');
Bursts = Bursts(SortedOrder);

disp(['Reduced to ', num2str(numel(Bursts)), ' from ', num2str(nBursts), ' bursts'])

% TODO rename and check