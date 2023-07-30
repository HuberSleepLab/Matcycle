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

    CurrCycle = measure_voltages(CurrCycle, ChannelBroadband);
    CurrCycle = is_true_peak(CurrCycle);

    CurrCycle = measure_periods(PrevCycle, CurrCycle, NextCycle, SampleRate);
    CurrCycle = measure_prominence(PrevCycle, CurrCycle, NextCycle);
    CurrCycle = measure_amplitude(CurrCycle, ChannelBroadband);
    CurrCycle = measure_amplitude_ramp(CurrCycle, ChannelBroadband);
    CurrCycle = measure_flank_consistency(CurrCycle, ChannelBroadband);
    CurrCycle = measure_monotonicity_in_time(CurrCycle, ChannelBroadband);
    CurrCycle = measure_monotonicity_in_amplitude(CurrCycle, ChannelBroadband);
    CurrCycle = measure_monotonicity_in_voltage(CurrCycle, ChannelBroadband);
    %     CurrCycle = measure_(CurrCycle, ChannelBroadband);

    AugmentedCycles(idxCycle) = CurrCycle;
end

%%%

% This is a separate for loop for determining properties that require
% the properties of the next cycle to already be calculated.
for idxCycle = 2:numel(AugmentedCycles)-1
    CurrCycle = AugmentedCycles(idxCycle);
    PrevCycle = AugmentedCycles(idxCycle-1);
    NextCycle = AugmentedCycles(idxCycle+1);


%     CurrCycle = measure_(PrevCycle, CurrCycle, NextCycle, ChannelBroadband);
    AugmentedCycles(idxCycle) = CurrCycle;
end

% remove edge peaks that are empty
AugmentedCycles([1 end]) = [];
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Cycle = measure_period_consistency(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)

end

function Cycle = measure_period_mean_consistency(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)
% I dont understand this one atm (oh mean consistency across both positive
% and negative periods)
% not going to do this one
end

function Cycle = measure_amplitude_consistency(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)

end

function Cycle = count_extra_peaks(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)

end

function Cycle = measure_notched_efficiency(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)
% calculate efficiency by taking the nearest positive peaks rather than the
% largest positive peaks ?
% wont do prominence
end


function Cycle = measure_amplitude(Cycle, ChannelBroadband)
Cycle.Amplitude = mean(ChannelBroadband([Cycle.PrevPosPeakIdx, Cycle.NextPosPeakIdx])) ...
    - ChannelBroadband(Cycle.NegPeakIdx);
end

function Cycle = measure_voltages(Cycle, ChannelBroadband)
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

function Cycle = measure_prominence(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)
% Returns a boolean, if the negative peak is prominent with respects to the
% two neighboring negative cycles.

MidpointFallingEdge = (CurrCycle.VoltagePrevPos-CurrCycle.VoltageNeg)/2;
Cycle1Signal = ChannelBroadband(PrevCycle.NegPeakIdx:CurrCycle.NegPeakIdx);
[~, FallingEdgeCrossings] = detect_crossings(Cycle1Signal, MidpointFallingEdge);

MidpointRisingEdge = (CurrCycle.VoltageNextPos-CurrCycle.VoltageNeg)/2;
Cycle2Signal = ChannelBroadband(CurrCycle.NegPeakIdx:NextCycle.NegPeakIdx);
[RisingEdgeCrossings, ~] = detect_crossings(Cycle2Signal, MidpointRisingEdge);

Cycle.isProminent = numel(FallingEdgeCrossings) <= 1 & numel(RisingEdgeCrossings) <= 1;
end

function Cycle = measure_amplitude_ramp(Cycle, ChannelBroadband)
% determines whether the rising edge is larger or smaller than the falling
% edge.

PrevPosPeak = ChannelBroadband(Cycle.PrevPosPeakIdx);
NextPosPeak = ChannelBroadband(Cycle.NextPosPeakIdx);

if PrevPosPeak < NextPosPeak
    Cycle.AmplitudeRamp = 1;
elseif PrevPosPeak > NextPosPeak
    Cycle.AmplitudeRamp = -1;
else
    Cycle.AmplitudeRamp = 0;
end
end

function Cycle = measure_flank_consistency(Cycle, ChannelBroadband)
FallingEdge = diff(ChannelBroadband([Cycle.NegPeakIdx, Cycle.PrevPosPeakIdx]));
RisingEdge = diff(ChannelBroadband([Cycle.NegPeakIdx, Cycle.NextPosPeakIdx]));

Cycle.FlankConsistency = min(FallingEdge/RisingEdge, RisingEdge/FallingEdge);
end

function Cycle = measure_monotonicity_in_time(Cycle, ChannelBroadband)
PrevPosPeak = ChannelBroadband(Cycle.PrevPosPeakIdx);
NegPeak =  ChannelBroadband(Cycle.NegPeakIdx);
NextPosPeak = ChannelBroadband(Cycle.NextPosPeakIdx);

FallingEdgeDiff = diff(ChannelBroadband(PrevPosPeak:NegPeak));
RisingEdgeDiff = diff(ChannelBroadband(NegPeak:NextPosPeak));

if numel(FallingEdgeDiff) < 2 || numel(RisingEdgeDiff) < 2
    Cycle.MonotonicityInTime = 0;
else
    Cycle.MonotonicityInTime = (nnz(FallingEdgeDiff < 0) + nnz(RisingEdgeDiff > 0)) / ...
        numel([FallingEdgeDiff, RisingEdgeDiff]); % TODO: make sure total doesn't duplicate midpoint?
end
end

function Cycle = measure_monotonicity_in_voltage(Cycle, ChannelBroadband)
PrevPosPeak = ChannelBroadband(Cycle.PrevPosPeakIdx);
NegPeak =  ChannelBroadband(Cycle.NegPeakIdx);
NextPosPeak = ChannelBroadband(Cycle.NextPosPeakIdx);

FallingEdgeDiff = diff(ChannelBroadband(PrevPosPeak:NegPeak));
RisingEdgeDiff = diff(ChannelBroadband(NegPeak:NextPosPeak));

MaxFallingEdge = diff(ChannelBroadband([NegPeak PrevPosPeak]));
MaxRisingEdge = diff(ChannelBroadband([NegPeak NextPosPeak]));

FallingEdgeEfficiency = (MaxFallingEdge - sum(abs(FallingEdgeDiff(FallingEdgeDiff>0))))/MaxFallingEdge;
RisingEdgeEfficiency = (MaxRisingEdge-sum(abs(RisingEdgeDiff(RisingEdgeDiff<0))))/MaxRisingEdge;

Cycle.MonotonicityVoltage = max(0, min(FallingEdgeEfficiency, RisingEdgeEfficiency));
end

