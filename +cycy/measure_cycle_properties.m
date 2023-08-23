function CycleTable = measure_cycle_properties(ChannelBroadband, CycleTable, SampleRate)
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
% Everything that looks weird was done for speed!
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
CycleTable = measure_monotonicity_in_amplitude(CycleTable, DeflectionsAmplitude, ...
    PrevPosPeakIndexes, NegPeakIndexes, NextPosPeakIndexes);
CycleTable = measure_period_consistency(CycleTable, numel(ChannelBroadband));
CycleTable = measure_amplitude_consistency(CycleTable);
CycleTable = measure_shape_consistency(CycleTable, ChannelBroadband);
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

FlankConsistency = min([CycleTable.FallingFlankAmplitude./CycleTable.RisingFlankAmplitude, ...
    CycleTable.RisingFlankAmplitude./CycleTable.FallingFlankAmplitude], [], 2);

FlankConsistency(FlankConsistency<0) = 0;

CycleTable.FlankConsistency = FlankConsistency;
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
% gives the ratio of how much of the signal during the cycle goes in the
% "wrong" direction.

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


function CycleTable = measure_monotonicity_in_amplitude(CycleTable, DeflectionsAmplitude, PrevPosPeakIndexes, NegPeakIndexes, NextPosPeakIndexes)
% find the amplitudes of the segments that go in the "wrong" direction
% relative to the cycle (e.g. rising in the falling edge). ReversalRatio is
% the ratio of the largest reversal to the change in amplitude, and
% MonotonicityInAmplitude is the sum of all reversals relative to the
% signal amplitude.

CycleCount = size(CycleTable, 1);

MonotonicityInAmplitude = zeros(CycleCount, 1);
ReversalRatios = MonotonicityInAmplitude;

FallingEdges = CycleTable.FallingFlankAmplitude;
RisingEdges = CycleTable.RisingFlankAmplitude;
Amplitudes = CycleTable.Amplitude;

FallingDeflections = DeflectionsAmplitude;
FallingDeflections(DeflectionsAmplitude>0) = nan;
RisingDeflections = DeflectionsAmplitude;
RisingDeflections(DeflectionsAmplitude<0) = nan;

for idxCycle = 1:CycleCount

    % falling edge reversals
    RisingReversals = RisingDeflections(PrevPosPeakIndexes(idxCycle)+1:NegPeakIndexes(idxCycle));
    MaxRisingReversal = max(RisingReversals);
    FallingEdgeReversalRatio = (abs(FallingEdges(idxCycle))-abs(MaxRisingReversal))/abs(FallingEdges(idxCycle));

    % rising edge reversals
    FallingReversals = FallingDeflections(NegPeakIndexes(idxCycle)+1:NextPosPeakIndexes(idxCycle));
    MaxFallingReversal = min(FallingReversals);
    RisingEdgeReversalRatio = (abs(RisingEdges(idxCycle))-abs(MaxFallingReversal))/abs(RisingEdges(idxCycle));

    ReversalRatio = min([FallingEdgeReversalRatio, RisingEdgeReversalRatio]);

    if isnan(ReversalRatio) || isempty(ReversalRatio)
        ReversalRatios(idxCycle) = 1;
    elseif ReversalRatio < 0
        ReversalRatios(idxCycle) = 0;
    else
        ReversalRatios(idxCycle) = ReversalRatio;
    end

    % monotonicity
    IncreaseDuringFallingEdge = sum(RisingReversals, 'omitnan');
    DecreaseDuringRisingEdge = sum(abs(FallingReversals), 'omitnan');
    MonotonicityInAmplitude(idxCycle) = (abs(Amplitudes(idxCycle)) - (IncreaseDuringFallingEdge + DecreaseDuringRisingEdge))/abs(Amplitudes(idxCycle));

    if MonotonicityInAmplitude(idxCycle) < 0
        MonotonicityInAmplitude(idxCycle) = 0;
    end
end

CycleTable.MonotonicityInAmplitude = MonotonicityInAmplitude;
CycleTable.ReversalRatio = ReversalRatios;
end


function CycleTable = measure_period_consistency(CycleTable, TimepointsCount)

NextPeak = [CycleTable.NegPeakIdx(2:end); TimepointsCount];
CurrPeak = CycleTable.NegPeakIdx;
PrevPeak = [1; CycleTable.NegPeakIdx(1:end-1)];

PrevPeriod = CurrPeak-PrevPeak;
NextPeriod = NextPeak-CurrPeak;

CycleTable.PeriodConsistency = min([PrevPeriod./NextPeriod, NextPeriod./PrevPeriod], [], 2);

end


function CycleTable = measure_amplitude_consistency(CycleTable)
% gets ratio of current cycle's amplitude relative to the neighbors, taking
% smallest
Amp1 = [CycleTable.Amplitude(2:end); 0];
Amp2 = CycleTable.Amplitude;
Amp3 = [0; CycleTable.Amplitude(1:end-1)];
AmplitudeConsistency = min([Amp1./Amp2, Amp2./Amp1, Amp2./Amp3, Amp3./Amp2], [], 2);
AmplitudeConsistency(AmplitudeConsistency<0) = 0;
CycleTable.AmplitudeConsistency = AmplitudeConsistency;
end


function CycleTable = measure_shape_consistency(CycleTable, ChannelBroadband)
% matches cycles by negative peak, and sees how much their voltages differ.

CycleCount = size(CycleTable, 1);
DifferencePrev = zeros(CycleCount, 1);
DifferenceNext = DifferencePrev;

StartCycles = CycleTable.PrevPosPeakIdx;
PeakCycles = CycleTable.NegPeakIdx;
EndCycles = CycleTable.NextPosPeakIdx;

ChannelBroadband = -ChannelBroadband; % flip so that later when looking at area under the curve, its positive.

for idxCycle = 2:CycleCount-1

    % identify current cycle
    [CurrCycleShape, StartDistance, EndDistance] = cycle_shape(ChannelBroadband, ...
        StartCycles(idxCycle), PeakCycles(idxCycle), EndCycles(idxCycle));

    % identify neighboring cycles, with same dimentions as current cycle
    PrevCycleShape = cycle_shape(ChannelBroadband, ...
        PeakCycles(idxCycle-1)-StartDistance, PeakCycles(idxCycle-1), PeakCycles(idxCycle-1)+EndDistance);
    NextCycleShape = cycle_shape(ChannelBroadband, ...
        PeakCycles(idxCycle+1)-StartDistance, PeakCycles(idxCycle+1), PeakCycles(idxCycle+1)+EndDistance);

    DifferencePrev(idxCycle) = compare_shape(CurrCycleShape, PrevCycleShape);
    DifferenceNext(idxCycle) = compare_shape(CurrCycleShape, NextCycleShape);

end

CycleTable.ShapeConsistency = min([DifferenceNext, DifferencePrev], [], 2);
end


function [CycleShape, StartDistance, EndDistance] = cycle_shape(ChannelBroadband, StartCycle, PeakCycle, EndCycle)
% gets each cycle from the data, normalizing the amplitude

CycleShape = ChannelBroadband(StartCycle:EndCycle);

% normalize between 0 and 1
Min = min(CycleShape);
Max = max(CycleShape);
CycleShape = (CycleShape-Min)./(Max-Min);

StartDistance = PeakCycle-StartCycle; % needed to align start to peak
EndDistance = EndCycle-PeakCycle;
end


function Difference = compare_shape(CurrCycleShape, NeighborCycleShape)
Difference = (sum(CurrCycleShape)-sum(abs(NeighborCycleShape-CurrCycleShape)))/sum(CurrCycleShape);
if Difference < 0
    Difference = 0;
end
end






