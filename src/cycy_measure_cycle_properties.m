function AugmentedCycles = cycy_measure_cycle_properties(ChannelBroadband, Cycles, SampleRate)
% Identifies various ways to characterize each peak. Based on Cole 2019,
% but relative to the negative peaks rather than positive peaks.
% NOTE: all fieldnames should start lowercase, so I know later on that they
% come from here.

% Part of Matcycle 2022, by Sophia Snipes.

AugmentedCycles = struct();

for idxCycle = 1:numel(Cycles)

    CurrCycle = Cycles(idxCycle);
    if idxCycle == 1
        PrevCycle = [];
    else
        PrevCycle = Cycles(idxCycle-1);
    end
    if idxCycle == numel(Cycles)
        NextCycle = [];
    else
        NextCycle = Cycles(idxCycle+1);
    end

    CurrCycle = measure_amplitudes(CurrCycle, ChannelBroadband);
    CurrCycle = is_true_peak(CurrCycle);

    CurrCycle = measure_periods(PrevCycle, CurrCycle, NextCycle, SampleRate);
    Cycle = measure_prominence(PrevCycle, CurrCycle, NextCycle);

    AugmentedCycles(idxCycle) = CurrCycle;
end
end

function Cycle = measure_prominence(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)
% Returns a boolean, if the negative peak is prominent with respects to the
% two neighboring negative cycles.


MidpointFallingEdge = (CurrCycle.VoltagePrevPos-CurrCycle.VoltageNeg)/2;
Cycle1Signal = ChannelBroadband(PrevCycle.NegPeakIdx:CurrCycle.NegPeakIdx);


end
% 
% function Cycle = count_crossings(Wave, Threshold)
% 
% end


function Cycle = measure_amplitudes(Cycle, ChannelBroadband)
Cycle.VoltagePrevPos = ChannelBroadband(Cycle.PrevPosPeakIdx);
Cycle.VoltageNeg = ChannelBroadband(Cycle.NegPeakIdx);
Cycle.VoltageNextPos = ChannelBroadband(Cycle.NextPosPeakIdx);
end

function Cycle = is_true_peak(Cycle)
Cycle.isTruePeak = Cycle.VoltageNeg < Cycle.VoltagePrevPos & ...
    Cycle.VoltageNeg < Cycle.VoltageNextPos;
end

function CurrCycle = measure_periods(PrevCycle, CurrCycle, NextCycle, SampleRate)
CurrCycle.PeriodPos = (CurrCycle.NextPosPeakIdx - CurrCycle.PrevPosPeakIdx)/SampleRate;

if isempty(PrevCycle)
    CurrCycle.PeriodNeg = (NextCycle.NegPeakIdx - CurrCycle.NegPeakIdx)/SampleRate;
elseif isempty(NextCycle)
    CurrCycle.PeriodNeg = (CurrCycle.NegPeakIdx - PrevCycle.NegPeakIdx)/SampleRate;
else
    CurrCycle.PeriodNeg = (NextCycle.NegPeakIdx - PrevCycle.NegPeakIdx)/2/SampleRate;
end
end



