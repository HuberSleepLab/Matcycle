function [Signal, t] = simulate_aperiodic_eeg(Exponent, Offset, Duration, SampleRate, Plot)
arguments
    Exponent = 2;
    Offset = 2;
    Duration = 30; % seconds
    SampleRate = 250;
    Plot = false;
end
%  [Data, t] = simulate_aperiodic_eeg(Slope, Intercept, Duration, SampleRate, WelchWindow)
%
% Creates an artificial EEG trace without any oscillations. Expects inputs
% that are the typical outputs of the FOOOF algorithm. Defaults are
% provided, so can be run just as [Data, t] = simulate_aperiodic_eeg().
%
% Inputs:
% - Exponent is the slope of the aperiodic signal. Wake is typically around
% 1, and NREM 3 is around 3.
% - Offset is the overall power the aperiodic signal, and it depends
% on the duration of the signal used to calculate the power spectrum.
% Assumes offset comes from FOOOF, based on power calculated with pWelch.
% - Duration is the duration of the desired output signal.
% - SampleRate is the sample rate of the desired output signal (should be
% the same as the sample rate from which the exponent/offset were derived)
% - WelchWindow is the duration in seconds of the window used to calculate power,
% assuming that the Welch method was used, which calculates power over
% smaller overlapping windows, then averages these. If a pure FFT was used,
% then WelchWindow should be the length of the original signal, in seconds.
%
% From Matcycle, Snipes, 2024

%%% create a fake power spectrum based on inputs

% power spectrum should be as if the output of a simple FFT. Since
% offsets/exponents are usually derived from averaging power over smaller
% windows, then the offset needs to be adjusted to account for the
% difference in length.
% Offset = Offset/(Duration/WelchWindow);
Offset = Offset-log10(Duration);
Exponent = abs(Exponent); % FOOOF outputs slopes as positive values, some people might provide negative; this is safe

nPoints = Duration * SampleRate;
if mod(nPoints, 2) ~= 0 % if number is odd
    nPoints = nPoints-1;
end
Frequencies = SampleRate * (0:(nPoints/2)) / nPoints;


Power = Offset-log10(Frequencies.^Exponent);
Power(1:dsearchn(Frequencies', .2)) = Power(end); % Set the DC component to zero

Power = 10.^Power;

if Plot
    figure
    plot(Frequencies, Power, 'LineWidth',2)
    set(gca, 'YScale', 'log', 'XScale', 'log');
    title('simulated power')
end

% Generate complex spectrum to randomize phase
Complex = (sqrt(Power/2)) .* exp(1i * 2 * pi * rand(1, numel(Frequencies)));
Complex2 = [Complex, conj(Complex(end-1:-1:2))];


% Convert to time domain
Signal = ifft(Complex2, 'symmetric') * nPoints; % Scale by nPoints to correct magnitude


% Generate time vector
t = linspace(0, Duration, nPoints);

if Plot
    hold on
    [Power, Frequencies] = cycy.utils.compute_power_fft(Signal, SampleRate);
    plot(Frequencies, Power, ':', 'LineWidth',2, 'Color','r')
end