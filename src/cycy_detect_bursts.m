function Bursts = cycy_detect_bursts(EEGBroadband, ChannelIndex, EEGNarrowbands,...
    NarrowbandRanges, CriteriaSets, KeepTimepoints)
arguments
    EEGBroadband struct
    ChannelIndex (1,1) {mustBeInteger, mustBePositive}
    EEGNarrowbands struct
    NarrowbandRanges struct
    CriteriaSets struct
    KeepTimepoints = ones(1, size(EEGBroadband.data, 2));
end
% From EEG data, finds all the bursts in a single channel.
%
% EEGBroadband is an EEGLAB struct:
% (https://eeglab.org/tutorials/ConceptsGuide/Data_Structures.html#eeg-and-alleeg).
%
% EEGNarrowbands is an EEGLAB struct with multiple entries for each filtered
% range.
%
% CriteriaSets is a struct array that can contain different parameters
% for detecting bursts.
% The fields can include:
% - isProminent: whether peak sticks out relative to neighboring signal
% - truePeak: whether the min value is actually the minimum in the range
% - periodConsistency: whether the period is consistent left and right
% - periodMeanConsistency: mean of the above
% - ampConsistency: TODO
% - efficiency: TODO
% - efficiencyAdj: TODO
% - monotonicity: TODO
% - flankConsistency: TODO
%
% NarrowbandRanges is a struct with each field a different band corresponding to
% the relevant bands, and the edges of that band [LowCutoff, HighCutoff].
% Should be same number of fields as items in FiltEEG.
%
% KeepTimepoints (optional) is a vector the same number of timepoints as the EEG data, and
% should be a 1 if its a clean timepoint, 0 if an artefact. Bursts will not
% be detected where there are artefacts.

% Part of Matcycle 2022, by Sophia Snipes.

Signs = [1 -1]; % do burst detection on both original and inverted signal

BandLabels = fieldnames(NarrowbandRanges);
ChannelBroadband = EEGBroadband.data(ChannelIndex, :);
SampleRate = EEGBroadband.srate;

% gather all the bursts and peaks for a single component from all
% the bands
AllBursts = struct();

for idxBand = 1:numel(BandLabels)
    Band = NarrowbandRanges.(BandLabels{idxBand});
    ChannelNarrowband = EEGNarrowbands(idxBand).data(ChannelIndex, :);

    for Sign = Signs
        SignChannelBroadband = ChannelBroadband*Sign;
        SignChannelNarrowband = ChannelNarrowband*Sign;

        for idxCriteriaSet = 1:numel(CriteriaSets) % loop through combination of thresholds
            CriteriaSet = CriteriaSets(idxCriteriaSet);

            % find all peaks in a given band
            Cycles = cycy_detect_cycles(SignChannelBroadband, SignChannelNarrowband);
            Cycles = cycy_cycle_properties(SignChannelBroadband, Cycles, SampleRate);

            CriteriaSet.period = 1./Band; % add period threshold

            % remove thresholds that are empty
            CriteriaSet = remove_empty_fields_from_struct(CriteriaSet);

            % find bursts
            [BurstsSubset, ~] = cycy_aggregate_cycles(Cycles, CriteriaSet, KeepTimepoints);

            % add metadata
            Metadata = struct();
            Metadata.Band = BandLabels(idxBand);
            Metadata.ChannelIndex = ChannelIndex;
            Metadata.ChannelIndexOriginal = indexes2labels(ChannelIndex, EEGBroadband.chanlocs);
            Metadata.Sign = Sign;
            Metadata.CriteriaSetIndex = idxCriteriaSet;

            BurstsSubset = add_fields_to_struct(BurstsSubset, Metadata);

            % save to collective struct
            AllBursts = catStruct(AllBursts, BurstsSubset);
        end
    end
end

% remove duplicates and add to general struct
Min_Peaks = [CriteriaSets.Min_Peaks];
Min_Peaks = min(Min_Peaks);
Bursts = cycy_remove_overlapping_bursts(AllBursts, Min_Peaks);

disp(['Finished ', num2str(ChannelIndex)])

