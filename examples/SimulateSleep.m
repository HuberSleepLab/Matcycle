clear
clc
close all

load('D:\Data\LSM\Preprocessed\Clean\Waves\Sleep\P15_Sleep_NightPre_Welch.mat')

Data = EEG.data;
SampleRate = EEG.srate;
WelchWindowLength = 4;
WelchOverlap = 0.5;
SmoothSpan = 2;

% calculate power
% [EpochPower, Frequencies] = oscip.compute_power_on_epochs(Data, ...
%     SampleRate, EpochLength, WelchWindowLength, WelchOverlap);


ScoringInTime = oscip.utils.scoring2time(visnum, 20, SampleRate, size(EEG.data, 2));

NREM = Data(11, ScoringInTime==-2);

Duration = 10*60;
NREM = NREM(1:Duration*SampleRate);

%%
[Power, FreqsOld] = cycy.utils.compute_power(NREM, SampleRate, WelchWindowLength, .5);
PowerSmoothOld = cycy.utils.smooth_spectrum(Power, FreqsOld, SmoothSpan);

figure
plot(FreqsOld, log10(Power))
hold on
plot(FreqsOld, log10(PowerSmoothOld))
% set(gca, 'yscale', 'log', 'xscale', 'log')

%%
FooofModel = fooof(FreqsOld, PowerSmoothOld, [.8 40], struct(), true);



%%
% calculate slopes
Slope = -FooofModel.aperiodic_params(2);
% Intercept = log(PowerSmooth(dsearchn(Frequencies', 1)));
Intercept = FooofModel.aperiodic_params(1);
[Data, t] = cycy.sim.simulate_aperiodic_eeg(Slope, Intercept, Duration, SampleRate);

fData = cycy.utils.highpass_filter(Data, SampleRate, 0.8, 0.4, 'equiripple', 1, 80);
fData = cycy.utils.lowpass_filter(fData, SampleRate, 40, 45);

% EEG2 = EEG;
% EEG2.data = fData;
% EEG2 = eeg_checkset(EEG2);
%  EEG2 = pop_eegfiltnew(EEG2, 1);
%  fData = EEG2.data;

figure
hold on
plot(FreqsOld, PowerSmoothOld)


[Power, Freqs] = cycy.utils.compute_power(fData, SampleRate, WelchWindowLength, WelchOverlap);
PowerSmooth = cycy.utils.smooth_spectrum(Power, Freqs, SmoothSpan);
plot(Freqs, PowerSmooth)
legend({'Original', 'Artificial'})
set(gca, 'YScale', 'log', 'XScale', 'log');




%%

[Data, t] = cycy.utils.simulate_aperiodic_eeg(-0.5, 0, 50, SampleRate);

fData = cycy.utils.highpass_filter(Data, SampleRate, 0.8, 0.4, 'equiripple', 1, 80);
fData = cycy.utils.lowpass_filter(fData, SampleRate, 40, 45);


[Periodic, ~] = cycy.sim.simulate_periodic_eeg(numel(Data)/SampleRate, SampleRate, 10, 20, 1, .3);

sumData = fData + Periodic;

figure('Units','centimeters', 'position', [0 0 40 5])
plot(t, sumData)
xlim([0 20])
ylim([-100 100])


figure
[Power, Freqs] = cycy.utils.compute_power_fft(sumData, SampleRate);
PowerSmooth = cycy.utils.smooth_spectrum(Power, Freqs, SmoothSpan);
plot(Freqs, PowerSmooth)
set(gca, 'YScale', 'log', 'XScale', 'log');
