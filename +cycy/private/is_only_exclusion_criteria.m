function ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, IdxCriteria)
% identifies all cycles that were excluded only because of this criteria
I = 1:size(CyclesMeetCriteria, 2);
I(IdxCriteria) = [];
Remaining = all(CyclesMeetCriteria(:, I), 1);
ExcludedCycles = Remaining & ~CyclesMeetCriteria(:, IdxCriteria);
end