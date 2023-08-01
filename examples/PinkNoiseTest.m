% close all
clear
clc


addpath(genpath(extractBefore(mfilename('fullpath'), 'PinkNoiseTest')))

fs = 250;
Minutes = 10;
nPoints = fs*60*Minutes;

MinCyclesPerBurst = 4; % minimum number of cycles per burst

% % Burst Thresholds for finding very clean bursts
% BT = struct();
% BT(1).isProminent = 1;
% BT(1).periodConsistency = .7;
% BT(1).periodMeanConsistency = .7;
% BT(1).truePeak = 1;
% BT(1).efficiencyAdj = .6;
% BT(1).flankConsistency = .5;
% BT(1).ampConsistency = .25;
% 
% % Burst thresholds for notched waves, but compensates
% % with more strict thresholds for everything else
% BT(2).monotonicity = .8;
% BT(2).periodConsistency = .6;
% BT(2).periodMeanConsistency = .6;
% BT(2).efficiency = .8;
% BT(2).truePeak = 1;
% BT(2).flankConsistency = .5;
% BT(2).ampConsistency = .5;

BT = struct();
BT.monotonicity = .6;
BT.periodConsistency = .6;
BT.periodMeanConsistency = .6;
BT.efficiency = .6;
BT.truePeak = 1;
BT.flankConsistency = .5;
BT.ampConsistency = .6;

Bands.ThetaLow = [2 6];
Bands.Theta = [4 8];
Bands.ThetaAlpha = [6 10];
Bands.Alpha = [8 12];
Bands.AlphaHigh = [10 14];

Repeats = 100;

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
%     Power = abs(S);
    % plot(freqs, Power(1:L/2))
    S(1)=0;

    t = linspace(0, nPoints/fs, nPoints);
    % figure
    Signal = real(ifft(S));
    % plot(t, Signal)

    % filter between 2 and 40 hz
    Signal = cycy_cycy.utils.highpass_filter(Signal, fs, 2);
    Signal = lowpass_filter(Signal, fs, 40);
    %     hold on;plot(t, Signal)

    Keep_Points = ones(1, nPoints); % set to 0 any points that contain artifacts or just wish to ignore.


    % look at bursts
    BandNames = fieldnames(Bands);

    EEG.data(Indx_R, :) = Signal;
    EEG.srate = fs;

    for Indx_F = 1:numel(BandNames)
        B = Bands.(BandNames{Indx_F});
        fSignal = cycy_cycy.utils.highpass_filter(Signal, fs, B(1));
        fSignal = lowpass_filter(fSignal, fs, B(2));

        % count bursts
        FiltEEG(Indx_F).data(Indx_R, :) = fSignal;
    end
    disp(['Finished R',num2str(Indx_R)])
end

FinalBursts = cycy_detect_bursts(EEG, FiltEEG, BT, MinCyclesPerBurst, Bands, Keep_Points);

T = tabulate([FinalBursts.Channel]);
periods = cat(2, periods, FinalBursts.period);
npeaks =  cat(2, npeaks, FinalBursts.nPeaks);



%%


figure('Units','normalized', 'Position',[0 0 1 .5])
subplot(1, 3, 1)
Distribution = T(:, 2);
histogram(Distribution)
title(['Number of Bursts: ', num2str(numel(FinalBursts)/Repeats), ' per ', num2str(Minutes), 'min; 5%: ', num2str(quantile(Distribution, .95))])

subplot(1, 3, 2)
histogram(1./periods)
title(['Frequency Mean: ', num2str(mean(1./periods))])


subplot(1, 3, 3)
histogram(npeaks)
title(['Tot peaks Mean: ', num2str(mean(npeaks)), '; 5%: ', num2str(quantile(npeaks, .95))])
saveas(gcf,  [num2str(Repeats), '_Diagnostics.jpg']);




