function Bursts = cycy_detect_bursts_all_channels(EEGBroadband, EEGNarrowbands, NarrowbandRanges, ...
    CriteriaSets, RunParallel, KeepTimepoints)
arguments
    EEGBroadband struct
    EEGNarrowbands struct
    NarrowbandRanges struct
    CriteriaSets struct
    RunParallel logical = false
    KeepTimepoints = ones(1, size(EEGBroadband.data, 2));
end
% From EEG data, finds all the bursts in each channel.
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
% RunParallel is a boolean (default false), if true, runs burst detection in 
% channels in parallel.
%
% KeepTimepoints (optional) is a vector the same number of timepoints as the EEG data, and
% should be a 1 if its a clean timepoint, 0 if an artefact. Bursts will not
% be detected where there are artefacts.

% Part of Matcycle 2022, by Sophia Snipes.

[ChannelCount, ~] = size(EEGBroadband.data);

% initialize spot to put data.
% We use a cell array here because that's what works well with parfor.
AllChannelBursts = cell([1, ChannelCount]);

if RunParallel
    parfor Indx_C = 1:ChannelCount % get bursts for every component
        AllChannelBursts{Indx_C} = cycy_detect_bursts(Indx_C, EEGBroadband, ...
            EEGNarrowbands, CriteriaSets, MinCyclesPerBurst, NarrowbandRanges, KeepTimepoints);
    end
else
    for Indx_C = 1:ChannelCount
        AllChannelBursts{Indx_C} = cycy_detect_bursts(Indx_C, EEGBroadband, ...
            EEGNarrowbands, CriteriaSets, NarrowbandRanges, KeepTimepoints);
    end
end

% convert from cell array to single struct
Bursts = struct();
for Indx_C = 1:ChannelCount
    if isempty(AllChannelBursts{Indx_C})
        continue
    end

    Bursts = catStruct(Bursts, AllChannelBursts{Indx_C});
end