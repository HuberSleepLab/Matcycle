% This script demonstrates how the burst detection works with just one set
% of critera, one channel, and one frequency band.
clear
clc
close all

load("C:\Users\colas\Code\Matcycle\example_data\EEGbroadband_fulltime.mat", "EEGbroadband")
DataBroadband = EEGbroadband.data(3, :);
SampleRate = EEGbroadband.srate;
% t = linspace(0, numel(DataBroadband)/SampleRate, numel(DataBroadband));


%% Filter narrowband in frequency of interest

Range = [10 14];

DataNarrowband = cycy.utils.highpass_filter(DataBroadband, SampleRate, Range(1));
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, Range(2));



%% detect bursts

%%% set parameters
CriteriaSet = struct();
CriteriaSet.isProminent = 1;
CriteriaSet.periodConsistency = .7;
CriteriaSet.periodMeanConsistency = .7;
CriteriaSet.truePeak = 1;
CriteriaSet.efficiencyAdj = .6;
CriteriaSet.flankConsistency = .5;
CriteriaSet.ampConsistency = .25;
CriteriaSet.MinCyclesPerBurst = 3;
CriteriaSet.period = sort(1./Range); % add period threshold

%%
%%% detect cycles
% find all cycles in a given band
Cycles = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, Cycles, SampleRate);

%%% detect bursts
% find bursts
 [Bursts, Diagnostics, CyclesMeetCriteria, AcceptedCycles] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);





