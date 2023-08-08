function [Bursts, Diagnostics] = aggregate_cycles_into_bursts(Cycles, CriteriaSet, KeepTimepoints)
arguments
    Cycles
    CriteriaSet
    KeepTimepoints = []
end
% goes through all peaks found, puts them into structs according to
% whether they make up a burst, or if they are on their own.
% Peak_Thresholds is a struct, with fields already present in Peaks, and is
% a simple number that the peak's value has to be higher than. If two
% numbers are provided (like for period), then it will keep peaks within
% the smaller and larger number.
% MinCyclesPerBurst is the minimum number peaks in a burst.
% Bad_Time is an array indicating when there is noise or similar, and so
% not to count the peaks.
% Only consider peaks with a period between certain amounts (e.g. 1./[3 12])
% Burst criteria:
% - at least 3 consecutive peaks
% - monotonic > .9
% - period consistency > .7
% maybe TODO: global burst consistency also over a certain number
% Waves are all the other events
% Inputs: Peaks struct, P_Thresholds is a range of periods to accept,
% M_Threshold is for monotonicity (between 0 and 1), PC_Threshold is for
% period consistency (between 0 and 1), and C_Threshold is number of cycles
% in a row to consider a burst.

% Part of Matcycle 2022, by Sophia Snipes.


%%% Gather all peaks that meet all the threshold requirements

% remove thresholds that are empty
CriteriaSet = remove_empty_fields_from_struct(CriteriaSet);

% gather peaks based on single peak property requirements
[CyclesMeetCriteria, Diagnostics] = cycy.detect_cycles_that_meet_criteria( ...
    Cycles, CriteriaSet, KeepTimepoints);

% check when all criterias are met
AcceptedCycles = all(CyclesMeetCriteria);

% special cases
AcceptedCycles = extend_burst_by_amplitude_consistency(Cycles, CriteriaSet,...
    CyclesMeetCriteria, AcceptedCycles);

AcceptedCycles = extend_burst_by_period_consistency(Cycles, CriteriaSet, ...
    CyclesMeetCriteria, AcceptedCycles);


%%% Gather burst info

% identify edges of the bursts
[Starts, Ends] = find_streaks(AcceptedCycles, CriteriaSet.MinCyclesPerBurst);

if isempty(Starts) || isempty(Ends)
    Bursts = [];
    return
end

Bursts = convert_bursts_to_struct(Cycles, Starts, Ends);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function Struct = remove_empty_fields_from_struct(Struct)
% removes empty fields

Fieldnames  = fieldnames(Struct);

for Indx_F = 1:numel(Fieldnames)
    if isempty(Struct.(Fieldnames{Indx_F}))
        Struct = rmfield(Struct, Fieldnames{Indx_F});
    end
end
end

function [Starts, Ends] = find_streaks(BoolArray, MinSamples)
% identify starts and ends that make up streaks
% BinArray is ones and zeros, and tries to find streaks of ones

Starts = find(diff(BoolArray) == 1);
Ends = find(diff(BoolArray) == -1);

if isempty(Starts) || isempty(Ends)
    return
end

% handle edgecase of starting mid-burst
if Ends(1) < Starts(1)
    Ends(1) = [];
end

if Ends(end) < Starts(end)
    Starts(end) = [];
end

% select streaks that have the minimum number of cycles
Streaks = Ends-Starts;
remove = Streaks < MinSamples;

Starts(remove) = [];
Ends(remove) = [];

Starts = Starts+1; % adjust indexing
end


function AcceptedCycles = extend_burst_by_amplitude_consistency(Cycles, CriteriaSet, ...
    CyclesMeetCriteria, AcceptedCycles)
% if the edge of a burst would be excluded just because of amplitude
% consistency, include it instead.

if isfield(CriteriaSet, 'AmplitudeConsistency')
    CriteriaLabels = cycy.utils.get_criteria_labels(Cycles, CriteriaSet);

    idxCriteria = find(strcmp(CriteriaLabels, 'AmplitudeConsistency'));
    ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, idxCriteria);

    Ramp = [Cycles.AmplitudeRamp]; % whether amplitude of burst is increasing or decreasing
    [Starts, Ends]  = find_streaks(AcceptedCycles, CriteriaSet.MinCyclesPerBurst);

    for S = Starts(:)' % just make sure it's a row vector
        Edge = S-1;

        % if the peak just prior to the start is only excluded for amplitude
        % consistency, and it's because the amplitude is increasing, keep
        while Edge>0 && ExcludedCycles(Edge) && Ramp(Edge)>= 0
            AcceptedCycles(Edge) = 1;
            Edge = Edge-1;
        end
    end

    for E = Ends(:)'
        Edge = E+1;
        while ExcludedCycles(Edge) && Ramp(Edge)<=0 && Edge <= numel(ExcludedCycles)
            AcceptedCycles(Edge) = 1;
            Edge = Edge+1;
        end
    end
end
end


function AcceptedCycles = extend_burst_by_period_consistency(Cycles, CriteriaSet, ...
    CyclesMeetCriteria, AcceptedCycles)
% if the edge of a burst would be excluded just because of period
% consistency, include it instead.

if isfield(CriteriaSet, 'PeriodConsistency')
    CriteriaLabels = cycy.utils.get_criteria_labels(Cycles, CriteriaSet);

    idxCriteria = find(strcmp(CriteriaLabels, 'PeriodConsistency'));
    ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, idxCriteria);

    % Get all the peaks adjacent to a burst that are excluded only for the period
    [Starts, Ends]  = find_streaks(AcceptedCycles, CriteriaSet.MinCyclesPerBurst);
    NewEdges = intersect(find(ExcludedCycles), [Starts-1, Ends+1]);
    AcceptedCycles(NewEdges) = 1;
end
end


function Bursts = convert_bursts_to_struct(Cycles, Starts, Ends)

CyclePropertyLabels = fieldnames(Cycles);

Bursts = struct();
for idxBurst = 1:numel(Starts)
    CycleIndexes = Starts(idxBurst):Ends(idxBurst);
    Bursts(idxBurst).CyclesCount = numel(CycleIndexes);
    Bursts(idxBurst).CycleIndexes = CycleIndexes;

    %%% transfer all info about the individual peaks
    for Label = CyclePropertyLabels'
        AllCyclesProperties = [Cycles(CycleIndexes).(Label{1})];


        % handle differently depending on whether its a string or numbers,
        % and if it's the same for all elements in the burst or not
        UniqueProperties = unique(AllCyclesProperties);
        if isnumeric(AllCyclesProperties) && numel(UniqueProperties) > 1
            Bursts(idxBurst).(Label{1}) = AllCyclesProperties;
        elseif isnumeric(AllCyclesProperties) && numel(UniqueProperties) == 1
            Bursts(idxBurst).(Label{1}) = AllCyclesProperties(1);
        else
            AllCyclesProperties = [Cycles(CycleIndexes).(Label{1})];
            Bursts(idxBurst).(Label{1}) = AllCyclesProperties;
        end
    end

    %%% get properties of the burst itself
    Bursts(idxBurst).Start = Cycles(CycleIndexes(1)-1).PrevPosPeakIdx;
    Bursts(idxBurst).End =  Bursts(idxBurst).NextPosPeakIdx(end);
    Bursts(idxBurst).BurstFrequency = 1/mean(Bursts(idxBurst).PeriodNeg);
end
end
