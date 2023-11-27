function [Spectrum, Frequencies, Time] = multitaper(Data, SampleRate, WindowLength, MovingWindowSampleRate)
arguments
    Data
    SampleRate
    WindowLength = .5; % in seconds
    MovingWindowSampleRate = .02;
end
% function to create a timexfrequency plot for visualizing data. Based on
% Mike X Cohen's example code
% (https://mikexcohen.com/lecturelets/multitaper/multitaper.html)
% using multitapers.
% to correct for the 1/f; I recommend whitening the data

Frequencies = linspace(0, SampleRate/2, WindowLength*SampleRate/2+1);

% array sizes
nChannels = size(Data, 1);
nFrequencies = numel(Frequencies);

nTimepointsData = size(Data, 2);
Time = 0:MovingWindowSampleRate:nTimepointsData/SampleRate; % in s
nTimepoints = numel(Time);
nTimepointsWindow = WindowLength*SampleRate;

% edges of the sliding windows used to calculate power
Starts = round(Time*SampleRate-WindowLength/2+1);
StartofStarts = find(Starts>0, 1, 'first'); % starts after half window length since it averages before and after

Ends = round(Starts+WindowLength*SampleRate)-1;
EndofEnds = find(Ends>nTimepointsData, 1, 'first')-1;

% create tapers
Tapers = dpss(nTimepointsWindow,3); % this line will crash without matlab signal processing toolbox
nTapers = size(Tapers, 2)-1; % just copying Cohen on the number of tapers

Spectrum = nan(nChannels, nFrequencies, nTimepoints);

for TimepointIdx = StartofStarts:EndofEnds

    TaperPower = zeros(nChannels, nFrequencies, nTapers);
    for TaperIdx = 1:nTapers
        DataWindow = Data(:, Starts(TimepointIdx):Ends(TimepointIdx))'; % t x ch

        % taper the window
        TaperedData = DataWindow.*Tapers(:,TaperIdx);

        % compute power
        Power = fft(TaperedData)/nTimepointsWindow;
        Power = Power(1:nFrequencies, :)';
        TaperPower(:, :, TaperIdx) = abs(Power).^2; % WHY exponent???
    end

    % average across tapers
    Spectrum(:, :, TimepointIdx) = mean(TaperPower, 3);
end


