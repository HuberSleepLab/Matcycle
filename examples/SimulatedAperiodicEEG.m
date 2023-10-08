
load('E:\Data\Final\EEG\Unlocked\window8s_duration4m\Game\P01_Game_Baseline_Welch.mat')




% % Load EEG data
% EEGData = EEG.data(1, :);
% 
% % calculate power
% WelchWindow = 4;
% Overlap = 0.5;
% [Power, Frequencies] = cycy.utils.compute_power(EEGData, EEG.srate, WelchWindow, Overlap);

% % smooth data for better fooof
SmoothSpan = 2;
PowerSmooth = cycy.utils.smooth_spectrum(Power(11, :), Freqs, SmoothSpan);

% calculate FOOOF
FooofModel = fooof(Freqs, PowerSmooth, [2 40], struct(), true);

%%
% calculate slopes
Slope = -FooofModel.aperiodic_params(1);
Intercept = FooofModel.aperiodic_params(2);
[Data, t] = cycy.utils.simulate_aperiodic_eeg(Slope, Intercept);


%%

% filter


% plot