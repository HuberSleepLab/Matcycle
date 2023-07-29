function Filter = cycy_design_or_load_filter(Type, DesignMethod, SampleRate, PassbandFrequency, ...
    StopbandFrequency, PassbandRipple, StopbandAttenuation)
% designs filter, or looks if the filter already exists and uses that.
% Part of Matcycle 2022, by Sophia Snipes.

% set up place to save the filter, so it doesn't have to be designed over
% and over again (a problem for high sampling rates)
ScriptPath = mfilename('fullpath');
ScriptDir = extractBefore(ScriptPath, 'cycy_design_or_load_filter');

FilterFilename = strjoin({Type, num2str(SampleRate), num2str(PassbandFrequency), num2str(StopbandFrequency), ...
    num2str(PassbandRipple), num2str(StopbandAttenuation), [DesignMethod, '.mat']}, '_');

FilterBankDir = fullfile(ScriptDir, 'Filters');
FilterPath = fullfile(FilterBankDir, FilterFilename);

if exist(FilterPath, 'file')
    load(FilterPath, 'Filter')
    return
elseif ~exist(FilterBankDir, 'dir')
    mkdir(FilterBankDir)
end

% design filter
disp(['Designing ' Type, ' filter...'])
Filter = designfilt(Type, ...
    'PassbandFrequency', PassbandFrequency, ...
    'StopbandFrequency', StopbandFrequency, ...
    'StopbandAttenuation', StopbandAttenuation, ...
    'PassbandRipple', PassbandRipple,...
    'SampleRate', SampleRate, ...
    'DesignMethod', DesignMethod);

save(FilterPath, 'Filter')
% freqz(Filter,2^14,srate) % DEBUG