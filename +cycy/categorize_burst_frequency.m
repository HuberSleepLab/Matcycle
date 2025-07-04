function Bursts = categorize_burst_frequency(Bursts, FrequencyBins, Labels)
arguments
    Bursts
    FrequencyBins = 0:4:40;
    Labels = [];
end

BurstFrequencies = [Bursts.BurstFrequency];

BurstFrequencies = discretize(BurstFrequencies, FrequencyBins);

for BurstIdx = 1:numel(Bursts)

    if isnan(BurstFrequencies(BurstIdx))
        Bursts(BurstIdx).FrequencyCat = ' ';
    elseif isempty(Labels)
        Bursts(BurstIdx).FrequencyCat = BurstFrequencies(BurstIdx);
    else
        Bursts(BurstIdx).FrequencyCat = Labels(BurstFrequencies(BurstIdx));
    end
end

