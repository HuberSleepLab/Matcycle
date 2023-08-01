function plot_1channel_bursts(Wave, fs, Peaks, BurstPeakIDs, Peak_Thresholds)
% Plots single channel burst and parameters that were used to construct it.

% Part of Matcycle 2022, by Sophia Snipes.

t = linspace(0, numel(Wave)/fs, numel(Wave));

figure('Units','normalized','OuterPosition',[0 0 1 1])

% plot data
ax1 = subplot(3, 1, 1);
hold on
plot(t, Wave, 'Color', [.4 .4 .4])
scatter(t([Peaks.NegPeakIdx]), Wave([Peaks.NegPeakIdx]), 'MarkerEdgeColor', [.2 .2 .2])
scatter(t([Peaks(BurstPeakIDs).NegPeakIdx]), Wave([Peaks(BurstPeakIDs).NegPeakIdx]), 'filled', 'MarkerFaceColor', getColors(1, 1, 'red'))

legend({'data', 'all peaks', 'peaks in burst'})



%%% plot values that are between 0 and 1

% identify relevant fields
PeakFields = fieldnames(Peaks);

ThresholdFields = fieldnames(Peak_Thresholds);
disp(['Not including: ', strjoin(ThresholdFields(~ismember(ThresholdFields, PeakFields)), ' ')])
ThresholdFields(~ismember(ThresholdFields, PeakFields)) = []; % in case there's extra junk in there

Colors = getColors(numel(ThresholdFields));

ax2 = subplot(3, 1, 2);
hold on

RM = [];
for Indx_C = 1:numel(ThresholdFields) % loop through all provided thresholds
    Field = ThresholdFields{Indx_C};
    T = Peak_Thresholds.(Field); % threshold
    PeakField = [Peaks.(Field)]; % values of the peaks for that threshold

    % make sure it is appropriate for this plot
    if numel(T) ~= 1
        RM = cat(1, RM, Indx_C);
        continue
    end

    if max(PeakField)>1 || min(PeakField)<0
        RM = cat(1, RM, Indx_C);
        continue
    end

    % plot all points
    plot(t([Peaks.NegPeakIdx]), PeakField, 'o-', 'Color', Colors(Indx_C, :), 'LineWidth', 1.5)

    % plot kept points
    Keep = PeakField >= T;
    scatter(t([Peaks(Keep).NegPeakIdx]), PeakField(Keep), 'filled', 'MarkerFaceColor', Colors(Indx_C, :), 'HandleVisibility','off')
end

disp(ThresholdFields(RM))
ThresholdFields(RM) = [];
legend(ThresholdFields)
ylim([0 1])


% plot period

Period = [Peaks.period];
ax3 = subplot(3, 1, 3);
hold on
title('Frequency')

Colors = getColors([1, 3], '', 'red');
plot(t([Peaks.NegPeakIdx]), 1./[Peaks.periodPos], 'o-', 'Color', Colors(1, :))
plot(t([Peaks.NegPeakIdx]), 1./[Peaks.periodNeg], 'o-', 'Color', Colors(2, :))

if isfield(Peak_Thresholds, 'period')
    Peak_Thresholds.period = sort(Peak_Thresholds.period);
    Keep = Period >= Peak_Thresholds.period(1) &  Period <= Peak_Thresholds.period(2);
    plot(t([Peaks.NegPeakIdx]), 1./Period, 'ko-')
    scatter(t([Peaks(Keep).NegPeakIdx]), 1./Period(Keep), 'filled', 'MarkerFaceColor', 'k', 'HandleVisibility','off')
end

legend({'peak zc', 'trough zc', 'peak', 'trough'})

linkaxes([ax1,ax2],'x');
linkaxes([ax1,ax3],'x');

% TODO rename and check