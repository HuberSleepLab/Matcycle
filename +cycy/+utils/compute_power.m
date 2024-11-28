function [Power, Freqs] = compute_power(Data, SampleRate, WindowLength, Overlap)
% Data is a channel x time marix matrix. SampleRate is a single value in
% Hz, WindowLength is a single value in seconds, overlap is a ratio from 0
% to 1.
% e.g.:  [Power, Frequencies] = compute_power(Data, fs, 4, 0.5);
% Power is a Channel x Frequency matrix.
%
% From Matcycle, Snipes 2023.
arguments
    Data
    SampleRate (1, 1) {mustBePositive}
    WindowLength (1, 1) {mustBePositive} = 4;
    Overlap (1, 1) {mustBeLessThanOrEqual(Overlap, 1)} = .5;
end

Data(:, isnan(sum(Data, 1))) = [];

% FFT
nfft = 2^nextpow2(WindowLength*SampleRate);
if nfft > size(Data, 2)
    nfft = size(Data, 2);
end
noverlap = round(nfft*Overlap);
window = hanning(nfft);

[Power, Freqs] = pwelch(Data', window, noverlap, nfft, SampleRate);
Power = Power';
Freqs = Freqs';