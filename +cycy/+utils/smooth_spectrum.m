function SmoothData = smooth_spectrum(Power, Frequencies, SmoothSpan)
% function for smoothing data
% Data is a 1 x Freqs matrix.
FreqRes = Frequencies(2)-Frequencies(1);
SmoothPoints = round(SmoothSpan/FreqRes);
SmoothData = smooth(Power, SmoothPoints, 'lowess');
end