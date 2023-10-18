

load('E:\Data\Preprocessed\Clean\Waves\Game\P10_Game_Session2_Clean.mat')

%%
% % Load EEG data
EEGData = EEG.data(11, :);

% calculate power
WelchWindow = 4;
Overlap = 0.5;
[Power, Frequencies] = cycy.utils.compute_power(EEGData, EEG.srate, WelchWindow, Overlap);

% % smooth data for better fooof
SmoothSpan = 2;
PowerSmooth = cycy.utils.smooth_spectrum(Power, Frequencies, SmoothSpan);
figure
% cycy.plot.power_spectrum(PowerSmooth', Frequencies, true, true)
plot(log(Frequencies), log(PowerSmooth))
% plot(PowerSmooth)

% calculate FOOOF
FooofModel = fooof(Frequencies, PowerSmooth, [1 40], struct(), true);
% fooof_plot(FooofModel)


%%
% calculate slopes
Slope = -FooofModel.aperiodic_params(2);
% Intercept = log(PowerSmooth(dsearchn(Frequencies', 1)));
Intercept = FooofModel.aperiodic_params(1);
[Data, t] = cycy.utils.simulate_aperiodic_eeg(Slope, Intercept, 30, EEG.srate);

%%

% filter
fData = cycy.utils.highpass_filter(Data, EEG.srate, 0.5, 0.2);

% plot
figure;
hold on
plot(t, Data)
plot(t, fData)

%%
[Power, Frequencies] = cycy.utils.compute_power(fData, EEG.srate, WelchWindow, Overlap);
figure
cycy.plot.power_spectrum(Power, Frequencies, true, true)