function EEG = manually_score_bursts(EEG, isBurst, WindowLength, Scale)
arguments
    EEG
    isBurst = true;
    WindowLength = 20;
    Scale = 20;
end
% requires EEGLAB function, and input EEG signal needs to be called "EEG"

if isBurst
    CommandOnSave = 'EEG.ManualBurstWindows = TMPREJ(:, 1:2)';
else
    CommandOnSave = 'EEG.ManualNoiseWindows = TMPREJ(:, 1:2)';
end


Pix = get(0,'screensize');

if isfield(EEG, 'ManualBurstWindows') || isfield(EEG, 'ManualNoiseWindows') 
    RejectWindows = create_highlights(EEG);
    eegplot(EEG.data, 'srate', EEG.srate, 'spacing',Scale, 'winlength', WindowLength, ...
        'command', CommandOnSave, 'butlabel', 'Save', ...
        'winrej', RejectWindows, 'position', [0 0 Pix(3) Pix(4)]);

else
    eegplot(EEG.data, 'srate', EEG.srate, 'spacing', Scale, 'winlength', WindowLength, ...
        'command',CommandOnSave,'butlabel', ...
        'Save', 'position', [0 0 Pix(3) Pix(4)]);
end
end

function HighlightWindows = create_highlights(EEG)

ChannelCount = size(EEG.data, 1);

% burst highlights
if isfield(EEG, 'ManualBurstWindows')
Color = cycy.utils.pick_colors([1, 3], '', 'green');
BurstHighlights = windows2TMPREJ(EEG.ManualBurstWindows, Color(3, :), ChannelCount);
else
    BurstHighlights = [];
end

if isfield(EEG, 'ManualNoiseWindows')
Color = cycy.utils.pick_colors([1 3], '', 'red');
NoiseHighlights = windows2TMPREJ(EEG.ManualNoiseWindows, Color(3, :), ChannelCount);
else
    NoiseHighlights = [];
end

HighlightWindows = cat(1, BurstHighlights, NoiseHighlights);

end

function TMPREJ = windows2TMPREJ(Windows, Color, ChannelCount)
% turns windows (n x 2 array) into a TMPREJ array as required by EEGLAB, so
% [n x [Starts, Ends, R, G, B, ch1, ch2 ...] ]

WindowsCount = size(Windows, 1);

TMPREJ = ones(WindowsCount, 5+ChannelCount);
TMPREJ(:, 1:2) = Windows;
TMPREJ(:, 3:5) = repmat(Color, WindowsCount, 1);

end
