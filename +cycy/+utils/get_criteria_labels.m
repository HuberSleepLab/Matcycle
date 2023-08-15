function CriteriaLabels = get_criteria_labels(Cycles, CriteriaSet)
% selects the fieldnames from CriteriaSet that are also present in Cycles,
% and ignores criteria that are not specific to a signle cycle.

if isempty(CriteriaSet)
    CriteriaLabels = {};
    return
end

CycleFields = fieldnames(Cycles);

CriteriaLabels = fieldnames(CriteriaSet);

CriteriaLabels(~ismember(CriteriaLabels, CycleFields)) = []; % in case there's extra junk in there

% remove from criteria those that don't correspond to specific properties
% of cycles
CriteriaLabels(strcmp(CriteriaLabels, 'MinCyclesPerBurst')) = [];
end