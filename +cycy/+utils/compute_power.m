function [Power, Freqs] = compute_power(Data, SampleRate, WindowLength, Overlap)
% Data is a Ch x t matrix.
arguments
    Data
    SampleRate (1, 1) {mustBePositive}
    WindowLength (1, 1) {mustBePositive} = 4;
    Overlap (1, 1) {mustBePositive, mustBeLessThanOrEqual(Overlap, 1)} = .5;
end

% FFT
nfft = 2^nextpow2(WindowLength*SampleRate);
noverlap = round(nfft*Overlap);
window = hanning(nfft);
[Power, Freqs] = pwelch(Data', window, noverlap, nfft, SampleRate);
Power = Power';
Freqs = Freqs';