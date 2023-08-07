% Use this to check the effects of the narrowband filtering on the EEG
% data.
clear
clc
close all

load("C:\Users\colas\Code\Matcycle\example_data\EEGbroadband_fulltime.mat", "EEGbroadband")
DataBroadband = EEGbroadband.data(3, :);
SampleRate = EEGbroadband.srate;
t = linspace(0, numel(DataBroadband)/SampleRate, numel(DataBroadband));


Bands = struct();
% Bands.Theta = [4 8];
% Bands.Alpha = [8 12];
Bands.Alpha = [10 14];
Bands.Beta = [20 24];

%%

for Band = fieldnames(Bands)'
    Range = Bands.(Band{1});

    % filter the data (and cache the filter)
    [DataNarrowband, Filter] = cycy.utils.highpass_filter(DataBroadband, SampleRate, Range(1));
    freqz(Filter,2^14,SampleRate)

    clc
    disp(['Showing highpass ', num2str(Range(1))])
    disp('Press enter to continue')
    pause

    % filter the data (and cache the filter)
    [DataNarrowband, Filter] = cycy.utils.lowpass_filter(DataNarrowband, SampleRate, Range(2));
    freqz(Filter,2^14,SampleRate)

    clc
    disp(['Showing lowpass ', num2str(Range(2))])
    disp('Press enter to continue')
    pause


    % show original and filtered data
    figure('Units','normalized','OuterPosition',[0 0 1 .3])
    hold on
    plot(t, DataBroadband, 'k', 'LineWidth', 1.5)
    plot(t, DataNarrowband, 'r', 'LineWidth', 1)
    xlim([0 5])
    title(Band{1})

    % show original and filtered power spectrum
    [PowerBroadband, Freqs] = cycy.utils.compute_power(DataBroadband, SampleRate);
    [PowerNarrowband, ~] = cycy.utils.compute_power(DataNarrowband, SampleRate);

    figure
    hold on
    plot(Freqs, log(PowerBroadband), 'k')
    plot(Freqs, log(PowerNarrowband), 'r')
    xlim([0 60])


    clc
    disp(['Showing ', Band{1}])
    disp('Press enter to continue')
    pause
    close all
end



% TODO:
% - check data with and without filter
% - check spectrum with and without filter
