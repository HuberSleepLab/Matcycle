function Bursts = aggregate_bursts(AllBursts, EEG, MinCoherence)
% identifies bursts that occur at the same time that are actually coherent
% with each other, aggregates them together. Ignores bursts where there
% wasn't any overlap.

% Part of Matcycle 2022, by Sophia Snipes.


freqRes = 4;
fs = EEG.srate;
[nCh, ~] = size(EEG.data);

% reorder bursts by size so that biggest ones always get chosen as
% "prototype"

Starts = [AllBursts.Start];
Ends = [AllBursts.End];
Durations = Ends-Starts;
[~, Order] = sort(Durations, 'descend'); % start from the largest
AllBursts = AllBursts(Order);


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

    % get all the overlaps with this large burst
    Overlap_Starts = Starts >= Start_Edge & Starts < End_Edge & Indexes > Indx_B;
    Overlap_Ends = Ends > Start_Edge & Ends <= End_Edge & Indexes > Indx_B;
    Overlap = find(Overlap_Starts | Overlap_Ends);

    % skip if no other channel showed a burst (suspicious!)
    if isempty(Overlap)
        RM(Indx_B) = true; % no longer considered a burst
        continue
    end

    % only consider an overlap > 50%
    Starts_O = [AllBursts(Overlap).Start];
    Ends_O = [AllBursts(Overlap).End];
    Whole_Durations = Ends_O - Starts_O;

    Threshold_Durations = round(Whole_Durations*.5);

    Starts_O(Starts_O<Start_Edge) = Start_Edge;
    Ends_O(Ends_O>End_Edge) = End_Edge;
    Overlap_Durations = Ends_O - Starts_O;

    Overlap(Overlap_Durations < Threshold_Durations) = [];

    if isempty(Overlap)
        RM(Indx_B) = true; % no longer considered a burst
        continue
    end

    % determine if its the same burst based on coherence
    BMain = AllBursts(Indx_B);
    FreqRange_Main = 1./[max(BMain.period); min(BMain.period)];
    Coh_Bursts = [];

    for Indx_O = 1:numel(Overlap)
        B = AllBursts(Overlap(Indx_O));
        Ref = EEG.data(BMain.Channel, B.Start:B.End); % only use smaller bursts' time points
        Data = EEG.data(B.Channel, B.Start:B.End);

        [Coherence, Freqs] = getCoherence(Ref, Data, fs, freqRes);

        % look at coherence specifically in the frequency range of the main
        % burst
        Range = dsearchn(Freqs, FreqRange_Main); % coherence specific to frequency range of this burst
        Band_Coherence = mean(Coherence(Range(1):Range(2), :), 1);

        % save for later
        if Band_Coherence >= MinCoherence
            Coh_Bursts = cat(1, Coh_Bursts, Overlap(Indx_O));
        end
    end


    % if there are no channels coherent, same as not having overlap
    if numel(Coh_Bursts)<1
        continue
    end

    % remove from list of possible bursts all overlapping coherent
    RM(Coh_Bursts) = true;

    %%% assemble new burst's info
    NewB = BMain;
    NewB.Coh_Burst_Channels = [AllBursts(Coh_Bursts).Channel];
    NewB.Coh_Burst_Starts = [AllBursts(Coh_Bursts).Start];
    NewB.Coh_Burst_Ends = [AllBursts(Coh_Bursts).End];
    NewB.Coh_Burst_nPeaks = [AllBursts(Coh_Bursts).nPeaks];
    NewB.Coh_Burst_Signs = [AllBursts(Coh_Bursts).Sign];

    % special info
    NewB.Coh_Burst_amplitude = zeros(1, numel(Coh_Bursts));
    Coh_Peaks = struct();
    for Indx_C = 1:numel(Coh_Bursts)
        NewB.Coh_amplitude(Indx_C) = mean(AllBursts(Coh_Bursts(Indx_C)).amplitude);
        Coh_Peaks(Indx_C).NegPeakIdx = AllBursts(Coh_Bursts(Indx_C)).NegPeakIdx;
         Coh_Peaks(Indx_C).PosPeakIdx = AllBursts(Coh_Bursts(Indx_C)).PosPeakIdx;
    end
    NewB.Coh_Burst_Peaks = Coh_Peaks; % for travelling eventually?

    NewB.All_Start = min([NewB.Coh_Burst_Starts, NewB.Start]);
    NewB.All_End = max([NewB.Coh_Burst_Ends, NewB.End]);

    % how many channels involved in burst
    NewB.globality_bursts = numel(unique(NewB.Coh_Burst_Channels))./nCh;

    Bursts = cat_structs(Bursts, NewB);
end

% reodrer by start time
Starts = [Bursts.Start];
[~, SortedOrder] = sort(Starts, 'ascend');
Bursts = Bursts(SortedOrder);

disp(['Reduced to ', num2str(numel(Bursts)), ' from ', num2str(nBursts), ' bursts'])

