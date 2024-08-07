clear
clc
 close all

load('D:\Data\LSM\Preprocessed\Clean\Waves\Game\P10_Game_Session2_Clean.mat')

%%

close all

% % Load EEG data
EEGData = EEG.data(11, :);
fs = EEG.srate;

% calculate power
WelchWindow = 4;
Overlap = 0.5;
[Power, Frequencies] = cycy.utils.compute_power(EEGData, fs, WelchWindow, Overlap);
% [Power, Frequencies] = cycy.utils.compute_power_fft(EEGData, fs);

% % smooth data for better fooof
SmoothSpan = 2;
PowerSmoothOriginal = cycy.utils.smooth_spectrum(Power, Frequencies, SmoothSpan);
figure
% cycy.plot.power_spectrum(PowerSmoothOriginal', Frequencies, true, true)
plot(log10(Frequencies), log10(PowerSmoothOriginal))

figure
cycy.plot.power_spectrum(PowerSmoothOriginal', Frequencies, true, true)


% calculate FOOOF
FooofModel = fooof(Frequencies, PowerSmoothOriginal, [1 40], struct(), true);
% fooof_plot(FooofModel)

Duration = numel(EEGData)/EEG.srate;

%%
% calculate slopes
Slope = -FooofModel.aperiodic_params(2);
% Intercept = log(PowerSmooth(dsearchn(Frequencies', 1)));
Intercept = FooofModel.aperiodic_params(1);
[Data, t] = cycy.utils.simulate_aperiodic_eeg(Slope, Intercept, Duration, fs);

%%

% filter
fData = cycy.utils.highpass_filter(Data, EEG.srate, 0.5, 0.2);
fData = cycy.utils.lowpass_filter(fData, EEG.srate, 40, 45);

% plot
figure;
hold on
% plot(t, Data)
plot(T, fData)
xlim([0 10])

%%
[Power, Frequencies] = cycy.utils.compute_power(fData, EEG.srate, WelchWindow, Overlap);
PowerSmooth = cycy.utils.smooth_spectrum(Power', Frequencies, SmoothSpan);

figure
hold on
cycy.plot.power_spectrum(PowerSmoothOriginal', Frequencies, true, true)
cycy.plot.power_spectrum(PowerSmooth', Frequencies, true, true)
legend({'Original', 'Artificial'})