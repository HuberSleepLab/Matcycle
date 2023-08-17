% This script demonstrates how the burst detection works for multiple
% channels.

clear
clc
close all


%% load the EEG data

load("C:\Users\colas\Code\Matcycle\example_data\EEGbroadband.mat", "EEGbroadband")
% EEG data needs to be a structure with fields "data" (channels x time 
% array), "srate" (sampling rate), and "chanlocs" (1 x channel count struct; 
% EEGLAB's structure for channel information, containing field "labels" 
% and X, Y, Z coordinates).

SampleRate = EEGbroadband.srate;

%% filter the data

% create a struct with the fieldnames indicating the band labels and each
% containing the range of interest.
NarrowbandRanges = struct();
NarrowbandRanges.Theta = [4 8];
NarrowbandRanges.ThetaAlpha = [6 10];
NarrowbandRanges.Alpha = [8 12];
NarrowbandRanges.LowSigma = [10 14];
EEGNarrowbands = cycy.filter_eeg_narrowbands(EEGbroadband, NarrowbandRanges);



%% Detect bursts

% establish sets of criteria to be used together to determine bursts.
% Having multiple distinct sets allows the user to relax some thresholds
% while tightening others; for example allowing lower monotonicity but
% requiring that bursts be longer. 

CriteriaSets = struct();
CriteriaSets(1).isTruePeak = 1; % excludes edge cases in which the negative "peak" is actually the same as one of the positive "peaks"
CriteriaSets(1).PeaksCount = 1; % excludes cycles where there is more than one peak; essentially the strictest version of monotonicity
CriteriaSets(1).FlankConsistency = .65; % cycle should not have too asymetric flanks
CriteriaSets(1).MonotonicityInTime = 0.5; % shouldn't be many fluctuations on top of the cycle
CriteriaSets(1).MonotonicityInAmplitude = 0.7; % they shouldn't be very large either
CriteriaSets(1).isProminent = 1; % there shouldn't be other high-amplitude negative peaks that surpass the midpoint between the negative peak and the positive peaks in the cycle
CriteriaSets(1).PeriodConsistency = .6; % left and right negative peaks should be similarly distant
CriteriaSets(1).AmplitudeConsistency = .5; % left and right cycles should be of similar amplitude
CriteriaSets(1).MinCyclesPerBurst = 4; % all the above criteria have to be met for this many cycles in a row

CriteriaSets(2).isTruePeak = 1; % excludes edge cases in which the negative "peak" is actually the same as one of the positive "peaks"
CriteriaSets(2).VoltageNeg = [-100 0]; % make sure all negative peaks are actually negative values. N.B. thresholds by default need the value to be greater than the criteria; so need to provide a range for negative values
CriteriaSets(2).Amplitude = 30; % if you want, you can actually set an amplitude threshold; I recommend either none or a really small value
CriteriaSets(2).MinCyclesPerBurst = 3; % all the above criteria have to be met for this many cycles in a row

% detect bursts
RunParallel = false; % if there's a lot of data, channels can be run in parallel
Bursts = cycy.detect_bursts_all_channels(EEGbroadband, EEGNarrowbands, NarrowbandRanges, ...
    CriteriaSets, RunParallel);

% plot
cycy.plot.plot_all_bursts(EEGbroadband, 20, Bursts, 'CriteriaSetIndex')


%% Get further burst information

MinFrequencyRange = 1;

% aggregate bursts across channels
BurstClusters = cycy.aggregate_bursts_into_clusters(Bursts, EEGbroadband, MinFrequencyRange);

% TODO: run burst properties

%% plot final output

cycy.plot.plot_all_bursts(EEGbroadband, 20, BurstClusters, 'Band');
% the second input is the scale for the EEG; 20 is good for high-density
% clean wake data; use larger numbers for higher-amplitudes or fewer
% channels.




