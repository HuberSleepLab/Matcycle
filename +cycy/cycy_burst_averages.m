function Bursts = cycy_burst_averages(Bursts)
% gets mean values of all the peaks in a burst, so long as the fieldname is
% lowercase, and the number of items is equal to the number of peak ids.
% Part of Matcycle 2022, by Sophia Snipes.

Fields = char(fieldnames(Bursts));
uppercase = isstrprop(Fields,'upper');
Fields = string(Fields);
Fields(uppercase(:, 1)) = [];
Fields = deblank(Fields);

for Indx_B = 1:numel(Bursts)
    B = Bursts(Indx_B);
    for Indx_F = 1:numel(Fields)
        PeakData = B.(Fields{Indx_F});
        if numel(PeakData) == numel(B.PeakIDs)
            Bursts(Indx_B).(['Mean_', Fields{Indx_F}]) = mean(PeakData);
        elseif strcmp(Fields{Indx_F}, 'period') && numel(PeakData)==1
            Bursts(Indx_B).(['Mean_', Fields{Indx_F}]) = PeakData;
        end
    end
end