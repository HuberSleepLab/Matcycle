function check_single_channel_detection(EEGBroadband, EEGNarrowband, ChannelIdx, CriteriaSet)

DataBroadband = EEGBroadband.data(ChannelIdx, :);
DataNarrowband = EEGNarrowband.data(ChannelIdx, :);

SampleRate =EEGBroadband.srate;

Cycles = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, Cycles, SampleRate);

% detect bursts
[Bursts, ~] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);

cycy.plot.cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
    AugmentedCycles, CriteriaSet, Bursts);