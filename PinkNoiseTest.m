close all
clear
clc


%% generate signal

fs = 250;
Minutes = 10;


L = fs*60*Minutes;
c = linspace(1, fs, L/2);
freqs = fs*(0:(L/2))/L;
S = 1./c;
freqs = freqs(1:end-1);
figure;plot(freqs, S)


S(L/2+1:L)=flip(S);
S=S.*exp(j*2*pi*rand(1, L));
figure
Power = abs(S);
plot(freqs, Power(1:L/2))
S(1)=0;

t = linspace(0, L/fs, L);
figure
Signal = real(ifft(S));
plot(t, Signal)


Signal = hpfilt(Signal, fs, 2);
Signal = lpfilt(Signal, fs, 40);
hold on;plot(t, Signal)

%%


nPoints = L;
Min_Peaks = 3; % minimum number of cycles per burst

% Burst Thresholds for finding very clean bursts
BurstThresholds = struct();
BurstThresholds(1).isProminent = 1;
BurstThresholds(1).periodConsistency = .7;
BurstThresholds(1).periodMeanConsistency = .7;
BurstThresholds(1).truePeak = 1;
BurstThresholds(1).efficiencyAdj = .6;
BurstThresholds(1).flankConsistency = .5;
BurstThresholds(1).ampConsistency = .25;

% Burst thresholds for notched waves, but compensates
% with more strict thresholds for everything else
BurstThresholds(2).monotonicity = .8;
BurstThresholds(2).periodConsistency = .6;
BurstThresholds(2).periodMeanConsistency = .6;
BurstThresholds(2).efficiency = .8;
BurstThresholds(2).truePeak = 1;
BurstThresholds(2).flankConsistency = .5;
BurstThresholds(2).ampConsistency = .5;

Bands.ThetaLow = [2 6];
Bands.Theta = [4 8];
Bands.ThetaAlpha = [6 10];
Bands.Alpha = [8 12];

Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.


%% look at bursts
BandNames = fieldnames(Bands);

EEG = struct();
EEG.data = Signal;
EEG.srate = fs;
FiltEEG = EEG;

for Indx_F = 1:numel(BandNames)
    B = Bands.(BandNames{Indx_F});
    fSignal = hpfilt(Signal, fs, B(1));
    fSignal = lpfilt(fSignal, fs, B(2));

    Peaks = peakDetection(Signal, fSignal);
    Peaks = peakProperties(Signal, Peaks, fs);
    BT = removeEmptyFields(BurstThresholds(1));
    [~, BurstPeakIDs_Clean] = findBursts(Peaks, BT, Min_Peaks, Keep_Points);
    plotBursts(Signal, fs, Peaks, BurstPeakIDs_Clean, BT)

    BT = removeEmptyFields(BurstThresholds(2));
    [~, BurstPeakIDs_Clean] = findBursts(Peaks, BT, Min_Peaks, Keep_Points);
    plotBursts(Signal, fs, Peaks, BurstPeakIDs_Clean, BT)

    % count bursts
    FiltEEG(Indx_F).data = fSignal;
end

    FinalBursts = getAllBursts(EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points);









