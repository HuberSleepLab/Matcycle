function AugmentedCycles = measure_cycle_properties(ChannelBroadband, CycleTable, SampleRate)
% Identifies various ways to characterize each peak. Based on Cole 2019,
% but relative to the negative peaks rather than positive peaks.
% NOTE: all fieldnames should start lowercase, so I know later on that they
% come from here.
%
% Part of Matcycle 2022, by Sophia Snipes.

% data for measure_reversal_ratio; finds the amplitude of all the segments
% in the signal where there's a change in direction, to determine how much
% the largest segment goes in the "wrong" direction compared to the
% expected increase or decrease in voltage for the rising and falling edges
% of the cycle, respectively.
[LocalMinima, LocalMaxima] = find_all_peaks(ChannelBroadband);
[DeflectionsAmplitude, PrevPosPeakIndexes, NegPeakIndexes, NextPosPeakIndexes] = measure_deflection_amplitudes( ...
    ChannelBroadband, CycleTable, LocalMinima, LocalMaxima);


% Get all properties that can easily be conducted on vectors, by converting
% the struct into a table and back
CycleTable = retrieve_peak_voltages(CycleTable, ChannelBroadband);
CycleTable = measure_amplitudes(CycleTable, ChannelBroadband);
CycleTable = measure_flanks(CycleTable, ChannelBroadband);
CycleTable = measure_periods(CycleTable, numel(ChannelBroadband), SampleRate);
CycleTable = measure_amplitude_ramp(CycleTable);
CycleTable = count_extra_peaks(CycleTable, DeflectionsAmplitude, PrevPosPeakIndexes, NextPosPeakIndexes);
CycleTable = measure_monotonicity_in_time(CycleTable, ChannelBroadband);
Cycles = table2struct(CycleTable);


for idxCycle = 1:numel(Cycles)

    CurrCycle = Cycles(idxCycle);
    CurrCycle = measure_monotonicity_in_amplitude(CurrCycle, DeflectionsAmplitude, ...
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

function CycleTable = retrieve_peak_voltages(CycleTable, ChannelBroadband)
CycleTable.VoltagePrevPos = ChannelBroadband(CycleTable.PrevPosPeakIdx)';
CycleTable.VoltageNeg = ChannelBroadband(CycleTable.NegPeakIdx)';
CycleTable.VoltageNextPos = ChannelBroadband(CycleTable.NextPosPeakIdx)';
end


function CycleTable = measure_amplitudes(CycleTable, ChannelBroadband)
PositiveVoltages = (ChannelBroadband(CycleTable.PrevPosPeakIdx) + ChannelBroadband(CycleTable.NextPosPeakIdx))/2;
NegativeVoltages = ChannelBroadband(CycleTable.NegPeakIdx);
Amplitudes = PositiveVoltages-NegativeVoltages;
CycleTable.Amplitude = Amplitudes';
end


function CycleTable = measure_flanks(CycleTable, ChannelBroadband)
CycleTable.FallingFlankAmplitude = ChannelBroadband(CycleTable.PrevPosPeakIdx)' - ChannelBroadband(CycleTable.NegPeakIdx)';
CycleTable.RisingFlankAmplitude = ChannelBroadband(CycleTable.NextPosPeakIdx)' - ChannelBroadband(CycleTable.NegPeakIdx)';

CycleTable.FlankConsistency = min([CycleTable.FallingFlankAmplitude./CycleTable.RisingFlankAmplitude, ...
    CycleTable.RisingFlankAmplitude./CycleTable.FallingFlankAmplitude], [], 2);
end


function CycleTable = measure_periods(CycleTable, TimepointsCount, SampleRate)
CycleTable.PeriodPos = (CycleTable.NextPosPeakIdx - CycleTable.PrevPosPeakIdx)/SampleRate;

NextPeak = [CycleTable.NegPeakIdx(2:end); TimepointsCount];
PrevPeak = [1; CycleTable.NegPeakIdx(1:end-1)];
CycleTable.PeriodNeg = (NextPeak-PrevPeak)/2/SampleRate;
end


function CycleTable = measure_amplitude_ramp(CycleTable)
CycleTable.AmplitudeRamp = zeros(size(CycleTable, 1), 1);
CycleTable.AmplitudeRamp(CycleTable.VoltagePrevPos < CycleTable.VoltageNextPos) = 1;
CycleTable.AmplitudeRamp(CycleTable.VoltagePrevPos > CycleTable.VoltageNextPos) = -1;
end



function [LocalMinima, LocalMaxima] = find_all_peaks(ChannelBroadband)
DiffChannel = diff(ChannelBroadband);
LocalMinima = [false, DiffChannel(1:end-1) > 0 & DiffChannel(2:end) <= 0];
LocalMaxima = [false, DiffChannel(1:end-1) < 0 & DiffChannel(2:end) >= 0];
end


function [DeflectionsAmplitude, PrevPosPeakIndexes, NegPeakIndexes, NextPosPeakIndexes] = ...
    measure_deflection_amplitudes(ChannelBroadband, CycleTable, LocalMinima, LocalMaxima)
% measure the change in amplitude between each peak and trough in the
% signal.

Deflections = LocalMinima | LocalMaxima;
Deflections([1 end]) = 1; % include edges
Deflections(CycleTable.NegPeakIdx) = 1; % include cycle edges, for when they are not actually peaks, but cut the cycle en route
Deflections(CycleTable.PrevPosPeakIdx) = 1;
Deflections(CycleTable.NextPosPeakIdx) = 1; % redundantish from previous, but better safe
DeflectionsAmplitude = diff(ChannelBroadband(Deflections));

PrevPosPeakIndexes = map_cycle_to_reversal_indexes(Deflections, CycleTable.PrevPosPeakIdx);
NegPeakIndexes = map_cycle_to_reversal_indexes(Deflections, CycleTable.NegPeakIdx);
NextPosPeakIndexes = map_cycle_to_reversal_indexes(Deflections, CycleTable.NextPosPeakIdx);
end

function ReversalIndexes = map_cycle_to_reversal_indexes(Deflections, CycleIndexes)
Indexes = zeros(size(Deflections));
Indexes(CycleIndexes) = 1;
Indexes = Indexes(Deflections);
ReversalIndexes = find(Indexes == 1)-1; % shift by one since first delfection index is removed later
end


function CycleTable = count_extra_peaks(CycleTable, DeflectionsAmplitude, PrevPosPeakIdx, NextPosPeakIdx)
PeaksCount = zeros(size(CycleTable, 1), 1);
for idxCycle = 1:numel(PrevPosPeakIdx)
    Deflections = DeflectionsAmplitude(PrevPosPeakIdx(idxCycle):NextPosPeakIdx(idxCycle));
    PeaksCount(idxCycle) = nnz(Deflections>0);
end
end



function CycleTable = measure_monotonicity_in_time(CycleTable, ChannelBroadband)

CycleCount = size(CycleTable, 1);
MonotonicityInTime = zeros(CycleCount, 1);

Starts = CycleTable.PrevPosPeakIdx;
NegPoints = CycleTable.NegPeakIdx;
Ends =  CycleTable.NextPosPeakIdx;

% get the differential of the signal, to see which segments increase and
% decrease
ChannelDiff = diff(ChannelBroadband);

for idxCycle = 1:CycleCount

    Neg = NegPoints(idxCycle); % since its used twice, I just make it a variable
    FallingEdgeDiff = ChannelDiff(Starts(idxCycle):Neg-1);
    RisingEdgeDiff = ChannelDiff(Neg:Ends(idxCycle)-1);

    if ~(numel(FallingEdgeDiff) < 3 || numel(RisingEdgeDiff) < 3) % if there are enough points
        MonotonicityInTime(idxCycle) = (nnz(FallingEdgeDiff < 0) + nnz(RisingEdgeDiff > 0)) / ...
            numel([FallingEdgeDiff, RisingEdgeDiff]);
    end
end

CycleTable.MonotonicityInTime = MonotonicityInTime;
end

%%%%%%%%%%%%%%%%%%%
%%% single cycle functions


function Cycle = measure_monotonicity_in_amplitude(Cycle, DeflectionsAmplitude, PrevPosPeakIdx, NegPeakIdx, NextPosPeakIdx)
% find the amplitudes of the segments that go in the "wrong" direction
% relative to the cycle (e.g. rising in the falling edge). ReversalRatio is
% the ratio of the largest reversal to the change in amplitude, and
% MonotonicityInAmplitude is the sum of all reversals relative to the
% signal amplitude.

% falling edge reversals
FallingDeflections = DeflectionsAmplitude(PrevPosPeakIdx+1:NegPeakIdx); % don't include the PrevPosPeakIdx
RisingReversals = FallingDeflections(FallingDeflections>0);

MaxRisingReversal = max(RisingReversals);
FallingEdge = abs(Cycle.VoltagePrevPos-Cycle.VoltageNeg);
FallingEdgeReversalRatio = (FallingEdge-abs(MaxRisingReversal))/FallingEdge;

% rising edge reversals
RisingDeflections = DeflectionsAmplitude(NegPeakIdx+1:NextPosPeakIdx);
FallingReversals = RisingDeflections(RisingDeflections<0);

MaxFallingReversal = min(FallingReversals);
RisingEdge = abs(Cycle.VoltageNextPos-Cycle.VoltageNeg);
RisingEdgeReversalRatio = (RisingEdge-abs(MaxFallingReversal))/RisingEdge;

Cycle.ReversalRatio = min([FallingEdgeReversalRatio, RisingEdgeReversalRatio]);

if Cycle.ReversalRatio < 0
    Cycle.ReversalRatio = 0;
elseif isempty(Cycle.ReversalRatio)
    Cycle.ReversalRatio = 1;
end

% monotonicity
IncreaseDuringFallingEdge = sum(RisingReversals);
DecreaseDuringRisingEdge = sum(abs(FallingReversals));
Cycle.MonotonicityInAmplitude = (Cycle.Amplitude - (IncreaseDuringFallingEdge + DecreaseDuringRisingEdge))/Cycle.Amplitude;

if Cycle.MonotonicityInAmplitude < 0
    Cycle.MonotonicityInAmplitude = 0;
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



