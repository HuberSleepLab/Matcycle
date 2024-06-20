function [FiltData, Filter] = lowpass_filter(Data, SampleRate, PassbandFrequency, ...
    StopbandFrequency, DesignMethod, PassbandRipple, StopbandAttenuation)
arguments
    Data
    SampleRate (1, 1) {mustBePositive}
    PassbandFrequency (1, 1) {mustBePositive}
    StopbandFrequency (1, 1) {mustBePositive} = PassbandFrequency+1;
    DesignMethod = 'equiripple';
    PassbandRipple = 0.02; % TODO: check if should be 0.04 like highpass
    StopbandAttenuation = 40;
end
% High-pass filter for EEG data. Filters data optimally when around 3-20 Hz.
% All inputs after PassbandFrequency are optional.
% part of Matcycle 2022 by Sophia Snipes. Filter by Sven Leach.


% design filter, or load in from cache

Filter = cycy.utils.cache_function_output(@designfilt, 'lowpassfir', ...
    'PassbandFrequency', PassbandFrequency, ...
    'StopbandFrequency', StopbandFrequency, ...
    'StopbandAttenuation', StopbandAttenuation, ...
    'PassbandRipple', PassbandRipple,...
    'SampleRate', SampleRate, ...
    'DesignMethod', DesignMethod);

FiltData = filtfilt(Filter, double(Data'))'; % make sure data is double; EEGLAB sometimes gives singles