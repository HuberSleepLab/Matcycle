function eeg_data(Data, SampleRate, YGap, DisplayName, Color, LineWidth)
arguments
    Data
    SampleRate
    YGap = 20;
    DisplayName = '';
    Color = [.3 .3 .3];
    LineWidth = 0.5;
end
% Data is ch x time matrix
% YGap is how much to space the channels. Default is 20.

[ChannelCount, TimepointCount] = size(Data);

Time = linspace(0, TimepointCount/SampleRate, TimepointCount);

% spread out channels along the y axis
YAxisGaps = YGap*ChannelCount:-YGap:0;
YAxisGaps(end) = [];
DataSpread = Data+YAxisGaps';

% plot a single point for the legend (hack)
hold on
if ~isempty(DisplayName)
    plot(Time(1), DataSpread(1, 1), 'Color', Color, 'LineWidth', LineWidth, ...
        'HandleVisibility', 'on', 'DisplayName', DisplayName)
end

% main plot
plot(Time, DataSpread,  'Color', Color, 'LineWidth', LineWidth, ...
    'HandleVisibility', 'off')

YLims = [median(DataSpread(end, :))-YGap, median(DataSpread(1, :))+YGap];

if all(~isnan(YLims))
    ylim(YLims)
end