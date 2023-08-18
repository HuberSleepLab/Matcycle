function AugmentedCycles = measure_cycle_properties(ChannelBroadband, Cycles, SampleRate)
% Identifies various ways to characterize each peak. Based on Cole 2019,
% but relative to the negative peaks rather than positive peaks.
% NOTE: all fieldnames should start lowercase, so I know later on that they
% come from here.

% Part of Matcycle 2022, by Sophia Snipes.
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

    CurrCycle = retrieve_peak_voltages(CurrCycle, ChannelBroadband);
    CurrCycle = is_true_peak(CurrCycle);
    CurrCycle = count_extra_peaks(CurrCycle, ChannelBroadband);
    CurrCycle = measure_periods(PrevCycle, CurrCycle, NextCycle, SampleRate);
    CurrCycle = measure_amplitude(CurrCycle, ChannelBroadband);
    CurrCycle = measure_amplitude_ramp(CurrCycle, ChannelBroadband);
    CurrCycle = measure_flank_consistency(CurrCycle, ChannelBroadband);
    CurrCycle = measure_monotonicity_in_time(CurrCycle, ChannelBroadband);
    CurrCycle = measure_monotonicity_in_voltage(CurrCycle, ChannelBroadband);
    CurrCycle = measure_reversal_ratio(CurrCycle, ChannelBroadband);

    if idxCycle == 1
        AugmentedCyclesFirstPass = CurrCycle;
    else
        AugmentedCyclesFirstPass(idxCycle) = CurrCycle;
    end
end

%%%

% This is a separate for loop for determining properties that require
% the properties of the next cycle to already be calculated.
AugmentedCyclesSecondPass = struct();
for idxCycle = 2:numel(AugmentedCyclesFirstPass)-1
    CurrCycle = AugmentedCyclesFirstPass(idxCycle);
    PrevCycle = AugmentedCyclesFirstPass(idxCycle-1);
    NextCycle = AugmentedCyclesFirstPass(idxCycle+1);

    CurrCycle = measure_prominence(PrevCycle, CurrCycle, NextCycle, ChannelBroadband);
    CurrCycle = measure_period_consistency(PrevCycle, CurrCycle, NextCycle);
    CurrCycle = measure_amplitude_consistency(PrevCycle, CurrCycle, NextCycle);
    CurrCycle = measure_shape_consistency(PrevCycle, CurrCycle, NextCycle, ChannelBroadband);

    if idxCycle == 2
        AugmentedCyclesSecondPass = CurrCycle;
    else
        AugmentedCyclesSecondPass(idxCycle-1) = CurrCycle;
    end
end

% remove edge peaks that are empty
AugmentedCycles = AugmentedCyclesSecondPass;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Cycle = count_extra_peaks(Cycle, ChannelBroadband)
CycleSignal = ChannelBroadband(Cycle.PrevPosPeakIdx:Cycle.NextPosPeakIdx);
Cycle.PeaksCount = nnz(diff(sign(diff(CycleSignal))) > 1);
end

function Cycle = measure_amplitude(Cycle, ChannelBroadband)
Cycle.Amplitude = mean(ChannelBroadband([Cycle.PrevPosPeakIdx, Cycle.NextPosPeakIdx])) ...
    - ChannelBroadband(Cycle.NegPeakIdx);
end

function Cycle = retrieve_peak_voltages(Cycle, ChannelBroadband)
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

CurrCycle.Frequency = 1/CurrCycle.PeriodNeg;
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

FallingEdgeDiff = diff(ChannelBroadband(Cycle.PrevPosPeakIdx:Cycle.NegPeakIdx));
RisingEdgeDiff = diff(ChannelBroadband(Cycle.NegPeakIdx:Cycle.NextPosPeakIdx));

if numel(FallingEdgeDiff) < 2 || numel(RisingEdgeDiff) < 2
    Cycle.MonotonicityInTime = 0;
else
    Cycle.MonotonicityInTime = (nnz(FallingEdgeDiff < 0) + nnz(RisingEdgeDiff > 0)) / ...
        numel([FallingEdgeDiff, RisingEdgeDiff]);
end
end

function Cycle = measure_monotonicity_in_voltage(Cycle, ChannelBroadband)

FallingEdgeDiff = diff(ChannelBroadband(Cycle.PrevPosPeakIdx:Cycle.NegPeakIdx));
RisingEdgeDiff = diff(ChannelBroadband(Cycle.NegPeakIdx:Cycle.NextPosPeakIdx));

IncreaseDuringFallingEdge = sum(abs(FallingEdgeDiff(FallingEdgeDiff>0)));
DecreaseDuringRisingEdge = sum(abs(RisingEdgeDiff(RisingEdgeDiff<0)));

Monotonicity = (Cycle.Amplitude - (IncreaseDuringFallingEdge + DecreaseDuringRisingEdge))/Cycle.Amplitude;

Cycle.MonotonicityInAmplitude = max(0, Monotonicity);
end

function Cycle = measure_reversal_ratio(Cycle, ChannelBroadband)
% this the proportion of the longest segment either rising during the
% falling edge or falling during the rising edge, relative to its
% respective edge, such that 0 indicates a single sub-peak is as tall as
% the main cycle, and 1 indicates that the signal is completely monotonic

FallingEdgeAmplitude = diff(ChannelBroadband([Cycle.NegPeakIdx, Cycle.PrevPosPeakIdx]));
RisingEdgeAmplitude = diff(ChannelBroadband([Cycle.NegPeakIdx, Cycle.NextPosPeakIdx]));

% largest falling deflection during rising edge
RisingEdge = ChannelBroadband(Cycle.NegPeakIdx:Cycle.NextPosPeakIdx);
TurnPoints = [2 diff(sign(diff(RisingEdge))) -2];
Troughs = RisingEdge(TurnPoints > 1);
Peaks = RisingEdge(TurnPoints <-1);
RisingEdgeMaxReversal = max(Peaks(1:end-1)-Troughs(2:end));

% largest rising deflection during falling edge
FallingEdge = ChannelBroadband(Cycle.PrevPosPeakIdx:Cycle.NegPeakIdx);
TurnPoints = [-2 diff(sign(diff(FallingEdge))) 2];
Troughs = FallingEdge(TurnPoints > 1);
Peaks = FallingEdge(TurnPoints <-1);
FallingEdgeMaxReversal = max(Peaks(2:end)-Troughs(1:end-1));

Cycle.ReversalRatio = min([(RisingEdgeAmplitude-RisingEdgeMaxReversal)/RisingEdgeAmplitude ...
    (FallingEdgeAmplitude-FallingEdgeMaxReversal)/FallingEdgeAmplitude]);
if Cycle.ReversalRatio < 0
    Cycle.ReversalRatio = 0;
end
end




%%%%%%%%%%%%%%%%
%%% Functions for second for loop

function CurrCycle = measure_prominence(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)
% Returns a boolean, if the negative peak is prominent with respects to the
% two neighboring negative cycles.

MidpointFallingEdge = CurrCycle.VoltageNeg + (CurrCycle.VoltagePrevPos-CurrCycle.VoltageNeg)/2;
Cycle1Signal = ChannelBroadband(PrevCycle.NegPeakIdx:CurrCycle.NegPeakIdx);
[~, FallingEdgeCrossings] = detect_crossings(Cycle1Signal, MidpointFallingEdge);

MidpointRisingEdge = CurrCycle.VoltageNeg + (CurrCycle.VoltageNextPos-CurrCycle.VoltageNeg)/2;
Cycle2Signal = ChannelBroadband(CurrCycle.NegPeakIdx:NextCycle.NegPeakIdx);
[RisingEdgeCrossings, ~] = detect_crossings(Cycle2Signal, MidpointRisingEdge);

CurrCycle.isProminent = numel(FallingEdgeCrossings) <= 1 & numel(RisingEdgeCrossings) <= 1;
end

function CurrCycle = measure_period_consistency(PrevCycle, CurrCycle, NextCycle)
PrevPeriod = CurrCycle.NegPeakIdx-PrevCycle.NegPeakIdx;
NextPeriod = NextCycle.NegPeakIdx-CurrCycle.NegPeakIdx;
CurrCycle.PeriodConsistency = min([PrevPeriod/NextPeriod, NextPeriod/PrevPeriod]);
end


function CurrCycle = measure_amplitude_consistency(PrevCycle, CurrCycle, NextCycle)
% gets ratio of current cycle's amplitude relative to the neighbors, taking
% smallest

Amp1 = PrevCycle.Amplitude;
Amp2 = CurrCycle.Amplitude;
Amp3 = NextCycle.Amplitude;

CurrCycle.AmplitudeConsistency = min([Amp1/Amp2, Amp2/Amp1, Amp2/Amp3, Amp3/Amp2]);
end


function CurrCycle = measure_shape_consistency(PrevCycle, CurrCycle, NextCycle, ChannelBroadband)
% matches cycles by negative peak, and sees how much their voltages differ.

[PrevCycleShape, PrevNegIndex] = cycle_shape(ChannelBroadband, PrevCycle);
[CurrCycleShape, CurrNegIndex] = cycle_shape(ChannelBroadband, CurrCycle);
[NextCycleShape, NextNegIndex] = cycle_shape(ChannelBroadband, NextCycle);

DifferencePrev = compare_shape(CurrCycleShape, PrevCycleShape, CurrNegIndex, PrevNegIndex);
DifferenceNext = compare_shape(CurrCycleShape, NextCycleShape, CurrNegIndex, NextNegIndex);

CurrCycle.ShapeConsistency = (DifferenceNext+DifferencePrev)/2;

end

function [CycleShape, NegIndex] = cycle_shape(ChannelBroadband, Cycle)
% gets each cycle from the data, normalizing the amplitude

PrevPoint = Cycle.PrevPosPeakIdx;
NextPoint = Cycle.NextPosPeakIdx;
NegPoint = Cycle.NegPeakIdx;

CycleShape = -ChannelBroadband(PrevPoint:NextPoint); % flip so dealing with positive numbers

Min = min(CycleShape);
Max = max(CycleShape);
CycleShape = (CycleShape-Min)./(Max-Min);

NegIndex = NegPoint-PrevPoint; % needed to align to peak
end


function Difference = compare_shape(CurrCycleShape, NeighborCycleShape, ...
    CurrNegIndex, NeighborNegIndex)

% cut to same size
LeftEdge = min(CurrNegIndex, NeighborNegIndex);
RightEdge = min(numel(CurrCycleShape)-CurrNegIndex, numel(NeighborCycleShape)-NeighborNegIndex);
CurrCycleShape = CurrCycleShape(CurrNegIndex-LeftEdge+1:CurrNegIndex+RightEdge);
NeighborCycleShape = NeighborCycleShape(NeighborNegIndex-LeftEdge+1:NeighborNegIndex+RightEdge);

Difference = (sum(CurrCycleShape)-sum(abs(NeighborCycleShape-CurrCycleShape)))/sum(CurrCycleShape);

if Difference<0
    Difference = 0;
end
end



