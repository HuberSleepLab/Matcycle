% This script implements all of the functions in the repository, so you
% can see how it works, from a (clean) EEG to a final burst structure.
% For your data, try to make the different sections (%%) as different
% scripts, loop through all your files and save the output of each step
% somewhere.


%% Establish parameters

% pick a clean EEG file
Filename_EEG = ''; % should be a MAT file containing and EEGLAB structure.
Filepath_EEG = '';

% add subfolders of the current repo
addpath(genpath(extractBefore(mfilename('fullpath'), 'Example')))

%% Filter the EEG data

% frequency band of interest (could loop through more than one pair; should
% not be too broad).
Theta = [8 12];

load(fullfile(Filepath_EEG, Filename_EEG), 'EEG')
fs = EEG.srate;
[nCh, nPoints] = size(EEG.data);

FiltEEG = EEG;

% filter all the data
FiltEEG.data = hpfilt(FiltEEG.data, fs, Theta(1));
FiltEEG.data = lpfilt(FiltEEG.data, fs, Theta(2));


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

% Burst thresholds for finding bursts with less monotonicity, but compensates
% with more strict thresholds for everything else
BurstThresholds(2).monotonicity = .8;
BurstThresholds(2).periodConsistency = .6;
BurstThresholds(2).periodMeanConsistency = .6;
BurstThresholds(2).efficiency = .8;
BurstThresholds(2).truePeak = 1;
BurstThresholds(2).flankConsistency = .5;
BurstThresholds(2).ampConsistency = .5;

Bands.Theta = Theta;

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.

% DEBUG: use these lines to check if the thresholds are working:
Signal = EEG.data(1, :);
fSignal = FiltEEG.data(1, :);
Peaks = peakDetection(Signal, fSignal);
Peaks = peakProperties(Signal, Peaks, fs);
BT = removeEmptyFields(BurstThresholds(1));
[~, BurstPeakIDs_Clean] = findBursts(Peaks, BT, Min_Peaks, Keep_Points);
plotBursts(Signal, fs, Peaks, BurstPeakIDs_Clean, BT)

% get bursts in all data
AllBursts = getAllBursts(EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points);


%%












