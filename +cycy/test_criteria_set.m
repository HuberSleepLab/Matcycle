function Bursts = test_criteria_set(DataBroadband, SampleRate, NarrowbandRange, CriteriaSet)
% runs burst detection with a single narrowband range and criteria set to
% see how the criteria are doing

% CriteriaSet.PeriodNeg = sort(1./NarrowbandRange);

% filter data
DataNarrowband = cycy.utils.highpass_filter(DataBroadband, SampleRate, NarrowbandRange(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, NarrowbandRange(2));


% detect cycles
Cycles = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, Cycles, SampleRate);

% detect bursts
[Bursts, Diagnostics] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);


cycy.plot.cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
    AugmentedCycles, CriteriaSet, Bursts);
cycy.plot.criteriaset_diagnostics(Diagnostics)
figure
cycy.plot.power_without_bursts(DataBroadband, SampleRate, Bursts)
