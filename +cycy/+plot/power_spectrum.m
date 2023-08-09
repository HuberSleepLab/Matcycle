function power_spectrum(Power, Frequencies, LogX, LogY, Legend)
arguments
    Power
    Frequencies
    LogX
    LogY
    Legend = {};
end

PowerPlotCount = size(Power, 1);

Colors = cycy.utils.pick_colors(PowerPlotCount);

for idxPower = 1:PowerPlotCount
    plot(Frequencies, Power(idxPower, :), 'LineWidth', 2, 'Color', Colors(idxPower, :))
end

ylabel('Power')
xlabel('Frequency (Hz)')

if LogX
    set(gca, 'XScale', 'log')
end

if LogY
    set(gca, 'YScale', 'log')
end

xlim([0.5 40])

if ~isempty(Legend)
    legend(Legend)
end