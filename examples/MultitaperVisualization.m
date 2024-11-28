clear
clc
close all

%%% choose the file to look at
Filepath = 'E:\Data\Preprocessed\Clean\Waves\Music\P07_Music_Session2_Clean.mat';
% Filepath = 'E:\Data\Preprocessed\Clean\Waves\Game\P10_Game_Session2_Clean.mat';



%%
% Choose window to look at
Window = [80 95]; % seconds
Window = [0 400];
Window = [0 300];
WindowLength = 3;
MovingWindowSampleRate = .1;

% load(Filepath, 'EEG')

% reduce data to make it faster
EEGRedux = pop_select(EEG, 'time', Window);
EEGRedux = pop_select(EEGRedux, 'channel', [117]); % 6, Fz, C3, P3 O1

% run multitaper
Data = EEGRedux.data;
SampleRate = EEG.srate;

[Spectrum, Frequencies, Time] = cycy.utils.multitaper(Data, SampleRate, WindowLength, MovingWindowSampleRate);


% plot
PlotProps = chART.load_plot_properties({'LSM', 'Manuscript'});
ChannelLabels = {EEGRedux.chanlocs.labels};         

figure('Units','normalized','OuterPosition',[0 0 1 1])
for ChannelIdx = 1:size(Spectrum, 1)
    LData = squeeze(log(Spectrum(ChannelIdx, :, :)));

    subplot(size(Spectrum, 1), 1, ChannelIdx)
    cycy.plot.time_frequency(LData, Frequencies, Time(end), 'contourf', [1 40], [-10, -2], 100)
    chART.set_axis_properties(PlotProps)
    colormap(PlotProps.Color.Maps.Linear)
    title(ChannelLabels(ChannelIdx))
end