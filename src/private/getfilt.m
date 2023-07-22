function Filter = getfilt(type, method, srate, PassFrq, StopFrq, PassRipple, StopAtten)
% designs filter, or looks if the filter already exists and uses that.
% Part of Matcycle 2022, by Sophia Snipes.

% set up place to save the filter, so it doesn't have to be designed over
% and over again (a problem for high sampling rates)
CD = mfilename('fullpath');
CD = extractBefore(CD, 'getfilt');

Filename = strjoin({type, num2str(srate), num2str(PassFrq), num2str(StopFrq), ...
    num2str(PassRipple), num2str(StopAtten), [method, '.mat']}, '_');

FilterBankFolder = fullfile(CD, 'Filters');
Filepath = fullfile(FilterBankFolder, Filename);

if exist(Filepath, 'file')
    load(Filepath, 'Filter')
    return
elseif ~exist(FilterBankFolder, 'dir')
    mkdir(FilterBankFolder)
end

% design filter
disp(['Designing ' type, ' filter...'])
Filter = designfilt(type,'PassbandFrequency', PassFrq, 'StopbandFrequency',...
    StopFrq, 'StopbandAttenuation', StopAtten, 'PassbandRipple', PassRipple,...
    'SampleRate', srate, 'DesignMethod', method);

save(Filepath, 'Filter')
% freqz(Filter,2^14,srate) % DEBUG