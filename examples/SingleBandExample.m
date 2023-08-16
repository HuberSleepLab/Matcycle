% This script demonstrates how the burst detection works with just one set
% of critera, one channel, and one frequency band.
clear
clc
close all

%% load the EEG data

Path = fullfile(extractBefore(cd, 'examples'), 'example_data');
load(fullfile(Path, "EEGbroadband_fulltime.mat"), "EEGbroadband") % like this, it will run when you are inside the folder where this script is saved
DataBroadband = EEGbroadband.data(2, :); % try channels 1 and 3 as well ;)
SampleRate = EEGbroadband.srate;


%% 
Path = 'E:\Data\Preprocessed\Simple\Sleep\MAT';
File = 'P15_Sleep_NightPre.mat';
load(fullfile(Path, File), "EEG") % like this, it will run when you are inside the folder where this script is saved
DataBroadband = EEG.data(2, :); 
SampleRate = EEG.srate;

DataBroadband =  cycy.utils.highpass_filter(DataBroadband, SampleRate, 3);


%% Plot spectrum, to at what frequencies there are oscillations

[Power, Frequencies] = cycy.utils.compute_power(DataBroadband, SampleRate);

figure
cycy.plot.power_spectrum(Power, Frequencies, true, true)

%% Filter narrowband for burst detection

Range = [12 16]; % select a range that is wide enough to cover the variability you expect for a specific band (i.e. start and end of the oscillatory bump in the power spectrum)

DataNarrowband = cycy.utils.highpass_filter(DataBroadband, SampleRate, Range(1)); % if you want, you can specify other aspects of the filter; see function
DataNarrowband = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, Range(2));
% running the filters will create a cache in the folder you're located.
% This is to save time next time you want to filter something.

% Determine bursts according to detection criteria

%%
tic
% set parameters
CriteriaSet = struct();

% CriteriaSet.VoltageNeg = 0; % makes sure all negative peaks are actually negative values
% CriteriaSet.isTruePeak = 1; % excludes edge cases in which the negative "peak" is actually the same as one of the positive "peaks".  % use only if not uising flank consistency
% CriteriaSet.PeaksCount = [0 2.1]; % excludes cycles where there is more than N peaks; essentially the strictest version of monotonicity
% CriteriaSet.PeriodNeg = sort(1./Range); % makes sure all peaks are actually in the range of the narrowband filter
% CriteriaSet.Amplitude = 20; % if you want, you can set an amplitude threshold, but it almost defeats the point
CriteriaSet.FlankConsistency = .3; % cycle should not have too asymetric flanks
% CriteriaSet.MonotonicityInTime = 0.5; % there shouldn't be many faster fluctuations on top of the cycle
CriteriaSet.MonotonicityInAmplitude = 0.7; % those faster fluctuations shouldn't be very large either
% CriteriaSet.isProminent = 1; % there shouldn't be other high-amplitude negative peaks that surpass the midpoint between the negative peak and the positive peaks in the cycle.
CriteriaSet.PeriodConsistency = .6; % left and right negative peaks should be similarly distant
CriteriaSet.AmplitudeConsistency = .3; % left and right cycles should be of similar amplitude

CriteriaSet.MinCyclesPerBurst = 8; % all the above criteria have to be met for this many cycles in a row

% detect cycles
Cycles = cycy.detect_cycles(DataBroadband, DataNarrowband);
AugmentedCycles = cycy.measure_cycle_properties(DataBroadband, Cycles, SampleRate);

% detect bursts
[Bursts, Diagnostics] = cycy.aggregate_cycles_into_bursts(AugmentedCycles, CriteriaSet);
toc

%% Plot channel and corresponding cycle properties to evaluate if the above criteria set is good

cycy.plot.cycles_and_criteria(DataBroadband, SampleRate, DataNarrowband, ...
    AugmentedCycles, CriteriaSet, Bursts);

%% Plot diagnostics to help determine good criteria

% plot bar graph of how many cycles each critiera disqualified for bursts
cycy.plot.criteriaset_diagnostics(Diagnostics)

% plot distribution of values for each criteria to better decide new
% thresholds
cycy.plot.properties_distributions(AugmentedCycles)

