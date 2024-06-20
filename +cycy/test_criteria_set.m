function Bursts = test_criteria_set(DataBroadband, SampleRate, NarrowbandRange, CriteriaSet, Plots)
% runs burst detection with a single narrowband range and criteria set to
% see how the criteria are doing
% plots should be 3 
arguments
DataBroadband
SampleRate
NarrowbandRange
CriteriaSet
Plots = [true true true];
end

if isfield(CriteriaSet, 'PeriodNeg') && ~isempty(CriteriaSet.PeriodNeg) && CriteriaSet.PeriodNeg
    CriteriaSet.PeriodNeg = sort(1./NarrowbandRange);
end

% filter data
DataNarrowband = cycy.utils.highpass_filter(DataBroadband, SampleRate, NarrowbandRange(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, NarrowbandRange(2));


% detect cycles
CycleTable = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, CycleTable, SampleRate);

% detect bursts
[Bursts, Diagnostics] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);


if Plots(1)
cycy.plot.criteriaset_diagnostics(Diagnostics)
end

if Plots(2)
cycy.plot.properties_distributions(AugmentedCycles);
end

if isempty(Bursts)
    figure
    [PowerBroadband, Frequencies] = cycy.utils.compute_power(DataBroadband, SampleRate);
    cycy.plot.power_spectrum(PowerBroadband, Frequencies, true, true, [], cycy.utils.pick_colors(1, '', 'blue'));
    return
end

cycy.plot.cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
    AugmentedCycles, CriteriaSet, Bursts);

if Plots(3)
figure
cycy.plot.power_without_bursts(DataBroadband, SampleRate, Bursts)
end

