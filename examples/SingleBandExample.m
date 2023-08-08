% This script demonstrates how the burst detection works with just one set
% of critera, one channel, and one frequency band.
clear
clc
close all

%% load the EEG data

load("C:\Users\colas\Code\Matcycle\example_data\EEGbroadband_fulltime.mat", "EEGbroadband")
DataBroadband = EEGbroadband.data(3, :);
SampleRate = EEGbroadband.srate;

%% Filter narrowband in frequency of interest

Range = [10 14];

DataNarrowband = cycy.utils.highpass_filter(DataBroadband, SampleRate, Range(1));
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, Range(2));

%% Determine burst detection criteria

%%% set parameters
CriteriaSet = struct();

% CriteriaSet.VoltageNeg = 0; % make sure all negative peaks are actually negative values
CriteriaSet.isTruePeak = 1; % excludes edge cases in which the negative "peak" is actually the same as one of the positive "peaks"
CriteriaSet.PeaksCount = 1; % excludes cycles where there is more than one peak; essentially the strictest version of monotonicity
CriteriaSet.PeriodNeg = sort(1./Range); % makes sure all peaks are actually in the range of the narrowband filter
% CriteriaSet.Amplitude = 20; % if you want, you can actually set an amplitude threshold; I recommend either none or a really small value
CriteriaSet.FlankConsistency = .5; % cycle should not have too asymetric flanks
CriteriaSet.MonotonicityInTime = 0.5; % shouldn't be many fluctuations on top of the cycle
CriteriaSet.MonotonicityInAmplitude = 0.5; % they shouldn't be very large either
CriteriaSet.isProminent = 1; % there shouldn't be other high-amplitude negative peaks that surpass the midpoint between the negative peak and the positive peaks in the cycle
CriteriaSet.PeriodConsistency = .7; % left and right negative peaks should be similarly distant
CriteriaSet.AmplitudeConsistency = .25; % left and right cycles should be of similar amplitude

CriteriaSet.MinCyclesPerBurst = 3; % all the above criteria have to be met for this many cycles in a row


%% Detect

% detect cycles
Cycles = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, Cycles, SampleRate);

% detect bursts
 [Bursts, Diagnostics] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);


%% Plot channel and corresponding cycle properties to evaluate if the above criteria set is good

cycy.plot.cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
   AugmentedCycles, CriteriaSet, Bursts);

%% Plot diagnostics to help determine good criteria

% plot bar graph of how many cycles each critiera disqualified for bursts
cycy.plot.criteriaset_diagnostics(Diagnostics)

% plot distribution of values for each criteria to better decide new
% thresholds
cycy.plot.properties_distributions(AugmentedCycles)