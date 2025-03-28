function Bursts = average_cycles(Bursts, Fields)


for BurstIdx = 1:numel(Bursts)
    for Field = Fields
        Bursts(BurstIdx).(['Mean',Field{1}]) = mean(Bursts(BurstIdx).(Field{1}), 'omitnan');
    end
end