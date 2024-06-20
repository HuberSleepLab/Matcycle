function Bursts = assign_band_label(Bursts, Bands, NewFieldname)
% given specific bands, assign each burst to that band based on the mean
% cycle frequency. Bands is a struct, with each field indicating the name
% of the band, and assigned a 1 x 2 array with the edges of the band.

BandLabels = fieldnames(Bands);
BurstFrequences = [Bursts.BurstFrequency];
BurstBands = ones(1, numel(Bursts))*(numel(BandLabels)+1);

% assign band
for idxBand = 1:numel(BandLabels)
    Band = Bands.(BandLabels{idxBand});
    BurstBands(BurstFrequences>=Band(1) & BurstFrequences<=Band(2)) = idxBand;
end

BandLabels = cat(1, BandLabels, {'Other'});

% save label to burst struct
for indxBursts = 1:numel(Bursts)
    Bursts(indxBursts).(NewFieldname) = BandLabels{BurstBands(indxBursts)};
end