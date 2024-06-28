function time_frequency(Data, Frequencies, tMax, PlotType, FreqRange, ColorAxisLimits, Levels)
arguments
    Data
    Frequencies
    tMax
    PlotType = 'imagesc';
    FreqRange = [1 40];
    ColorAxisLimits = [min(Data(:)), max(Data(:))];
    Levels = 40;
end
% Data is Freqs x time

Time = linspace(0, tMax, size(Data, 2));


switch PlotType
    case 'imagesc'
        imagesc(Time, Frequencies, Data)
        set(gca, 'YDir', 'normal')

    case 'contourf'
        contourf(Time, Frequencies, Data, Levels, 'linecolor','none')
end

colorbar
ylabel('Frequency (Hz)')
xlabel('Time (s)')

if ~isempty(FreqRange)
    ylim(FreqRange)
end

if ~isempty(ColorAxisLimits)
    clim(ColorAxisLimits)
end