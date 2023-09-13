function criteriaset_diagnostics(Diagnostics)

CriteriaLabels = fieldnames(Diagnostics);
isUnique = contains(CriteriaLabels, 'Unique');
CriteriaLabelsUnique = CriteriaLabels(isUnique);
CriteriaLabelsUnique = replace(CriteriaLabelsUnique, 'Unique', '');

CriteriaLabels(isUnique) = [];
Diagnostics = cell2mat(struct2cell(Diagnostics));


figure('Units','normalized', 'position', [0 0 .5 .5])
subplot(1,2,1)
bar(categorical(CriteriaLabels), Diagnostics(~isUnique))
title('Cycles disqualified')

subplot(1,2,2)
bar(categorical(CriteriaLabelsUnique), Diagnostics(isUnique))
title('Cycles uniquely disqualified')