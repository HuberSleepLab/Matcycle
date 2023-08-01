function [Bursts, Diagnostics] = aggregate_cycles_into_bursts(Cycles, CriteriaSet, KeepTimepoints)
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

% gather peaks based on single peak property requirements
[CyclesMeetCriteria, Diagnostics] = detect_cycles_that_meet_criteria( ...
    Cycles, CriteriaSet, KeepTimepoints);

% check when all criterias are met
AcceptedCycles = all(CyclesMeetCriteria);

% special cases
AcceptedCycles = extend_burst_by_amplitude_consistency(Cycles, CriteriaSet,...
    CyclesMeetCriteria, AcceptedCycles);

AcceptedCycles = extend_burst_by_period_consistency(Cycles, CriteriaSet, ...
    CyclesMeetCriteria, AcceptedCycles);



%%%%%%%%%%%%%%%%%%%%%%
%%% Gather burst info

% identify edges of the bursts
[Starts, Ends] = find_streaks(AcceptedCycles, CriteriaSet.MinCyclesPerBurst);

if isempty(Starts) || isempty(Ends)
    Bursts = struct();
    return
end

Bursts = convert_bursts_to_struct(Cycles, Starts, Ends);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% functions

function CriteriaLabels = get_criteria_labels(Cycles, CriteriaSet)
CycleFields = fieldnames(Cycles);

CriteriaLabels = fieldnames(CriteriaSet);
CriteriaLabels(~ismember(CriteriaLabels, CycleFields)) = []; % in case there's extra junk in there

% remove from criteria those that don't correspond to specific properties
% of cycles
CriteriaLabels(strcmp(CriteriaLabels, 'MinCyclesPerBurst')) = [];
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


function [CyclesMeetCriteria, Diagnostics] = detect_cycles_that_meet_criteria( ...
    Cycles, CriteriaSet, KeepTimepoints)
% Creates a matrix (# criteria x # cycles) of booleans, indicating whether
% each cycle meets each criteria. Cycles and Criterias are structs, sich
% that all the fieldnames of Criterias should be present in Cycles.
% KeepTimepoints is a vector of booleans the length of your original
% signal.

CriteriaLabels = get_criteria_labels(Cycles, CriteriaSet);

% TODO: explain what this is
Diagnostics = struct();

% computes booleans of whether each cycle meets each criteria
CyclesMeetCriteria = true(numel(CriteriaLabels), numel(Cycles));

for idxCriteria = 1:numel(CriteriaLabels)

    Criteria = CriteriaLabels{idxCriteria};
    Threshold = CriteriaSet.(Criteria);
    CycleProperty = [Cycles.(Criteria)];

    if numel(Threshold) == 1 % a scalar is provided
        isMet = CycleProperty >= Threshold;
    elseif numel(Threshold) == 2 % a range is provided
        isMet = CycleProperty >= Threshold(1) & CycleProperty <= Threshold(2);
    else
        error('incorrect number of criteria inputs')
    end

    CyclesMeetCriteria(idxCriteria, :) = isMet;
    Diagnostics.(Criteria) = nnz(~isMet);
end

% ignore cycles with a peak that is not included in KeepTimepoints
if ~isempty(KeepTimepoints)
    KeepTimepoints = find(KeepTimepoints);
    Peak_Points = [Cycles.NegPeakIdx];
    isMet = ismember(Peak_Points, KeepTimepoints);
    CyclesMeetCriteria = cat(1, CyclesMeetCriteria, isMet);
    Diagnostics.Noise = nnz(~isMet);
end

% identify number of peaks uniquely removed by a single factor for later
for idxCriteria = 1:numel(CriteriaLabels)
    Criteria = CriteriaLabels{idxCriteria};
    ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, idxCriteria);
    Diagnostics.([Criteria, 'u']) = nnz(ExcludedCycles);
end
end


function ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, IdxCriteria)
% identifies all cycles that were excluded only because of this criteria
I = 1:size(CyclesMeetCriteria, 1);
I(IdxCriteria) = [];
Remaining = all(CyclesMeetCriteria(I, :));
ExcludedCycles = Remaining & ~CyclesMeetCriteria(IdxCriteria, :);
end


function AcceptedCycles = extend_burst_by_amplitude_consistency(Cycles, CriteriaSet, ...
    CyclesMeetCriteria, AcceptedCycles)
% if the edge of a burst would be excluded just because of amplitude 
% consistency, include it instead.

if isfield(CriteriaSet, 'AmplitudeConsistency')
    CriteriaLabels = get_criteria_labels(Cycles, CriteriaSet);

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
      CriteriaLabels = get_criteria_labels(Cycles, CriteriaSet);

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
    for Label = CyclePropertyLabels
        AllCyclesProperties = [Cycles(CycleIndexes).(Label)];

        % handle differently depending on whether its a string or numbers,
        % and if it's the same for all elements in the burst or not
        UniqueProperties = unique(AllCyclesProperties);
        if isnumeric(AllCyclesProperties) && numel(UniqueProperties) > 1
            Bursts(idxBurst).(Label) = AllCyclesProperties;
        elseif isnumeric(AllCyclesProperties) && numel(UniqueProperties) == 1
            Bursts(idxBurst).(Label) = AllCyclesProperties(1);
        else
            AllCyclesProperties = {Cycles(CycleIndexes).(Label)};
            if numel(unique(AllCyclesProperties))==1
                Bursts(idxBurst).(Label) = AllCyclesProperties(1);
            else
                Bursts(idxBurst).(Label) = AllCyclesProperties;
            end
        end
    end

    %%% get properties of the burst itself

    % start, end, duration
    Bursts(idxBurst).Start = Cycles(CycleIndexes(1)-1).PosPeakIdx;
    Bursts(idxBurst).End =  Bursts(idxBurst).PosPeakIdx(end);
end
end
