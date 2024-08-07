 function [Data, t] = simulate_aperiodic_eeg(Slope, Intercept, Duration, SampleRate)
arguments
    Slope = -2;
    Intercept = 2;
    Duration = 30; % seconds
    SampleRate = 250;
end

nPoints = Duration * SampleRate;
Frequencies = SampleRate * (0:(nPoints/2)) / nPoints;

% % Calculate the power spectrum
% logFrequencies = log10(Frequencies);
% 
% LogPower = Intercept + Slope * logFrequencies;
% LogPower(1) = 0; % Set the DC component to zero
% 
% % Convert power to amplitude
% Power = 10.^(LogPower); % Convert dB to linear scale


Power = 1/(Frequencies).^Slope + Intercept;

figure
plot(Frequencies, Power)
set(gca, 'YScale', 'log', 'XScale', 'log');
title('simulated power')

% Generate complex spectrum
% Complex = Power .* exp(1i * 2 * pi * rand(1, numel(Frequencies)));
% Complex2 = [Complex, conj(Complex(end-1:-1:2))];
Complex = Power;
Complex2 = [Complex, conj(Complex(end-1:-1:2))];

% Convert to time domain
Data = real(ifft(Complex2, 'symmetric'));

% Generate time vector
t = linspace(0, Duration, nPoints);

hold on
[Power, Frequencies] = cycy.utils.compute_power_fft(Data, SampleRate);
plot(Frequencies, Power)