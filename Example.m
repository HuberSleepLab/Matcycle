% This script implements all of the contained functions in the repo, so you
% can see from a (clean) EEG to a final burst structure. For your data, try
% to make the different sections (%%), loop through all your files and save
% the output of each step somewhere.


%% Establish parameters

% pick a clean EEG file
Filename_EEG = ''; % should be a MAT file containing and EEGLAB structure.
Filepath_EEG = '';

% frequency band of interest (could loop through more than one pair; should
% not be too broad).
Band = [8 12];


%%

load(fullfile(Filepath_EEG, Filename_EEG), 'EEG')
fs = EEG.srate;

FiltEEG = EEG;

% filter all the data
FiltEEG.data = hpfilt(FiltEEG.data, fs, Band(1));
FiltEEG.data = lpfilt(FiltEEG.data, fs, Band(2));