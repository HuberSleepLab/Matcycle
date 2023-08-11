function EEG = manually_score_bursts(EEG, ChannelsToHighlight, WindowLength, Scale)
arguments
    EEG
    ChannelsToHighlight = [];
        WindowLength = 20;
    Scale = 20;
end
% requires EEGLAB function, and input EEG signal needs to be called "EEG"

% get colors for the EEG channels
StandardColor = {[0.19608  0.19608  0.51765]};
LineColors = repmat(StandardColor, size(EEG.data, 1), 1);
LineColors(cycy.utils.labels2indexes(ChannelsToHighlight, EEG.chanlocs), :) = ...
    repmat({[1 0 0]}, numel(ChannelsToHighlight), 1); % make red channels to focus on

LineColors = repmat({'b'}, 1, size(EEG.data, 1));
LineColors(cycy.utils.labels2indexes(ChannelsToHighlight, EEG.chanlocs)) = ...
    repmat({'r'}, 1, numel(ChannelsToHighlight));

Pix = get(0,'screensize');

if isfield(EEG, 'ManualBurstWindows')
    RejectWindows = windows2TMPREJ(EEG.ManualBurstWindows, size(EEG.data, 1));
    eegplot(EEG.data, 'srate', EEG.srate, 'spacing', 50, 'winlength', WindowLength, ...
        'command', 'EEG.ManualBurstWindows = TMPREJ(:, 1:2)', 'color', LineColors', 'butlabel', 'Save', ...
        'winrej', RejectWindows, 'position', [0 0 Pix(3) Pix(4)])

else
    eegplot(EEG.data, 'srate', EEG.srate, 'spacing', 50, 'winlength', WindowLength, ...
        'command', 'EEG.ManualBurstWindows = TMPREJ(:, 1:2)', 'color', LineColors, 'butlabel', ...
        'Save', 'position', [0 0 Pix(3) Pix(4)])
end
end

function RejectWindows = windows2TMPREJ(Windows, ChannelCount)

Color = [1 1 0];
WindowsCount = size(Windows, 1);

RejectWindows = ones(WindowsCount, 5+ChannelCount);
RejectWindows(:, 1:2) = Windows;
RejectWindows(:, 3:5) = repmat(Color, WindowsCount, 1);
end