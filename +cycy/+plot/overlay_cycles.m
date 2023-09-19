function overlay_cycles(Burst, EEG)

SampleRate = EEG.srate;

CycleCount = numel(Burst.NegPeakIdx);
hold on
for idxCycle = 1:CycleCount
    PrevPoint = Burst.PrevPosPeakIdx(idxCycle);
    NegPoint = Burst.NegPeakIdx(idxCycle);
    NextPoint = Burst.NextPosPeakIdx(idxCycle);
    Cycle = EEG.data(Burst.ChannelIndex, PrevPoint:NextPoint);
    Min = min(Cycle);
    Max = max(Cycle);
    Cycle = (Cycle-Min)./(Max-Min);
        
    Time = linspace(PrevPoint-NegPoint, NextPoint-NegPoint, numel(Cycle))/SampleRate;

    plot(Time, Cycle, 'Color',[.7 .7 .7 .3])
end
