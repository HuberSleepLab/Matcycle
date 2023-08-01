% This script implements all of the functions in the repository, so you
% can see how it works, from a (clean) EEG to a final burst struct.
% For your data, try to make the different sections (%%) as different
% scripts, loop through all your files and save the output of each step
% somewhere.

% add subfolders of the current repo
addpath(genpath(extractBefore(mfilename('fullpath'), 'Example')))
cycy_addpaths() % little function to add the src folders to path

%% Load the EEG data

clear
clc
close all


% pick a clean EEG file
Filename_EEG = 'P10_Music_Session1_Clean.mat'; % should be a MAT file containing and EEGLAB struct.
Filepath_EEG = 'E:\Data\Preprocessed\Clean\Waves\Music';

load(fullfile(Filepath_EEG, Filename_EEG), 'EEG')

%% select data
Channel = 2; % for now, just look at 1 channel
Timepoints = [6700 7700]; % narrow window, just to check things

fs = EEG.srate;
BroadbandEEG = EEG;
nPoints = numel(BroadbandEEG.data);

%% View power
% check out the spectrum to know frequency range of interest

[Power, Freqs] = cycy_power(BroadbandEEG.data, fs, 4, .5);
figure
plot(Freqs, log(Power))
xlim([0.5 40])

%% Filter data

% frequencies to filter in
NarrowBand = [8 12];
BroadBand = [4 40];


% Broadband filter
Raw = BroadbandEEG.data;
t = linspace(0, nPoints/fs, nPoints);
BroadbandEEG.data = cycy_cycy.utils.highpass_filter(BroadbandEEG.data, fs, BroadBand(1));
BroadbandEEG.data = lowpass_filter(BroadbandEEG.data, fs, BroadBand(2));

NarrowbandEEG = BroadbandEEG;

% narrowband filter in the band of interest for oscillations
NarrowbandEEG.data = cycy_cycy.utils.highpass_filter(NarrowbandEEG.data, fs, NarrowBand(1));
NarrowbandEEG.data = lowpass_filter(NarrowbandEEG.data, fs, NarrowBand(2));


%% Run main script

CriteriaSets = struct();
CriteriaSets.isProminent = 1;
CriteriaSets.periodConsistency = .7;
CriteriaSets.periodMeanConsistency = .7;
CriteriaSets.truePeak = 1;
CriteriaSets.efficiencyAdj = .6;
CriteriaSets.flankConsistency = .5;
CriteriaSets.ampConsistency = .25;
CriteriaSets.MinCyclesPerBurst = 3;
CriteriaSets.period = NarrowBand;
NarrowbandRanges = struct();
NarrowbandRanges.Alpha = NarrowBand;

FinalBursts = cycy_detect_bursts(BroadbandEEG, NarrowbandEEG, NarrowbandRanges, ...
    CriteriaSets);


%% plot data

figure('Units','normalized','outerposition',[0 0 1 .5])
hold on
plot(t, Raw, 'LineWidth', 1.5, 'Color', [.5 .5 .5])
plot(t, BroadbandEEG.data, 'LineWidth', 1.5, 'Color', 'k')
plot(t, NarrowbandEEG.data,'r:', 'LineWidth', 1.5 )
xlim([0 10])

%% Detect bursts

Keep_Points = ones(1, nPoints); % if you have information identifying noise, set values to 0

% Burst Thresholds for finding very clean bursts
CriteriaSets = struct();
CriteriaSets.isProminent = 1;
CriteriaSets.periodConsistency = .7;
CriteriaSets.periodMeanConsistency = .7;
CriteriaSets.truePeak = 1;
CriteriaSets.efficiencyAdj = .6;
CriteriaSets.flankConsistency = .5;
CriteriaSets.ampConsistency = .25;
CriteriaSets.MinCyclesPerBurst = 3;
CriteriaSets.period = NarrowBand;

Signal = EEG.data(1, :);
fSignal = NarrowbandEEG.data(1, :);
Cycles = cycy_detect_cycles(Signal, fSignal);
Cycles = cycy_measure_cycle_properties(Signal, Cycles, fs);

[~, BurstPeakIDs_Clean] = cycy_aggregate_cycles(Cycles, CriteriaSets, Keep_Points);
cycy_plot_1channel_bursts(Signal, fs, Cycles, BurstPeakIDs_Clean, CriteriaSets)

%% Get bursts for each channel

MinCyclesPerBurst = 3; % minimum number of cycles per burst

% Burst Thresholds for finding very clean bursts
CriteriaSets = struct();
CriteriaSets(1).isProminent = 1;
CriteriaSets(1).periodConsistency = .7;
CriteriaSets(1).periodMeanConsistency = .7;
CriteriaSets(1).truePeak = 1;
CriteriaSets(1).efficiencyAdj = .6;
CriteriaSets(1).flankConsistency = .5;
CriteriaSets(1).ampConsistency = .25;

% Burst thresholds for notched waves, but compensates
% with more strict thresholds for everything else
CriteriaSets(2).monotonicity = .8;
CriteriaSets(2).periodConsistency = .6;
CriteriaSets(2).periodMeanConsistency = .6;
CriteriaSets(2).efficiency = .8;
CriteriaSets(2).truePeak = 1;
CriteriaSets(2).flankConsistency = .5;
CriteriaSets(2).ampConsistency = .5;

Bands.Alpha = NarrowBand; % format like this so it can loop through fieldnames to find relevant bands

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.

% DEBUG: use these lines to check if the thresholds are working:
Signal = EEG.data(1, :);
fSignal = NarrowbandEEG.data(1, :);
Cycles = cycy_detect_cycles(Signal, fSignal);
Cycles = cycy_measure_cycle_properties(Signal, Cycles, fs);
BT = remove_empty_fields_from_struct(CriteriaSets(1));
[~, BurstPeakIDs_Clean] = cycy_aggregate_cycles(Cycles, BT, MinCyclesPerBurst, Keep_Points);
cycy_plot_1channel_bursts(Signal, fs, Cycles, BurstPeakIDs_Clean, BT)

% get bursts in all data
AllBursts = cycy_detect_bursts(EEG, NarrowbandEEG, CriteriaSets, MinCyclesPerBurst, Bands, Keep_Points);


%% get burst properties
MinCoherence = .75;

% assemble bursts across channels based on coherence
Bursts = cycy_aggregate_bursts(AllBursts, EEG, MinCoherence);

% get properties of the main channel
Bursts = cycy_burst_shape_properties(Bursts, EEG);
Bursts = cycy_burst_averages(Bursts); % does the mean of the main peak's properties

% classify the bursts by shape
Bursts = cycy_classify_bursts_shape(Bursts);

YGap = 20; % distance between EEG channels. 20 is good for high density
cycy_plot_all_bursts(EEG, YGap, Bursts, 'BT')





