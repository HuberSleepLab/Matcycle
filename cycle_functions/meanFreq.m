function AllBursts = meanFreq(AllBursts)
% loops through all bursts, gets mean frequency based on period

for Indx_B = 1:numel(AllBursts)
    AllBursts(Indx_B).Frequency = 1/mean(AllBursts(Indx_B).period);
end