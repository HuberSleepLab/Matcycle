function [Bursts, BurstPeakIDs, Diagnostics] = cycy_aggregate_cycles(Peaks, Peak_Thresholds, Min_Peaks, Keep_Points)
% goes through all peaks found, puts them into structures according to
% whether they make up a burst, or if they are on their own.
% Peak_Thresholds is a struct, with fields already present in Peaks, and is
% a simple number that the peak's value has to be higher than. If two
% numbers are provided (like for period), then it will keep peaks within
% the smaller and larger number.
% Min_Peaks is the minimum number peaks in a burst.
% Bad_Time is an array indicating when there is noise or similar, and so
% not to count the peaks.
% Only consider peaks with a period between certain amounts (e.g. 1./[3 12])
% Burst criteria:
% - at least 3 consecutive peaks
% - monotonic > .9
% - period consistency > .7
% maybe TODO: global burst consistency also over a certain number
% Waves are all the other events
% Inputs: Peaks structure, P_Thresholds is a range of periods to accept,
% M_Threshold is for monotonicity (between 0 and 1), PC_Threshold is for
% period consistency (between 0 and 1), and C_Threshold is number of cycles
% in a row to consider a burst.

% Part of Matcycle 2022, by Sophia Snipes.


%%%%%%%%%%%%%%%%%%%%%%
%%% Gather all peaks that meet all the threshold requirements


%%% gather peaks based on single peak property requirements

PeakFields = fieldnames(Peaks);

ThresholdFields = fieldnames(Peak_Thresholds);
ThresholdFields(~ismember(ThresholdFields, PeakFields)) = []; % in case there's extra junk in there


Diagnostics = struct();

Candidates = []; % candidates of peaks to keep
for Indx_C = 1:numel(ThresholdFields) % loop through all provided thresholds
    Field = ThresholdFields{Indx_C};
    T = Peak_Thresholds.(Field); % threshold
    PeakField =  [Peaks.(Field)]; % values of the peaks for that threshold

    if numel(T) == 1
        C =PeakField >= T;
    elseif numel(T) == 2 % if a range is provided
        T = sort(T); % make sure first number is the smallest
        C = PeakField >= T(1) & PeakField <= T(2);
    else
        error('incorrect threshold inputs')
    end

    Candidates = cat(1, Candidates, C);
    Diagnostics.(Field) = nnz(~C);

end


% also ignore peaks in 0 timepoints of Keep_Time
if ~isempty(Keep_Points)
    Keep_Points = find(Keep_Points);
    Peak_Points = [Peaks.NegPeakID];
    C = ismember(Peak_Points, Keep_Points);
    Candidates = cat(1, Candidates, C);
    Diagnostics.Noise = nnz(~C);
end


% merge all requirements
AllCandidates = all(Candidates);



%%% special cases

% identify edges of bursts that might be changing amplitude
if isfield(Peak_Thresholds, 'ampConsistency')
    Indx = find(strcmp(ThresholdFields, 'ampConsistency'));
    Unique = singleThreshold(Candidates, Indx);
    Ramp = [Peaks.ampRamp]; % whether amplitude of burst is increasing or decreasing
    [Starts, Ends]  = getStreaks(AllCandidates, Min_Peaks);
    for S = Starts(:)' % just make sure it's a row vector
        Edge = S-1;

        % if the peak just prior to the start is only excluded for amplitude
        % consistency, and it's because the amplitude is increasing, keep
        while Unique(Edge) && Ramp(Edge)>= 0 && Edge>0
            AllCandidates(Edge) = 1;
            Edge = Edge-1;
        end
    end

    for E = Ends(:)'
        Edge = E+1;
        while Unique(Edge) && Ramp(Edge)<=0 && Edge <= numel(Unique)
            AllCandidates(Edge) = 1;
            Edge = Edge+1;
        end
    end
end

% include peaks that are on the edge but incorrect period consistency
if isfield(Peak_Thresholds, 'periodConsistency')

    Indx = find(strcmp(ThresholdFields, 'periodConsistency'));
    Unique = singleThreshold(Candidates, Indx);

    % Get all the peaks adjacent to a burst that are excluded only for the period
    [Starts, Ends]  = getStreaks(AllCandidates, Min_Peaks);
    NewEdges = intersect(find(Unique), [Starts-1, Ends+1]);
    AllCandidates(NewEdges) = 1;
end


% identify number of peaks uniquely removed by a single factor for later
for Indx_C = 1:numel(ThresholdFields)
    Field = ThresholdFields{Indx_C};
    Unique = singleThreshold(Candidates, Indx_C);
    Diagnostics.([Field, 'u']) = nnz(Unique);
end

%%% Get bursts that meet minimum cycle requirements
[Starts, Ends] = getStreaks(AllCandidates, Min_Peaks);

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
    P = Peaks;
    Bursts(Indx_S).PeakIDs = IDs;
    Bursts(Indx_S).nPeaks = numel(IDs);

    %%% transfer all info about the individual peaks
    for Indx_F = 1:numel(PeakFields)
        Field = PeakFields{Indx_F};
        All = [P(IDs).(Field)];

        % handle differently depending on whether its a string or numbers,
        % and if it's the same for all elements in the burst or not
        AllTypes = unique(All);
        if isnumeric(All) && numel(AllTypes) > 1
            Bursts(Indx_S).(Field) = All;
        elseif isnumeric(All) && numel(AllTypes) == 1
            Bursts(Indx_S).(Field) = All(1);
        else
            All = {P(IDs).(Field)};
            if numel(unique(All))==1
                Bursts(Indx_S).(Field) = All(1);
            else
                Bursts(Indx_S).(Field) = All;
            end
        end
    end

    %%% get properties of the burst itself

    % start, end, duration
    Bursts(Indx_S).Start = Peaks(IDs(1)-1).PosPeakID;
    Bursts(Indx_S).End =  Bursts(Indx_S).PosPeakID(end);
end

BurstPeakIDs = [Bursts.PeakIDs];

end



function Unique = singleThreshold(Candidates, Indx)
% identifies all the peaks that were removed for a single threshold

I = 1:size(Candidates, 1);
I(Indx) = [];
Remaining = all(Candidates(I, :));
Unique = Remaining & ~Candidates(Indx, :);
end