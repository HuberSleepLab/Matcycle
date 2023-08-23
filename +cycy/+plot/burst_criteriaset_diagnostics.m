function burst_criteriaset_diagnostics(Bursts)

% NarrowbandRanges = unique({Bursts.Band});
NarrowbandRanges = [];
CriteriaSets = unique([Bursts.CriteriaSetIndex]);
Signs = [-1, 1];

Total = zeros(1, numel(NarrowbandRanges)*numel(CriteriaSets)*numel(Signs));
TotalUnique = Total;
Labels = cell(size(Total));

Index = 1;
% for Band = NarrowbandRanges
for CriteriaSet = CriteriaSets
    for Sign = Signs
        % isBand = strcmp({Bursts.Band}, Band);

        isCriteriaSet = [Bursts.CriteriaSetIndex] == CriteriaSet;
        isSign = [Bursts.Sign] == Sign;
        isUnique = [Bursts.debugUniqueCriteria];
        % Total(Index) = nnz(isBand & isCriteriaSet & isSign);
        % TotalUnique(Index) = nnz(isBand & isCriteriaSet & isSign & isUnique);
        % Labels{Index} = strjoin({['band', Band{1}], ['set', num2str(CriteriaSet)], ['sign', num2str(Sign)]}, ':');
        Total(Index) = nnz(isCriteriaSet & isSign);
        TotalUnique(Index) = nnz(isCriteriaSet & isSign & isUnique);
        Labels{Index} = strjoin({['set', num2str(CriteriaSet)], ['sign', num2str(Sign)]}, ':');

        Index = Index+1;
    end
end
% end


figure('Units','normalized', 'Position', [0 0 1 .4])
subplot(1, 2, 1)
bar(categorical(Labels), Total)
title('Total bursts by criteria set')

subplot(1, 2, 2)
bar(categorical(Labels), TotalUnique)
title('Total bursts by a SINGLE criteria set')


% TODO, pool for different criteria


