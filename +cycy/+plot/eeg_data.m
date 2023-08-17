function eeg_data(Data, SampleRate, YGap, Color, LineWidth, DisplayName)
arguments
    Data
    SampleRate
    YGap = 20;
    Color = [.3 .3 .3];
    LineWidth = 0.5;
    DisplayName = '';
end
% Data is ch x time matrix
% YGap is how much to space the channels. Default is 20.

if isempty(DisplayName)
    HandleVisibility = 'off';
else
    HandleVisibility = 'on';
end
    
[ChannelCount, TimepointCount] = size(Data);

Timepoints = linspace(0, TimepointCount/SampleRate, TimepointCount);

YAxisGaps = YGap*ChannelCount:-YGap:0;
YAxisGaps(end) = [];

DataSpread = Data+YAxisGaps';

plot(Timepoints, DataSpread,  'Color', Color, 'LineWidth', LineWidth, ...
    'HandleVisibility', HandleVisibility, 'DisplayName', DisplayName)