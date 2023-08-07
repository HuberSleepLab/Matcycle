% Use this to check the effects of the narrowband filtering on the EEG
% data. Make sure that there are no weird effects
clear
clc
close all

load("C:\Users\colas\Code\Matcycle\example_data\EEGbroadband.mat", "EEGbroadband")
Data = EEGbroadband.data(80, :);
SampleRate = EEGbroadband.srate;
t = linspace(0, numel(Data)/SampleRate, numel(Data));


Bands = struct();
Bands.ThetaLow = [2 6];
Bands.Alpha = [8 12];
Bands.Beta = [20 24];

%%

for Band = fieldnames(Bands)'
    Range = Bands.(Band{1});

    % filter the data (and cache the filter)
    [FiltData, Filter] = cycy.utils.highpass_filter(Data, SampleRate, Range(1));
    freqz(Filter,2^14,SampleRate)

    clc
    disp(['Showing highpass ', num2str(Range(1))])
    disp('Press enter to continue')
    pause

        % filter the data (and cache the filter)
    [FiltData, Filter] = cycy.utils.lowpass_filter(FiltData, SampleRate, Range(2));
    freqz(Filter,2^14,SampleRate)

    clc
    disp(['Showing lowpass ', num2str(Range(2))])
    disp('Press enter to continue')
    pause


    figure('Units','normalized','OuterPosition',[0 0 1 .3])
    hold on
    plot(t, Data, 'k', 'LineWidth', 1.5)
    plot(t, FiltData, 'r', 'LineWidth', 1)


end



% TODO:
% - check data with and without filter
% - check spectrum with and without filter
 