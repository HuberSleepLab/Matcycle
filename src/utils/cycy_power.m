function [Power, Freqs] = cycy_power(Data, fs, Window, Overlap)
% Data is a Ch x t matrix. 

if ~exist("Window", 'var') || isempty(Window)
    Window = 4; % duration of window to do FFT
end

if ~exist("Overlap", 'var') || isempty(Window)
   Overlap = .5; % duration of window to do FFT
end

% FFT
nfft = 2^nextpow2(Window*fs);
noverlap = round(nfft*Overlap);
window = hanning(nfft);
[Power, Freqs] = pwelch(Data', window, noverlap, nfft, fs);
Power = Power';
Freqs = Freqs';