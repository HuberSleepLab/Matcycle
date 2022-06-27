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

% zero pad the data if its too short
if nPnts < MinPoints
    zData = zeros(nCh, MinPoints);
    Start = (MinPoints-nPnts)/2;
    Range = round(Start:(Start+nPnts-1));
    zData(:, Range) = Data;

    zRef = zeros(1, MinPoints);
    zRef(Range) = Ref;

    nPnts = MinPoints;
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



% MinPoints = fs*2 + 1; % should be at least 2 seconds of data
%
% [nCh, nPnts] = size(Data);
%
% % zero pad the data if its too short
% if nPnts < MinPoints
%     zData = zeros(nCh, MinPoints);
%     Start = (MinPoints-nPnts)/2;
%     Range = round(Start:(Start+nPnts-1));
%     zData(:, Range) = Data;
%
%     zRef = zeros(1, MinPoints);
%     zRef(Range) = Ref;
%
%     nPnts = MinPoints;
% else
%     zData = Data;
%     zRef = Ref;
% end
%
% % get coherence for each channel
% Coherence = zeros(freqRes*fs/2+1, nCh);
% for Indx_Ch = 1:nCh
%     [Coherence(:, Indx_Ch), Freq] = mscohere(zRef, zData(Indx_Ch, :), ...
%         hanning(fs), fs/2, freqRes*fs, fs);
% end
