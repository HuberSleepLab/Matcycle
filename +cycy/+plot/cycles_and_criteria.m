function cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
    Cycles, CriteriaSet, Bursts, KeepTimepoints)
arguments
    DataBroadband
    SampleRate (1,1)
    DataNarrowband = [];
    Cycles = [];
    CriteriaSet = [];
    Bursts = [];
    KeepTimepoints = true(1, numel(DataBroadband));
end

t = linspace(0, numel(DataBroadband)/SampleRate, numel(DataBroadband));


if isempty(CriteriaSet)
    figure('Units','normalized','OuterPosition',[0 0 1 .25])
    SubplotCount = 1;
else
    figure('Units','normalized','OuterPosition',[0 0 1 1])
    SubplotCount = 4;
end

%%% plot EEG signal and detected peaks

DataBroadband(~KeepTimepoints) = nan;

% EEG signal
ax1 = subplot(SubplotCount, 1, 1);
hold on
plot(t, DataBroadband, 'Color', [.2 .2 .2])
xlabel('Time (s)')
ylabel('Voltage')
Legend = {'Broadband'};

if ~isempty(DataNarrowband)
    DataNarrowband(~KeepTimepoints) = nan;

    plot(t, DataNarrowband, 'Color', cycy.utils.pick_colors(1, '', 'yellow'))
    Legend = cat(2, Legend, 'Narrowband');
end

% peaks
if ~isempty(Cycles)
    scatter(t([Cycles.PrevPosPeakIdx]), DataBroadband([Cycles.PrevPosPeakIdx]), 10, ...
        'filled', 'MarkerFaceColor', [.8 .8 .8], 'HandleVisibility','off')
    scatter(t([Cycles.NegPeakIdx]), DataBroadband([Cycles.NegPeakIdx]), 10, ...
        'filled', 'MarkerFaceColor', 'k', 'HandleVisibility', 'off')
end

if ~isempty(Bursts)
    AcceptedCycles = [Bursts.NegPeakIdx];
    scatter(t(AcceptedCycles), DataBroadband(AcceptedCycles), ...
        'filled', 'MarkerFaceColor', cycy.utils.pick_colors(1, 1, 'red'))
    Legend = cat(2, Legend, 'Accepted cycles');
end

legend(Legend)

if isempty(CriteriaSet)
    xlim([0 10])
    return
end

%%% plot criteria used to detect bursts

% criteria with values between 0 and 1
[CriteriaLabels, AbridgedCriteriaSet] = select_criteria_between_0_1(Cycles, CriteriaSet);

CyclesMeetCriteria = cycy.detect_cycles_that_meet_criteria(Cycles, AbridgedCriteriaSet, ...
    KeepTimepoints);

ax2 = subplot(SubplotCount, 1, 2);
plot_criteria(t, Cycles, CriteriaLabels, CyclesMeetCriteria)
ylim([0 1])
title('Applied critiera')


% frequency
ax3 = subplot(SubplotCount, 1, 3);
PeriodCriteria.PeriodNeg = CriteriaSet.PeriodNeg;
CyclesMeetCriteria = cycy.detect_cycles_that_meet_criteria(Cycles, PeriodCriteria, ...
    KeepTimepoints);
plot_criteria(t, Cycles, {'Frequency'}, CyclesMeetCriteria)
legend off
title('Frequency')

%%% plot properties that weren't used as criteria
ax4 = subplot(SubplotCount, 1, 4);
PropertyLabels = select_properties_between_0_1(Cycles);
PropertyLabels(contains(PropertyLabels, CriteriaLabels)) = [];
plot_criteria(t, Cycles, PropertyLabels, false(numel(PropertyLabels), numel(Cycles)))
title('Unused criteria')

linkaxes([ax1,ax2],'x');
linkaxes([ax1,ax3],'x');
linkaxes([ax1,ax4],'x');

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% Functions

function [CriteriaLabels, AbridgedCriteraSet] = select_criteria_between_0_1(Cycles, CriteriaSet)
AllCriteriaLabels = cycy.utils.get_criteria_labels(Cycles, CriteriaSet);

AllCriteriaLabels(contains(AllCriteriaLabels, 'Period')) = [];
CriteriaLabels = {};
AbridgedCriteraSet = struct();

for Criteria = AllCriteriaLabels'
    Values = [Cycles.(Criteria{1})];

    if all(Values<=1 & Values>=0)
        CriteriaLabels = cat(2, CriteriaLabels, Criteria);
        AbridgedCriteraSet.(Criteria{1}) = CriteriaSet.(Criteria{1});
    else
        warning([Criteria{1}, ' criteria values out of range'])
    end
end
end

function PropertyLabels = select_properties_between_0_1(Cycles)
AllPropertyLabels = fieldnames(Cycles);
AllPropertyLabels(contains(AllPropertyLabels, 'Period')) = [];
PropertyLabels = {};
for Property = AllPropertyLabels'
    Values = [Cycles.(Property{1})];
    if all(Values<=1 & Values>=0)
        PropertyLabels = cat(2, PropertyLabels, Property);
    end
end

end


function plot_criteria(t, Cycles, CriteriaLabels, CyclesMeetCriteria)

if isempty(CriteriaLabels)
    return
end

Colors = cycy.utils.pick_colors(numel(CriteriaLabels));


hold on
for idxCriteria = 1:numel(CriteriaLabels)
    CycleProperties = [Cycles.(CriteriaLabels{idxCriteria})];

    plot(t([Cycles.NegPeakIdx]), CycleProperties, 'o-', 'Color', Colors(idxCriteria, :), 'LineWidth', 1.5)
    
    Keep = CyclesMeetCriteria(idxCriteria, :);
    scatter(t([Cycles(Keep).NegPeakIdx]), CycleProperties(Keep), ...
        'filled', 'MarkerFaceColor', Colors(idxCriteria, :), 'HandleVisibility','off')
end

legend(CriteriaLabels)
end

