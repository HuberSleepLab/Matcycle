function FinalBursts = cycy_detect_bursts(EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points)
% From EEG data, finds all the bursts in each channel.
% EEG is an EEGLAB struct:
% (https://eeglab.org/tutorials/ConceptsGuide/Data_Structures.html#eeg-and-alleeg).
% FiltEEG is an EEGLAB struct with multiple entries for each filtered
% range.
% BurstThreshold is a struct array that can contain different parameters
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
% Bands is a struct with each field a different band corresponding to
% the relevant bands, and the edges of that band [LowCutoff, HighCutoff].
% Should be same number of fields as items in FiltEEG.

% Part of Matcycle 2022, by Sophia Snipes.

nChan = size(EEG.data, 1);

% initialize spots to put data
AllBursts = cell([1, nChan]);

if nChan < 6
    for Indx_C = 1:nChan 
    AllBursts{Indx_C} = loopChannels(Indx_C, EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points);
    end
else
%                 for Indx_C = 1:nChan % get bursts for every component % DEBUG
    parfor Indx_C = 1:nChan % get bursts for every component
        AllBursts{Indx_C} = loopChannels(Indx_C, EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points);
    end
end

% save to single struct
FinalBursts = struct();
for Indx_C = 1:nChan
    if isempty(AllBursts{Indx_C})
        continue
    end

    FinalBursts = catStruct(FinalBursts, AllBursts{Indx_C});
end
end



function CBursts = loopChannels(Indx_C, EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points)

% handle min peaks when variable for each BT
if isempty(Min_Peaks) && isfield(BurstThresholds, 'Min_Peaks')
    Min_Peaks = [BurstThresholds.Min_Peaks];
    BurstThresholds = rmfield(BurstThresholds, 'Min_Peaks');
else
    Min_Peaks = repmat(Min_Peaks, numel(BurstThresholds), 1);
end 

% do both positive and negative signal
Signs = [1 -1];
Fields = {'Band', 'Channel', 'Channel_Label', 'Sign', 'BT'};

BandLabels = fieldnames(Bands);
Chan = EEG.data(Indx_C, :);
fs = EEG.srate;

% gather all the bursts and peaks for a single component from all
% the bands
CBursts = struct();

for Indx_B = 1:numel(BandLabels)
    Band = Bands.(BandLabels{Indx_B});
    fChan = FiltEEG(Indx_B).data(Indx_C, :);

    for Indx_S = 1:numel(Signs)
        Signal = Chan*Signs(Indx_S);
        fSignal = fChan*Signs(Indx_S);

        for Indx_BT = 1:numel(BurstThresholds) % loop through combination of thresholds

            % assemble meta info to save for each peak
            Labels = [BandLabels(Indx_B), Indx_C, indexes2labels(Indx_C, EEG.chanlocs), Signs(Indx_S), Indx_BT];

            % find all peaks in a given band
            Peaks = cycy_detect_cycles(Signal, fSignal);
            Peaks = cycy_cycle_properties(Signal, Peaks, fs);

            % assign labels to peaks
            for n = 1:numel(Peaks)
                for Indx_F = 1:numel(Fields)
                    Peaks(n).(Fields{Indx_F}) = Labels{Indx_F};
                end
            end

            BT = BurstThresholds(Indx_BT);
            BT.period = 1./Band; % add period threshold

            % remove thresholds that are empty
            BT = removeEmptyFields(BT);

            % find bursts
            [Bursts, ~] = cycy_aggregate_cycles(Peaks, BT, Min_Peaks(Indx_BT), Keep_Points);

            disp([BandLabels{Indx_B}])

            % save to collective struct
            CBursts = catStruct(CBursts, Bursts);
        end
    end
end

% remove duplicates and add to general struct
Min_Peaks = min(Min_Peaks);
CBursts = cycy_remove_overlapping_bursts(CBursts, Min_Peaks);

disp(['Finished ', num2str(Indx_C)])

end