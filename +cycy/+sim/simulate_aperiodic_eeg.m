function [Data, t] = simulate_aperiodic_eeg(Slope, Intercept, Duration, SampleRate, WelchWindow)
arguments
    Slope = -2;
    Intercept = 2;
    Duration = 30; % seconds
    SampleRate = 250;
    WelchWindow = Duration;
end

% intercept is adjusted for the length of the signal relative to the FOOOF
% output, which is typically supplied with power over shorter windows. So
% if power was calculated over 4 s windows, and now we're creating a 20
% second data snippet that emulates that power spectrum, the FFT slope is
% going to be 5 times higher amplitude.
Intercept = Intercept - log10(Duration/WelchWindow); 

nPoints = Duration * SampleRate;
Frequencies = SampleRate * (0:(nPoints/2)) / nPoints;

% Calculate the power spectrum
logFrequencies = log10(Frequencies);

LogPower = Intercept + Slope * logFrequencies;
LogPower(1:dsearchn(Frequencies', .5)) = LogPower(dsearchn(Frequencies', 40)); % Set the DC component to zero

% Convert power to amplitude
Power = 10.^(LogPower); % Convert dB to linear scale

% DEBUG
% figure
% plot(Frequencies, Power, 'LineWidth',2)
% set(gca, 'YScale', 'log', 'XScale', 'log');
% title('simulated power')

% Generate complex spectrum to randomize phase
Complex = (sqrt(Power/2)) .* exp(1i * 2 * pi * rand(1, numel(Frequencies)));
Complex2 = [Complex, conj(Complex(end-1:-1:2))];

% Convert to time domain
Data = real(ifft(Complex2, 'symmetric') * nPoints); % Scale by nPoints to correct magnitude

% Generate time vector
t = linspace(0, Duration, nPoints);

% DEBUG
% hold on
% [Power, Frequencies] = cycy.utils.compute_power_fft(Data, SampleRate);
% plot(Frequencies, Power, ':', 'LineWidth',2)