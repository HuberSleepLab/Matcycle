clear
clc
close all

%%% choose the file to look at
Filepath = 'E:\Data\Preprocessed\Clean\Waves\Music\P07_Music_Session2_Clean.mat';

% Choose window to look at
Window = [80 100]; % seconds

load(Filepath, 'EEG')

% reduce data to make it faster
EEGRedux = pop_select(EEG, 'time', Window);
EEGRedux = pop_select(EEGRedux, 'channel', [6 11 36 51 68]); % 6, Fz, C3, P3 O1

% run multitaper
Data = EEGRedux.data;
SampleRate = EEG.srate;
WindowLength = 1;
MovingWindowSampleRate = .1;

[Spectrum, Frequencies, Time] = cycy.utils.multitaper(Data, SampleRate, WindowLength, MovingWindowSampleRate);


%% plot
LData = squeeze(log(Spectrum(2, :, :)));
figure
cycy.plot.time_frequency(LData, Frequencies, Time(end), 'contourf', [1 40])