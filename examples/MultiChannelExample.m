% This script demonstrates how the burst detection works for multiple
% channels

clear
clc
close all


%% load the EEG data

load("C:\Users\colas\Code\Matcycle\example_data\EEGbroadband.mat", "EEGbroadband")

SampleRate = EEGbroadband.srate;

%% filter the data

NarrowbandRanges = struct();
NarrowbandRanges.Theta = [4 8];
NarrowbandRanges.ThetaAlpha = [6 10];
NarrowbandRanges.Alpha = [8 12];
NarrowbandRanges.LowSigma = [10 14];

BandLabels = fieldnames(NarrowbandRanges);

EEGnarrowbands = EEGbroadband;
for idxBand = 1:numel(BandLabels)
    EEGnarrowbands(idxBand) = EEGbroadband;
    EEGnarrowbands(idxBand).data = cycy.utils.highpass_filter(EEGnarrowbands(idxBand).data, ...
        SampleRate, NarrowbandRanges.(BandLabels{idxBand})(1));

      EEGnarrowbands(idxBand).data = cycy.utils.lowpass_filter(EEGnarrowbands(idxBand).data, ...
        SampleRate, NarrowbandRanges.(BandLabels{idxBand})(2));
end


%% Detect bursts

% establish criteria
CriteriaSets = struct();
RunParallel = false;

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
CriteriaSets(2).VoltageNeg = 0; % make sure all negative peaks are actually negative values
CriteriaSets(2).Amplitude = 30; % if you want, you can actually set an amplitude threshold; I recommend either none or a really small value
CriteriaSets(2).MinCyclesPerBurst = 3; % all the above criteria have to be met for this many cycles in a row

% detect bursts in each channel

% profile on
Bursts = cycy.detect_bursts_all_channels(EEGbroadband, EEGnarrowbands, NarrowbandRanges, ...
    CriteriaSets, RunParallel);

% profile viewer






