% This script implements all of the functions in the repository, so you
% can see how it works, from a (clean) EEG to a final burst structure.
% For your data, try to make the different sections (%%) as different
% scripts, loop through all your files and save the output of each step
% somewhere.


%% Establish parameters

% pick a clean EEG file
Filename_EEG = ''; % should be a MAT file containing and EEGLAB structure.
Filepath_EEG = '';


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
Clean_BT = struct();
Clean_BT.isProminent = 1;
Clean_BT.periodConsistency = .7;
Clean_BT.periodMeanConsistency = .7;
Clean_BT.truePeak = 1;
Clean_BT.efficiencyAdj = .6;
Clean_BT.flankConsistency = .5;
Clean_BT.ampConsistency = .25;

% Burst thresholds for finding bursts with less monotonicity, but compensates
% with more strict thresholds for everything else
Dirty_BT = struct();
Dirty_BT.monotonicity = .8;
Dirty_BT.periodConsistency = .6;
Dirty_BT.periodMeanConsistency = .6;
Dirty_BT.efficiency = .8;
Dirty_BT.truePeak = 1;
Dirty_BT.flankConsistency = .5;
Dirty_BT.ampConsistency = .5;

Bands.Theta = Theta;

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.

% DEBUG: use these lines to check if the thresholds are working:
Signal = EEG.data(1, :);
fSignal = FiltEEG.data(1, :);
Peaks = peakDetection(Signal, fSignal);
Peaks = peakProperties(Signal, Peaks, fs);
[~, BurstPeakIDs_Clean] = findBursts(Peaks, Clean_BT, Min_Peaks, Keep_Points);
plotBursts(Signal, fs, Peaks, BurstPeakIDs_Clean, Clean_BT)

% get bursts in all data
[AllBursts, AllPeaks] = getAllBursts(EEG, FiltEEG, ...
    Clean_BT, Dirty_BT, IsoPeak_Thresholds, Min_Peaks, Bands, Keep_Points);


%%












