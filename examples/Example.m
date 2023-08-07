% This script implements all of the functions in the repository, so you
% can see how it works, from a (clean) EEG to a final burst struct.
% For your data, try to make the different sections (%%) as different
% scripts, loop through all your files and save the output of each step
% somewhere.

% add subfolders of the current repo
addpath(genpath(extractBefore(mfilename('fullpath'), 'Example')))
cycy.addpaths() % little function to add the src folders to path

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

[Power, Freqs] = cycy.power(BroadbandEEG.data, fs, 4, .5);
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
BroadbandEEG.data = cycy.cycy.utils.highpass_filter(BroadbandEEG.data, fs, BroadBand(1));
BroadbandEEG.data = lowpass_filter(BroadbandEEG.data, fs, BroadBand(2));

NarrowbandEEG = BroadbandEEG;

% narrowband filter in the band of interest for oscillations
NarrowbandEEG.data = cycy.cycy.utils.highpass_filter(NarrowbandEEG.data, fs, NarrowBand(1));
NarrowbandEEG.data = lowpass_filter(NarrowbandEEG.data, fs, NarrowBand(2));


%% Run main script

CriteriaSet = struct();
CriteriaSet.isProminent = 1;
CriteriaSet.periodConsistency = .7;
CriteriaSet.periodMeanConsistency = .7;
CriteriaSet.truePeak = 1;
CriteriaSet.efficiencyAdj = .6;
CriteriaSet.flankConsistency = .5;
CriteriaSet.ampConsistency = .25;
CriteriaSet.MinCyclesPerBurst = 3;
CriteriaSet.period = NarrowBand;
NarrowbandRanges = struct();
NarrowbandRanges.Alpha = NarrowBand;

FinalBursts = cycy.detect_bursts(BroadbandEEG, NarrowbandEEG, NarrowbandRanges, ...
    CriteriaSet);


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
CriteriaSet = struct();
CriteriaSet.isProminent = 1;
CriteriaSet.periodConsistency = .7;
CriteriaSet.periodMeanConsistency = .7;
CriteriaSet.truePeak = 1;
CriteriaSet.efficiencyAdj = .6;
CriteriaSet.flankConsistency = .5;
CriteriaSet.ampConsistency = .25;
CriteriaSet.MinCyclesPerBurst = 3;
CriteriaSet.period = NarrowBand;

Signal = EEG.data(1, :);
fSignal = NarrowbandEEG.data(1, :);
Cycles = cycy.detect_cycles(Signal, fSignal);
Cycles = cycy.measure_cycle_properties(Signal, Cycles, fs);

[~, BurstPeakIDs_Clean] = cycy.aggregate_cycles_into_bursts(Cycles, CriteriaSet, Keep_Points);
cycy.plot_1channel_bursts(Signal, fs, Cycles, BurstPeakIDs_Clean, CriteriaSet)

%% Get bursts for each channel

MinCyclesPerBurst = 3; % minimum number of cycles per burst

% Burst Thresholds for finding very clean bursts
CriteriaSet = struct();
CriteriaSet(1).isProminent = 1;
CriteriaSet(1).periodConsistency = .7;
CriteriaSet(1).periodMeanConsistency = .7;
CriteriaSet(1).truePeak = 1;
CriteriaSet(1).efficiencyAdj = .6;
CriteriaSet(1).flankConsistency = .5;
CriteriaSet(1).ampConsistency = .25;

% Burst thresholds for notched waves, but compensates
% with more strict thresholds for everything else
CriteriaSet(2).monotonicity = .8;
CriteriaSet(2).periodConsistency = .6;
CriteriaSet(2).periodMeanConsistency = .6;
CriteriaSet(2).efficiency = .8;
CriteriaSet(2).truePeak = 1;
CriteriaSet(2).flankConsistency = .5;
CriteriaSet(2).ampConsistency = .5;

Bands.Alpha = NarrowBand; % format like this so it can loop through fieldnames to find relevant bands

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.

% DEBUG: use these lines to check if the thresholds are working:
Signal = EEG.data(1, :);
fSignal = NarrowbandEEG.data(1, :);
Cycles = cycy.detect_cycles(Signal, fSignal);
Cycles = cycy.measure_cycle_properties(Signal, Cycles, fs);
BT = remove_empty_fields_from_struct(CriteriaSet(1));
[~, BurstPeakIDs_Clean] = cycy.aggregate_cycles_into_bursts(Cycles, BT, MinCyclesPerBurst, Keep_Points);
cycy.plot_1channel_bursts(Signal, fs, Cycles, BurstPeakIDs_Clean, BT)

% get bursts in all data
AllBursts = cycy.detect_bursts(EEG, NarrowbandEEG, CriteriaSet, MinCyclesPerBurst, Bands, Keep_Points);


%% get burst properties
MinCoherence = .75;

% assemble bursts across channels based on coherence
Bursts = cycy.aggregate_bursts(AllBursts, EEG, MinCoherence);

% get properties of the main channel
Bursts = cycy.burst_shape_properties(Bursts, EEG);
Bursts = cycy.burst_averages(Bursts); % does the mean of the main peak's properties

% classify the bursts by shape
Bursts = cycy.classify_bursts_shape(Bursts);

YGap = 20; % distance between EEG channels. 20 is good for high density
cycy.plot_all_bursts(EEG, YGap, Bursts, 'BT')





