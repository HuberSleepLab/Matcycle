function [Power, Frequencies] = compute_power_fft(Data, fs)
% runs fft on signal. Data is a 1 x t array.

% Parameters
nPoints = numel(Data);  % Total number of samples

% Compute the FFT of the signal
fftSignal = fft(Data);

% Compute the power spectrum
Power = abs(fftSignal/nPoints).^2;
Frequencies = fs * (0:(nPoints/2)) / nPoints;

% Only take the first half of the spectrum (positive frequencies)
Power = Power(1:nPoints/2+1);
Power(2:end-1) = 2 * Power(2:end-1);  % Adjust for symmetry
