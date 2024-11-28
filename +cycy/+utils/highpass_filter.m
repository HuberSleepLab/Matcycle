function [FiltData, Filter] = highpass_filter(Data, SampleRate, PassbandFrequency, ...
    StopbandFrequency, DesignMethod, PassbandRipple, StopbandAttenuation)
arguments
    Data
    SampleRate (1, 1) {mustBePositive}
    PassbandFrequency (1, 1) {mustBePositive}
    StopbandFrequency (1, 1) {mustBePositive} = PassbandFrequency-1;
    DesignMethod = 'equiripple';
    PassbandRipple = 0.04;
    StopbandAttenuation = 40;
end
% High-pass filter for EEG data. Filters data optimally when around 3-20 Hz.
% All inputs after PassbandFrequency are optional.
% part of Matcycle 2022 by Sophia Snipes. Filter by Sven Leach.


% design filter, or load in from cache
Filter = cycy.utils.cache_function_output(@designfilt, 'highpassfir', ...
    'PassbandFrequency', PassbandFrequency, ...
    'StopbandFrequency', StopbandFrequency, ...
    'StopbandAttenuation', StopbandAttenuation, ...
    'PassbandRipple', PassbandRipple,...
    'SampleRate', SampleRate, ...
    'DesignMethod', DesignMethod);

% skip any rows that have NaN values
NaNRows = any(isnan(Data), 2);
FiltData = nan(size(Data));
Data(NaNRows, :) = [];

% apply filter
FData = filtfilt(Filter, double(Data'))'; % make sure data is double; EEGLAB sometimes gives singles
FiltData(~NaNRows, :) = FData;

