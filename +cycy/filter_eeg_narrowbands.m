function EEGNarrowbands = filter_eeg_narrowbands(EEGBroadband, NarrowbandRanges)
% filters EEG data into the specified narrow bands (a structure, each field
% indicating a lower and upper bound like so: NarrowbandRanges.Alpha = [8 12];

SampleRate = EEGBroadband.srate;

BandLabels = fieldnames(NarrowbandRanges);

% create a struct array the same as the broadband data, but containing all
% the filtered data.
EEGNarrowbands = EEGBroadband;
for idxBand = 1:numel(BandLabels)
    EEGNarrowbands(idxBand) = EEGBroadband;
    EEGNarrowbands(idxBand).data = cycy.utils.highpass_filter(EEGNarrowbands(idxBand).data, ...
        SampleRate, NarrowbandRanges.(BandLabels{idxBand})(1));

      EEGNarrowbands(idxBand).data = cycy.utils.lowpass_filter(EEGNarrowbands(idxBand).data, ...
        SampleRate, NarrowbandRanges.(BandLabels{idxBand})(2));
      disp(['Finished filtering ', BandLabels{idxBand}])
end