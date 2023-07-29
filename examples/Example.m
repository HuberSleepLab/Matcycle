% This script implements all of the functions in the repository, so you
% can see how it works, from a (clean) EEG to a final burst struct.
% For your data, try to make the different sections (%%) as different
% scripts, loop through all your files and save the output of each step
% somewhere.

% add subfolders of the current repo
addpath(genpath(extractBefore(mfilename('fullpath'), 'Example')))
cycy_addpaths() % little function to add the src folders to path

%% Load the EEG data

% pick a clean EEG file
Filename_EEG = 'P15_Sleep_NightPost.mat'; % should be a MAT file containing and EEGLAB struct.
Filepath_EEG = 'E:\Data\Preprocessed\Simple\Sleep\MAT';

load(fullfile(Filepath_EEG, Filename_EEG), 'EEG')

%% select data
Channel = 2; % for now, just look at 1 channel
Timepoints = [6700 7700]; % narrow window, just to check things

fs = EEG.srate;
CutEEG = EEG;
CutEEG.data = EEG.data(2, fs*6700:fs*7700);
nPoints = numel(CutEEG.data);

%% View power
% check out the spectrum to know frequency range of interest

[Power, Freqs] = cycy_power(CutEEG.data, fs, 4, .5);
figure
plot(Freqs, log(Power))
xlim([0.5 40])

%% Filter data

% frequencies to filter in
NarrowBand = [12 15];
BroadBand = [4 40];


% Broadband filter
Raw = CutEEG.data;
t = linspace(0, nPoints/fs, nPoints);
CutEEG.data = cycy_hpfilt(CutEEG.data, fs, BroadBand(1));
CutEEG.data = cycy_lpfilt(CutEEG.data, fs, BroadBand(2));

FiltEEG = CutEEG;

% narrowband filter in the band of interest for oscillations
FiltEEG.data = cycy_hpfilt(FiltEEG.data, fs, NarrowBand(1));
FiltEEG.data = cycy_lpfilt(FiltEEG.data, fs, NarrowBand(2));

%% plot data

figure('Units','normalized','outerposition',[0 0 1 .5])
hold on
plot(t, Raw, 'LineWidth', 1.5, 'Color', [.5 .5 .5])
plot(t, CutEEG.data, 'LineWidth', 1.5, 'Color', 'k')
plot(t, FiltEEG.data,'r:', 'LineWidth', 1.5 )
xlim([0 10])

%% Detect bursts

Keep_Points = ones(1, nPoints); % if you have information identifying noise, set values to 0

% Burst Thresholds for finding very clean bursts
BurstThresholds = struct();
BurstThresholds.isProminent = 1;
BurstThresholds.periodConsistency = .7;
BurstThresholds.periodMeanConsistency = .7;
BurstThresholds.truePeak = 1;
BurstThresholds.efficiencyAdj = .6;
BurstThresholds.flankConsistency = .5;
BurstThresholds.ampConsistency = .25;
BurstThresholds.Min_Peaks = 3;
BurstThresholds.period = NarrowBand;

Signal = EEG.data(1, :);
fSignal = FiltEEG.data(1, :);
Cycles = cycy_detect_cycles(Signal, fSignal);
Cycles = cycy_cycle_properties(Signal, Cycles, fs);

[~, BurstPeakIDs_Clean] = cycy_aggregate_cycles(Cycles, BurstThresholds, Keep_Points);
cycy_plot_1channel_bursts(Signal, fs, Cycles, BurstPeakIDs_Clean, BurstThresholds)

%% Get bursts for each channel

Min_Peaks = 3; % minimum number of cycles per burst

% Burst Thresholds for finding very clean bursts
BurstThresholds = struct();
BurstThresholds(1).isProminent = 1;
BurstThresholds(1).periodConsistency = .7;
BurstThresholds(1).periodMeanConsistency = .7;
BurstThresholds(1).truePeak = 1;
BurstThresholds(1).efficiencyAdj = .6;
BurstThresholds(1).flankConsistency = .5;
BurstThresholds(1).ampConsistency = .25;

% Burst thresholds for notched waves, but compensates
% with more strict thresholds for everything else
BurstThresholds(2).monotonicity = .8;
BurstThresholds(2).periodConsistency = .6;
BurstThresholds(2).periodMeanConsistency = .6;
BurstThresholds(2).efficiency = .8;
BurstThresholds(2).truePeak = 1;
BurstThresholds(2).flankConsistency = .5;
BurstThresholds(2).ampConsistency = .5;

Bands.Alpha = NarrowBand; % format like this so it can loop through fieldnames to find relevant bands

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.

% DEBUG: use these lines to check if the thresholds are working:
Signal = EEG.data(1, :);
fSignal = FiltEEG.data(1, :);
Cycles = cycy_detect_cycles(Signal, fSignal);
Cycles = cycy_cycle_properties(Signal, Cycles, fs);
BT = removeEmptyFields(BurstThresholds(1));
[~, BurstPeakIDs_Clean] = cycy_aggregate_cycles(Cycles, BT, Min_Peaks, Keep_Points);
cycy_plot_1channel_bursts(Signal, fs, Cycles, BurstPeakIDs_Clean, BT)

% get bursts in all data
AllBursts = cycy_detect_bursts(EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points);


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





