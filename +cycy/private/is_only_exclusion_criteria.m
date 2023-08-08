function ExcludedCycles = is_only_exclusion_criteria(CyclesMeetCriteria, IdxCriteria)
% identifies all cycles that were excluded only because of this criteria
I = 1:size(CyclesMeetCriteria, 1);
I(IdxCriteria) = [];
Remaining = all(CyclesMeetCriteria(I, :));
ExcludedCycles = Remaining & ~CyclesMeetCriteria(IdxCriteria, :);
end