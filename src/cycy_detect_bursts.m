function CBursts = cycy_detect_bursts(EEGBroadband, ChannelIndex, EEGNarrowbands,...
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


% do burst detection on both original and inverted signal
Signs = [1 -1];
Fields = {'Band', 'Channel', 'Channel_Label', 'Sign', 'BT'};

BandLabels = fieldnames(NarrowbandRanges);
Chan = EEGBroadband.data(ChannelIndex, :);
fs = EEGBroadband.srate;

% gather all the bursts and peaks for a single component from all
% the bands
CBursts = struct();

for Indx_B = 1:numel(BandLabels)
    Band = NarrowbandRanges.(BandLabels{Indx_B});
    fChan = EEGNarrowbands(Indx_B).data(ChannelIndex, :);

    for Indx_S = 1:numel(Signs)
        Signal = Chan*Signs(Indx_S);
        fSignal = fChan*Signs(Indx_S);

        for Indx_BT = 1:numel(CriteriaSets) % loop through combination of thresholds

            % assemble meta info to save for each peak
            Labels = [BandLabels(Indx_B), ChannelIndex, indexes2labels(ChannelIndex, EEGBroadband.chanlocs), Signs(Indx_S), Indx_BT];

            % find all peaks in a given band
            Peaks = cycy_detect_cycles(Signal, fSignal);
            Peaks = cycy_cycle_properties(Signal, Peaks, fs);

            % assign labels to peaks
            for n = 1:numel(Peaks)
                for Indx_F = 1:numel(Fields)
                    Peaks(n).(Fields{Indx_F}) = Labels{Indx_F};
                end
            end

            BT = CriteriaSets(Indx_BT);
            BT.period = 1./Band; % add period threshold

            % remove thresholds that are empty
            BT = removeEmptyFields(BT);

            % find bursts
            [Bursts, ~] = cycy_aggregate_cycles(Peaks, BT, KeepTimepoints);

            disp([BandLabels{Indx_B}])

            % save to collective struct
            CBursts = catStruct(CBursts, Bursts);
        end
    end
end

% remove duplicates and add to general struct
Min_Peaks = min(Min_Peaks);
CBursts = cycy_remove_overlapping_bursts(CBursts, Min_Peaks);

disp(['Finished ', num2str(ChannelIndex)])

end