function FinalBursts = getAllBursts(EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points)
% From EEG data, finds all the bursts in each channel.
% EEG is an EEGLAB structure.
% FiltEEG is an EEGLAB structure with multiple entries for each filtered
% range.
% BurstThreshold1 & 2 are structures that can contain different parameters
% for detecting bursts.
% Can be:
% - isProminent:
% - truePeak:
% - periodConsistency:
% - periodMeanConsistency:
% - ampConsistency:
% - efficiency:
% - efficiencyAdj:
% - monotonicity:
% - flankConsistency:
% Bands is a structure with each field a different band corresponding to
% the relevant bands, and the edges of that band [LowCutoff, HighCutoff].
% Should be same number of fields as items in FiltEEG.

% Part of Matcycle 2022, by Sophia Snipes.

% TODO: maybe BurstThreshold only 1 entry, and then can loop through
% different dimentions.


% do both positive and negative signal
Signs = [1 -1];
Fields = {'Band', 'Channel', 'Sign', 'BT'};

fs = EEG.srate;

% other parameters
nChan = size(EEG.data, 1);


% initialize spots to put data
AllBursts = cell([1, nChan]);
AllPeaks = AllBursts;

BandLabels = fieldnames(Bands);

% for Indx_C = 1:nChan % get bursts for every component % DEBUG
parfor Indx_C = 1:nChan % get bursts for every component

    % stupid parfor problems
    EEG2 = EEG;
    FiltEEG2 = FiltEEG;
    B = Bands;

    Chan = EEG2.data(Indx_C, :);

    % gather all the bursts and peaks for a single component from all
    % the bands
    CBursts = struct();

    for Indx_B = 1:numel(BandLabels)
        Band = B.(BandLabels{Indx_B});
        fChan = FiltEEG2(Indx_B).data(Indx_C, :);

        for Indx_S = 1:numel(Signs)
            Signal = Chan*Signs(Indx_S);
            fSignal = fChan*Signs(Indx_S);

            % remove edge peaks
            Peaks([1, end]) = [];

            for Indx_BT = 1:numel(BurstThresholds) % loop through combination of thresholds

                % assemble meta info to save for each peak
                Labels = [BandLabels(Indx_B), Indx_C, Signs(Indx_S), Indx_BT];

                % find all peaks in a given band
                Peaks = peakDetection(Signal, fSignal);
                Peaks = peakProperties(Signal, Peaks, fs);

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
                [Bursts, ~] = findBursts(Peaks, BT, Min_Peaks, Keep_Points);

                % save to collective structure
                CBursts = catStruct(CBursts, Bursts);
            end
        end
    end

    % remove duplicates and add to general structure
    CBursts = removeOverlapBursts(CBursts, Min_Peaks);
    AllBursts{Indx_C} = CBursts;

    disp(['Finished ', num2str(Indx_C)])
end

% save to single structure
FinalBursts = struct();
FinalPeaks = struct();
for Indx_C = 1:nChan
    FinalBursts = catStruct(FinalBursts, AllBursts{Indx_C});
    FinalPeaks = catStruct(FinalPeaks, AllPeaks{Indx_C});
end