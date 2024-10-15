function [Data, t] = simulate_periodic_eeg(CenterFrequency, BurstAmplitude, BurstDensity, BurstDuration, Duration, SampleRate, Plot)
arguments
    CenterFrequency = 10;
    BurstAmplitude = 20;
    BurstDensity = .5;
    BurstDuration = 1;
    Duration = 10;
    SampleRate = 250;
    Plot = false;
end
% [Data, t] = simulate_periodic_eeg(Duration, SampleRate, CenterFrequency, BurstAmplitude, BurstDuration, BurstDensity, Plot)
%
% creates a signal where bursts come and go.
% Duration in seconds
% SampleRate
% CenterFrequency is the frequency of the oscillation bursts
% BurstAmplitude is peak to peak in microvolts.
% BurstDuration is how long each burst should be.
% Burst density is the proportion of the signal that should have a burst.
% Plot will plot the signal and power spectrum.
%
% from Matcycle, Snipes, 2024

    t = [];
    Data = [];

% set up blank signal
nPoints = Duration*SampleRate;

% only have even number of points (because aperiodic signal goes wonky?)
if isnan(nPoints)
    warning('invalid duration or sample rate')
    return
elseif nPoints < BurstDuration*SampleRate
    warning('Duration set to less than a single burst')
    return
elseif mod(nPoints, 2) ~= 0 % if number is odd
    nPoints = nPoints-1;
end

t = linspace(0, Duration, nPoints);
Data = zeros(1, nPoints);


if BurstDensity==1
    Data = (BurstAmplitude/2).*sin(2*pi*CenterFrequency*t);
    return
elseif BurstDensity>1
    error('Burst density has to be between 0 and 1')
end

% set up a single burst's signal
nPointsBurst = floor(BurstDuration*SampleRate);
tBurst = linspace(0, BurstDuration, nPointsBurst);
Burst = (BurstAmplitude/2).*sin(2*pi*CenterFrequency*tBurst);

% randomize gaps to place between bursts
% takes the remaining time not occupied by bursts, randomly identifies
% points in this range, and then the difference between these points are
% going to be the gaps.
nBursts = floor(nPoints*BurstDensity/nPointsBurst);
if nBursts == 0 || isnan(nBursts)
    return
end

Gaps = randperm(round(nPoints*(1-BurstDensity)), nBursts+1);
nPointsGaps = diff(sort(Gaps));

% place bursts in signal
Start = 1;
for GapIdx = 1:numel(nPointsGaps)
    Start = Start+nPointsGaps(GapIdx)-1;
    End = Start+nPointsBurst-1;

    Data(Start:End) = Burst;
    Start = End;
end


if Plot
    figure('Units','normalized', 'Position',[0 0 .3 .15])
    subplot(1, 2 , 1)
    plot(t,Data)
    xlabel('Time (s)')
    box off
    [Power, Frequencies] = cycy.utils.compute_power(Data, SampleRate);

    subplot(1, 2, 2)
    plot(Frequencies, smooth(Frequencies, Power, 2))
    xlabel('Frequency (Hz)')
    box off
end