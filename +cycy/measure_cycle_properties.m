function AugmentedCycles = measure_cycle_properties(ChannelBroadband, Cycles, SampleRate)
% Identifies various ways to characterize each peak. Based on Cole 2019,
% but relative to the negative peaks rather than positive peaks.
% NOTE: all fieldnames should start lowercase, so I know later on that they
% come from here.
%
% Part of Matcycle 2022, by Sophia Snipes.

% Get all cycle amplitudes
Cycles = measure_amplitudes(Cycles, ChannelBroadband);

% data for measure_reversal_ratio; finds the amplitude of all the segments
% in the signal where there's a change in direction, to determine how much
% the largest segment goes in the "wrong" direction compared to the
% expected increase or decrease in voltage for the rising and falling edges
% of the cycle, respectively.
[LocalMinima, LocalMaxima] = find_all_peaks(ChannelBroadband);
[DeflectionsAmplitude, PrevPosPeakIndexes, NegPeakIndexes, NextPosPeakIndexes] = measure_deflection_amplitudes( ...
    ChannelBroadband, Cycles, LocalMinima, LocalMaxima);

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
    CurrCycle = measure_reversal_ratio(CurrCycle, DeflectionsAmplitude, ...
        PrevPosPeakIndexes(idxCycle), NegPeakIndexes(idxCycle), NextPosPeakIndexes(idxCycle));

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

%%%%%%%%%%%%%%%%%%%%
%%% array-level functions

function Cycles = measure_amplitudes(Cycles, ChannelBroadband)

PositiveVoltages = (ChannelBroadband([Cycles.PrevPosPeakIdx]) + ChannelBroadband([Cycles.NextPosPeakIdx]))/2;
NegativeVoltages = ChannelBroadband([Cycles.NegPeakIdx]);
Amplitudes = PositiveVoltages-NegativeVoltages;

% Use arrayfun to apply the operation and update the struct
Cycles = arrayfun(@(Cycles, Amplitudes) setfield(Cycles, 'Amplitude2', Amplitudes), Cycles, Amplitudes);
% Table = struct2table(Cycles);
% Table.Amplitudes = Amplitudes';
% Cycles = table2struct(Table);

end


function [LocalMinima, LocalMaxima] = find_all_peaks(ChannelBroadband)

DiffChannel = diff(ChannelBroadband);
LocalMinima = [false, DiffChannel(1:end-1) > 0 & DiffChannel(2:end) <= 0];
LocalMaxima = [false, DiffChannel(1:end-1) < 0 & DiffChannel(2:end) >= 0];
end

function [DeflectionsAmplitude, PrevPosPeakIndexes, NegPeakIndexes, NextPosPeakIndexes] = ...
    measure_deflection_amplitudes(ChannelBroadband, Cycles, LocalMinima, LocalMaxima)
% measure the change in amplitude between each peak and trough in the
% signal.

Deflections = LocalMinima | LocalMaxima;
Deflections([1 end]) = 1; % include edges
Deflections([Cycles.NegPeakIdx]) = 1; % include cycle edges, for when they are not actually peaks, but cut the cycle en route
Deflections([Cycles.PrevPosPeakIdx]) = 1;
Deflections([Cycles.NextPosPeakIdx]) = 1; % redundantish from previous, but better safe
DeflectionsAmplitude = diff(ChannelBroadband(Deflections));

PrevPosPeakIndexes = map_cycle_to_reversal_indexes(Deflections, [Cycles.PrevPosPeakIdx]);
NegPeakIndexes = map_cycle_to_reversal_indexes(Deflections, [Cycles.NegPeakIdx]);
NextPosPeakIndexes = map_cycle_to_reversal_indexes(Deflections, [Cycles.NextPosPeakIdx]);
end

function ReversalIndexes = map_cycle_to_reversal_indexes(Deflections, CycleIndexes)
Indexes = zeros(size(Deflections));
Indexes(CycleIndexes) = 1;
Indexes = Indexes(Deflections);
ReversalIndexes = find(Indexes == 1)-1; % shift by one since first delfection index is removed later
end

%%%%%%%%%%%%%%%%%%%
%%% single cycle functions

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

function Cycle = measure_reversal_ratio(Cycle, DeflectionsAmplitude, PrevPosPeakIdx, NegPeakIdx, NextPosPeakIdx)

% falling edge reversals
FallingDeflections = DeflectionsAmplitude(PrevPosPeakIdx+1:NegPeakIdx); % don't include the PrevPosPeakIdx
MaxRisingReversal = max(FallingDeflections);
if MaxRisingReversal < 0
    MaxRisingReversal = [];
end

FallingEdge = abs(Cycle.VoltagePrevPos-Cycle.VoltageNeg);
FallingEdgeReversalRatio = (FallingEdge-abs(MaxRisingReversal))/FallingEdge;


% rising edge reversals
RisingDeflections = DeflectionsAmplitude(NegPeakIdx+1:NextPosPeakIdx);
MaxFallingReversal = min(RisingDeflections);

if MaxFallingReversal > 0
    MaxFallingReversal = [];
end

RisingEdge = abs(Cycle.VoltageNextPos-Cycle.VoltageNeg);
RisingEdgeReversalRatio = (RisingEdge-abs(MaxFallingReversal))/RisingEdge;

Cycle.ReversalRatio = min([FallingEdgeReversalRatio, RisingEdgeReversalRatio]);

if Cycle.ReversalRatio < 0
    Cycle.ReversalRatio = 0;
elseif isempty(Cycle.ReversalRatio)
    Cycle.ReversalRatio = 1;
end
end


%%%%%%%%%%%%%%%%
%%% Functions for second for loop

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



