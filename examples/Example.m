% This script implements all of the functions in the repository, so you
% can see how it works, from a (clean) EEG to a final burst structure.
% For your data, try to make the different sections (%%) as different
% scripts, loop through all your files and save the output of each step
% somewhere.


%% Establish parameters

% pick a clean EEG file
Filename_EEG = 'P15_Music_Session2_Clean.mat'; % should be a MAT file containing and EEGLAB structure.
Filepath_EEG = 'E:\Data\Preprocessed\Clean\Waves\Music';

% add subfolders of the current repo
addpath(genpath(extractBefore(mfilename('fullpath'), 'Example')))

%% Filter the EEG data

% frequency band of interest (could loop through more than one pair; should
% not be too broad).
Alpha = [8 12];

load(fullfile(Filepath_EEG, Filename_EEG), 'EEG')
fs = EEG.srate;
[nCh, nPoints] = size(EEG.data);

FiltEEG = EEG;

% filter all the data
FiltEEG.data = cycy_hpfilt(FiltEEG.data, fs, Alpha(1));
FiltEEG.data = cycy_lpfilt(FiltEEG.data, fs, Alpha(2));


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

Bands.Alpha = Alpha; % format like this so it can loop through fieldnames to find relevant bands

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.

% DEBUG: use these lines to check if the thresholds are working:
Signal = EEG.data(1, :);
fSignal = FiltEEG.data(1, :);
Peaks = cycy_detect_cycles(Signal, fSignal);
Peaks = cycy_cycle_properties(Signal, Peaks, fs);
BT = removeEmptyFields(BurstThresholds(1));
[~, BurstPeakIDs_Clean] = cycy_aggregate_cycles(Peaks, BT, Min_Peaks, Keep_Points);
cycy_plot_1channel_bursts(Signal, fs, Peaks, BurstPeakIDs_Clean, BT)

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





