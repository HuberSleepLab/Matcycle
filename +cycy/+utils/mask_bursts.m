function [BurstMask, ReferenceMask] = mask_bursts(EEGData, Bursts)
% creates a matrix the size of the data in EEG, with values of the data
% only during the bursts

BurstMask = nan(size(EEGData));

% identify location of bursts
if isfield(Bursts, 'ClusterStart')
    Starts = [Bursts.ClusterStarts];
    Ends = [Bursts.ClusterEnds];
    Channels = [Bursts.ClusterChannelIndexes];
elseif ~isfield(Bursts, 'Start')
    return
else
    Starts = [Bursts.Start];
    Ends = [Bursts.End];
    Channels = [Bursts.ChannelIndex];
end

% move data from EEG to mask
for idxBursts = 1:numel(Starts)
    BurstMask(Channels(idxBursts), Starts(idxBursts):Ends(idxBursts)) = ...
        EEGData(Channels(idxBursts), Starts(idxBursts):Ends(idxBursts));
end

% create seperate mask just for reference channels when burst clusters are
% provided, so that they can be made thicker
if ~isfield(Bursts, 'ClusterStart')
    ReferenceMask = [];
    return
end

ReferenceMask = nan(size(EEGData));

RefStarts = [Bursts.Start];
RefEnds = [Bursts.End];
RefChannels = [Bursts.ChannelIndex];

for idxRefBursts = 1:numel(RefStarts)
   ReferenceMask(RefChannels(idxRefBursts), RefStarts(idxRefBursts):RefEnds(idxRefBursts)) = ...
        EEGData(RefChannels(idxRefBursts), RefStarts(idxRefBursts):RefEnds(idxRefBursts));
end
end
