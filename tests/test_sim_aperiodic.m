DefaultExponent = 3;
DefaultOffset = 1;
Duration = 120;
SampleRate = 250;
WelchWindow = 4;
WelchWindowOverlap = .5;
SmoothSpan = 3;


%% Test_Exponent

Exponents = -5:.3:5;

NewExponents = nan(size(Exponents));
NewOffsets = NewExponents;
for ExpIdx = 1:numel(Exponents)

[Signal, t] = cycy.sim.simulate_aperiodic_eeg(Exponents(ExpIdx), DefaultOffset, Duration, SampleRate, false);


[Power, Frequencies] = cycy.utils.compute_power(Signal, SampleRate, WelchWindow, WelchWindowOverlap);
% [Power, Frequencies] = cycy.utils.compute_power_fft(Signal, SampleRate);
PowerSmooth = cycy.utils.smooth_spectrum(Power, Frequencies, SmoothSpan);

% run FOOOF
[NewExponents(ExpIdx),  NewOffsets(ExpIdx), PeriodicPower, FooofFrequencies] = fooof_spectrum(PowerSmooth, Frequencies, [3 35]);

end

figure
plot(Exponents, NewExponents-abs(Exponents))

figure
plot(Exponents, NewOffsets)

% PROBLEM: there's a systematic bias in exponent
% PROBLEM: offset changes slightly


