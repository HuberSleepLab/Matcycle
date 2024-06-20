function plot_all_bursts(EEG, YGap, Bursts, ColorCategory)
arguments
    EEG
    YGap = 20;
    Bursts = [];
    ColorCategory = [];
end
% function to view bursts in the EEG
% Type is either 'ICA' or 'EEG', and will appropriately plot the bursts
% over the channels or the components, accordingly.
% colorcode indicates based on which property to pick the colors.
% Part of Matcycle 2022, by Sophia Snipes.
% ColorCategory is the fieldname that you want to use to color code the
% bursts.


figure('Units','normalized', 'OuterPosition',[0 0 1 1])
hold on

% plot broadband EEG data
cycy.plot.eeg_data(EEG.data, EEG.srate, YGap, '', [.6 .6 .6])

% get colors for plotting
[Colors, CategoryLabels] = pick_group_colors(Bursts, ColorCategory);

for idxCategory = 1:numel(CategoryLabels)

    % selecy data for each color
    if ischar(Bursts(1).(ColorCategory))|| iscell(Bursts(1).(ColorCategory))
        Category = CategoryLabels{idxCategory};
        BurstIndexes = strcmp({Bursts.(ColorCategory)}, Category);
    else
        Category = CategoryLabels(idxCategory);
        BurstIndexes = [Bursts.(ColorCategory)]==Category;
        Category = string(Category);
    end

    % get data for each burst category
    [BurstMask, ReferenceMask] = mask_bursts(EEG.data, Bursts(BurstIndexes));

    % plot bursts
    if isempty(ReferenceMask)
        cycy.plot.eeg_data(BurstMask, EEG.srate, YGap, Category, Colors(idxCategory, :), 1);
    else
        cycy.plot.eeg_data(BurstMask, EEG.srate, YGap, '', Colors(idxCategory, :));
        cycy.plot.eeg_data(ReferenceMask, EEG.srate, YGap, Category, Colors(idxCategory, :), 2)
    end
end

legend
xlim(Bursts(1).Start/EEG.srate+[0 15])
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function [BurstMask, ReferenceMask] = mask_bursts(EEGData, Bursts)
% creates a matrix the size of the data in EEG, with values of the data
% only during the bursts

BurstMask = nan(size(EEGData));

% identify location of bursts
if isfield(Bursts, 'ClusterStart')
    Starts = [Bursts.ClusterStarts];
    Ends = [Bursts.ClusterEnds];
    Channels = [Bursts.ClusterChannelIndexes];
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


function [Colors, CategoryLabels] = pick_group_colors(Bursts, ColorCategory)

% default output
if isempty(ColorCategory)
    Colors = [0 0 0];
    CategoryLabels = {};
    return
end

% identify different category labels
if ischar(Bursts(1).(ColorCategory))
    CategoryLabels = unique({Bursts.(ColorCategory)});
else
    CategoryLabels = unique([Bursts.(ColorCategory)]);
end

% select colors
if numel(CategoryLabels) <= 10
    Colors = cycy.utils.pick_colors(numel(CategoryLabels));
elseif numel(CategoryLabels) <= 20
    Colors = jet(numel(CategoryLabels));
else
    Colors = rand(numel(CategoryLabels), 3);
end
end