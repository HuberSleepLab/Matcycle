function [Signal, t] = eeg(AperiodicParameters, PeriodicParameters, ...
    Duration, SampleRate, WelchWindow, highpass,  lowpass)
arguments
    AperiodicParameters = struct();
    PeriodicParameters = struct();
    Duration = 20;
    SampleRate = 250;
    WelchWindow = 4;
    highpass = .8;
    lowpass = 45;
end
% AperiodicParameters is a structure that includes the fields:
% - Exponent (positive values)
% - Intercept

% PeriodicParameters is a structure with fields:
% - Frequency
% - Amplitude
% - Density
% - Duration

% Duration is the duration of the whole EEG signal
% WelchWindow is the window you used to derive the aperiodic information

if isempty(AperiodicParameters)
    AperiodicParameters.Exponent = 1;
    AperiodicParameters.Offset = 1;
end

if isempty(PeriodicParameters)
    PeriodicParameters.Frequency = 10;
    PeriodicParameters.Amplitude = 20;
    PeriodicParameters.Density = .2;
    PeriodicParameters.Duration = 1;
end


[Aperiodic, t] = cycy.sim.simulate_aperiodic_eeg(AperiodicParameters.Exponent, ...
    AperiodicParameters.Offset, Duration, SampleRate);

[Periodic, ~] = cycy.sim.simulate_periodic_eeg(PeriodicParameters.Frequency, ...
    PeriodicParameters.Amplitude, PeriodicParameters.Density, PeriodicParameters.Duration, ...
    Duration, SampleRate);

Signal = Aperiodic + Periodic;

Signal = cycy.utils.highpass_filter(Signal, SampleRate, highpass, 0.3, 'equiripple', 1, 80);
Signal = cycy.utils.lowpass_filter(Signal, SampleRate, lowpass, lowpass+5);

