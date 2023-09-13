function Bursts = detect_bursts_all_channels(EEGBroadband, EEGNarrowbands, NarrowbandRanges, ...
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
% See cycy.detect_bursts() for argument documentation.
%
% RunParallel is a boolean (default false), if true, runs burst detection in 
% channels in parallel.
%
% Part of Matcycle 2022, by Sophia Snipes.

[ChannelCount, ~] = size(EEGBroadband.data);

% initialize spot to put data.
% We use a cell array here because that's what works well with parfor.
AllChannelBursts = cell([1, ChannelCount]);

if RunParallel
    parfor idxChannel = 1:ChannelCount % get bursts for every component
        AllChannelBursts{idxChannel} = cycy.detect_bursts(EEGBroadband, idxChannel, ...
            EEGNarrowbands, NarrowbandRanges, CriteriaSets, KeepTimepoints);
    end
else
    for idxChannel = 1:ChannelCount
        AllChannelBursts{idxChannel} = cycy.detect_bursts(EEGBroadband, idxChannel, ...
            EEGNarrowbands, NarrowbandRanges, CriteriaSets, KeepTimepoints);
    end
end

% convert from cell array to struct
Bursts = struct();
for idxChannel = 1:ChannelCount
    Bursts = cat_structs(Bursts, AllChannelBursts{idxChannel});
end