function power_spectrum(Power, Frequencies, LogX, LogY, Legend, Colors)
arguments
    Power
    Frequencies
    LogX = false;
    LogY = false;
    Legend = {};
    Colors =  cycy.utils.pick_colors(size(Power, 1));
end

hold on
for idxPower = 1:size(Power, 1)
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