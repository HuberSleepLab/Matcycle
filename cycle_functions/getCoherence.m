function [Coherence, Freq] = getCoherence(Ref, Data, fs, freqRes)
% gets coherence values between reference and all channels in Data (ch x
% t).
%
% Part of Matcycle 2022, by Sophia Snipes.

Window = 2; % duration of window to do FFT
% Overlap = .5; % overlap of hanning windows for FFT

MinPoints = fs*Window + 1; % should be at least 2 seconds of data
%  MinPoints = 2^nextpow2(Window*fs) + 1;

[nCh, nPnts] = size(Data);

% mirror signal if too short
if nPnts < MinPoints

    % concatenate data to itself, flipping each time to avoid jumps, until
    % correct length
    zData = [];
    fData = Data;

    zRef = [];
    fRef = [];
    while size(zData, 2) < MinPoints
        zData = cat(2, zData, fData);
        fData = flip(fData, 2);

        zRef = cat(2, zRef, fRef);
        fRef = flip(fRef, 2);
    end
    error()

else
    zData = Data;
    zRef = Ref;
end

% get coherence for each channel
% nfft = 2^nextpow2(Window*fs);
% noverlap = round(nfft*Overlap);
% window = hanning(nfft);

% [Coherence, Freq] = mscohere(zRef', zData', window, noverlap, nfft, fs);

[Coherence, Freq] = mscohere(zRef', zData', hanning(fs), fs/2, freqRes*fs, fs);



