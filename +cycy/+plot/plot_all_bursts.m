function plot_all_bursts(EEG, YGap, Bursts, ColorCode)
arguments
    EEG
    YGap = 20;
    Bursts = [];
    ColorCode = [];
end
% function to view bursts in the EEG
% Type is either 'ICA' or 'EEG', and will appropriately plot the bursts
% over the channels or the components, accordingly.
% colorcode indicates based on which property to pick the colors.
% Part of Matcycle 2022, by Sophia Snipes.


figure('Units','normalized', 'OuterPosition',[0 0 1 1])
hold on

% plot broadband EEG data
cycy.plot.eeg_data(EEG.data, EEG.srate, YGap)

% get colors for plotting
if isempty(ColorCode)
    % TODO
else
    if ischar(Bursts(1).(ColorCode))
        Groups = unique({Bursts.(ColorCode)});
    else
        Groups = unique([Bursts.(ColorCode)]);
    end

    if numel(Groups) <= 10
        Colors = cycy.utils.pick_colors(numel(Groups));
    elseif numel(Groups) <= 20
        Colors = jet(numel(Groups));
    else
        Colors = rand(numel(Groups), 3);
    end
end

for idxGroup = 1:numel(Groups)
    if ischar(Bursts(1).(ColorCode))
        Group = Groups{idxGroup};
        BurstIndexes = strcmp({Bursts.(ColorCode)}, Group);
    else
        Group = Groups(idxGroup);
        BurstIndexes = [Bursts.(ColorCode)]==Group;
    end

    [BurstMask, ReferenceMask] = mask_bursts(EEG.data, Bursts(BurstIndexes));
    cycy.plot.eeg_data(BurstMask, EEG.srate, YGap, Colors(idxGroup))
    if ~isempty(ReferenceMask)
        cycy.plot.eeg_data(ReferenceMask, EEG.srate, YGap, Colors(idxGroup), 2, Group)
    end
end


xlim(Bursts(1).Start/EEG.srate+[0 20])
legend(Groups)
end

function [BurstMask, ReferenceMask] = mask_bursts(EEGData, Bursts)
% creates a matrix the size of the data in EEG, with values of the data
% only during the bursts

BurstMask = nan(size(EEGData));

if isfield(Bursts, 'ClusterStart')
    Starts = [Bursts.ClusterStarts];
    Ends = [Bursts.ClusterEnds];
    Channels = [Bursts.ClusterChannelIndexes];
else
    Starts = [Bursts.Start];
    Ends = [Bursts.End];
    Channels = [Bursts.ChannelIndex];
end

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
    BurstMask(RefChannels(idxRefBursts), RefStarts(idxRefBursts):RefEnds(idxRefBursts)) = ...
        EEGData(RefChannels(idxRefBursts), RefStarts(idxRefBursts):RefEnds(idxRefBursts));
end
end