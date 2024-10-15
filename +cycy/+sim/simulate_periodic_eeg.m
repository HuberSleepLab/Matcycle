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


% set up blank signal
t = [];
Data = [];
nPoints = Duration*SampleRate;
nPoints = round(nPoints);

if isnan(nPoints)
    warning('invalid duration or sample rate')
    return
elseif nPoints < BurstDuration*SampleRate
    warning('Duration set to less than a single burst')
    return
elseif nPoints > 10^9
    warning('Number of points is too large')
    return
end

% check that nPoints is an acceptable number of points
if mod(nPoints, 2) ~= 0 % if number is odd, make even number of points
    nPoints = nPoints-1;
    RemovedPoint = true;
else
    RemovedPoint = false;
end

% check that center frequency is ok
if isnan(CenterFrequency) || CenterFrequency==0
    warning('Invalid center frequency')
    return

elseif CenterFrequency >= SampleRate/2 % Nyquist rule is it has to be half, practically, should be 1/5th
    warning('Center frequency is too high for the chosen sample rate. Should be less than half it.')
    return
elseif 1/CenterFrequency > BurstDuration
    warning('Period of given center frequency is longer than a single burst duration.')
    return
end


% check that burst density is ok
if BurstDensity==1
    t = linspace(0, Duration, nPoints);
    Data = (BurstAmplitude/2).*sin(2*pi*CenterFrequency*t);
    return
elseif BurstDensity>1
    warning('Burst density has to be between 0 and 1')
end

% check that there's enough data for the bursts
nPointsBurst = floor(BurstDuration*SampleRate);
nBursts = floor(nPoints*BurstDensity/nPointsBurst);
if nBursts == 0 || isnan(nBursts)
    warning('no actual bursts')
    return
end

% check that there's at least 3 cycles in a burst
if nPointsBurst < 3*(1/CenterFrequency)*SampleRate
    warning('Burst duration is too short for center frequency. Should have at least 3 cycles')
    return
end

t = linspace(0, Duration, nPoints);
Data = zeros(1, nPoints);


% set up a single burst's signal
tBurst = linspace(0, BurstDuration, nPointsBurst);
Burst = (BurstAmplitude/2).*sin(2*pi*CenterFrequency*tBurst);

% randomize gaps to place between bursts
% takes the remaining time not occupied by bursts, randomly identifies
% points in this range, and then the difference between these points are
% going to be the gaps.

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

if exist('RemovedPoint', 'var') && RemovedPoint
    Data(end+1)= Data(end);
    t(end+1) = t(end)+diff(t([1, 2]));
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