function [Power, Freqs] = discrete_time_frequency(Data, SampleRate, EpochLength, WindowLength, Overlap)
% Calculates a time-frequency plot for data, but nothing fancy, just
% non-overlapping windows.
% Data is ch x t. Power is a ch x Freq x t matrix or Freq x t if only 1
% channel provided.

nChans = size(Data, 1);
Timepoints = size(Data, 2);
Freqs = linspace(0, SampleRate/2, WindowLength*SampleRate/2+1);
nFreqs = numel(Freqs);

Starts = 1:EpochLength*SampleRate:Timepoints;
Starts(end) = [];
Ends = Starts+EpochLength*SampleRate-1;
% Ends(end) = Timepoints;
nWindows = numel(Starts);

 Power = nan(nChans, nFreqs, nWindows);

for WindowIdx = 1:nWindows
    DataWindow = Data(:, Starts(WindowIdx):Ends(WindowIdx));
    [PowerWindow, Freqs] = cycy.utils.compute_power(DataWindow, SampleRate, WindowLength, Overlap);

    Power(:, :, WindowIdx) = PowerWindow;
end


Power = squeeze(Power);