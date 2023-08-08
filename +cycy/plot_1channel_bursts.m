function plot_1channel_bursts(DataBroadband, fs, Cycles, BurstPeakIDs, CriteriaSet)
% Plots single channel burst and parameters that were used to construct it.

% Part of Matcycle 2022, by Sophia Snipes.

t = linspace(0, numel(DataBroadband)/fs, numel(DataBroadband));

figure('Units','normalized','OuterPosition',[0 0 1 1])

% plot data
ax1 = subplot(3, 1, 1);
hold on
plot(t, DataBroadband, 'Color', [.4 .4 .4])
scatter(t([Cycles.NegPeakIdx]), DataBroadband([Cycles.NegPeakIdx]), 'MarkerEdgeColor', [.2 .2 .2])
scatter(t([Cycles(BurstPeakIDs).NegPeakIdx]), DataBroadband([Cycles(BurstPeakIDs).NegPeakIdx]), 'filled', 'MarkerFaceColor', getColors(1, 1, 'red'))

legend({'data', 'all peaks', 'peaks in burst'})



%%% plot values that are between 0 and 1

% identify relevant fields
CycleProperties = fieldnames(Cycles);

CriteriaLabels = fieldnames(CriteriaSet);
disp(['Not including: ', strjoin(CriteriaLabels(~ismember(CriteriaLabels, CycleProperties)), ' ')])
CriteriaLabels(~ismember(CriteriaLabels, CycleProperties)) = []; % in case there's extra junk in there

Colors = getColors(numel(CriteriaLabels));

ax2 = subplot(3, 1, 2);
hold on

RM = [];
for Indx_C = 1:numel(CriteriaLabels) % loop through all provided thresholds
    Field = CriteriaLabels{Indx_C};
    T = CriteriaSet.(Field); % threshold
    PeakField = [Cycles.(Field)]; % values of the peaks for that threshold

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
    plot(t([Cycles.NegPeakIdx]), PeakField, 'o-', 'Color', Colors(Indx_C, :), 'LineWidth', 1.5)

    % plot kept points
    Keep = PeakField >= T;
    scatter(t([Cycles(Keep).NegPeakIdx]), PeakField(Keep), 'filled', 'MarkerFaceColor', Colors(Indx_C, :), 'HandleVisibility','off')
end

disp(CriteriaLabels(RM))
CriteriaLabels(RM) = [];
legend(CriteriaLabels)
ylim([0 1])


% plot period

Period = [Cycles.period];
ax3 = subplot(3, 1, 3);
hold on
title('Frequency')

Colors = getColors([1, 3], '', 'red');
plot(t([Cycles.NegPeakIdx]), 1./[Cycles.periodPos], 'o-', 'Color', Colors(1, :))
plot(t([Cycles.NegPeakIdx]), 1./[Cycles.periodNeg], 'o-', 'Color', Colors(2, :))

if isfield(CriteriaSet, 'period')
    CriteriaSet.period = sort(CriteriaSet.period);
    Keep = Period >= CriteriaSet.period(1) &  Period <= CriteriaSet.period(2);
    plot(t([Cycles.NegPeakIdx]), 1./Period, 'ko-')
    scatter(t([Cycles(Keep).NegPeakIdx]), 1./Period(Keep), 'filled', 'MarkerFaceColor', 'k', 'HandleVisibility','off')
end

legend({'peak zc', 'trough zc', 'peak', 'trough'})

linkaxes([ax1,ax2],'x');
linkaxes([ax1,ax3],'x');

% TODO rename and check