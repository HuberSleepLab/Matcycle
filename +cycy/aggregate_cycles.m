function [Bursts, BurstPeakIDs, Diagnostics] = aggregate_cycles(Cycles, CriteriaSet, KeepTimepoints)
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


%%%%%%%%%%%%%%%%%%%%%%
%%% Gather all peaks that meet all the threshold requirements


%%% gather peaks based on single peak property requirements

CycleFields = fieldnames(Cycles);

Criterias = fieldnames(CriteriaSet);
Criterias(~ismember(Criterias, CycleFields)) = []; % in case there's extra junk in there

% remove from criteria those that don't correspond to specific properties 
% of cycles
Criterias(strcmp(Criterias, 'MinCyclesPerBurst')) = [];

% TODO: explain what this is 
Diagnostics = struct();

% computes booleans of whether each cycle meets each criteria
CyclesMeetCriteria = true(numel(Criterias), numel(Cycles));
for idxCriteria = 1:numel(Criterias)
    Criteria = Criterias{idxCriteria};
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

% check when all criterias are met
AllCriteriaMet = all(CyclesMeetCriteria);


%%% special cases

% if the edge of a burst would be excluded just because of amplitude 
% consistency, include it instead.
if isfield(CriteriaSet, 'AmplitudeConsistency')
    Indx = find(strcmp(Criterias, 'AmplitudeConsistency'));
    Unique = is_only_exclusion_criteria(CyclesMeetCriteria, Indx);
    Ramp = [Cycles.ampRamp]; % whether amplitude of burst is increasing or decreasing
    [Starts, Ends]  = getStreaks(AllCriteriaMet, CriteriaSet.MinCyclesPerBurst);
    for S = Starts(:)' % just make sure it's a row vector
        Edge = S-1;

        % if the peak just prior to the start is only excluded for amplitude
        % consistency, and it's because the amplitude is increasing, keep
        while Unique(Edge) && Ramp(Edge)>= 0 && Edge>0
            AllCriteriaMet(Edge) = 1;
            Edge = Edge-1;
        end
    end

    for E = Ends(:)'
        Edge = E+1;
        while Unique(Edge) && Ramp(Edge)<=0 && Edge <= numel(Unique)
            AllCriteriaMet(Edge) = 1;
            Edge = Edge+1;
        end
    end
end

% if the edge of a burst would be excluded just because of period 
% consistency, include it instead.
if isfield(CriteriaSet, 'periodConsistency')

    Indx = find(strcmp(Criterias, 'periodConsistency'));
    Unique = is_only_exclusion_criteria(CyclesMeetCriteria, Indx);

    % Get all the peaks adjacent to a burst that are excluded only for the period
    [Starts, Ends]  = getStreaks(AllCriteriaMet, CriteriaSet.MinCyclesPerBurst);
    NewEdges = intersect(find(Unique), [Starts-1, Ends+1]);
    AllCriteriaMet(NewEdges) = 1;
end


% identify number of peaks uniquely removed by a single factor for later
for idxCriteria = 1:numel(Criterias)
    Criteria = Criterias{idxCriteria};
    Unique = is_only_exclusion_criteria(CyclesMeetCriteria, idxCriteria);
    Diagnostics.([Criteria, 'u']) = nnz(Unique);
end

%%% Get bursts that meet minimum cycle requirements
[Starts, Ends] = getStreaks(AllCriteriaMet, CriteriaSet.MinCyclesPerBurst);

if isempty(Starts) || isempty(Ends)
    Bursts = struct();
    BurstPeakIDs = [];
    return
end


%%%%%%%%%%%%%%%%%%%%%%
%%% Gather burst info

Bursts = struct();
for Indx_S = 1:numel(Starts)
    IDs = Starts(Indx_S):Ends(Indx_S);
    P = Cycles;
    Bursts(Indx_S).PeakIDs = IDs;
    Bursts(Indx_S).nPeaks = numel(IDs);

    %%% transfer all info about the individual peaks
    for Indx_F = 1:numel(CycleFields)
        Criteria = CycleFields{Indx_F};
        All = [P(IDs).(Criteria)];

        % handle differently depending on whether its a string or numbers,
        % and if it's the same for all elements in the burst or not
        AllTypes = unique(All);
        if isnumeric(All) && numel(AllTypes) > 1
            Bursts(Indx_S).(Criteria) = All;
        elseif isnumeric(All) && numel(AllTypes) == 1
            Bursts(Indx_S).(Criteria) = All(1);
        else
            All = {P(IDs).(Criteria)};
            if numel(unique(All))==1
                Bursts(Indx_S).(Criteria) = All(1);
            else
                Bursts(Indx_S).(Criteria) = All;
            end
        end
    end

    %%% get properties of the burst itself

    % start, end, duration
    Bursts(Indx_S).Start = Cycles(IDs(1)-1).PosPeakIdx;
    Bursts(Indx_S).End =  Bursts(Indx_S).PosPeakIdx(end);
end

BurstPeakIDs = [Bursts.PeakIDs];

end



function ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, IdxCriteria)
% identifies all cycles that were excluded only because of this criteria

I = 1:size(CyclesMeetCriteria, 1);
I(IdxCriteria) = [];
Remaining = all(CyclesMeetCriteria(I, :));
ExcludedCycles = Remaining & ~CyclesMeetCriteria(IdxCriteria, :);
end