function Bursts = simple_burst_detection(Signal, SampleRate, BurstRange, CriteriaSet)
% Bursts = simple_burst_detection(Signal, SampleRate, BurstRange, CriteriaSet)
%
% from Matcycle, Snipes, 2024

DataNarrowband = cycy.utils.highpass_filter(Signal, SampleRate, BurstRange(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, BurstRange(2));

Cycles = cycy.detect_cycles(Signal, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(Signal, Cycles, SampleRate);
Bursts = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);