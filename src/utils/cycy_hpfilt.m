function FiltData = cycy_hpfilt(Data, SampleRate, PassbandFrequency, StopbandFrequency)
% High-pass filter for EEG data. Filters data optimally when around 3-20 Hz.
% part of Matcycle 2022 by Sophia Snipes. Filter by Sven Leach.

Type = 'highpassfir';
DesignMethod = 'equiripple';
PassbandRipple = 0.04;
StopbandAttenuation = 40;

if ~exist('StopbandFrequency', 'var') || isempty(StopbandFrequency)
    StopbandFrequency = PassbandFrequency-1;
end

% design filter, or load in from cache
Filter = cycy_cache(@designfilt, Type, ...
    'PassbandFrequency', PassbandFrequency, ...
    'StopbandFrequency', StopbandFrequency, ...
    'StopbandAttenuation', StopbandAttenuation, ...
    'PassbandRipple', PassbandRipple,...
    'SampleRate', SampleRate, ...
    'DesignMethod', DesignMethod);

FiltData = filtfilt(Filter, double(Data'))'; % make sure data is double; EEGLAB sometimes gives singles


%%% old method
% method = 'cheby2';
% type = 'highpassiir';
% srate = fs;
% StopFrq = PassFrq-1; % not perfect, but easy to understand
% PassRipple = 0.1;
% StopAtten = 60;