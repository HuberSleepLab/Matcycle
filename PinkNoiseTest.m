close all
clear
clc


addpath(genpath(extractBefore(mfilename('fullpath'), 'PinkNoiseTest')))

fs = 250;
Minutes = 10;
nPoints = fs*60*Minutes;

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


Repeats = 130;

NBursts = zeros(1, Repeats);
periods = [];
npeaks = [];

EEG = struct();
EEG.data = nan(Repeats, nPoints);
FiltEEG = EEG;

for Indx_R = 1:Repeats

    % generate signal

    c = linspace(1, fs, nPoints/2);
    freqs = fs*(0:(nPoints/2))/nPoints;
    S = 1./c;
    % freqs = freqs(1:end-1);
    % figure;plot(freqs, S)


    S(nPoints/2+1:nPoints)=flip(S);
    S=S.*exp(j*2*pi*rand(1, nPoints));
    % figure
    Power = abs(S);
    % plot(freqs, Power(1:L/2))
    S(1)=0;

    t = linspace(0, nPoints/fs, nPoints);
    % figure
    Signal = real(ifft(S));
    % plot(t, Signal)

    % filter between 2 and 40 hz
    Signal = hpfilt(Signal, fs, 2);
    Signal = lpfilt(Signal, fs, 40);
    %     hold on;plot(t, Signal)

    Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.


    % look at bursts
    BandNames = fieldnames(Bands);

    EEG.data(Indx_R, :) = Signal;
    EEG.srate = fs;

    for Indx_F = 1:numel(BandNames)
        B = Bands.(BandNames{Indx_F});
        fSignal = hpfilt(Signal, fs, B(1));
        fSignal = lpfilt(fSignal, fs, B(2));

        % count bursts
        FiltEEG(Indx_F).data(Indx_R, :) = fSignal;
    end
    disp(['Finished R',num2str(Indx_R)])
end

FinalBursts = getAllBursts(EEG, FiltEEG, BurstThresholds, Min_Peaks, Bands, Keep_Points);

T = tabulate([FinalBursts.Channel]);
periods = cat(2, periods, FinalBursts.period);
npeaks =  cat(2, npeaks, FinalBursts.nPeaks);



%%


figure('Units','normalized', 'Position',[0 0 1 .5])
subplot(1, 3, 1)
Distribution = T(:, 2);
histogram(Distribution)
title(['Number of Bursts Mean: ', num2str(numel(FinalBursts)/Repeats), '; 5%: ', num2str(quantile(Distribution, .95))])

subplot(1, 3, 2)
histogram(1./periods)
title(['Frequency Mean: ', num2str(mean(1./periods))])


subplot(1, 3, 3)
histogram(npeaks)
title(['Tot peaks Mean: ', num2str(mean(npeaks)), '; 5%: ', num2str(quantile(npeaks, .95))])
saveas(gcf,  [num2str(Repeats), '_Diagnostics.jpg']);




