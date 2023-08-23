function [CyclesMeetCriteria, Diagnostics] = detect_cycles_that_meet_criteria( ...
    CycleTable, CriteriaSet, KeepTimepoints)
% Creates a matrix (# criteria x # cycles) of booleans, indicating whether
% each cycle meets each criteria. Cycles and Criterias are structs, sich
% that all the fieldnames of Criterias should be present in Cycles.
% KeepTimepoints is a vector of booleans the length of your original
% signal.

CriteriaLabels = cycy.utils.get_criteria_labels(CycleTable, CriteriaSet);

% TODO: explain what this is
Diagnostics = struct();

% computes booleans of whether each cycle meets each criteria
CyclesMeetCriteria = true(size(CycleTable, 1), numel(CriteriaLabels));

for idxCriteria = 1:numel(CriteriaLabels)

    Criteria = CriteriaLabels{idxCriteria};
    Threshold = CriteriaSet.(Criteria);
    CycleProperty = CycleTable.(Criteria);

    if numel(Threshold) == 1 % a scalar is provided
        isMet = CycleProperty >= Threshold;
    elseif numel(Threshold) == 2 % a range is provided
        isMet = CycleProperty >= Threshold(1) & CycleProperty <= Threshold(2);
    else
        error('incorrect number of criteria inputs')
    end

    CyclesMeetCriteria(:, idxCriteria) = isMet;
    Diagnostics.(Criteria) = nnz(~isMet);
end

% ignore cycles with a peak that is not included in KeepTimepoints
if ~isempty(KeepTimepoints)
    KeepTimepoints = find(KeepTimepoints);
    Peak_Points = CycleTable.NegPeakIdx;
    isMet = ismember(Peak_Points, KeepTimepoints);
    CyclesMeetCriteria = cat(2, CyclesMeetCriteria, isMet);
    Diagnostics.Noise = nnz(~isMet);
end

% identify number of peaks uniquely removed by a single factor for later
for idxCriteria = 1:numel(CriteriaLabels)
    Criteria = CriteriaLabels{idxCriteria};
    ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, idxCriteria);
    Diagnostics.([Criteria, 'Unique']) = nnz(ExcludedCycles);
end
end
