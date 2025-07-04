function Bursts = detect_bursts(EEGBroadband, ChannelIndex, EEGNarrowbands,...
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
%
% NarrowbandRanges is a struct with each field a different band corresponding to
% the relevant bands, and the edges of that band [LowCutoff, HighCutoff].
% Should be same number of fields as items in FiltEEG.
%
% KeepTimepoints (optional) is a vector the same number of timepoints as the EEG data, and
% should be a 1 if its a clean timepoint, 0 if an artefact. Bursts will not
% be detected where there are artefacts.
%
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
    if all(isnan(ChannelNarrowband))
        continue
    end

    for Sign = Signs
        SignChannelBroadband = ChannelBroadband*Sign;
        SignChannelNarrowband = ChannelNarrowband*Sign;

        for idxCriteriaSet = 1:numel(CriteriaSets) % loop through combination of thresholds
            CriteriaSet = CriteriaSets(idxCriteriaSet);

            % find all cycles in a given band
            CycleTable = cycy.detect_cycles(SignChannelBroadband, SignChannelNarrowband);
            CycleTable = cycy.measure_cycle_properties(SignChannelBroadband, CycleTable, SampleRate);

            if isfield(CriteriaSet, 'PeriodNeg') && ~isempty(CriteriaSet.PeriodNeg) && CriteriaSet.PeriodNeg
                CriteriaSet.PeriodNeg = sort(1./Band);
            end

            % find bursts
            [BurstsSubset, ~] = cycy.aggregate_cycles_into_bursts(CycleTable, CriteriaSet, KeepTimepoints);

            % add metadata
            Metadata = struct();
            Metadata.Band = BandLabels{idxBand};
            Metadata.ChannelIndex = ChannelIndex;
            Metadata.ChannelIndexLabel = EEGBroadband.chanlocs(ChannelIndex).labels;
            Metadata.Sign = Sign;
            Metadata.CriteriaSetIndex = idxCriteriaSet;

            BurstsSubset = add_fields_to_struct(BurstsSubset, Metadata);

            % save to collective struct
            AllBursts = cat_structs(AllBursts, BurstsSubset);
        end
    end
    disp(['Finished burst detection for ', BandLabels{idxBand}])
end

% Here we remove duplicate burst detections, by picking a single burst from
% those overlapping in time, detected with the different criteria.
% We do this by selecting the longest burst among every set of overlapping
% ones and discarding the others.
% Additionally, if any of the shorter bursts last more than the minimum
% number of cycles outside of the longest burst, then these will be
% cropped into their own short burst.
MinCyclesPerBurst = [CriteriaSets.MinCyclesPerBurst];
MinCyclesPerBurst = min(MinCyclesPerBurst);
Bursts = cycy.remove_overlapping_bursts(AllBursts, MinCyclesPerBurst);

disp(['Finished ', num2str(ChannelIndex)])

