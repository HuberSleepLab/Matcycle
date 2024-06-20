function Bursts = windows2bursts(EEG, Windows, Channel)

Bursts = struct();


for idxBurst = 1:size(Windows, 1)
    Bursts.Start = Windows(idxBurst);
    Bursts.End = Windows(idxBurst);
    Bursts.Channel = Channel;
    Bursts

end